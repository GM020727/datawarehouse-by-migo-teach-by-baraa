/*
-- 存储过程：加载 Silver 层（Bronze → Silver）

-- 脚本用途：
  -- 此存储过程执行 ETL（抽取、转换、加载）流程，将数据从 'bronze' 模式填充到 'silver' 模式表中。
-- 执行操作：
  -- 清空 Silver 层表。
  -- 将 Bronze 层中经过转换和清洗后的数据插入 Silver 层表。
-- 参数：
  -- 无。
  -- 此存储过程不接受任何参数，也不返回任何值。
-- 使用示例：
  -- EXEC silver.load_silver;
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS	
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=======================================================================';
		PRINT 'Loading Silver Layer';
		PRINT '=======================================================================';

		PRINT '-----------------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '-----------------------------------------------------------------------';

		-- 在 可编程性-存储过程 中
		-- 数据标准化 
		-- 标准化第一个表格 crm_cust_info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Tata: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date)
		select cst_id, cst_key,
			TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) as cst_lastname,
			CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				 ELSE 'n/a'
			END	cst_marital_status,  -- 将婚姻状况字段的值标准化为可读格式
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				 ELSE 'n/a'
			END	cst_gndr,	-- 将性别字段的值标准化为可读格式
			cst_create_date
		from(
			select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
			from bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		) t 
		where flag_last = 1;	-- 按客户筛选出最近的一条记录
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '----------';

		
		-- 标准化第二个表格 crm_prd_info
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Tata: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		select 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,	-- 提取类别ID
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,	-- 提取产品键
			prd_nm,
			ISNULL(prd_cost, 0) as prd_cost,
			case upper(trim(prd_line))
				when 'M' then 'Mountain'
				when 'R' then 'Road'
				when 'S' then 'Other Sales'
				when 'T' then 'Touring'
				else 'n/a'
			end as prd_line,	-- 将产品线代码映射为描述性值
			cast(prd_start_dt as DATE) as prd_start_dt,
			cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as DATE) as prd_end_dt	-- 将结束日期计算为下一个起始日期的前一天
		from bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '----------';

		-- 标准化第三个表格 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Tata: silver.crm_sales_details';

		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			case when sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 then NULL
			else cast(cast(sls_order_dt as varchar) as date)
			end as sls_order_dt,
			case when sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 then NULL
			else cast(cast(sls_ship_dt as varchar) as date)	
			end as sls_ship_dt,
			case when sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 then NULL
			else cast(cast(sls_due_dt as varchar) as date)
			end as sls_due_dt,
			case when sls_sales is null or sls_sales <= 0 or sls_sales !=  sls_quantity * abs(sls_price) 
					then sls_quantity * abs(sls_price)
				else sls_sales
			end as sls_sales,	-- 如果原始销售额值为空或不正确，则重新计算生成正确的值
			sls_quantity,
			case when sls_price is null or sls_price <= 0
					then sls_sales / nullif(sls_quantity, 0)
				else sls_price
			end as sls_price	-- 若原始单价无效，则推算补全
		FROM bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '----------';

		PRINT '-----------------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '-----------------------------------------------------------------------';

		-- 标准化第四个表 erp_cust_az12
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Tata: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(cid, bdate, gen)
		SELECT
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
				 ELSE cid
			END AS cid,	--如果存在，则移除'NAS'前缀
			CASE WHEN bdate > GETDATE() THEN NULL
				 ELSE bdate
			END AS bdate,	--将未来的出生日期设置为NULL
			CASE WHEN UPPER(TRIM (gen)) IN ('F', 'FEMALE') THEN 'Female'
				 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'n/a'
			END AS gen	-- 标准化性别值并处理未知情况
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '----------';

		-- 标准化第五个表
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Tata: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(cid, cntry)
		SELECT
			REPLACE(cid, '-', '') cid,
			CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				 WHEN TRIM(cntry) IN('US','USA') THEN 'United States'
				 WHEN TRIM(cntry) ='' OR cntry IS NULL THEN 'n/a'
				 ELSE TRIM(cntry)
			END AS cntry
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '----------';


		-- 标准化第六个表（无需操作）
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Tata: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '----------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================';
		PRINT 'Loading Silver Layer is Completed';
		PRINT '	    - Total load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR) + ' seconds';
		PRINT '=========================================';
	END TRY

	BEGIN CATCH
		PRINT '=======================================================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=======================================================================';
	END CATCH
END

