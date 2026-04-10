# Healthcare Data Speed & Design Lab

This project shows how to take a slow healthcare database and make it much faster using "Star Schema" design. We focused on solving real-world problems like tracking patient readmissions and hospital revenue.

## Project Files
- `old_schema.sql`: The original database (slow but organized).
- `star_schema.sql`: The new, faster database design.
- `etl_process.sql`: The code that moves and cleans data.
- `etl_design.txt`: Detailed logic for the data moving process.
- `design_decisions.txt`: Documentation of all table and column choices.
- `query_analysis.txt`: Breakdown of original performance issues.
- `star_schema_queries.txt`: Optimized SQL results and speed comparisons.
- `reflection.md`: A deep dive into why these changes work (Project Deliverable).

---

## What We Solved

### 1. Speeding Up Date Reports
**Problem:** The original system was slow when counting visits per month because it had to calculate the date for every single record during the search.
**Solution:** We created a `dim_date` table that has the month and year already written out. Now the database just looks it up instantly instead of doing math.

### 2. Simplifying Clinical Data
**Problem:** Finding which diagnosis code matches which procedure code required joining 4 different tables, which is very heavy for the computer.
**Solution:** We used bridge tables and simplified dimensions so the database has fewer "hops" to make to find the answer.

### 3. Fixing the "Readmission" Calculation
**Problem:** To see if a patient came back within 30 days, the old system had to compare every visit to every other visit. This was the slowest part of the whole system.
**Solution:** We did the math **before** saving the data. We added a simple checkbox (flag) to each visit that says "Yes" or "No" for readmission. Now the report just counts the "Yes" marks.

---

## Why the New Design is Better

1.  **Fewer Joins:** In the old way, you had to connect 3 or 4 tables to get a specialty name. In the new way, it's always just **one connection** away.
2.  **No More Busy Work:** We moved the heavy math (like calculating age or total bills) to the "loading" stage. When a user runs a report, the answers are already there waiting for them.
3.  **Accuracy:** By using "Bridge Tables," we make sure that if a patient has 3 different diagnoses, we don't accidentally triple-count their hospital bill.

## Performance Results
- **Monthly Reports:** Went from 1.3 seconds to 0.04 seconds (**30x faster**).
- **Readmission Reports:** Went from 0.4 seconds to 0.02 seconds (**17x faster**).
