# Data dictionary

SQL types, nullable attributes, primary keys and relationships are defined in `sql/schema.sql`. All pipeline output columns are specified in `src/schema.json`.

## grades

| Field | MySQL type |
|---|---|
| Grade | VARCHAR(32) NOT NULL PRIMARY KEY |

## states

| Field | MySQL type |
|---|---|
| State | VARCHAR(64) NOT NULL PRIMARY KEY |

## purposes

| Field | MySQL type |
|---|---|
| Purpose | VARCHAR(100) NOT NULL PRIMARY KEY |

## loans

| Field | MySQL type |
|---|---|
| LoanKey | BIGINT NOT NULL PRIMARY KEY |
| SourceLoanID | VARCHAR(64) |
| LoanAmount | DECIMAL(20,6) |
| FundedAmount | DECIMAL(20,6) |
| InterestRatePct | DOUBLE |
| Grade | VARCHAR(32) |
| SubGrade | VARCHAR(32) |
| LoanStatus | VARCHAR(100) |
| AnnualIncome | DOUBLE |
| DTI | DOUBLE |
| Purpose | VARCHAR(100) |
| State | VARCHAR(64) |
| HomeOwnership | VARCHAR(64) |
| ApplicationType | VARCHAR(64) |
| OutstandingPrincipal | DECIMAL(20,6) |
| TotalPayment | DECIMAL(20,6) |
| Recoveries | DECIMAL(20,6) |
| EmploymentLength | VARCHAR(64) |
| IssueDate | DATE |
| LastPaymentDate | DATE |
| TermMonths | INT |
| IssueMonth | VARCHAR(7) |
| VintageYear | INT |
| StatusGroup | VARCHAR(32) |
| ResolvedFlag | INT |
| BadResolvedFlag | INT |
| DistressFlag | INT |
| IncomeBand | VARCHAR(64) |
| DtiBand | VARCHAR(64) |
| FicoMid | DOUBLE |
