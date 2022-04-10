PRINT 'SCRIPT BEGIN_______________________________________________________________________________';
PRINT 'DATA DEFINITION LANGUAGE SCRIPTING'
PRINT '___________________________________________________________________________________________';
/***************************************************************************************************************
****************************************************************************************************************
_________________________________________________________
Object:			DDL.sql
Type:			Implementation script
Author:			Jay Quincy Allen
Description:	Drop and create all tables, views.
Version:		1 August, 2021 CE
_________________________________________________________
****************************************************************************************************************
************************* Ralph Kimball: What is a data warehouse? *********************************************
"A data warehouse is a copy of transaction data specifically structured for query and analysis. - Ralph Kimball"
"..., thereby limiting it's ability to tell a more thorough story about the organization. - Jay Quincy Allen"
****************************************************************************************************************/
USE [master]
GO
SET NOCOUNT ON;
GO
DECLARE @Now datetime2, @DataFile nvarchar(256), @DataPath nvarchar(max), @DataFullPath nvarchar(max);
DECLARE @LogFile nvarchar(256), @LogPath nvarchar(max), @LogFullPath nvarchar(max), @TabulaRasa bit;
DECLARE @SQL nvarchar(max), @DatabaseName sysname, @FilePath nvarchar(max), @FileName nvarchar(256);

SET @TabulaRasa = 1;
SET @DatabaseName = 'RelationalData';
SELECT @DataPath = N'C:\DATA\'
SELECT @LogPath = N'C:\DATA\'
SET @Now = GETDATE();

DROP TABLE IF EXISTS #Database;
CREATE TABLE #Database (id int IDENTITY(1,1), DatabaseName sysname, TabulaRasa bit)
DROP TABLE IF EXISTS #Scripts;
CREATE TABLE #Scripts (id int IDENTITY(1,1), [Name] sysname, StartTime datetime2, EndTime datetime2)
DROP TABLE IF EXISTS #DataFiles;
CREATE TABLE #DataFiles (id int IDENTITY(1,1), FilePath nvarchar(max), [FileName] nvarchar(256))
DROP TABLE IF EXISTS #Schemas;
CREATE TABLE #Schemas (id int IDENTITY(1,1), [SchemaName] sysname)
PRINT '									...									';

INSERT INTO #Scripts
	([Name], StartTime, EndTime)
SELECT 'DDL', @Now, NULL
INSERT INTO #DataFiles
	(FilePath, [FileName])
SELECT N'C:\DATA\', 'Auditing'
UNION
SELECT N'C:\DATA\', 'Demonstration'
UNION
SELECT N'C:\DATA\', 'Geographic'
UNION
SELECT N'C:\DATA\', 'Infrastructure'
UNION
SELECT N'C:\DATA\', 'Institution'
UNION
SELECT N'C:\DATA\', 'Invoice'
UNION
SELECT N'C:\DATA\', 'Order'
UNION
SELECT N'C:\DATA\', 'Person'
UNION
SELECT N'C:\DATA\', 'Security'

INSERT INTO #Database
	(DatabaseName, TabulaRasa)
SELECT @DatabaseName, @TabulaRasa;
INSERT INTO #Schemas
	([SchemaName])
SELECT 'Administration'
UNION
SELECT 'Auditing'
UNION
SELECT 'Configuration'
UNION
SELECT 'Demonstration'
UNION
SELECT 'Geographic'
UNION
SELECT 'Institution'
UNION
SELECT 'Invoice'
UNION
SELECT 'Order'
UNION
SELECT 'Person'
UNION
SELECT 'Postal'
UNION
SELECT 'Security'
UNION
SELECT 'Telecom'
UNION
SELECT 'Workflow'

SELECT @DataFile = @DatabaseName + '.mdf'
SELECT @DataFullPath = @DataPath + @DataFile;

SELECT @LogFile = @DatabaseName + '_Log.ldf'
SELECT @LogFullPath = @LogPath + @LogFile;

