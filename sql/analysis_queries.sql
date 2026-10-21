-- Q01: Portfolio controls
SELECT COUNT(*) Loans,SUM(FundedAmount) FundedAmount,SUM(OutstandingPrincipal) OutstandingPrincipal,AVG(InterestRatePct) MeanInterestRate,SUM(InterestRatePct*FundedAmount)/SUM(CASE WHEN InterestRatePct IS NOT NULL THEN FundedAmount END) WeightedInterestRate,SUM(ResolvedFlag) ResolvedLoans,SUM(BadResolvedFlag) BadResolvedLoans,SUM(BadResolvedFlag)/SUM(ResolvedFlag) BadResolvedShare FROM loans;

-- Q02: Snapshot status composition
SELECT LoanStatus,COUNT(*) Loans,SUM(FundedAmount) FundedAmount,COUNT(*)/SUM(COUNT(*)) OVER() LoanShare FROM loans GROUP BY LoanStatus ORDER BY Loans DESC;

-- Q03: Grade risk with maturity coverage
SELECT Grade,COUNT(*) Loans,SUM(FundedAmount) FundedAmount,SUM(ResolvedFlag)/COUNT(*) ResolvedShare,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY Grade ORDER BY Grade;

-- Q04: Subgrade Wilson interval
WITH s AS (SELECT SubGrade,SUM(ResolvedFlag) n,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) p FROM loans GROUP BY SubGrade) SELECT *, (p+1.96*1.96/(2*n)-1.96*SQRT(p*(1-p)/n+POW(1.96,2)/(4*n*n)))/(1+POW(1.96,2)/n) WilsonLower95,(p+1.96*1.96/(2*n)+1.96*SQRT(p*(1-p)/n+POW(1.96,2)/(4*n*n)))/(1+POW(1.96,2)/n) WilsonUpper95 FROM s ORDER BY SubGrade;

-- Q05: Vintage outcomes and unresolved share
SELECT VintageYear,COUNT(*) Loans,SUM(FundedAmount) FundedAmount,SUM(ResolvedFlag)/COUNT(*) ResolvedShare,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY VintageYear ORDER BY VintageYear;

-- Q06: Monthly issuance trend
WITH m AS (SELECT IssueMonth,COUNT(*) Loans,SUM(FundedAmount) FundedAmount FROM loans GROUP BY IssueMonth) SELECT *,FundedAmount/LAG(FundedAmount) OVER(ORDER BY IssueMonth)-1 MoMGrowth FROM m ORDER BY IssueMonth;

-- Q07: Purpose mix
SELECT Purpose,COUNT(*) Loans,SUM(FundedAmount) FundedAmount,SUM(FundedAmount)/SUM(SUM(FundedAmount)) OVER() FundingShare,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY Purpose ORDER BY FundingShare DESC;

-- Q08: State ranking
SELECT State,COUNT(*) Loans,SUM(FundedAmount) FundedAmount,DENSE_RANK() OVER(ORDER BY SUM(FundedAmount) DESC) FundingRank FROM loans GROUP BY State;

-- Q09: Income and debt bands
SELECT IncomeBand,DtiBand,COUNT(*) Loans,AVG(AnnualIncome) AverageIncome,SUM(ResolvedFlag) ResolvedLoans,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY IncomeBand,DtiBand ORDER BY IncomeBand,DtiBand;

-- Q10: Term comparison
SELECT TermMonths,COUNT(*) Loans,AVG(InterestRatePct) AverageRate,SUM(ResolvedFlag)/COUNT(*) ResolvedShare,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY TermMonths;

-- Q11: Origination FICO bands
SELECT CASE WHEN FicoMid IS NULL THEN 'Unknown' WHEN FicoMid<680 THEN 'Under 680' WHEN FicoMid<720 THEN '680-719' WHEN FicoMid<760 THEN '720-759' ELSE '760+' END FicoBand,COUNT(*) Loans,SUM(ResolvedFlag) ResolvedLoans,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY FicoBand;

-- Q12: Application type and grade
SELECT ApplicationType,Grade,COUNT(*) Loans,SUM(FundedAmount) FundedAmount,SUM(ResolvedFlag) ResolvedLoans,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY ApplicationType,Grade;

