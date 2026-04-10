# Healthcare Data Modeling & Performance Lab

This project focuses on analyzing healthcare encounter data, diagnosis-procedure combinations, and readmission metrics using SQL. It includes performance analysis and query optimization strategies.

## Project Structure
- `old_schema.sql`: Database schema and sample data.
- `console.sql`: SQL queries, `EXPLAIN` plans, and performance documentation.

## Analysis Steps

### 1. Monthly Encounters by Specialty
**Objective:** Calculate total encounters and unique patients per month, specialty, and encounter type.
**Optimization Note:** Identified that using `DATE_FORMAT` on indexed columns in a `GROUP BY` clause can trigger a Full Table Scan (`ALL`).

### 2. Diagnosis-Procedure Combinations
**Objective:** Find the most frequent pairs of ICD-10 diagnosis codes and CPT procedure codes.
**Technical Detail:** Implemented a 4-table join linking `diagnoses` → `encounter_diagnoses` → `encounter_procedures` → `procedures`.

### 3. Specialty Readmission Rates
**Objective:** Calculate the 30-day readmission rate per specialty.
**Logic:** 
- Used a **Self-Join** on the `encounters` table (matching on `patient_id`).
- Defined readmissions as any subsequent encounter occurring within 0-30 days of an `Inpatient` discharge date.
- Utilized a `LEFT JOIN` to ensure the denominator includes all inpatient stays, even those without a return visit.

## Performance & Senior-Level Observations
- **Join Complexity:** Multiple joins across large transactional tables (encounters/diagnoses) require careful indexing on foreign keys.
- **Self-Join Cost:** To optimize the readmission query, date filters (`e2.encounter_date > e.discharge_date`) are applied within the join condition to reduce the Cartesian product before aggregation.
- **Aggregation:** `COUNT(DISTINCT ...)` is used to ensure data integrity when calculating rates across joined encounter pairs.
