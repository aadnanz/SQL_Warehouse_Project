/*
===============================================================================
Stored Procedure: Load report Layer (stage -> report)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'report' schema tables from the 'stage' schema.
	Actions Performed:
		- Truncates stage tables.
		- Inserts transformed and cleansed data from stage into report tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC report.load_report;
===============================================================================
*/

CREATE OR ALTER PROCEDURE report.load_report AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading report Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Loading report.dim_customers
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: report.dim_customers';
		TRUNCATE TABLE report.dim_customers;
		PRINT '>> Inserting Data Into: report.dim_customers';

-- Populate table
INSERT INTO report.dim_customers(
    customer_id, customer_number, first_name, last_name, country,
    marital_status, gender, birthdate, create_date
)
SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    la.cntry,
    ci.cst_marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END,
    ca.bdate,
    ci.cst_create_date
FROM stage.crm_cust_info ci
LEFT JOIN stage.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN stage.erp_loc_a101 la
    ON ci.cst_key = la.cid;

SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';



-- Loading report.dim_products
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: report.dim_products';
		TRUNCATE TABLE report.dim_products;
		PRINT '>> Inserting Data Into: report.dim_products';

INSERT INTO report.dim_products(
    product_id, product_number, product_name, category_id,
    category, subcategory, maintenance, cost, product_line, start_date
)
SELECT
    pn.prd_id,
    pn.prd_key,
    pn.prd_nm,
    pn.cat_id,
    pc.cat,
    pc.subcat,
    pc.maintenance,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt
FROM stage.crm_prod_info pn
LEFT JOIN stage.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;


SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';



-- Loading crm_sales_details
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: report.fact_sales';
		TRUNCATE TABLE report.fact_sales;
		PRINT '>> Inserting Data Into: report.fact_sales';

INSERT INTO report.fact_sales(
    order_number, product_key, customer_key, order_date, 
    shipping_date, due_date, sales_amount, quantity, price
)
SELECT
    sd.sls_ord_num,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price
FROM stage.crm_sales_details sd
LEFT JOIN report.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN report.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;

SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

    END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING REPORT LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
