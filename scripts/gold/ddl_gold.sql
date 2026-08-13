/*
================================================================================================
### DDL 脚本：创建 Gold 层视图
================================================================================================
### 脚本用途：
  此脚本用于在数据仓库中创建 Gold 层的视图。
  Gold 层代表最终的维度表和事实表（星型模型）。

  **每个视图通过对 Silver 层数据进行转换和组合，生成干净、丰富且可直接用于业务的数据集。**

### 使用说明：
  这些视图可直接用于分析和报表查询。
*/

### Create demension:gold.dim_customers

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
  DROP VIEW gold.dim_customers;
GO
-- 处理性别,改列名，将列按逻辑分组以提高可读性,增加代理键ROW_NUMBER,最后建VIEW(在视图里面)
CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	CASE when cst_gndr != 'n/a' then cst_gndr
		 else coalesce(ca.gen, 'n/a')	-- COALESCE(ca.gen, 'n/a')：若 gen 字段为空，则替换为默认值 'n/a'
	end as gender,
	ca.bdate as birthday,
	ci.cst_create_date as create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON		  ci.cst_key = la.cid
GO

### Create demension:gold.dim_products
  
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
  DROP VIEW gold.dim_products;
GO
-- 调整行字段，给字段分组后改名并新增代理键最后建视图
create view gold.dim_products as
select 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name, 
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance,
	pn.prd_cost as cost, 
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date 
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null -- 过滤所有历史数据
GO
  
### Create demension:gold.fact_sales
  
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
  DROP VIEW gold.fact_sales;
GO
-- 联表，取关键列，改列名，建视图
create view gold.fact_sales AS
SELECT 
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id
GO
