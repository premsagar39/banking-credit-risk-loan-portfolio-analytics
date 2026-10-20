-- MySQL 8.0+. Run against an empty project database, never a production schema.

CREATE TABLE IF NOT EXISTS `grades` (
  `Grade` VARCHAR(32) NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE IF NOT EXISTS `states` (
  `State` VARCHAR(64) NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE IF NOT EXISTS `purposes` (
  `Purpose` VARCHAR(100) NOT NULL PRIMARY KEY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE TABLE IF NOT EXISTS `loans` (
  `LoanKey` BIGINT NOT NULL PRIMARY KEY,
  `SourceLoanID` VARCHAR(64),
  `LoanAmount` DECIMAL(20,6),
  `FundedAmount` DECIMAL(20,6),
  `InterestRatePct` DOUBLE,
  `Grade` VARCHAR(32),
  `SubGrade` VARCHAR(32),
  `LoanStatus` VARCHAR(100),
  `AnnualIncome` DOUBLE,
  `DTI` DOUBLE,
  `Purpose` VARCHAR(100),
  `State` VARCHAR(64),
  `HomeOwnership` VARCHAR(64),
  `ApplicationType` VARCHAR(64),
  `OutstandingPrincipal` DECIMAL(20,6),
  `TotalPayment` DECIMAL(20,6),
  `Recoveries` DECIMAL(20,6),
  `EmploymentLength` VARCHAR(64),
  `IssueDate` DATE,
  `LastPaymentDate` DATE,
  `TermMonths` INT,
  `IssueMonth` VARCHAR(7),
  `VintageYear` INT,
  `StatusGroup` VARCHAR(32),
  `ResolvedFlag` INT,
  `BadResolvedFlag` INT,
  `DistressFlag` INT,
  `IncomeBand` VARCHAR(64),
  `DtiBand` VARCHAR(64),
  `FicoMid` DOUBLE,
  FOREIGN KEY (`Grade`) REFERENCES grades(`Grade`),
  FOREIGN KEY (`State`) REFERENCES states(`State`),
  FOREIGN KEY (`Purpose`) REFERENCES purposes(`Purpose`),
  INDEX ix_vintage_grade (`VintageYear`,`Grade`),
  INDEX ix_status (`StatusGroup`),
  INDEX ix_issue (`IssueDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;

CREATE OR REPLACE VIEW resolved_loans AS SELECT * FROM loans WHERE ResolvedFlag=1;