IF @TabulaRasa = 1
	BEGIN
	PRINT '____________________________________________________________________________________________'
	PRINT 'DATABASE, FILE AND FILEGROUP MANAGEMENT...'
	IF EXISTS(SELECT 1 FROM sys.databases WHERE [name] = @DatabaseName)
		BEGIN
		--PRINT 'EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = ' + @DatabaseName + ''
		SELECT @SQL = '
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = ''' + @DatabaseName + ''''
		EXEC sp_executesql @SQL;
		END
	IF EXISTS(SELECT 1 FROM sys.databases WHERE [name] = @DatabaseName)
		BEGIN
		SELECT @SQL = '
		PRINT ''	ALTER DATABASE [' + @DatabaseName + '] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE''
		ALTER DATABASE [' + @DatabaseName + '] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE'
		EXEC sp_executesql @SQL;
		END
	IF EXISTS(SELECT 1 FROM sys.databases WHERE [name] = @DatabaseName)
		BEGIN
		PRINT '	DROP DATABASE [' + @DatabaseName + ']'
		SELECT @SQL = '
		DROP DATABASE [' + @DatabaseName + ']'
		EXEC sp_executesql @SQL;
		END
	PRINT '	CREATE DATABASE [' + @DatabaseName + ']'
	SELECT @SQL = '
	CREATE DATABASE [' + @DatabaseName + ']
		CONTAINMENT = NONE
	ON  PRIMARY 
		(NAME = ''' + @DatabaseName + ''', FILENAME = ''' + @DataFullPath + ''', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB)
	LOG ON 
		(NAME = ''' + @DatabaseName + '_Log'', FILENAME = ''' + @LogFullPath + ''', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB)
	WITH CATALOG_COLLATION = DATABASE_DEFAULT'
	--PRINT @SQL;
	EXEC sp_executesql @SQL;
	--ENABLE FULL TEXT
	SELECT @SQL = '
	IF (1 = FULLTEXTSERVICEPROPERTY(''IsFullTextInstalled''))
		BEGIN
		EXEC [' + @DatabaseName + '].[dbo].[sp_fulltext_database] @action = ''enable''
		END'
	EXEC sp_executesql @SQL;
	PRINT '	DATABASE CREATED.'
	END
GO
USE RelationalData
GO
DECLARE @SQL nvarchar(max), @DatabaseName sysname, @Count int, @Row int = 1, @TabulaRasa bit;
DECLARE @FilePath nvarchar(max), @FileName nvarchar(256), @FullPath nvarchar(max);

SELECT @TabulaRasa = TabulaRasa FROM #Database

IF @TabulaRasa = 1
	BEGIN
	PRINT '	CREATE FILEGROUPS AND FILES...'

	SELECT @DatabaseName = DatabaseName FROM #Database
	SELECT @Count = COUNT(1) FROM #DataFiles

	WHILE @Count >= @Row
		BEGIN
		SELECT	@FilePath = [FilePath],
				@FileName = [FileName]
			FROM #DataFiles
		WHERE	[id] = @Row;
		SELECT @SQL = '
	ALTER DATABASE [' + @DatabaseName + '] ADD FILEGROUP [' + @FileName + ']'
		EXEC sp_executesql @SQL;
		SELECT @FullPath = @FilePath + @FileName + '.ndf'
		SELECT @SQL = '
	ALTER DATABASE [' + @DatabaseName + ']
		ADD FILE (NAME = ''' + @FileName + ''',
	FILENAME = ''' + @FullPath + ''',
				SIZE = 8192KB , FILEGROWTH = 65536KB ) 
	TO FILEGROUP [' + @FileName + ']'
		EXEC sp_executesql @SQL;
		SELECT @Row = @Row + 1;
		END;
	PRINT 'DATABASE, FILEGROUPS AND FILES CREATED.'
	END;
GO
PRINT '									...									';
GO
BEGIN
DECLARE @Count int, @Row int, @SQL nvarchar(max), @TabulaRasa bit;
DECLARE @SchemaName sysname, @TableName sysname, @ForeignKey sysname;
DECLARE @ViewName sysname, @ProcedureName sysname, @FunctionName sysname;
DECLARE @Schemas TABLE (id int IDENTITY(1,1), SchemaName sysname)
DECLARE @Tables TABLE (id int IDENTITY(1,1), SchemaName sysname, TableName sysname)
DECLARE @Views TABLE (id int IDENTITY(1,1), SchemaName sysname, ViewName sysname)
DECLARE @Functions TABLE (id int IDENTITY(1,1), SchemaName sysname, FunctionName sysname)
DECLARE @Procedures TABLE (id int IDENTITY(1,1), SchemaName sysname, ProcedureName sysname)
DECLARE @ForeignKeys TABLE (id int IDENTITY(1,1), SchemaName sysname, TableName sysname, ForeignKey sysname)

SELECT @TabulaRasa = TabulaRasa FROM #Database

IF @TabulaRasa = 0
	BEGIN
	INSERT INTO @ForeignKeys
		(SchemaName, TableName, ForeignKey)
	SELECT	SCHEMA_NAME(schema_id), OBJECT_NAME(parent_object_id), [name]
		FROM sys.foreign_keys

	SELECT @Count = @@ROWCOUNT
	SET @Row = 1
	PRINT 'DROP FOREIGN KEYS...'
	WHILE @Count >= @Row
		BEGIN
		SELECT	@SchemaName = SchemaName,
				@TableName = TableName,
				@ForeignKey = ForeignKey
			FROM @ForeignKeys
		WHERE ID = @Row
		SELECT @SQL = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] DROP CONSTRAINT IF EXISTS [' + @ForeignKey + ']'
		EXEC sp_executesql @SQL
		--PRINT @SQL
		SELECT @Row = @Row + 1
		END
	PRINT 'DROP FUNCTIONS...'
	INSERT INTO @Functions
		(SchemaName, FunctionName)
	SELECT ROUTINE_SCHEMA, ROUTINE_NAME
		FROM INFORMATION_SCHEMA.ROUTINES
	WHERE		ROUTINE_TYPE = 'FUNCTION' 

	SELECT @Count = @@ROWCOUNT
	SET @Row = 1

	WHILE @Count >= @Row
		BEGIN
		SELECT	@FunctionName = FunctionName,
				@SchemaName = SchemaName
			FROM @Functions
		WHERE id = @Row
		SELECT @SQL = 'DROP FUNCTION IF EXISTS [' + @SchemaName + '].[' + @FunctionName + ']'
		PRINT @SQL
		EXEC (@SQL)
		SELECT @Row = @Row + 1
		END
	PRINT 'DROP STORED PROCEDURES...'
	INSERT INTO @Procedures
		(SchemaName, ProcedureName)
	SELECT SCHEMA_NAME(schema_id), [name]
		FROM sys.procedures

	SET @Count = @@ROWCOUNT
	SELECT @Row = 1
	WHILE @Count >= @Row
		BEGIN
		SELECT	@ProcedureName = ProcedureName,
				@SchemaName = SchemaName
			FROM @Procedures
		WHERE id = @Row
		SELECT @SQL = 'DROP PROCEDURE IF EXISTS [' + @SchemaName + '].[' + @ProcedureName + '];'
		EXEC sp_executesql @SQL
		--PRINT @SQL
		SELECT @Row = @Row + 1
		END

	INSERT INTO @Views
		(SchemaName, ViewName)
	SELECT SCHEMA_NAME(schema_id), [name]
		FROM sys.views

	SET @Count = @@ROWCOUNT
	SELECT @Row = 1
	PRINT 'DROP VIEWS...'
	WHILE @Count >= @Row
		BEGIN
		SELECT	@ViewName = ViewName,
				@SchemaName = SchemaName
			FROM @Views
		WHERE id = @Row
		SELECT @SQL = 'DROP VIEW IF EXISTS [' + @SchemaName + '].[' + @ViewName + '];'
		EXEC (@SQL)
		SELECT @Row = @Row + 1
		END

	INSERT INTO @Tables
		(SchemaName, TableName)
	SELECT SCHEMA_NAME(schema_id), [name]
		FROM sys.tables

	SET @Count = @@ROWCOUNT
	SELECT @Row = 1
	PRINT 'DROP TABLES...'
	WHILE @Count >= @Row
		BEGIN
		SELECT	@TableName = TableName,
				@SchemaName = SchemaName
			FROM @Tables
		WHERE id = @Row
		SELECT @SQL = 'DROP TABLE IF EXISTS [' + @SchemaName + '].[' + @TableName + '];'
		EXEC (@SQL)
		SELECT @Row = @Row + 1
		END
	INSERT INTO @Schemas
		(SchemaName)
	SELECT [name]
		FROM sys.schemas
	WHERE	schema_id <> principal_id
	SELECT @Count = @@ROWCOUNT
	SET @Row = 1
	PRINT 'DROP SCHEMAS...'
	WHILE @Count >= @Row
		BEGIN
		SELECT @SchemaName = SchemaName
			FROM @Schemas
		WHERE	id = @Row
		SELECT @SQL = 'DROP SCHEMA IF EXISTS [' + @SchemaName + ']'
		--PRINT @SQL
		EXEC (@SQL)
		SELECT @Row = @Row + 1
		END
	END;
PRINT 'CREATE SCHEMAS...';
SELECT @Count = COUNT(1) FROM #Schemas;
SET @Row = 1;
WHILE @Count >= @Row
	BEGIN
	SELECT @SchemaName = [SchemaName]
		FROM #Schemas
	WHERE	[id] = @Row;
	SELECT @SQL = '
CREATE SCHEMA [' + @SchemaName + ']'	
	EXEC sp_executesql @SQL;
	SELECT @Row = @Row + 1;
	END
END;
PRINT 'SCHEMAS CREATED.';
GO

PRINT '									...									';
GO
PRINT 'CREATE TYPES...';
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Name8')
	BEGIN
	CREATE TYPE Name8 FROM nvarchar(8) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Name16')
	BEGIN
	CREATE TYPE Name16 FROM nvarchar(16) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Name32')
	BEGIN
	CREATE TYPE [Name32] FROM nvarchar(32) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Name64')
	BEGIN
	CREATE TYPE [Name64] FROM nvarchar(64) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Name128')
	BEGIN
	CREATE TYPE Name128 FROM nvarchar(128) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Description256')
	BEGIN
	CREATE TYPE [Description256] FROM nvarchar(256) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Description512')
	BEGIN
	CREATE TYPE [Description512] FROM nvarchar(512) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'Description1024')
	BEGIN
	CREATE TYPE [Description1024] FROM nvarchar(1024) NOT NULL;
	END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'DescriptionMax')
	BEGIN
	CREATE TYPE [DescriptionMax] FROM nvarchar(max) NOT NULL;
	END;
IF NOT EXISTS(SELECT 1 FROM sys.types  WHERE is_user_defined = 1 AND [name] = 'PersonNames')
	BEGIN
	CREATE TYPE dbo.PersonNames AS TABLE (id smallint IDENTITY(1,1), PersonId int, [NameElement] Name64)
	END;
GO
PRINT 'TYPES CREATED.'
PRINT '									...									';
GO
PRINT 'CREATE TABLES...';
GO
PRINT '	Configuration...';
CREATE TABLE Configuration.[Status](
	StatusId		tinyint		IDENTITY(1,1)		NOT NULL,
	[Value]			sysname							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
CONSTRAINT [PK_ConfigurationStatus] PRIMARY KEY CLUSTERED 
	(StatusId ASC)
ON Auditing,
CONSTRAINT [AK_ConfigurationStatus] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Auditing) ON Auditing;
GO
--SELECT o.type, o.type_desc, ot.Code
--	FROM sys.objects o
--LEFT OUTER JOIN Configuration.ObjectType ot
--	ON		o.type = ot.Code
--		AND	o.type_desc = ot.Name
--GROUP BY o.type, o.type_desc, ot.Code
--	ORDER BY o.type
----SQL_Latin1_General_CP1_CI_AS
----Latin1_General_CI_AS_KS_WS

CREATE TABLE Configuration.ObjectType(
	ObjectTypeId	tinyint			IDENTITY(1,1)						NOT NULL,
	Code			varchar(8)		COLLATE Latin1_General_CI_AS_KS_WS	NOT NULL,
	[Name]			sysname			COLLATE Latin1_General_CI_AS_KS_WS	NOT NULL,
	[Description]	Description256										NOT NULL,
	SystemUserId	smallint		DEFAULT 1							NOT NULL,
	SystemTime		datetime2		DEFAULT GETDATE()					NOT NULL,
	ExecutionId		int												NOT NULL,
CONSTRAINT [PK_ConfigurationObjectType] PRIMARY KEY CLUSTERED 
	(ObjectTypeId ASC)
ON Auditing,
CONSTRAINT [AK_ConfigurationObjectType_0] UNIQUE NONCLUSTERED 
	(Code ASC),
CONSTRAINT [AK_ConfigurationObjectType_1] UNIQUE NONCLUSTERED 
	([Description] ASC)
ON Auditing) ON Auditing;
GO
--ALTER TABLE Configuration.ObjectType
--	ALTER COLUMN Code
--VARCHAR(8) COLLATE Latin1_General_CI_AS_KS_WS NOT NULL

CREATE TABLE Configuration.[Name](
	NameId			int			IDENTITY(1,1)		NOT NULL,
	[Value]			sysname							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
CONSTRAINT [PK_ConfigurationName] PRIMARY KEY CLUSTERED 
	(NameId ASC)
ON Auditing,
CONSTRAINT [AK_ConfigurationName] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Auditing) ON Auditing;
GO
CREATE TABLE Configuration.[Object](
	ObjectId		int			IDENTITY(1,1)		NOT NULL,
	ParentObjectId	int								NOT NULL,
	NameId			int								NOT NULL,
	ObjectTypeId	tinyint							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
CONSTRAINT [PK_ConfiguratioObject] PRIMARY KEY CLUSTERED 
	(ObjectId ASC)
ON Auditing,
CONSTRAINT [AK_ConfigurationObject] UNIQUE NONCLUSTERED 
	(ParentObjectId ASC, NameId ASC)
ON Auditing) ON Auditing;
GO
CREATE TRIGGER Configuration.ObjectOneTrigger
ON Configuration.[Object]
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ParentObjectId int;
	SELECT @ParentObjectId = ParentObjectId
		FROM inserted
	IF @ParentObjectId IS NULL
		BEGIN
		SELECT @ParentObjectId = IDENT_CURRENT('Configuration.Object');
		SELECT @ParentObjectId = @ParentObjectId + 1;
		END
	INSERT INTO Configuration.[Object]
		(ParentObjectId, NameId, ObjectTypeId, SystemUserId, SystemTime)
	SELECT	@ParentObjectId, NameId, ObjectTypeId, SystemUserId, SystemTime
		FROM inserted
END
GO
PRINT '									...									';
GO
PRINT '	Auditing...';
GO
CREATE TABLE Auditing.Execution(
	ExecutionId			int			IDENTITY(1,1)		NOT NULL,
	ParentExecutionId	int								NOT NULL,
	ObjectId			int								NOT NULL,
	[EventName]			sysname							NOT NULL,
	SystemUserId		smallint	DEFAULT 1			NOT NULL,
	SystemTime			datetime2	DEFAULT GETDATE()	NOT NULL,
CONSTRAINT [PK_AuditingExecution] PRIMARY KEY CLUSTERED 
	(ExecutionId ASC)
ON Auditing,
CONSTRAINT [AK_AuditingExecution] UNIQUE NONCLUSTERED 
	(ParentExecutionId ASC, ObjectId ASC, [EventName] ASC)
ON Auditing) ON Auditing;
GO
CREATE TRIGGER Auditing.ExecutionOneTrigger
ON Auditing.Execution
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ParentExecutionId int;
	SELECT @ParentExecutionId = ParentExecutionId
		FROM inserted
	IF @ParentExecutionId IS NULL
		BEGIN
		SELECT @ParentExecutionId = IDENT_CURRENT('Auditing.Execution');
		SELECT @ParentExecutionId = @ParentExecutionId + 1;
		END
	INSERT INTO Auditing.Execution
		(ParentExecutionId, ObjectId, EventName, SystemUserId, SystemTime)
	SELECT	@ParentExecutionId, ObjectId, EventName, SystemUserId, SystemTime
		FROM inserted
END
GO
CREATE TABLE Auditing.ExecutionDescription(
	ExecutionId		int								NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	[Value]			nvarchar(max)					NOT NULL,
	SystemUserId	smallint		DEFAULT 1		NOT NULL,
CONSTRAINT [PK_AuditingExecutionDescription] PRIMARY KEY CLUSTERED 
	(ExecutionId ASC, SystemTime ASC)
ON Auditing) ON Auditing;
GO
CREATE TABLE Auditing.ExecutionError(
	ExecutionId		int								NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	[Value]			nvarchar(max)					NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
CONSTRAINT [PK_AuditingExecutionError] PRIMARY KEY CLUSTERED 
	(ExecutionId ASC, SystemTime ASC)
ON Auditing) ON Auditing;
GO
CREATE TABLE Auditing.ExecutionStatus(
	ExecutionId		int								NOT NULL,
	StatusId		tinyint							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
CONSTRAINT [PK_AuditingExecutionStatus] PRIMARY KEY CLUSTERED 
	(ExecutionId ASC, StatusId ASC, SystemTime ASC)
ON Auditing) ON Auditing;
GO
PRINT '									...									';
GO
PRINT '	Geographic...';
GO
CREATE TABLE Geographic.Place(
	PlaceId				int			IDENTITY(1,1)		NOT NULL,
	ParentPlaceId		int								NOT NULL,
	NameId				int								NOT NULL,
	AbbreviationNameId	int								NOT NULL,
	SystemUserId		smallint	DEFAULT 1			NOT NULL,
	SystemTime			datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId			int								NOT NULL,
CONSTRAINT [PK_GeographicPlace] PRIMARY KEY CLUSTERED 
	(PlaceId ASC)
ON Geographic,
CONSTRAINT [AK_GeographicPlace] UNIQUE NONCLUSTERED 
	(ParentPlaceId ASC, NameId ASC)
ON Geographic) ON Geographic
GO
CREATE TRIGGER Geographic.PlaceOneTrigger
ON Geographic.Place
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ParentPlaceId int;
	SELECT @ParentPlaceId = ParentPlaceId 
		FROM inserted
	IF @ParentPlaceId IS NULL
		BEGIN
		SELECT @ParentPlaceId = IDENT_CURRENT('Geographic.Place');
		SELECT @ParentPlaceId = @ParentPlaceId + 1;
		END
		INSERT INTO Geographic.Place
			(ParentPlaceId, NameId, AbbreviationNameId, SystemUserId, SystemTime)
		SELECT	@ParentPlaceId, NameId, AbbreviationNameId, SystemUserId, SystemTime
			FROM inserted
END
GO
CREATE TABLE Geographic.[Name](
	NameId			int			IDENTITY(1,1)		NOT NULL,
	[Value]			Name64							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId			int							NOT NULL,
CONSTRAINT [PK_GeographicName] PRIMARY KEY CLUSTERED 
	(NameId ASC)
ON Geographic,
CONSTRAINT [AK_GeographicName] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Geographic) ON Geographic
GO
PRINT '									...									';
GO
--=======================================Institution=====================================================================
PRINT '									...									';
GO
PRINT '	Institution...';
GO
CREATE TABLE Institution.[Level](
	LevelId			tinyint		IDENTITY(1,1)		NOT NULL,
	[Name]			Name64							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_InstitutionLevel] PRIMARY KEY CLUSTERED 
	(LevelId ASC)
ON Infrastructure,
CONSTRAINT [AK_InstitutionLevel] UNIQUE NONCLUSTERED 
	([Name] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Institution.[Name](
	NameId			int			IDENTITY(1,1)		NOT NULL,
	[Value]			Name64							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_InstitutionName] PRIMARY KEY CLUSTERED 
	(NameId ASC)
ON Infrastructure,
CONSTRAINT [AK_InstitutionName] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Infrastructure) ON Infrastructure
GO
--select * from Institution.Organization
CREATE TABLE Institution.Organization(
	OrganizationId			int		IDENTITY(1,1)			NOT NULL,
	ParentOrganizationId	int								NOT NULL,
	NameId					int								NOT NULL,
	LevelId					tinyint							NOT NULL,
	Active					bit								NOT NULL,
	SystemUserId			smallint	DEFAULT 1			NOT NULL,
	SystemTime				datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId				int								NOT NULL,
CONSTRAINT [PK_InstitutionOrganization] PRIMARY KEY CLUSTERED 
	(OrganizationId ASC)
ON Infrastructure,
CONSTRAINT [AK_InstitutionOrganization] UNIQUE NONCLUSTERED 
	(ParentOrganizationId ASC, NameId ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TRIGGER Institution.OrganizationOneTrigger
ON Institution.Organization
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ParentOrganizationId int;
	SELECT	@ParentOrganizationId = ParentOrganizationId
		FROM inserted
	IF @ParentOrganizationId IS NULL
		BEGIN
		SELECT @ParentOrganizationId = IDENT_CURRENT('Institution.Organization');
		SELECT @ParentOrganizationId = @ParentOrganizationId + 1;
		END
	INSERT INTO Institution.Organization
		(ParentOrganizationId, NameId, LevelId, Active, SystemUserId, SystemTime)
	SELECT	@ParentOrganizationId, NameId, LevelId, Active, SystemUserId, SystemTime
		FROM inserted
END
GO
PRINT '	Orders...';
GO

PRINT '	Invoices...';
GO
--=========================================Person Schema Tables and Materialized Views================================================
PRINT '									...									';
GO
PRINT '	Person...';
GO
CREATE TABLE Person.NameElement(
	NameElementId		int			IDENTITY(1,1)		NOT NULL,
	[Value]				Name64							NOT NULL,
	SystemUserId		smallint	DEFAULT 1			NOT NULL,
	SystemTime			datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId			int								NOT NULL,
CONSTRAINT [PK_PersonNameElement] PRIMARY KEY CLUSTERED 
	(NameElementId ASC)
ON Person,
CONSTRAINT [AK_PersonNameElement] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Person) ON Person
GO
CREATE TABLE Person.Individual(
	IndividualId	int				IDENTITY(1,1)		NOT NULL,
	[HashName]		varbinary(32)						NOT NULL,
--The SHA2_256 hash of the composite of the name elements of the individual.
	SystemUserId	smallint		DEFAULT 1			NOT NULL,
	SystemTime		datetime2		DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int									NOT NULL,
CONSTRAINT [PK_PersonIndividual] PRIMARY KEY CLUSTERED 
	(IndividualId ASC)
ON Person,
CONSTRAINT [AK_PersonIndividual] UNIQUE NONCLUSTERED 
	([HashName] ASC)
ON Person) ON Person
GO
CREATE TABLE Person.NameCategory(
	NameCategoryId	tinyint		IDENTITY(1,1)		NOT NULL,
	[Value]			Name32							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_PersonNameCategory] PRIMARY KEY CLUSTERED 
	(NameCategoryId ASC)
ON Person,
CONSTRAINT [AK_PersonNameCategory] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Person) ON Person
GO
CREATE TABLE Person.IndividualNameElement(
	IndividualId	int								NOT NULL,
	NameElementId	int								NOT NULL,	
	NameCategoryId	tinyint							NOT NULL,
	SortOrder		tinyint							NOT NULL,
	Active			bit								NOT NULL,
	[Current]		bit								NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_PersonIndividualNameElement] PRIMARY KEY CLUSTERED 
	(IndividualId ASC, NameElementId ASC, NameCategoryId ASC, SortOrder ASC, Active ASC)
ON Person) ON Person

GO
CREATE TRIGGER Person.IndividualNameElementInsertNext
ON Person.IndividualNameElement
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE Person.IndividualNameElement SET	[Current] = 0
		FROM inserted i
	INNER JOIN Person.IndividualNameElement pne
		ON		i.IndividualId = pne.IndividualId
			AND	i.NameElementId = pne.NameElementId
			AND	i.NameCategoryId = pne.NameCategoryId
			AND	i.SortOrder = pne.SortOrder
	WHERE	pne.[Current] = 1;
	INSERT INTO Person.IndividualNameElement
		(IndividualId, NameElementId, NameCategoryId, SortOrder, Active, [Current], SystemUserId, SystemTime)
	SELECT	IndividualId, NameElementId, NameCategoryId, SortOrder, Active, 1, SystemUserId, SystemTime
		FROM inserted;
END;
GO
PRINT '	Postal...';
GO
CREATE TABLE Postal.Code(
	CodeId			int			IDENTITY(1,1)		NOT NULL,
	PlaceId			int								NOT NULL,--Country
	[Value]			Name16							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_PostalCode] PRIMARY KEY CLUSTERED 
	(CodeId ASC)
ON Geographic,
CONSTRAINT [AK_PostalCode] UNIQUE NONCLUSTERED 
	(PlaceId ASC, [Value] ASC)
ON Geographic) ON Geographic
GO
CREATE TABLE Postal.[DeliveryLine] (
	DeliveryLineId	int			IDENTITY(1,1)		NOT NULL,
	[Value]			Name64							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_PostalDeliveryLine] PRIMARY KEY CLUSTERED 
	(DeliveryLineId ASC)
ON Geographic,
CONSTRAINT [AK_PostalDeliveryLine] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Geographic) ON Geographic
GO
CREATE TABLE Postal.[Address](
	AddressId		int			IDENTITY(1,1)		NOT NULL,
	PlaceId			int								NOT NULL,--City, Township, etc
	CodeId			int								NOT NULL,
	[HashAddress]	varbinary(32)					NOT NULL,--The SHA2_256 hash of the composite of the delivery lines of the address + PostalCodeId
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_PostalAddress] PRIMARY KEY CLUSTERED 
	(AddressId ASC)
ON Geographic,
CONSTRAINT [AK_PostalAddress] UNIQUE NONCLUSTERED 
	([HashAddress] ASC)
ON Geographic) ON Geographic
GO
CREATE TABLE Postal.[AddressDeliveryLine] (
	AddressId		int								NOT NULL,
	DeliveryLineId	int								NOT NULL,
	ValidTime		smalldatetime					NOT NULL,
	Active			bit								NOT NULL,
	[Current]		bit								NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_PostalAddressDeliveryLine] PRIMARY KEY CLUSTERED 
	(AddressId ASC, DeliveryLineId ASC, ValidTime ASC)
ON Geographic) ON Geographic
GO
--======================BI-TEMPORAL TRIGGER====================================
CREATE TRIGGER Postal.AddressDeliveryLineNext
ON Postal.[AddressDeliveryLine]
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE Postal.[AddressDeliveryLine] SET	[Current] = 0
		FROM inserted i
	INNER JOIN Postal.[AddressDeliveryLine] ladl
		ON		i.AddressId = ladl.AddressId
			AND	i.DeliveryLineId = ladl.DeliveryLineId
	WHERE	ladl.[Current] = 1;
	INSERT INTO Postal.[AddressDeliveryLine]
		(AddressId, DeliveryLineId, ValidTime, Active, [Current], SystemUserId, SystemTime)
	SELECT	AddressId, DeliveryLineId, ValidTime, Active, 1, SystemUserId, SystemTime
		FROM inserted;
END;
GO
--===============Security Schema Tables================================================
PRINT '									...									';
GO
PRINT '	Security...';
GO
/*			On the Domain tables...
Security.Domain logically inherits from Telecom.Domain. Although all objects within 
the "Security" schema are in some way "Telecom" objects, "Security" was created to 
isolate data objects specifically related to wide and local area networks. In most 
cases, this means data from an organization's LDAP system(s).
The following Oracle URL demonstrates this concept.
https://docs.oracle.com/cd/B14099_19/web.1012/b15901/mapping003.htm#i1143147
*/
CREATE TABLE Security.Domain(
	DomainId		int								NOT NULL,--References Telecom.Domain.DomainId(PK)
	[Name]			sysname							NOT NULL,--LDAP FQDN name
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_Domain] PRIMARY KEY CLUSTERED
	(DomainId ASC)
ON Infrastructure,
CONSTRAINT [AK_Domain] UNIQUE NONCLUSTERED
	([Name] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Security.[Name](
	NameId			int			IDENTITY(1,1)		NOT NULL,
	[Value]			sysname							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_SecurityName] PRIMARY KEY CLUSTERED
	(NameId ASC)
ON Infrastructure,
CONSTRAINT [AK_SecurityName] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Security.[User](
	UserId			smallint	IDENTITY(1,1)		NOT NULL,
	DomainId		int								NOT NULL,
	NameId			int								NOT NULL,
	Active			bit								NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_SecurityUser] PRIMARY KEY CLUSTERED 
	(UserId ASC)
ON Infrastructure,
CONSTRAINT [AK_SecurityUser] UNIQUE NONCLUSTERED 
	(DomainId ASC, NameId ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Security.[Group](
	GroupId			smallint	IDENTITY(1,1)		NOT NULL,
	DomainId		int								NOT NULL,
	NameId			int								NOT NULL,
	Active			bit								NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_SecurityGroup] PRIMARY KEY CLUSTERED 
	(GroupId ASC)
ON Infrastructure,
CONSTRAINT [AK_SecurityGroup] UNIQUE NONCLUSTERED 
	(DomainId ASC, NameId ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Security.UserGroup(
	UserId			smallint							NOT NULL,
	GroupId			smallint							NOT NULL,
	ValidTime		smalldatetime						NOT NULL,
	Active			bit									NOT NULL,
	[Current]		bit									NOT NULL,
	SystemUserId	smallint		DEFAULT 1			NOT NULL,
	SystemTime		datetime2		DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int									NOT NULL,
CONSTRAINT [PK_SecurityUserGroup] PRIMARY KEY CLUSTERED 
	(UserId ASC, GroupId ASC, ValidTime ASC)
ON Infrastructure) ON Infrastructure
GO
--======================BI-TEMPORAL TRIGGER====================================
CREATE TRIGGER Security.UserGroupInsertNext
ON Security.UserGroup
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE Security.UserGroup SET	[Current] = 0
		FROM inserted i
	INNER JOIN Security.UserGroup sug
		ON		i.UserId = sug.UserId
			AND	i.GroupId = sug.GroupId
	INSERT INTO Security.UserGroup
		(UserId, GroupId, ValidTime, Active, [Current], SystemUserId, SystemTime)
	SELECT	UserId, GroupId, ValidTime, Active, 1, SystemUserId, SystemTime
		FROM inserted;
END;
GO
PRINT '	Telecom...';
GO
CREATE TABLE Telecom.Domain(
	DomainId			int	IDENTITY(1,1)				NOT NULL,
	LabelId				int								NOT NULL,
	TopLevelDomainId	smallint						NOT NULL,
	SystemUserId		smallint	DEFAULT 1			NOT NULL,
	SystemTime			datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId			int								NOT NULL,
CONSTRAINT [PK_TelecomDomain] PRIMARY KEY CLUSTERED 
	(DomainId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomDomain] UNIQUE NONCLUSTERED 
	(LabelId ASC, TopLevelDomainId ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.LabelUse(
	LabelUseId		tinyint		IDENTITY(1,1)		NOT NULL,
	[Value]			varchar(16)						NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_TelecomLabelUse] PRIMARY KEY CLUSTERED 
	(LabelUseId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomLabelUse] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.[Label](
	LabelId			int			IDENTITY(1,1)		NOT NULL,
	[Value]			varchar(63)						NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_TelecomLabel] PRIMARY KEY CLUSTERED 
	(LabelId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomLabel] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.[Scheme](
	SchemeId		tinyint		IDENTITY(1,1)		NOT NULL,
	[Value]			varchar(16)						NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_TelecomScheme] PRIMARY KEY CLUSTERED 
	(SchemeId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomScheme] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.TopLevelDomain(
	TopLevelDomainId	smallint	IDENTITY(1,1)		NOT NULL,
	[Value]				varchar(63)						NOT NULL,
	SystemUserId		smallint	DEFAULT 1			NOT NULL,
	SystemTime			datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId			int								NOT NULL,
CONSTRAINT [PK_TelecomTopLevelDomain] PRIMARY KEY CLUSTERED 
	(TopLevelDomainId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomTopLevelDomain] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.Place(
	PlaceId			int								NOT NULL,
	[Code]			varchar(16)						NOT NULL,
	Active			bit								NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_TelecomPlace] PRIMARY KEY CLUSTERED 
	(PlaceId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomPlace] UNIQUE NONCLUSTERED 
	([Code] ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.Email(
	EmailId			int			IDENTITY(1,1)		NOT NULL,
	DomainId		int								NOT NULL,
	LocalPart		Name64							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_TelecomEmail] PRIMARY KEY CLUSTERED 
	(EmailId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomEmail] UNIQUE NONCLUSTERED 
	(DomainId ASC, LocalPart ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.[Url](
	UrlId			int			IDENTITY(1,1)		NOT NULL,
	UrlHASH			varbinary(32)					NOT NULL,
	DomainId		int								NOT NULL,
	SchemeId		tinyint							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_TelecomUrl] PRIMARY KEY CLUSTERED 
	(UrlId ASC)
ON Infrastructure,
CONSTRAINT [AK_TelecomUrl] UNIQUE NONCLUSTERED 
	(UrlHASH ASC)
ON Infrastructure) ON Infrastructure
GO
CREATE TABLE Telecom.UrlLabel(
	UrlId			int									NOT NULL,
	LabelId			int									NOT NULL,
	LabelUseId		tinyint								NOT NULL,
	SortOrder		smallint							NOT NULL,
	ValidTime		smalldatetime						NOT NULL,
	Active			bit									NOT NULL,
	[Current]		bit									NOT NULL,
	SystemUserId	smallint		DEFAULT 1			NOT NULL,
	SystemTime		datetime2		DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int									NOT NULL,
CONSTRAINT [PK_TelecomUrlLabel] PRIMARY KEY CLUSTERED 
	(UrlId ASC, LabelId ASC, LabelUseId ASC, SortOrder ASC, ValidTime ASC)
ON Infrastructure) ON Infrastructure
GO
--======================BI-TEMPORAL TRIGGER====================================
CREATE TRIGGER Telecom.UrlLabelNext
ON Telecom.UrlLabel
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE Telecom.UrlLabel SET	[Current] = 0
		FROM inserted i
	INNER JOIN Telecom.UrlLabel ul
		ON		i.UrlId = ul.UrlId
			AND	i.LabelId = ul.LabelId
			AND	i.LabelUseId = ul.LabelUseId
			AND	i.SortOrder = ul.SortOrder
	INSERT INTO Telecom.UrlLabel
		(UrlId, LabelId, LabelUseId, SortOrder, ValidTime, Active, [Current], SystemUserId, SystemTime)
	SELECT	UrlId, LabelId, LabelUseId, SortOrder, ValidTime, Active, 1, SystemUserId, SystemTime
		FROM inserted;
END;
GO
PRINT '	Workflow...';
GO
CREATE TABLE Workflow.Task(
	TaskId			int			IDENTITY(1,1)		NOT NULL,
	[Name]			Name64							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_WorkflowTask] PRIMARY KEY CLUSTERED 
	(TaskId ASC)
ON Person,
CONSTRAINT [AK_WorkflowTask] UNIQUE NONCLUSTERED 
	([Name] ASC)
ON Person) ON Person
GO
CREATE TABLE Workflow.[Status](
	StatusId		tinyint		IDENTITY(1,1)		NOT NULL,
	[Value]			Name64							NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_WorkflowStatus] PRIMARY KEY CLUSTERED 
	(StatusId ASC)
ON Person,
CONSTRAINT [AK_WorkflowStatus] UNIQUE NONCLUSTERED 
	([Value] ASC)
ON Person) ON Person
GO
CREATE TABLE Workflow.TaskStatus(
	TaskId			int								NOT NULL,
	StatusId		tinyint							NOT NULL,
	ValidTime		datetime2						NOT NULL,
	SystemUserId	smallint	DEFAULT 1			NOT NULL,
	SystemTime		datetime2	DEFAULT GETDATE()	NOT NULL,
	ExecutionId		int								NOT NULL,
CONSTRAINT [PK_WorkflowTaskStatus] PRIMARY KEY CLUSTERED 
	(TaskId ASC)
ON Person) ON Person
GO
PRINT '									...									';
GO
PRINT 'TABLES CREATED.';
GO
--=================================================================================
--=====CREATE MATERIALIZED VIEWS===================================================
--=================================================================================
PRINT 'CREATE MATERIALIZED VIEWS...';
GO
PRINT '	Auditing...'
GO
CREATE VIEW Auditing.Executions
WITH SCHEMABINDING
AS
SELECT	a.ExecutionId, a.ParentExecutionId, a.EventName,
		a.ObjectId, n.[Value] AS 'Object',
		a.SystemTime, a.SystemUserId, sn.[Value] AS 'User', d.[Name] AS 'Domain'
	FROM Auditing.Execution a
INNER JOIN Configuration.[Object] o
	ON a.ObjectId = o.ObjectId
INNER JOIN Configuration.[Name] n
	ON	o.NameId = n.NameId
INNER JOIN Security.[User] u
	ON	a.SystemUserId = u.UserId
INNER JOIN Security.[Name] sn
	ON	u.NameId = sn.NameId
INNER JOIN Security.Domain d
	ON	u.DomainId = d.DomainId
GO
CREATE UNIQUE CLUSTERED INDEX AuditingExecutions_IX_0
   ON Auditing.Executions (ExecutionId);
GO
PRINT '									...									';
GO
CREATE VIEW Auditing.ExecutionLog
WITH SCHEMABINDING
AS
SELECT	e.SystemTime, e.ExecutionId, e.EventName, n.[Value] AS 'Object',
		ed.[Value] AS 'Description', s.StatusId, s.[Value] AS 'Status', ee.[Value] AS 'Error'
	FROM Auditing.Execution e
INNER JOIN Configuration.[Object] o
	ON	e.ObjectId = o.ObjectId
INNER JOIN Configuration.[Name] n
	ON	o.NameId = n.NameId
LEFT OUTER JOIN Auditing.ExecutionDescription ed
	ON e.ExecutionId = ed.ExecutionId
LEFT OUTER JOIN Auditing.ExecutionStatus es
	ON	e.ExecutionId = es.ExecutionId
LEFT OUTER JOIN Configuration.[Status] s
	ON	es.StatusId = s.StatusId
LEFT OUTER JOIN Auditing.ExecutionError ee
	ON	e.ExecutionId = ee.ExecutionId
--ORDER BY e.SystemTime, ed.SystemTime, es.SystemTime
GO
--CREATE UNIQUE CLUSTERED INDEX AuditingExecutionLog_IX_0
--   ON Auditing.Executions (ExecutionId ASC, StatusId ASC);
GO
PRINT '	Configuration...'
GO
CREATE VIEW Configuration.[Objects]
WITH SCHEMABINDING
AS
SELECT	o.ObjectId, o.ParentObjectId, n.[Value] AS 'Object', o.ObjectTypeId, ot.[Name] AS 'ObectType',
		o.SystemTime, o.SystemUserId, sn.[Value] AS 'User', d.[Name] AS 'Domain'
	FROM Configuration.[Object] o
INNER JOIN Configuration.[Name] n
	ON	o.NameId = n.NameId
INNER JOIN Configuration.ObjectType ot
	ON	o.ObjectTypeId = ot.ObjectTypeId
INNER JOIN Security.[User] u
	ON	o.SystemUserId = u.UserId
INNER JOIN Security.[Name] sn
	ON	u.NameId = sn.NameId
INNER JOIN Security.Domain d
	ON	u.DomainId = d.DomainId
GO
CREATE UNIQUE CLUSTERED INDEX ConfigurationObjects_IX_0
   ON Configuration.[Objects] (ObjectId);
GO
PRINT '									...									';
GO
PRINT '	Geographic...'
GO
PRINT '									...									';
GO
PRINT '	Individual...'
GO
PRINT '									...									';
GO
PRINT '	Postal...'
GO
PRINT '									...									';
GO
PRINT '	Insitution...'
GO
CREATE VIEW Institution.Organizations
WITH SCHEMABINDING
AS
SELECT	o.OrganizationId, o.ParentOrganizationId, n.[Value] AS 'Organization',
		o.Active, o.LevelId, l.[Name] AS 'Level',
		o.SystemTime, o.SystemUserId, sn.[Value] AS 'User', d.[Name] AS 'Domain'
	FROM Institution.Organization o
INNER JOIN Institution.[Name] n
	ON o.NameId = n.NameId
INNER JOIN Institution.[Level] l
	ON	o.LevelId = l.LevelId
INNER JOIN Security.[User] u
	ON	o.SystemUserId = u.UserId
INNER JOIN Security.[Name] sn
	ON	u.NameId = sn.NameId
INNER JOIN Security.Domain d
	ON	u.DomainId = d.DomainId
GO
CREATE UNIQUE CLUSTERED INDEX InsitutionOrganizations_IX_0
   ON Institution.Organizations (OrganizationId);
GO
PRINT '									...									';
GO
PRINT '	Security...'
GO
CREATE VIEW Security.Users
WITH SCHEMABINDING
AS
SELECT	u.UserId, u.NameId, n.[Value] AS 'User',
		d.DomainId, d.[Name] AS 'Domain',
		u.SystemTime, u.SystemUserId
	FROM Security.[User] u
INNER JOIN Security.[Name] n
	ON u.NameId = n.NameId
INNER JOIN Security.Domain d
	ON	u.DomainId = d.DomainId
GO
CREATE UNIQUE CLUSTERED INDEX SecurityUsers_IX_0
   ON Security.Users (UserId);
GO
PRINT '									...									';
GO
PRINT '	Telecom...'
GO
CREATE VIEW Telecom.[Domains]
WITH SCHEMABINDING
AS
SELECT	d.DomainId, d.LabelId, l.[Value] AS 'Domain',
		d.TopLevelDomainId, tld.[Value] AS 'TopLevelDomain', d.SystemTime
	FROM Telecom.Domain d
INNER JOIN Telecom.[Label] l	
	ON	d.LabelId = l.LabelId
INNER JOIN Telecom.TopLevelDomain tld
	ON	d.TopLevelDomainId = tld.TopLevelDomainId
GO
CREATE UNIQUE CLUSTERED INDEX TelecomDomain_IX_0
   ON Telecom.[Domains] (DomainId);
GO
PRINT '									...									';
GO
PRINT 'MATERIALIZED VIEWS CREATED.';
GO
DECLARE @Now datetime2 = GETDATE();
DECLARE @ObjectId int, @NameId int, @ObjectTypeId tinyint, @LevelId tinyint, @LabelId int, @TopLevelDomainId tinyint;
DECLARE @DatabaseName sysname, @Domain sysname, @DomainId int, @User sysname, @UserId smallint;
DECLARE @Difference bigint, @Message nvarchar(max), @StartTime datetime2, @ParentExecutionId int;
SELECT @DatabaseName = DatabaseName FROM #Database
SELECT @Domain = @DatabaseName + '.com';

PRINT 'SEED TELECOM...'
BEGIN
INSERT INTO Telecom.TopLevelDomain
	([Value], SystemUserId, SystemTime, ExecutionId)
VALUES
	('', 1, @Now, 1);
SELECT @TopLevelDomainId = SCOPE_IDENTITY();
SELECT	@User = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name])),
		@Domain = LEFT([name], PATINDEX('%\%', [name]) - 1)
	FROM sys.server_principals 
WHERE principal_id = SUSER_ID();
INSERT INTO Telecom.[Label]
	([Value], SystemUserId, SystemTime, ExecutionId)
VALUES
	(@Domain, 1, @Now, 1);
SELECT @LabelId = SCOPE_IDENTITY();
INSERT INTO Telecom.Domain
	(LabelId, TopLevelDomainId, SystemUserId, SystemTime, ExecutionId)
VALUES
	(@LabelId, @TopLevelDomainId, 1, @Now, 1);
SELECT @DomainId = SCOPE_IDENTITY();
PRINT 'SEED SECURITY...'
INSERT INTO Security.Domain
	(DomainId, [Name], SystemUserId, SystemTime, ExecutionId)
VALUES
	(@DomainId, @Domain, 1, @Now, 1);
INSERT INTO Security.[Name]
	([Value], SystemUserId, SystemTime, ExecutionId)
VALUES
	(@User, 1, @Now, 1)
SELECT @NameId = SCOPE_IDENTITY();
INSERT INTO Security.[User]
	(DomainId, NameId, Active, SystemUserId, SystemTime, ExecutionId)
VALUES
	(@DomainId, @NameId, 1, 1, @Now, 1)
SELECT @UserId = SCOPE_IDENTITY();
END;

PRINT '									...									';

PRINT 'SEED CONFIGURATION...'
BEGIN
INSERT INTO Configuration.ObjectType
	([Code], [Name], [Description], SystemUserId, SystemTime, ExecutionId)
SELECT 'AF', 'FUNCTION', 'Aggregate function (CLR)', 1, @Now, 1
UNION
SELECT 'C', 'CONSTRAINT', 'CHECK constraint', 1, @Now, 1
UNION
SELECT 'D', 'DEFAULT_CONSTRAINT', 'DEFAULT (constraint or stand-alone)', 1, @Now, 1
UNION
SELECT 'EC', 'CONSTRAINT', 'Edge constraint',1 , @Now, 1
UNION
SELECT 'ET', 'TABLE', 'External Table', 1, @Now, 1
UNION
SELECT 'F', 'CONSTRAINT', 'FOREIGN KEY constraint', 1, @Now, 1
UNION
SELECT 'FN', 'FUNCTION', 'SQL scalar function', 1, @Now, 1
UNION
SELECT 'FS', 'FUNCTION', 'Assembly (CLR) scalar-function', 1, @Now, 1
UNION
SELECT 'FT', 'FUNCTION', 'Assembly (CLR) table-valued function', 1, @Now, 1
UNION
SELECT 'IF', 'FUNCTION', 'SQL inline table-valued function', 1, @Now, 1
UNION
SELECT 'IT', 'INTERNAL_TABLE', 'Internal table', 1, @Now, 1
UNION
SELECT 'MSSQL', 'MS_SQL_SERVER', 'Microsoft SQL Server', 1, @Now, 1
UNION
SELECT 'NetBIOS', 'NetBIOS', 'NetBIOS name of machine', 1, @Now, 1
UNION
SELECT 'P', 'SQL_STORED_PROCEDURE', 'Stored Procedure', 1, @Now, 1
UNION
SELECT 'PC', 'PROCEDURE', 'Assembly (CLR) stored-procedure', 1, @Now, 1
UNION
SELECT 'PG', 'GUIDE', 'Plan guide', 1, @Now, 1
UNION
SELECT 'PK', 'PRIMARY_KEY_CONSTRAINT', 'Primary key constraint', 1, @Now, 1
UNION
SELECT 'R', 'RULE', 'Rule (old-style, stand-alone)', 1, @Now, 1
UNION
SELECT 'RF', 'PROCEDURE', 'Replication-filter-procedure', 1, @Now, 1
UNION
SELECT 'S', 'SYSTEM_TABLE', 'System table', 1, @Now, 1
UNION
SELECT 'SC', 'SCRIPT', 'Scripting', 1, @Now, 1
UNION
SELECT 'SN', 'SYNONYM', 'Synonym', 1, @Now, 1
UNION
SELECT 'SO', 'SEQUENCE', 'Sequence object', 1, @Now, 1
UNION
SELECT 'SQ', 'SERVICE_QUEUE', 'Service queue', 1, @Now, 1
UNION
SELECT 'ST', 'STATS_TREE', 'STATS_TREE', 1, @Now, 1
UNION
SELECT 'TA', 'TRIGGER', 'Assembly (CLR) DML trigger', 1, @Now, 1
UNION
SELECT 'TF', 'SQL_TABLE_VALUED_FUNCTION', 'SQL table-valued-function', 1, @Now, 1
UNION
SELECT 'TR', 'SQL_TRIGGER', 'SQL trigger', 1, @Now, 1
UNION
SELECT 'TT', 'TYPE_TABLE', 'Type table', 1, @Now, 1
UNION
SELECT 'U', 'USER_TABLE', 'User table', 1, @Now, 1
UNION
SELECT 'UQ', 'UNIQUE_CONSTRAINT', 'Unique constraint', 1, @Now, 1
UNION
SELECT 'V', 'VIEW', 'View', 1, @Now, 1
UNION
SELECT 'X', 'PROCEDURE', 'Extended stored procedure', 1, @Now, 1
--SELECT o.type, o.type_desc
--	FROM sys.objects o
--GROUP BY o.type, o.type_desc ORDER BY o.type
--SELECT ot.Code, ot.Description
--	FROM Configuration.ObjectType ot
--D 	DEFAULT_CONSTRAINT
--F 	FOREIGN_KEY_CONSTRAINT
--FN	SQL_SCALAR_FUNCTION
--IT	INTERNAL_TABLE
--P 	SQL_STORED_PROCEDURE
--PK	PRIMARY_KEY_CONSTRAINT
--S 	SYSTEM_TABLE
--SQ	SERVICE_QUEUE
--TF	SQL_TABLE_VALUED_FUNCTION
--TR	SQL_TRIGGER
--TT	TYPE_TABLE
--U 	USER_TABLE
--UQ	UNIQUE_CONSTRAINT
--V 	VIEW
----SQL_Latin1_General_CP1_CI_AS
----Latin1_General_CI_AS_KS_WS

INSERT INTO Configuration.[Status]
	([Value], SystemTime, SystemUserId)
VALUES
	('Succeeded', @Now, @UserId)
INSERT INTO Configuration.[Status]
	([Value], SystemTime, SystemUserId)
VALUES
	('Failed', @Now, @UserId)
INSERT INTO Configuration.[Status]
	([Value], SystemTime, SystemUserId)
VALUES
	('Processing', @Now, @UserId)
INSERT INTO Configuration.[Status]
	([Value], SystemTime, SystemUserId)
VALUES
	('Caution', @Now, @UserId)
INSERT INTO Configuration.[Status]
	([Value], SystemTime, SystemUserId)
VALUES
	('Information', @Now, @UserId)
INSERT INTO Configuration.[Status]
	([Value], SystemTime, SystemUserId)
VALUES
	('Unknown', @Now, @UserId)
PRINT '									...									';
END;
BEGIN
INSERT INTO Configuration.[Name]
	([Value], SystemUserId, SystemTime)
VALUES
	('DDL', @UserId, @Now)
SELECT @NameId = SCOPE_IDENTITY();
SELECT @ObjectTypeId = ObjectTypeId FROM Configuration.ObjectType WHERE [Code] = 'SC';
--When creating the first record in a tables with a reciprocal relationship,
--pass the parent Id value 1 to avoid the FK violation
--After the first record, the parent Id can be NULL if creating a top-level 
--record where parent id and the PK are the same value.
INSERT INTO Configuration.[Object]
	(ParentObjectId, NameId, ObjectTypeId, SystemUserId, SystemTime)
VALUES
	(1, @NameId, @ObjectTypeId, @UserId, @Now)
SELECT @ObjectId = ObjectId FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId;
END;
PRINT '			**Auditing-Initial Seeding**'
BEGIN
/*
When creating the first record in a tables with a reciprocal relationship,
	pass the parent Id value 1 to avoid the FK violation
	After the first record, the parent Id can be NULL if creating a top-level 
	record where parent id and the PK are the same value.
*/
SELECT @StartTime = StartTime FROM #Scripts WHERE [Name] = 'DDL'
INSERT INTO Auditing.Execution
	(ParentExecutionId, ObjectId, EventName, SystemUserId, SystemTime)
VALUES
	(1, @ObjectId, 'DDL', @UserId, @StartTime)
SELECT @ParentExecutionId = ExecutionId 
	FROM Auditing.Execution
WHERE		EventName = 'DDL'
		AND	SystemTime = (SELECT MAX(SystemTime) FROM Auditing.Execution WHERE EventName = 'DDL')
INSERT INTO Auditing.ExecutionDescription
	(ExecutionId, [Value], SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 'Data Definition Language implementation script execution', @UserId, @StartTime)
INSERT INTO Auditing.ExecutionStatus
	(ExecutionId, StatusId, SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 3, @UserId, @StartTime)
UPDATE #Scripts SET EndTime = @Now WHERE [Name] = 'DDL';
SELECT @Difference = DATEDIFF_BIG(millisecond, StartTime, EndTime) 
	FROM #Scripts
SELECT @Message = CONVERT(varchar(32), DATEADD(millisecond, @Difference, 0), 114);
SET @Now = GETDATE();
INSERT INTO Auditing.ExecutionStatus
	(ExecutionId, StatusId, SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 1, @UserId, @Now)
END;
PRINT '___________________________________________________________________________________________';
PRINT 'Time elapsed: ' + @Message;
PRINT 'SCRIPT END_________________________________________________________________________________';

--SELECT * FROM Telecom.TopLevelDomain
--SELECT * FROM Telecom.Label
--SELECT * FROM Telecom.LabelUse
--SELECT * FROM Telecom.Place
--SELECT * FROM Telecom.Scheme

--SELECT * FROM Telecom.Domain
--SELECT * FROM Security.Domain
--SELECT * FROM Security.[Users]
--SELECT * FROM Configuration.Objects
--SELECT * FROM Auditing.Executions
--SELECT * FROM Auditing.ExecutionDescription
--SELECT * FROM Auditing.ExecutionStatus
--SELECT * FROM Auditing.ExecutionError
--SELECT * FROM Institution.Organizations
