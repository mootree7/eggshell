-- Marketing Campaign Analysis
WITH campaign_metrics AS (
    SELECT 
        c.campaign_id,
        c.campaign_name,
        SUM(t.transaction_amount) as total_revenue,
        COUNT(DISTINCT t.customer_id) as unique_customers
    FROM MARKETING_DB.CAMPAIGN_SCHEMA.ACTIVE_CAMPAIGNS c
    LEFT JOIN SALES_DB.TRANSACTION_SCHEMA.CUSTOMER_TRANSACTIONS t
        ON c.campaign_id = t.campaign_id
    WHERE c.is_active = true
    GROUP BY 1, 2
),

customer_segments AS (
    SELECT 
        s.segment_id,
        s.segment_name,
        COUNT(m.customer_id) as member_count
    FROM CUSTOMER_DB.SEGMENT_DEFINITIONS s
    JOIN CUSTOMER_DB.SEGMENTATION_SCHEMA.SEGMENT_MEMBERS m
        ON s.segment_id = m.segment_id
    GROUP BY 1, 2
),

regional_performance AS (
    SELECT 
        r.region_code,
        r.region_name,
        cm.campaign_id,
        AVG(t.conversion_rate) as avg_conversion
    FROM GEOGRAPHY_DB.REGION_SCHEMA.REGION_HIERARCHY r
    JOIN MARKETING_DB.CAMPAIGN_SCHEMA.CAMPAIGN_REGIONS cr
        ON r.region_code = cr.region_code
    JOIN ANALYTICS_DB.METRICS_SCHEMA.TRACKING_METRICS t
        ON r.region_code = t.region_code
    JOIN campaign_metrics cm
        ON t.campaign_id = cm.campaign_id
    GROUP BY 1, 2, 3
)

INSERT INTO REPORTING_DB.DASHBOARD_SCHEMA.CAMPAIGN_PERFORMANCE
SELECT 
    cm.*,
    cs.segment_name,
    rp.region_name,
    rp.avg_conversion
FROM campaign_metrics cm
JOIN customer_segments cs
    ON cm.segment_id = cs.segment_id
JOIN regional_performance rp
    ON cm.campaign_id = rp.campaign_id;