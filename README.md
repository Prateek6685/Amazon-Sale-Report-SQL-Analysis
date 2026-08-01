## Amazon Sale Report — SQL Analysis
Dataset: Kaggle Amazon Sale Report (128,975 rows)

### Approach
1. Cleaned and structured data in Excel (Power Query)
2. Built KPI dashboard + PivotTables in Excel
3. Rebuilt the same analysis in MySQL to cross-validate

### Key SQL techniques used
- Window functions (RANK, PARTITION BY)
- CTEs
- CASE WHEN status categorization
- Bulk import via LOAD DATA LOCAL INFILE

## A Real Debugging Story: Bypassing GUI Limits for Bulk Data Ingestion
Initially, I attempted to import this 128,000+ row dataset using the MySQL Workbench Import Wizard. The GUI struggled with the volume, processing row-by-row inserts that would have taken hours, and eventually crashed. 

To solve this, I pivoted to a programmatic approach using a `LOAD DATA LOCAL INFILE` SQL script. This introduced new challenges: the server blocked the local upload for security reasons (Error 3948), and the default UTF-8 encoding crashed on anomalous characters in the raw text (Error 1300). 

I debugged this by explicitly reconfiguring the global server settings (`SET GLOBAL local_infile = 1`) and mapping the data stream to a `latin1` character set. This bypassed the GUI overhead and successfully reduced the import time from several hours down to a few seconds.

### Files
- sales_queries.sql
- sales_clean.csv (or a note that raw data is from Kaggle, linked)
