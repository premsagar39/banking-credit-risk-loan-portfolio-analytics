# Measure definitions


Resolved outcomes include Fully Paid and Charged Off only. No default prediction, lifetime loss estimate, causal effect or lender decision recommendation is made. Wilson intervals quantify binomial sampling uncertainty, not selection or censoring bias.

## Loans

Format: `#,0`

```dax
COUNTROWS(Loans)
```

## Funded Amount

Format: `$#,0`

```dax
SUM(Loans[FundedAmount])
```

## Outstanding Principal

Format: `$#,0`

```dax
SUM(Loans[OutstandingPrincipal])
```

## Average Loan Size

Format: `$#,0`

```dax
DIVIDE([Funded Amount],[Loans])
```

## Mean Interest Rate

Format: `0.00%`

```dax
AVERAGE(Loans[InterestRatePct])/100
```

## Weighted Interest Rate

Format: `0.00%`

```dax
DIVIDE(SUMX(Loans,Loans[InterestRatePct]*Loans[FundedAmount]),SUMX(FILTER(Loans,NOT ISBLANK(Loans[InterestRatePct])),Loans[FundedAmount]))/100
```

## Resolved Loans

Format: `#,0`

```dax
SUM(Loans[ResolvedFlag])
```

## Charged Off Loans

Format: `#,0`

```dax
SUM(Loans[BadResolvedFlag])
```

## Bad Resolved Share

Format: `0.0%`

```dax
DIVIDE([Charged Off Loans],[Resolved Loans])
```

## Resolved Share

Format: `0.0%`

```dax
DIVIDE([Resolved Loans],[Loans])
```

## Unresolved Loans

Format: `#,0`

```dax
[Loans]-[Resolved Loans]
```

## Current Loans

Format: `#,0`

```dax
CALCULATE([Loans],Loans[StatusGroup]="Current")
```

## Late or Grace Loans

Format: `#,0`

```dax
CALCULATE([Loans],Loans[StatusGroup]="Late / grace")
```

## Default Status Loans

Format: `#,0`

```dax
CALCULATE([Loans],Loans[StatusGroup]="Default")
```

## Fully Paid Loans

Format: `#,0`

```dax
CALCULATE([Loans],Loans[StatusGroup]="Resolved good")
```

## Snapshot Distress Share

Format: `0.0%`

```dax
DIVIDE(SUM(Loans[DistressFlag]),[Loans])
```

## Median Stated Income

Format: `$#,0`

```dax
MEDIANX(FILTER(Loans,Loans[AnnualIncome]>=0),Loans[AnnualIncome])
```

## Mean Nonnegative DTI

Format: `0.0`

```dax
AVERAGEX(FILTER(Loans,Loans[DTI]>=0),Loans[DTI])
```

## Median Origination FICO

Format: `0`

```dax
MEDIAN(Loans[FicoMid])
```

## Mean Term Months

Format: `0.0`

```dax
AVERAGE(Loans[TermMonths])
```

## Funding Share

Format: `0.0%`

```dax
DIVIDE([Funded Amount],CALCULATE([Funded Amount],ALLSELECTED(Loans)))
```

## Exposure to Funding

Format: `0.0%`

```dax
DIVIDE([Outstanding Principal],[Funded Amount])
```

## Bad Share Wilson Lower

Format: `0.0%`

```dax
VAR N=[Resolved Loans] VAR P=[Bad Resolved Share] RETURN IF(N>0,DIVIDE(P+3.8416/(2*N)-1.96*SQRT(P*(1-P)/N+3.8416/(4*N*N)),1+3.8416/N))
```

## Bad Share Wilson Upper

Format: `0.0%`

```dax
VAR N=[Resolved Loans] VAR P=[Bad Resolved Share] RETURN IF(N>0,DIVIDE(P+3.8416/(2*N)+1.96*SQRT(P*(1-P)/N+3.8416/(4*N*N)),1+3.8416/N))
```

## Outcome Gap pp

Charged-off share among resolved loans minus the selected-vintage weighted share; percentage points.

```dax
VAR B=CALCULATE([Bad Resolved Share],ALLSELECTED(Loans[VintageYear])) RETURN IF(NOT ISBLANK([Bad Resolved Share]) && NOT ISBLANK(B),100*([Bad Resolved Share]-B))
```

## Coverage Gap pp

Resolved share minus selected-vintage weighted coverage; percentage points. Not a maturity adjustment.

```dax
VAR B=CALCULATE([Resolved Share],ALLSELECTED(Loans[VintageYear])) RETURN IF([Loans]>0,100*([Resolved Share]-B))
```
