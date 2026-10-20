"""Chunked historical accepted-loan analysis. No credit approval decisions or predictive model."""
from pathlib import Path
import argparse
import json
import numpy as np
import pandas as pd
import duckdb

ROOT=Path(__file__).resolve().parents[1]
COLUMNS=['id','loan_amnt','funded_amnt','term','int_rate','grade','sub_grade','issue_d','loan_status','annual_inc','dti','purpose','addr_state','home_ownership','emp_length','fico_range_low','fico_range_high','application_type','out_prncp','total_pymnt','recoveries','last_pymnt_d']

def classify_status(status):
    """Resolve only fully paid and charged-off outcomes; keep current/default/late separate."""
    return np.select([status.str.contains('Fully Paid',na=False),status.str.contains('Charged Off',na=False),status.eq('Current'),status.eq('Default'),status.str.contains('Late|Grace',na=False)],['Resolved good','Resolved bad','Current','Default','Late / grace'],default='Other')

def clean_chunk(d,offset):
    d=d.copy()
    d['LoanKey']=np.arange(offset+1,offset+len(d)+1,dtype='int64')
    d['IssueDate']=pd.to_datetime(d.issue_d,format='%b-%Y',errors='coerce')
    d['LastPaymentDate']=pd.to_datetime(d.last_pymnt_d,format='%b-%Y',errors='coerce')
    numeric=['loan_amnt','funded_amnt','int_rate','annual_inc','dti','fico_range_low','fico_range_high','out_prncp','total_pymnt','recoveries']
    for c in numeric:d[c]=pd.to_numeric(d[c],errors='coerce')
    valid=d.IssueDate.notna() & d.loan_amnt.gt(0) & d.funded_amnt.ge(0) & d.loan_status.notna()
    d=d.loc[valid].copy()
    d['StatusGroup']=classify_status(d.loan_status)
    d['ResolvedFlag']=d.StatusGroup.isin(['Resolved good','Resolved bad']).astype(int)
    d['BadResolvedFlag']=d.StatusGroup.eq('Resolved bad').astype(int)
    d['DistressFlag']=(d.StatusGroup.isin(['Resolved bad','Default'])).astype(int)
    d['IncomeBand']=pd.cut(d.annual_inc,bins=[-np.inf,40000,80000,120000,np.inf],labels=['Under 40k','40k to under 80k','80k to under 120k','120k+'],right=False).astype('string').fillna('Unknown')
    d.loc[d.annual_inc.lt(0),'IncomeBand']='Unknown'
    d['DtiBand']=pd.cut(d.dti.where(d.dti.ge(0)),bins=[0,10,20,30,40,np.inf],labels=['Under 10','10 to under 20','20 to under 30','30 to under 40','40+'],right=False).astype('string').fillna('Unknown')
    d['FicoMid']=(d.fico_range_low+d.fico_range_high)/2
    d['TermMonths']=pd.to_numeric(d.term.astype('string').str.extract(r'(\d+)',expand=False),errors='coerce')
    d['IssueMonth']=d.IssueDate.dt.strftime('%Y-%m');d['VintageYear']=d.IssueDate.dt.year
    rename={'id':'SourceLoanID','loan_amnt':'LoanAmount','funded_amnt':'FundedAmount','int_rate':'InterestRatePct','grade':'Grade','sub_grade':'SubGrade','loan_status':'LoanStatus','annual_inc':'AnnualIncome','dti':'DTI','purpose':'Purpose','addr_state':'State','home_ownership':'HomeOwnership','application_type':'ApplicationType','out_prncp':'OutstandingPrincipal','total_pymnt':'TotalPayment','recoveries':'Recoveries','emp_length':'EmploymentLength'}
    d=d.rename(columns=rename)
    for c in ['SourceLoanID','Grade','SubGrade','Purpose','State','HomeOwnership','ApplicationType','EmploymentLength']:
        d[c]=d[c].astype('string').str.strip().fillna('Unknown')
    d=d[['LoanKey',*rename.values(),'IssueDate','LastPaymentDate','TermMonths','IssueMonth','VintageYear','StatusGroup','ResolvedFlag','BadResolvedFlag','DistressFlag','IncomeBand','DtiBand','FicoMid']]
    return d,int((~valid).sum())

