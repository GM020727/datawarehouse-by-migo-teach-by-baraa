/*
# 质量检查
-- 脚本用途：  
-- 此脚本用于对 'silver' 模式中的数据进行多项质量检查，涵盖数据一致性、准确性及标准化等方面。检查内容包括：
  -- - 主键是否为空或重复
  -- - 字符串字段中是否存在多余空格
  -- - 数据标准化与一致性
  -- - 日期范围及顺序是否无效
  -- - 关联字段之间的数据一致性
-- 使用说明：
  -- 在 Silver 层数据加载完成后运行这些检查。
  -- 对检查过程中发现的任何异常进行排查与处理。
*/

-- 对第一个表数据标准化

-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No Result
-- 检查主键是否存在空值或重复值
-- 预期结果：无返回结果
SELECT cst_id,COUNT(*)
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;

-- 对筛查出来的主键进行操作

-- 查看详情
select * 
from bronze.crm_cust_info
where cst_id = 29466;

-- 添加窗口函数对重复数据按时间进行排序 倒序
select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
from bronze.crm_cust_info
where cst_id = 29466;

-- 对所有重复数据进行排序（把不需要的旧数据选出来）
select *
from(
	select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
	from bronze.crm_cust_info
) t where flag_last != 1

-- 只保留最新的数据 flag_last = 1
select *
from(
	select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
	from bronze.crm_cust_info
) t where flag_last = 1


-- Check for unwanted Spaces
-- Expectation:No Results
-- 检查是否存在多余的空格
-- 预期结果：无返回记录

-- 筛查firstname
select cst_firstname
from bronze.crm_cust_info
where cst_firstname != TRIM(cst_firstname)

-- 筛查lastname
select cst_lastname
from bronze.crm_cust_info
where cst_lastname != TRIM(cst_lastname)

-- 筛查多余空格之后对有额外空格的列进行 TRIM 操作
select cst_id, cst_key,
	TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) as cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
from(
	select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
	from bronze.crm_cust_info
) t where flag_last = 1

-- Data Standardization & Consistency
-- 数据标准化及一致性检查（缩写形式标准化为可读格式，根据筛查出来的缩写配对对应的 全称）
select distinct cst_gndr
from bronze.crm_cust_info

-- In our data warehouse,we aim to store clear and meaningful valuesrather than using abbreviated terms
-- In our data warehouse,we use the default value 'n/a'for missing values
-- Apply uPPER() just in case mixed-case values appear later in your column.
-- Apply TRIMO) just in case spacesappear later in your column.
-- 数据仓库中的值应清晰、有意义，避免使用缩写词。
-- 数据仓库中，缺失值统一填充为默认值 'n/a'
-- 使用 UPPER() 进行统一大写处理，避免列中将来出现大小写混杂的情况。
-- 使用 TRIM() 去除首尾空格，避免列中将来出现多余空格的情况。
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
) t where flag_last = 1	-- 按客户筛选出最近的一条记录

-- Quality of Silver
-- Re-run the quality check queries from the bronze layerto verify the quality of data in the silver layer.
-- Silver 层数据质量检查
-- 重新运行 Bronze 层的质量检查查询，以验证 Silver 层中的数据质量。

-- 检查主键是否存在空值或重复值
-- 预期结果：无返回结果
SELECT cst_id,COUNT(*)
from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;

-- 检查是否存在多余的空格
-- 预期结果：无返回记录

-- 筛查firstname
select cst_firstname
from silver.crm_cust_info
where cst_firstname != TRIM(cst_firstname)

-- 筛查lastname
select cst_lastname
from silver.crm_cust_info
where cst_lastname != TRIM(cst_lastname)

-- 数据标准化及一致性检查
select distinct cst_gndr
from silver.crm_cust_info

select distinct cst_marital_status
from silver.crm_cust_info

select * from silver.crm_cust_info

-- 对第二个表数据标准化

--检查数据列字段（常规检查如上，以下为新检查）

-- Check for NULLs or Negative Numbers
-- 检查是否存在空值或负数
select prd_cost
from bronze.crm_prd_info
where prd_cost < 0 or prd_cost is null

-- Check forInvalid Date Orders
-- 检查是否存在无效的日期顺序（查出后看一下错误类型，可以去Excel把典型案例拿出来想解决方案）
select * 
from bronze.crm_prd_info
where prd_end_dt < prd_start_dt

