# Data quality decisions

Read 2,260,701 source records in 100,000-row chunks, selecting 22 source fields. Excluded 33 invalid/footer rows; retained 2,260,668 loans. Nonmissing source identifiers are unique; a stable source-row surrogate supports missing IDs. No raw job text, ZIP, URLs or employer names are exported.

Resolved outcome flags include Fully Paid and Charged Off, including legacy equivalents. Current, Default, Late and Grace are separate states. Default is not relabeled Charged Off. Missing or negative DTI is Unknown; negative income is Unknown. Loan terms parse from text; source dates have month-level precision. FICO midpoint uses origination lower/upper bands, not later scores.

The status capture date is unverified. The latest payment month is March 2019, but that is not a confirmed extraction date. Do not derive months-on-book or lifetime default rates from it. 2018 vintages are less mature than old vintages, so report resolved coverage beside bad share.

Only accepted applications are included; conclusions do not generalize to declined applicants or a current lending population. Wilson 95% intervals quantify binomial sampling variability in resolved observations, not selection bias, censoring or causal uncertainty. No predictive model is fitted; realized payment/recovery variables are descriptive snapshot fields and would be leakage in origination prediction.

Full local rows are gitignored. Public packs use aggregate marts; dataset redistribution rights must be checked separately from the MIT code license.
