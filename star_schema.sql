-- =============================================
-- 3.2 Build the Star Schema
-- This schema implements a Star Schema optimized for healthcare analytics.
-- It resolves performance bottlenecks identified in the legacy normalized schema.
-- =============================================

-- create a Databse for the warehouse
CREATE DATABASE IF NOT EXISTS healthcare_dw;
USE healthcare_dw;

-- ---------------------------------------------------------
-- 1. DIMENSION TABLES
-- ---------------------------------------------------------

-- Date Dimension: Resolves DATE_FORMAT bottlenecks in Questions 1 & 4
CREATE TABLE dim_date(
    date_key INT PRIMARY KEY, -- Format: YYYYMMDD
    full_date DATE NOT NULL ,
    calender_year INT NOT NULL,
    calender_month INT NOT NULL,
    calender_day INT NOT NULL,
    year_months VARCHAR(7) NOT NULL,  -- Format: YYYY-MM
    month_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    INDEX idx_year_month (year_months)
)COMMENT 'Resolves date calculation bottlenecks by pre-calculating strings';

-- Patient Dimension: Flattens patient metadata
CREATE TABLE dim_patient(
    patient_key INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    mrn VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    age_at_encounter INT,           -- Calculated at load time
    INDEX idx_patient_mrn (mrn)
) COMMENT 'Flattens patient metadata for faster filtering';

-- Provider Dimension
CREATE TABLE dim_provider (
    provider_key INT AUTO_INCREMENT PRIMARY KEY,
    provider_id INT,                       -- Source System ID
    provider_name VARCHAR(200),            -- Combined First + Last
    credential VARCHAR(20),
    INDEX idx_provider_id (provider_id)
);

-- Specialty Dimension: Allows direct join to Fact Table
CREATE TABLE dim_specialty (
    specialty_key INT AUTO_INCREMENT PRIMARY KEY,
    specialty_id INT,
    specialty_name VARCHAR(100),
    specialty_code VARCHAR(10)
);

-- Department Dimension
CREATE TABLE dim_department (
    department_key INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT,
    department_name VARCHAR(100)
);

-- Encounter Type Dimension: Resolves string-comparison bottlenecks in Question 3
CREATE TABLE dim_encounter_type (
    encounter_type_key INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50),                 -- Inpatient, Outpatient, ER
    is_emergency_flag BOOLEAN DEFAULT FALSE
);

-- Diagnosis Dimension
CREATE TABLE dim_diagnosis (
    diagnosis_key INT AUTO_INCREMENT PRIMARY KEY,
    diagnosis_id INT,
    icd10_code VARCHAR(10),
    icd10_description VARCHAR(200),
    INDEX idx_icd10 (icd10_code)
);

-- Procedure Dimension
CREATE TABLE dim_procedure (
    procedure_key INT AUTO_INCREMENT PRIMARY KEY,
    procedure_id INT,
    cpt_code VARCHAR(10),
    cpt_description VARCHAR(200),
    INDEX idx_cpt (cpt_code)
);


- ---------------------------------------------------------
-- 2. FACT TABLE
-- ---------------------------------------------------------

-- Fact Encounter: One row per encounter (Option A Grain)
CREATE TABLE fact_encounters (
    fact_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    encounter_id INT,                      -- Source System ID

    -- Foreign Keys to Dimensions
    date_key INT,
    patient_key INT,
    provider_key INT,
    specialty_key INT,
    department_key INT,
    encounter_type_key INT,
    primary_diagnosis_key INT,             -- Hybrid approach: Primary diagnosis
    primary_procedure_key INT,             -- Hybrid approach: Primary procedure

    -- Pre-Aggregated Metrics: Resolves Questions 3 & 4
    total_allowed_amount DECIMAL(12,2),    -- From Billing table
    total_diagnosis_count INT,             -- Count from bridge
    total_procedure_count INT,             -- Count from bridge
    length_of_stay_days INT,               -- Discharge - Admission
    is_readmission_flag BOOLEAN,           -- Pre-calculated 30-day logic

    -- Relationships
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    FOREIGN KEY (provider_key) REFERENCES dim_provider(provider_key),
    FOREIGN KEY (specialty_key) REFERENCES dim_specialty(specialty_key),
    FOREIGN KEY (department_key) REFERENCES dim_department(department_key),
    FOREIGN KEY (encounter_type_key) REFERENCES dim_encounter_type(encounter_type_key),
    FOREIGN KEY (primary_diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key),
    FOREIGN KEY (primary_procedure_key) REFERENCES dim_procedure(procedure_key),

    -- Performance Indexes
    INDEX idx_fact_date (date_key),
    INDEX idx_fact_specialty (specialty_key),
    INDEX idx_fact_readm (is_readmission_flag)
) COMMENT 'Central fact table. Stores pre-calculated metrics to avoid expensive runtime sums and counts';


-- ---------------------------------------------------------
-- 3. BRIDGE TABLES (Hybrid Approach)
-- ---------------------------------------------------------

-- Bridge Encounter Diagnoses: For Question 2 clinical deep-dives
CREATE TABLE bridge_encounter_diagnoses (
    bridge_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    fact_key BIGINT,
    diagnosis_key INT,
    diagnosis_sequence INT,                -- 1 = Primary, 2+ = Secondary
    FOREIGN KEY (fact_key) REFERENCES fact_encounters(fact_key),
    FOREIGN KEY (diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key),
    INDEX idx_bridge_diag (diagnosis_key)
) COMMENT 'Supports many-to-many diagnosis analysis while keeping the Fact Table grain lean';


-- Bridge Encounter Procedures
CREATE TABLE bridge_encounter_procedures (
    bridge_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    fact_key BIGINT,
    procedure_key INT,
    procedure_date DATE,
    FOREIGN KEY (fact_key) REFERENCES fact_encounters(fact_key),
    FOREIGN KEY (procedure_key) REFERENCES dim_procedure(procedure_key)
);