# Implementation scripts

๐ This template is still under development and requires accompanying documentation.

๐ T-SQL for creating initial Data Warehouse structures on a Microsoft SQL Server instance.

๐ The files contained within this repository will optionally create the database, files and filegroups. 

๐ Once file and filegroups are in place, the scripts drop and create all database objects.

๐ If the @TabulaRasa bit variable is set to 1 in the DDL.sql script, then the entire database is dropped and recreated. Otherwise, the database, file and filegroups are ๐ left in place, but all other objects below that are dropped and then recreated.

๐ The scripts should be executed in the following order:
    
        ๐DDL.sql - Data definition language - tables, triggers, materialized views.
        ๐DRI.sql - Declarative referential integrity - foreign key constraints.
        ๐Programmability.sql - stored procedures, functions, assemblies, et al
        ๐DML.sql - Data manipulation language - Initial seeding of tables

๐๏ธ https://datawarehouse.relationaldata.net/

๐ซ jqa@RelationalData.net
