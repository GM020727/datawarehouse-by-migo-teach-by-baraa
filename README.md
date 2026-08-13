<img width="1460" height="110" alt="image" src="https://github.com/user-attachments/assets/d2500665-fdf6-4221-aed3-edf497c70319" /># datawarehouse-by-migo-teach-by-baraa
building a madern data warehouse with SQL Server, including ETL processes, data modeling, and analytics.

# 跟着YouTube的baraa自学数据仓库、
用法：
  1.下载到本地
  2.打开数据库（sql server）
  3.在数据库打开scripts里面的init_database.sql并运行（建立新库，和新schema）
  4.打开bronze的两个SQL文件分别运行，先d后p，记得运行EXEC脚本（从本地加载数据）
  5.打开Silver的两个SQL文件分别运行，先d后p，记得运行EXEC脚本（ETL）
  6.打开gold的SQL文件并运行（搭建事实表和维度表，星型模型）

...

项目需求
## 构建数据仓库(数据工程)
### 目标
开发一个现代数据仓库，使用SQLServer整合销售数据，支持分析报告和明智决策。
#### 规范要求
- **数据源**:从两个提供为CSV文件的源系统(ERP和CRM)导入数据。
- **数据质量**:分析前清理并解决数据质量问题。
- **集成**:将两个数据源整合为一个单一且用户友好的数据模型，专为分析查询设计。
- **范围**:仅关注最新数据集;无需数据历史记录。
- **文档**:提供清晰的数据模型文档，以支持业务利益相关者和分析团队。

---
## BI:分析与报告(数据分析师)
## 目标
- **客户行为**
- **产品表现**
- **销售趋势**
开发基于SQL的分析工具，以提供以下方面的详细洞察:
---

## 许可证
本项目根据[MIT许可证](LICENSE)授权。您可以自由使用、修改并共享此项目，并需注明出处。

