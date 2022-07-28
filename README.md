# Implementation scripts

👋 Hi!
👀 USE WITH CAUTION! This template is still under development and requires accompanying documentation.

👀 T-SQL for creating initial Data Warehouse structures on a Microsoft SQL Server instance.

👀 The following files optionally create the database, files and filegroups. 
👀 Once file and filegroups are in place, the scripts drop and create all database objects.
👀 If the @TabulaRasa bit variable is set to 1 in the DDL.sql script, then the entire database is dropped and recreated. Otherwise, the database, fil and filegroups are 👀 left in place, but all other objects below that are dropped and then recreated.
👀 The scripts should be executed in the following order:
    DDL.sql - Data definition language - tables, triggers, materialized views.
    DRI.sql - Declarative referential integrity - foreign key constraints.
    Programmability.sql - stored procedures, functions, assemblies, et al
    DML.sql - Data manipulation language - Initial seeding of tables
💞️ https://datawarehouse.relationaldata.net/
📫 jqa@RelationalData.net
