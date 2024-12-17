-- Create databases
CREATE DATABASE CUSTOMER_DB;
CREATE DATABASE ORDER_DB;
CREATE DATABASE PRODUCT_DB;
CREATE DATABASE ANALYTICS_DB;
CREATE DATABASE RISK_DB;
CREATE DATABASE STAGING_DB;
CREATE DATABASE ARCHIVE_DB;

-- Create tables in respective databases
USE CUSTOMER_DB;
CREATE TABLE CUSTOMER_PROFILE (
    customer_id INT,
    customer_name VARCHAR(255),
    registration_date DATE
);

USE ORDER_DB;
CREATE TABLE ORDER_HISTORY (
    order_id INT,
    customer_id INT,
    order_amount DECIMAL(10, 2),
    product_id INT
);

USE PRODUCT_DB;
CREATE TABLE PRODUCT_CATALOG (
    product_id INT,
    product_category VARCHAR(255)
);

USE ANALYTICS_DB;
CREATE TABLE USER_EVENTS (
    user_id INT,
    session_id INT,
    session_duration INT,
    event_type VARCHAR(255),
    event_date DATE
);

CREATE TABLE CUSTOMER_360_VIEW (
    customer_id INT,
    customer_name VARCHAR(255),
    registration_date DATE,
    total_orders INT,
    lifetime_value DECIMAL(10, 2),
    preferred_category VARCHAR(255),
    total_sessions INT,
    avg_session_length DECIMAL(10, 2),
    purchase_events INT,
    risk_score DECIMAL(10, 2),
    customer_tier VARCHAR(255)
);

CREATE TABLE QUALITY_FLAGS (
    report_name VARCHAR(255),
    last_checked_timestamp TIMESTAMP,
    records_processed INT
);

USE RISK_DB;
CREATE TABLE CUSTOMER_RISK_ASSESSMENT (
    customer_id INT,
    risk_score DECIMAL(10, 2),
    last_assessment_date DATE,
    is_active BOOLEAN
);

USE STAGING_DB;
CREATE TABLE CALCULATE_CUSTOMER_TIER (
    customer_id INT,
    tier VARCHAR(255)
);

USE ARCHIVE_DB;
CREATE TABLE CUSTOMER_360_ARCHIVE (
    customer_id INT,
    customer_name VARCHAR(255),
    registration_date DATE,
    total_orders INT,
    lifetime_value DECIMAL(10, 2),
    preferred_category VARCHAR(255),
    total_sessions INT,
    avg_session_length DECIMAL(10, 2),
    purchase_events INT,
    risk_score DECIMAL(10, 2),
    customer_tier VARCHAR(255),
    archived_timestamp TIMESTAMP
);