-- Q13: Loan size bands
SELECT CASE WHEN LoanAmount<10000 THEN 'Under 10k' WHEN LoanAmount<20000 THEN '10k-20k' WHEN LoanAmount<30000 THEN '20k-30k' ELSE '30k+' END SizeBand,COUNT(*) Loans,AVG(InterestRatePct) AverageRate,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY SizeBand;

-- Q14: Loan to stated income ratio
SELECT IncomeBand,COUNT(*) Loans,AVG(LoanAmount/NULLIF(AnnualIncome,0)) MeanLoanIncomeRatio,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans WHERE AnnualIncome>0 GROUP BY IncomeBand;

-- Q15: Outstanding exposure by grade
SELECT Grade,SUM(OutstandingPrincipal) OutstandingPrincipal,SUM(OutstandingPrincipal)/SUM(SUM(OutstandingPrincipal)) OVER() ExposureShare FROM loans GROUP BY Grade ORDER BY Grade;

-- Q16: Funding concentration HHI across states
WITH s AS (SELECT State,SUM(FundedAmount) FundedAmount FROM loans GROUP BY State), shares AS (SELECT FundedAmount/SUM(FundedAmount) OVER() p FROM s) SELECT SUM(p*p) StateFundingHHI FROM shares;

-- Q17: Largest grade exposure within states
WITH s AS (SELECT State,Grade,SUM(FundedAmount) FundedAmount FROM loans GROUP BY State,Grade),r AS (SELECT *,ROW_NUMBER() OVER(PARTITION BY State ORDER BY FundedAmount DESC,Grade) rn FROM s) SELECT * FROM r WHERE rn=1 ORDER BY FundedAmount DESC;

-- Q18: Home ownership comparison
SELECT HomeOwnership,COUNT(*) Loans,SUM(ResolvedFlag) ResolvedLoans,SUM(BadResolvedFlag)/NULLIF(SUM(ResolvedFlag),0) BadResolvedShare FROM loans GROUP BY HomeOwnership ORDER BY Loans DESC;

-- Q19: Current distress and charge-offs kept distinct
SELECT StatusGroup,COUNT(*) Loans,SUM(FundedAmount) FundedAmount,SUM(OutstandingPrincipal) OutstandingPrincipal FROM loans WHERE StatusGroup IN ('Resolved bad','Default','Late / grace') GROUP BY StatusGroup;

-- Q20: Year-over-year monthly issuance
WITH m AS (SELECT IssueMonth,SUM(FundedAmount) FundedAmount FROM loans GROUP BY IssueMonth) SELECT a.IssueMonth,a.FundedAmount,b.FundedAmount PriorYearFunding,a.FundedAmount/NULLIF(b.FundedAmount,0)-1 YoYGrowth FROM m a LEFT JOIN m b ON b.IssueMonth=DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(a.IssueMonth,'-01'),'%Y-%m-%d'),INTERVAL 1 YEAR),'%Y-%m') ORDER BY a.IssueMonth;

-- Q21: Vintage outcomes and coverage against a weighted within-grade benchmark
WITH v AS (
 SELECT Grade,VintageYear,COUNT(*) Loans,SUM(ResolvedFlag) ResolvedLoans,SUM(BadResolvedFlag) ChargedOffLoans
 FROM loans GROUP BY Grade,VintageYear
)
SELECT *,ResolvedLoans*1e0/NULLIF(Loans,0) ResolvedCoverage,
 ChargedOffLoans*1e0/NULLIF(ResolvedLoans,0) ChargedOffShare,
 100*(ChargedOffLoans*1e0/NULLIF(ResolvedLoans,0)-SUM(ChargedOffLoans) OVER(PARTITION BY Grade)*1e0/NULLIF(SUM(ResolvedLoans) OVER(PARTITION BY Grade),0)) OutcomeGapPP,
 100*(ResolvedLoans*1e0/NULLIF(Loans,0)-SUM(ResolvedLoans) OVER(PARTITION BY Grade)*1e0/NULLIF(SUM(Loans) OVER(PARTITION BY Grade),0)) CoverageGapPP
FROM v ORDER BY Grade,VintageYear;
