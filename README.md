# Loan Portfolio Analytics

Historical analysis of LendingClub accepted loans, comparing funding, loan grades and vintage outcomes while tracking how much of the portfolio has resolved.

![Loan Portfolio Analytics dashboard](reports/figures/portfolio_overview.png)

**Python · MySQL · Power BI · Power Query · DAX**

## Results

- 2,260,668 accepted loans and USD 34.00 billion in funded principal.
- 269,320 charged-off loans among 1,348,059 resolved loans: a 19.98% resolved-outcome share.
- 59.63% of the portfolio is resolved, so outcome comparisons need to be read alongside maturity coverage.

## Analysis

The Python pipeline validates loan identifiers and classifies status before generating portfolio summaries. The SQL analyses compare grades, vintages, borrower characteristics and loan purposes. A vintage comparison page shows outcome and coverage gaps against the selected vintages.

The five-page Power BI report contains 26 DAX measures, filters, tooltips and drillthrough. Top navigation and KPIs lead into a central review table with supporting charts on either side.

## Explore

- [21 SQL analyses](sql/analysis_queries.sql) and [database schema](sql/schema.sql)
- [Analysis notebook](notebooks/01_analysis.ipynb) and [Python pipeline](src/pipeline.py)
- [Power BI project](powerbi/Loan_Portfolio.pbip) and [DAX measures](powerbi/measures.dax)
- [Vintage comparison](reports/figures/comparison_review.png)
- [Data dictionary](reports/DATA_DICTIONARY.md), [data preparation](reports/DATA_QUALITY.md) and [measure definitions](powerbi/MEASURE_DEFINITIONS.md)

## Run locally

Use Python 3.11+ and obtain `accepted_2007_to_2018Q4.csv` separately.

```bash
pip install -r requirements.txt
python src/pipeline.py --source "path/to/accepted_2007_to_2018Q4.csv"
python src/comparison_analysis.py
python -m pytest tests -q
```

For MySQL 8, create an empty local database, set the `DATABASE_URL` environment variable using `.env.example`, enable LOCAL INFILE and run `python src/database.py`. SQL results and KPI reconciliation are saved under `reports/`.

Open `powerbi/Loan_Portfolio.pbip` in Power BI Desktop. Set `DataRoot` to the generated `data/` folder with a trailing slash, then refresh. Themes are in `powerbi/themes/`.

## Data notes

This is descriptive analysis of accepted loans. The charged-off share uses resolved loans as its denominator; it is not an origination default prediction. Unresolved loans, accepted-only selection and different observation periods limit comparisons. Vintage gaps retain grade filters and do not adjust for maturity.

Source: [LendingClub historical data](https://www.kaggle.com/datasets/wordsforthewise/lending-club). Raw loan records are excluded because redistribution terms have not been confirmed. Code is covered by [MIT](LICENSE).
