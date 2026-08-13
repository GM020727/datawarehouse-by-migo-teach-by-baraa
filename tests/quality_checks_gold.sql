-- gold layer 建设详细步骤及必要检查

-- 搭建维度表 gold.dim_customers 步骤
SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON		  ci.cst_key = la.cid

-- 联表后要检查是否因联表引入了重复项
SELECT cst_id,COUNT(*) FROM 
	(SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
	ON		  ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 la
	ON		  ci.cst_key = la.cid
) t GROUP BY cst_id
HAVING COUNT(*) > 1

-- 检查常规逻辑（性别是否对应）
SELECT DISTINCT
	ci.cst_gndr,
	ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON		  ci.cst_key = la.cid
ORDER BY 1,2
-- NULL值通常来自连接的表!如果SQL找不到匹配项，将出现NULL

-- 处理性别配对（确认主表然后以主表为基础修改配对表）
SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE when cst_gndr != 'n/a' then cst_gndr
		 else coalesce(ca.gen, 'n/a')	-- COALESCE(ca.gen, 'n/a')：若 gen 字段为空，则替换为默认值 'n/a'
	end as new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON		  ci.cst_key = la.cid
ORDER BY 1,2

-- 最终成果：处理性别,改列名，将列按逻辑分组以提高可读性,增加代理键ROW_NUMBER,最后建VIEW(在视图里面)
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

-- 建立视图后检查table
SELECT * from gold.dim_customers
select distinct gender from gold.dim_customers

-- 搭建 gold.dim_products 步骤
select 
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt
from silver.crm_prd_info pn
where prd_end_dt is null -- 过滤所有历史数据

-- 联表
select 
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null -- 过滤所有历史数据

-- 检查重复数据
select prd_key, count(*) from(
	select 
		pn.prd_id,
		pn.cat_id,
		pn.prd_key,
		pn.prd_nm,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
	from silver.crm_prd_info pn
	left join silver.erp_px_cat_g1v2 pc
	on pn.cat_id = pc.id
	where prd_end_dt is null -- 过滤所有历史数据
) t group by prd_key
having count(*) > 1

-- 调整行字段，给字段分组后改名并新增代理键
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

-- 最后成果：调整行字段，给字段分组后改名并新增代理键最后建视图
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

/*
===========================================================
质量检查
===========================================================
脚本目的:
  
  此脚本执行质量检查以验证金层的数据完整性、一致性与准确性。
  维度表中代理键的唯一性。这些检查确保:
  - 事实表与维度表之间的参照完整性。
  - 验证数据模型中的关系以用于分析目的。
使用说明:
  - 在加载银层数据后运行这些检查。
  - 调查并解决检查过程中发现的任何差异。
*/  
-- view 后检查
SELECT * from gold.dim_products

-- ==========================================================
-- Checking 'gold.dim_customers'
-- 检查 gold.dim_customers 中客户键的唯一性
-- 预期结果：无返回
SELECT
  customer_key,
  COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT (*) > 1;

-- 检查 gold.product_key
-- 检查 gold.dim_products 中产品键的唯一性
-- 预期结果：无返回
SELECT
  product_key,
  COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- 检查事实表 gold.fact_sales

-- 外键完整性（维度）
select * from gold.dim_products f

-- 检查所有维度表是否能成功连接到事实表
-- 1
select * 
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
where c.customer_key is null
-- 2
select * 
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
left join gold.dim_products p
on p.product_key = f.product_key
where p.product_key is null