-- 解决方案1
-- End Date = Start Date of the NExT' Record -1
-- 结束日期 = 下一条记录的起始日期 - 1

-- 关注于特定的几行，先修正小部分确认可行性
-- LEAD()  Access values from the next row within a window
-- LEAD() 函数：获取当前窗口内下一行的数据值
SELECT 
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')

-- 标准化后检查
-- 无效值和空值
select prd_cost
from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null
-- 无效时间
select * 
from silver.crm_prd_info
where prd_end_dt < prd_start_dt
-- 字段标准化
select distinct prd_line
from silver.crm_prd_info
--查看整体
select * from silver.crm_prd_info 


-- 对第三个表数据标准化

-- 整数转化为日期（整数->变长字符型->日期   int->vachar->date）
-- 检查负数和零(该例子只有0)，检查字符数是否都是8个，检查时间是否超出规定时间
SELECT nullif(sls_order_dt, 0) as sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101 
OR sls_order_dt < 190001

-- 检查日期逻辑是否合理（如结束日期早于开始日期）
SELECT *
FROM bronze.crm_sales_details
where sls_order_dt > sls_due_dt OR sls_order_dt > sls_ship_dt

--Check Data Consistency: Between Sales, Quantity, andPrice
-- Sales = Quantity * Price
-- Values must not be NULL, zero, or negative.
-- 检查数据一致性：销售额、数量与单价之间的关系
-- 销售额 = 数量 × 单价
-- 所有值均不得为空、为零或为负数
SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
order by sls_sales,sls_quantity,sls_price
-- 查询出问题后去咨询相关业务部门的人确认问题归因
-- 假设规则：如果销售额为负数、零或空值，则使用 数量*单价 重新计算得出
		  -- 如果单价为零或空值，则使用 销售额/数量 计算得出
		  -- 如果单价为负数，则将其转换为正值
SELECT DISTINCT
	sls_sales as old_sls_sales,
	sls_quantity,
	sls_price as oldsls_price,
	case when sls_sales is null or sls_sales <= 0 or sls_sales !=  sls_quantity * abs(sls_price) 
			then sls_quantity * abs(sls_price)
		else sls_sales
	end as sls_sales,
	case when sls_price is null or sls_price <= 0
			then sls_sales / nullif(sls_quantity, 0)
		else sls_price
	end as sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
order by sls_sales,sls_quantity,sls_price
-- 完成后要回去修改silver.crm_sales_details表的数据格式

-- 最后检查
SELECT *
FROM silver.crm_sales_details
where sls_order_dt > sls_due_dt OR sls_order_dt > sls_ship_dt

SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
order by sls_sales,sls_quantity,sls_price

select * FROM silver.crm_sales_details

-- 第四个表标准化步骤（省略常规检查）
-- 检查是否存在超出正常范围的日期（如未来日期或过早日期）
SELECT DISTINCT
	bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01'OR bdate > GETDATE()

-- 数据标准化与一致性
SELECT DISTINCT
	gen,
	CASE WHEN UPPER(TRIM (gen)) IN ('F', 'FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		 ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12

-- 检查
SELECT DISTINCT
	bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE()

SELECT DISTINCT
	CASE WHEN UPPER(TRIM (gen)) IN ('F', 'FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		 ELSE 'n/a'
END AS gen
FROM silver.erp_cust_az12

select * FROM silver.erp_cust_az12

-- 标准化第五个表
SELECT
	cid,
	cntry
FROM bronze.erp_loc_a101;

-- 对比找关联
SELECT cst_key FROM silver.crm_cust_info;

-- 字段标准化 检查
select distinct cntry
FROM bronze.erp_loc_a101
order by cntry

-- 修正
select distinct cntry as old_cntry,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		 WHEN TRIM(cntry) IN('US','USA') THEN 'United States'
		 WHEN TRIM(cntry) ='' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101
order by cntry

-- 检验
select distinct cntry
FROM silver.erp_loc_a101
order by cntry

select * FROM silver.erp_loc_a101

-- 标准化第6个表
-- 基础检查
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
OR subcat != TRIM(subcat)
OR maintenance != TRIM(maintenance)

-- 字段检查（都要检查）
select distinct 
cat
from bronze.erp_px_cat_g1v2

-- 检验
select *
from silver.erp_px_cat_g1v2
