-- Extract SQL Queries

WITH
    A1 AS
    (
        SELECT *
        FROM
            ANALYTICS_DB.METRICS_SCHEMA.TRACKING_METRICS
        LIMIT 1
    )

    ,A2 AS
    (
        SELECT *
        FROM
            CUSTOMER_DB.SEGMENTATION_SCHEMA.SEGMENT_MEMBERS
        LIMIT 1
    )

    ,A3 AS
    (
        SELECT *
        FROM
            GEOGRAPHY_DB.REGION_SCHEMA.REGION_HIERARCHY
        LIMIT 1
    )

    ,A4 AS
    (
        SELECT *
        FROM
            MARKETING_DB.CAMPAIGN_SCHEMA.ACTIVE_CAMPAIGNS
        LIMIT 1
    )

    ,A5 AS
    (
        SELECT *
        FROM
            MARKETING_DB.CAMPAIGN_SCHEMA.CAMPAIGN_REGIONS
        LIMIT 1
    )

    ,A6 AS
    (
        SELECT *
        FROM
            REPORTING_DB.DASHBOARD_SCHEMA.CAMPAIGN_PERFORMANCE
        LIMIT 1
    )

    ,A7 AS
    (
        SELECT *
        FROM
            SALES_DB.TRANSACTION_SCHEMA.CUSTOMER_TRANSACTIONS
        LIMIT 1
    )

SELECT
    'Data Preview' as DATA_PREVIEW
FROM
    A1
;
