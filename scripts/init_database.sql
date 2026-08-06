/*
============================================================================
创建数据库和架构
============================================================================
脚本目的:
  此脚本会在检查数据库是否已存在之后，创建一个新的名为'DataWarehouse'的数据库。
  如果数据库已存在，则将其删除并重新创建。
  此外，该脚本将在数据库中设置三个架构:'bronze'、'silver'和'gold'。

警告:
  运行此脚本将删除整个'DataWarehouse’数据库(如果存在)。
  数据库中的所有数据将被永久删除。
  请谨慎操作，并确保在运行此脚本前已做好备份。
*/

-- Create Database 'DataWarehouse

use master;
GO

-- Drop and recreate the 'datawarehouse' database
if exists (select 1 from sys.databases where name = 'DataWarehouse')
begin
	alter database DataWarehouse set single_user with rollback immediate;
	drop database DataWarehouse;
end;
GO

--Create the 'DataWarehouse' database
create database DataWarehouse; 
GO

use DataWarehouse;
GO

-- Create Schemas
create schema bronze;
GO
create schema silver;
GO
create schema gold;
GO