def run(source,root=ROOT):
    root=Path(root);out=root/'data/processed';exports=root/'data/exports';reports=root/'reports'
    for p in [out,exports,reports]:p.mkdir(parents=True,exist_ok=True)
    file=out/'loans.csv';raw_count=invalid=0;missing={};first=True
    for chunk in pd.read_csv(source,usecols=COLUMNS,dtype='string',chunksize=100000,low_memory=False):
        for c in COLUMNS:missing[c]=missing.get(c,0)+int(chunk[c].isna().sum())
        clean,rejected=clean_chunk(chunk,raw_count);raw_count+=len(chunk);invalid+=rejected
        clean.to_csv(file,index=False,mode='w' if first else 'a',header=first,float_format='%.6f',date_format='%Y-%m-%d')
        first=False
        print(f'Processed {raw_count:,} source rows',flush=True)
    con=duckdb.connect()
    con.execute("CREATE TABLE loans AS SELECT * FROM read_csv_auto(?, sample_size=-1, types={'SourceLoanID':'VARCHAR'})",[str(file)])
    con.execute("COPY loans TO ? (FORMAT PARQUET, COMPRESSION ZSTD)",[str(out/'loans.parquet')])
    totals=con.execute('''SELECT COUNT(*) n,SUM(FundedAmount) funded,SUM(LoanAmount) issued,SUM(OutstandingPrincipal) outstanding,AVG(InterestRatePct) average_rate,SUM(InterestRatePct*FundedAmount)/SUM(CASE WHEN InterestRatePct IS NOT NULL THEN FundedAmount END) weighted_rate,SUM(ResolvedFlag) resolved,SUM(BadResolvedFlag) bad,SUM(DistressFlag) distressed,MIN(IssueDate) first_issue,MAX(IssueDate) last_issue,MAX(LastPaymentDate) last_payment,COUNT(DISTINCT State) states FROM loans''').fetchdf().iloc[0].to_dict()
    for label,col in [('grade','Grade'),('status','LoanStatus'),('purpose','Purpose'),('state','State'),('income','IncomeBand'),('dti','DtiBand'),('term','TermMonths'),('home_ownership','HomeOwnership'),('monthly','IssueMonth'),('vintage','VintageYear')]:
        frame=con.execute(f'''SELECT {col}, COUNT(*) AS Loans,SUM(FundedAmount) AS FundedAmount,SUM(OutstandingPrincipal) AS OutstandingPrincipal,AVG(InterestRatePct) AS AverageInterestRate,SUM(ResolvedFlag) AS ResolvedLoans,SUM(BadResolvedFlag) AS BadResolvedLoans,SUM(BadResolvedFlag)*1.0/NULLIF(SUM(ResolvedFlag),0) AS BadResolvedShare,SUM(ResolvedFlag)*1.0/COUNT(*) AS ResolvedShare FROM loans GROUP BY {col} ORDER BY {col}''').fetchdf()
        if label=='grade':
            n=frame.ResolvedLoans;p=frame.BadResolvedShare;denom=1+1.96**2/n;center=(p+1.96**2/(2*n))/denom;half=1.96*np.sqrt(p*(1-p)/n+1.96**2/(4*n*n))/denom
            frame['WilsonLower95']=center-half;frame['WilsonUpper95']=center+half
        frame.to_csv(exports/(label+'_portfolio.csv'),index=False,float_format='%.8f')
        if label in ['grade','state','purpose']:
            dimension={'grade':'grades','state':'states','purpose':'purposes'}[label]
            frame[[col]].to_csv(out/(dimension+'.csv'),index=False)
    con.execute('''SELECT VintageYear,Grade,COUNT(*) AS Loans,SUM(FundedAmount) AS FundedAmount,SUM(ResolvedFlag) AS ResolvedLoans,SUM(BadResolvedFlag) AS BadResolvedLoans,SUM(BadResolvedFlag)*1.0/NULLIF(SUM(ResolvedFlag),0) AS BadResolvedShare FROM loans GROUP BY VintageYear,Grade ORDER BY VintageYear,Grade''').fetchdf().to_csv(exports/'vintage_grade.csv',index=False,float_format='%.8f')
    duplicate_ids=con.execute("SELECT COUNT(*) FROM (SELECT SourceLoanID FROM loans WHERE SourceLoanID <> 'Unknown' GROUP BY SourceLoanID HAVING COUNT(*)>1)").fetchone()[0]
    totals={k:(str(v) if hasattr(v,'isoformat') else int(v) if k in ['n','resolved','bad','distressed','states'] else float(v)) for k,v in totals.items()}
    totals.update(raw_rows=raw_count,invalid_rows_excluded=invalid,duplicate_nonmissing_source_ids=int(duplicate_ids),bad_resolved_share=totals['bad']/totals['resolved'],distress_snapshot_share=totals['distressed']/totals['n'],missing_by_source_column=missing,source_status_capture_date='Unverified; latest payment month is not a confirmed capture date')
    assert totals['n']+invalid==raw_count
    assert duplicate_ids==0,'Duplicate loan identifiers require review'
    (reports/'metrics.json').write_text(json.dumps(totals,indent=2),encoding='utf-8')
    print(json.dumps(totals,indent=2),flush=True)
    con.close();return totals

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source',required=True,type=Path);a=p.parse_args()
    if not a.source.is_file():p.error('Loan CSV not found')
    run(a.source)
