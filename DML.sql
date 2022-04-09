USE RelationalData
GO
PRINT 'SCRIPT BEGIN_______________________________________________________________________________';
/*************************************************************************************************
************************************ What is data governance? ************************************
**************************************************************************************************
Object:			DML.sql
Type:			Implementation script
Author:			Jay Quincy Allen
Description:	This script contains all seeding (initial inserts) for this database.
				This data is required for operation of this database.
				This includes data such as, but not limited to: 
				.Net collections, auditing statuses, geographic place names, postal codes, etc.
Version:		1 August, 2021 CE
**************************************************************************************************
				"the process of managing the availability, usability, integrity and security 
				of the data in enterprise systems, based on internal data standards and policies 
				that also control data usage. Effective data governance ensures that data is 
				consistent and trustworthy and doesn't get misused. It's increasingly critical 
				as organizations face new data privacy regulations and rely more and more on 
				data analytics to help optimize operations and drive business decision-making."
				https://searchdatamanagement.techtarget.com/definition/data-governance
**************************************************************************************************/
PRINT 'DML SCRIPTING'
PRINT '___________________________________________________________________________________________';
GO
SET NOCOUNT ON;
GO
DECLARE @Now datetime2 = GETDATE();
DECLARE @DatabaseName sysname, @Domain sysname, @DomainId int, @User sysname, @UserId smallint, @LabelId int;
DECLARE @Difference bigint, @Message nvarchar(max), @StartTime datetime2, @ParentExecutionId int, @SystemUserId smallint;
DROP TABLE IF EXISTS #Scripts;
DECLARE @NameId int, @ObjectId int, @ObjectTypeId tinyint;
CREATE TABLE #Scripts (id int IDENTITY(1,1), [Name] sysname, StartTime datetime2, EndTime datetime2)
PRINT '			**Auditing**'
PRINT '___________________________________________________________________________________________';
INSERT INTO #Scripts
	([Name], StartTime, EndTime)
SELECT 'DML', @Now, NULL

SELECT @DatabaseName = DB_NAME()
SELECT	@User = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name])),
		@Domain = LEFT([name], PATINDEX('%\%', [name]) - 1)
	FROM sys.server_principals 
WHERE principal_id = SUSER_ID();

SELECT @UserId = UserId
	FROM Security.[Users]
WHERE		[User] = @User
		AND	Domain = @Domain

SELECT @ObjectTypeId = ObjectTypeId FROM Configuration.ObjectType WHERE [Code] = 'SC'

EXEC Configuration.NameInsert 'DML', @UserId, @NameId output;

IF NOT EXISTS(SELECT 1 FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId)
	BEGIN
	EXEC Configuration.ObjectInsert NULL, @NameId, @ObjectTypeId, @UserId, @ObjectId output;
	END;

SELECT @ObjectId = ObjectId FROM Configuration.[Objects] WHERE [Object] = 'DML' AND ParentObjectId = ObjectId

INSERT INTO Auditing.Execution
	(ParentExecutionId, ObjectId, EventName, SystemTime, SystemUserId)
VALUES
	(NULL, @ObjectId, 'DML', @Now, @UserId)
SELECT @ParentExecutionId = ExecutionId FROM Auditing.Execution WHERE ParentExecutionId = ExecutionId AND EventName = 'DML'

INSERT INTO Auditing.ExecutionDescription
	(ExecutionId, SystemTime, [Value], SystemUserId)
VALUES
	(@ParentExecutionId, @Now, 'DML implementation script execution', @UserId)
INSERT INTO Auditing.ExecutionStatus
	(ExecutionId, SystemTime, StatusId, SystemUserId)
VALUES
	(@ParentExecutionId, @Now, 3, @UserId)
--=======================================================================================================================
DECLARE @LevelId tinyint, @ParentOrganizationId int, @OrganizationId int, @NameElement Name64;
DECLARE @OrganizationName varchar(128), @ParentOrganizationName varchar(128);
DECLARE @NameCategory varchar(64), @PersonId int, @NameCategoryId tinyint, @NameHash varbinary(32);
DECLARE @FN varchar(64), @MN varchar(64), @MN2 varchar(64), @LN varchar(64), @FNId int, @MNId int, @MN2Id int, @LNId int;
DECLARE @SchemeId tinyint;

SELECT @Now = GETDATE();

PRINT '			Insitution'

BEGIN
EXEC Institution.LevelInsert 'Agency', @UserId, @LevelId output
EXEC Institution.LevelInsert 'Department', @UserId, @LevelId output
EXEC Institution.LevelInsert 'Division', @UserId, @LevelId output
EXEC Institution.LevelInsert 'Group', @UserId, @LevelId output
EXEC Institution.LevelInsert 'Team', @UserId, @LevelId output
EXEC Institution.LevelInsert 'Parent', @UserId, @LevelId output
EXEC Institution.NameInsert 'Relational Models LLC', @UserId, @NameId output;
/*
When creating the first record in a tables with a reciprocal relationship,
	pass the parent Id value 1 to avoid the FK violation
	After the first record, the parent Id can be NULL if creating a top-level 
	record where parent id and the PK are the same value.
*/
EXEC Institution.OrganizationInsert 1, @NameId, @LevelId, 1, @UserId, @OrganizationId output;
EXEC Institution.NameInsert 'Microsoft Corporation', @UserId, @NameId output
EXEC Institution.OrganizationInsert NULL, @NameId, @LevelId, 1, @UserId, @OrganizationId output;
END;

SELECT @ParentOrganizationId = ParentOrganizationid FROM Institution.Organizations WHERE Organization = @OrganizationName  AND ParentOrganizationId = OrganizationId;
SELECT @ParentOrganizationName = Organization FROM Institution.Organizations WHERE ParentOrganizationId = @ParentOrganizationId;
--PRINT 'Organization ' + CAST(@OrganizationId AS varchar(128)) + ': ' + @OrganizationName + ' created with a parent of ' + CAST(@ParentOrganizationId AS varchar(10)) + ': ' + @ParentOrganizationName + '.'
EXEC Institution.LevelInsert 'Agency', @UserId, @LevelId output
SELECT @OrganizationName = 'United States Department of Health and Human Services';
EXEC Institution.OrganizationCreate NULL, @OrganizationName, @LevelId, 1, @UserId, @OrganizationId output
SELECT @ParentOrganizationId = @OrganizationId; --KEEP THE ParentOrganizationId FROM HHS
--========================================================================================================================
EXEC Institution.LevelInsert 'Center', @UserId, @LevelId output
SELECT @OrganizationName = 'United States Centers for Disease Control and Prevention';
EXEC Institution.OrganizationCreate @ParentOrganizationId, @OrganizationName, @LevelId, 1, @UserId, @OrganizationId output
--=======================================================================================================
EXEC Institution.LevelInsert 'Institute', @UserId, @LevelId output
SELECT @OrganizationName = 'United States National Institutes of Health';
EXEC Institution.OrganizationCreate @ParentOrganizationId, @OrganizationName, @LevelId, 1, @UserId, @OrganizationId output
SELECT @ParentOrganizationId = @OrganizationId;
--========================================================================================================================
SELECT @OrganizationName = 'United States National Cancer Institute';
SELECT @ParentOrganizationId = @OrganizationId;
EXEC Institution.OrganizationCreate @ParentOrganizationId, @OrganizationName, @LevelId, 1, @UserId, @OrganizationId output
--========================================================================================================================

--===========================Individual=================================================
PRINT '			Individual'
--=============================================================================================
SELECT @NameCategory = 'Legal Name';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output

SELECT @NameCategory = 'Birth Certificate';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output

SELECT @NameCategory = 'Driver''s License';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output

SELECT @NameCategory = 'Passport';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output

--=======================================
SELECT @FN = 'Jay';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
--=======================================
SELECT @MN = 'Quincy';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
--=======================================
SELECT @LN = 'Allen';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameCategory = 'Legal Name';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output

SELECT @NameHash = HASHBYTES('SHA2_256', CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId

SELECT @NameCategory = 'Given Name';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output

EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId

SELECT @NameCategory = 'Birth Certificate';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId

SELECT @NameCategory = 'Driver''s License';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId

SELECT @NameCategory = 'Passport';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
SELECT @NameCategory = 'Legal Name';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output

--=============================================================================================
BEGIN
SELECT @FN = 'George';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Washington';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'John';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Adams';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Thomas';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Jefferson';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'James';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Madison';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'James';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Monroe';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'John';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Quincy';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Adams';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Andrew';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Jackson';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Martin';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Van';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Buren';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'William';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Henry';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Harrison';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'John';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Tyler';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'James';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Knox';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Polk';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Zachary';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Taylor';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Millard';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Filmore';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Franklin';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Pierce';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'James';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Buchanan';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Abraham';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Lincoln';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Andrew';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Johnson';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Hiram';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Ulysses';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Grant';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Ulysses';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'S.';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Grant';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameCategory = 'Known By';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @NameCategory = 'Legal Name';
EXEC Person.NameCategoryInsert @NameCategory, @UserId, @NameCategoryId output
--=======================================
SELECT @FN = 'Rutheford';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Birchard';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Hayes';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'James';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Abram';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Garfield';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Chester';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Alan';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Arthur';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Stephen';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Grover';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Cleveland';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Benjamin';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Harrison';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'William';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'McKinley';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Theodore';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Roosevelt';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'William';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Howard';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Taft';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Thomas';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Woodrow';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Wilson';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Warren';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Gamaliel';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Harding';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Calvin';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @LN = 'Coolidge';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Herbert';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Clark';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Hoover';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Franklin';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Delano';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Roosevelt';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Harry';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'S.';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Truman';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Dwight';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'David';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Eisenhower';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'John';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Fitzgerald';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Kennedy';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Lyndon';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Baines';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Johnson';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Richard';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Milhous';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Nixon';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Geralnd';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Rudolph';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Ford';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'James';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Earl';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Carter';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Ronald';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Wilson';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Reagan';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'George';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Herbert';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @MN2 = 'Walker';
EXEC Person.NameElementInsert @MN2, @UserId, @MN2Id output
SELECT @LN = 'Bush';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @MN2 + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MN2Id, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'William';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Jefferson';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Clinton';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'George';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Walker';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Bush';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
--=============================================================================================
SELECT @FN = 'Barack';
EXEC Person.NameElementInsert @FN, @UserId, @FNId output
SELECT @MN = 'Hussein';
EXEC Person.NameElementInsert @MN, @UserId, @MNId output
SELECT @LN = 'Obama';
EXEC Person.NameElementInsert @LN, @UserId, @LNId output
--=======================================
SELECT @NameHash = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @FN + @MN + @LN));
EXEC Person.IndividualInsert @NameHash, @UserId, @PersonId output;
--=======================================
EXEC Person.IndividualNameElementInsert @PersonId, @FNId, @NameCategoryId, 1, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @MNId, @NameCategoryId, 2, 1, @UserId
EXEC Person.IndividualNameElementInsert @PersonId, @LNId, @NameCategoryId, 3, 1, @UserId
--=============================================================================================
END;
--SELECT * FROM Person.PersonsNames(1, ' ')
--SELECT * FROM Person.Individual
--select * from Person.PersonNameElement
--select * from Person.NameCategory

PRINT '			Telecom'
BEGIN
EXEC Telecom.LabelUseInsert 'Subdomain', @UserId, @LabelId output
EXEC Telecom.LabelUseInsert 'Subdirectory', @UserId, @LabelId output
EXEC Telecom.SchemeInsert 'http', @UserId, @SchemeId output
EXEC Telecom.SchemeInsert 'https', @UserId, @SchemeId output
EXEC Telecom.SchemeInsert 'mailto', @UserId, @SchemeId output
EXEC Telecom.SchemeInsert 'ftp', @UserId, @SchemeId output
EXEC Telecom.SchemeInsert 'sftp', @UserId, @SchemeId output
END;
BEGIN
PRINT '				Top level domain name...'
DECLARE @Count int, @Row int;
DECLARE @TLDList TABLE (id int IDENTITY(1,1), [value] varchar(63));
DECLARE @TLD varchar(63), @TopLevelDomainId smallint;

EXEC Telecom.TopLevelDomainInsert 'local', @TopLevelDomainId output;

INSERT INTO @TLDList
	([value])
SELECT TLD 
	FROM Staging.dbo.TLD;
SELECT @Count = @@ROWCOUNT;
SET @Row = 1;

WHILE @Count >= @Row
	BEGIN
	SELECT @TLD = [value]
		FROM @TLDList
	WHERE	id = @Row;
	EXEC Telecom.TopLevelDomainInsert @TLD, @TopLevelDomainId output;
	SELECT @Row = @Row + 1;
	END;
--NEXT:	SEED URL DATA HERE

DECLARE @Urls TABLE (id int IDENTITY(1,1), [Name] nvarchar(253))
DECLARE @LabelUseId tinyint, @UrlHASH varbinary(32);
DECLARE @TopLevelDomain varchar(63), @UrlString varchar(max), @UrlId int;
DECLARE @SubDomains varchar(2083), @Subdirectories varchar(2083);
DECLARE @SubdomainsSet TABLE (Subdomain varchar(63),  SortOrder smallint);
DECLARE @SubdirectoriesSet TABLE (Subdirectory varchar(63), SortOrder smallint);

INSERT INTO @Urls
	([Name])
SELECT 'www.msdn.microsoft.com'
UNION
SELECT 'DataExSitu.com'
UNION
SELECT 'info.general.datamodeler.net'
UNION
SELECT 'relationalmodels.com'
UNION
SELECT 'relationalmodels.com/contact'
UNION
SELECT 'datamodeler.net/A/B/C'
UNION
SELECT 'datamodeling.datamodeler.net/F/E/D/dimensionalmodeling.aspx'

SELECT @Count = @@ROWCOUNT;
SET @Row = 1;
SET @Now = GETDATE();

WHILE @Count >= @Row
	BEGIN
	--PRINT '_____________________DEBUG_____________________';
	--PRINT '@Row: ' + CAST(@Row AS VARCHAR(10))

	DELETE FROM @SubdomainsSet;
	DELETE FROM @SubdirectoriesSet;
	SELECT @UrlString = '';
	SELECT @TopLevelDomain = '';
	SELECT @SubDomains = '';
	SELECT @Subdirectories = '';
	
	SELECT	@UrlString = [Name],
			@SubDomains =		CASE WHEN PATINDEX('%/%', [Name]) = 0 --when there are no subdirectories
									THEN [Name]
									ELSE LEFT([Name], PATINDEX('%/%', [Name])-1)--Return the part of the string without the subdirectories
								END,
			@Subdirectories =	CASE WHEN (LEN([Name]) - LEN(REPLACE([Name], '/', ''))) <> 0 --When there are one or more subdirectories
									THEN RIGHT([Name], LEN([Name]) - PATINDEX('%/%', [Name]))--Return the part of the string with subdirectories
									ELSE ''
								END
		FROM @Urls
	WHERE	id = @Row;

	SELECT @TopLevelDomain  = REVERSE(LEFT(REVERSE(@SubDomains), PATINDEX('%.%', REVERSE(@SubDomains))-1))
	--PRINT '_____________________DEBUG_____________________';

	INSERT INTO @SubdomainsSet			--Create a set of subdomain lables from the delimited string.
		(Subdomain, SortOrder)
	SELECT [value], [Key]
			FROM OPENJSON(CONCAT('["', REPLACE(@SubDomains, '.', '","'), '"]'))
	WHERE	[value] <> ''
		ORDER BY CONVERT(int, [key]);

	DELETE @SubdomainsSet				--Remove the .com, .org, whatever. Those are top level domain names.
		FROM @SubdomainsSet
	WHERE	Subdomain = @TopLevelDomain;

	INSERT INTO @SubdirectoriesSet			--Create a set of subdirectory labels from the delimited string
		(Subdirectory, SortOrder)
	SELECT [value], [Key]
			FROM OPENJSON(CONCAT('["', REPLACE(@Subdirectories, '/', '","'), '"]'))
	WHERE	[value] <> ''
		ORDER BY CONVERT(int, [key]);

	INSERT INTO Telecom.[Label]
		([Value], SystemTime)
	SELECT l.Subdomain, @Now
		FROM @SubdomainsSet l
	LEFT OUTER JOIN Telecom.[Label] tl
		ON	l.Subdomain = tl.[Value]
	WHERE		tl.[Value] IS NULL
			AND	l.Subdomain IS NOT NULL;
			
	SELECT @LabelId = l.Labelid
		FROM @SubdomainsSet lables
	INNER JOIN Telecom.[Label] l
		ON	lables.Subdomain = l.[Value]
	WHERE	SortOrder = (SELECT MAX(SortOrder) FROM @SubdomainsSet);

	INSERT INTO Telecom.[Label]
		([Value], SystemTime)
	SELECT l.Subdirectory, @Now
		FROM @SubdirectoriesSet l
	LEFT OUTER JOIN Telecom.[Label] tl
		ON	l.Subdirectory = tl.[Value]
	WHERE		tl.[Value] IS NULL
			AND	l.Subdirectory IS NOT NULL;

	EXEC Telecom.TopLevelDomainInsert @TopLevelDomain, @TopLevelDomainId output
	EXEC Telecom.DomainInsert @LabelId, @TopLevelDomainId, @DomainId output;
	
	SELECT @UrlHASH = HASHBYTES('SHA2_256', CONVERT(nvarchar(256), @UrlString));
	SELECT @SchemeId = 1;

	EXEC Telecom.UrlInsert @UrlHASH, @DomainId, @SchemeId, @UserId, @UrlId output

	SELECT @LabelUseId = LabelUseId FROM Telecom.LabelUse WHERE [Value] = 'Subdomain';
	SELECT @Now = GETDATE();

	DISABLE TRIGGER Telecom.UrlLabelNext ON Telecom.UrlLabel; 

	INSERT INTO Telecom.UrlLabel
		(UrlId, LabelId, LabelUseId, SortOrder, ValidTime, Active, [Current], SystemUserId, SystemTime)
	SELECT	@UrlId, l.LabelId, @LabelUseId, labels.SortOrder, @Now, 1, 1, @UserId, @Now
		FROM Telecom.[Label] l
	INNER JOIN @SubdomainsSet labels
		ON	l.[Value] = labels.Subdomain
	LEFT OUTER JOIN Telecom.UrlLabel urlLabel
		ON		urlLabel.UrlId = @UrlId
			AND	urlLabel.LabelUseId = @LabelUseId
			AND	urlLabel.LabelId  = l.LabelId
			AND	urlLabel.SortOrder = labels.SortOrder
			AND	urlLabel.Active = 1
	WHERE	urlLabel.UrlId IS NULL;

	IF @Subdirectories <> ''
		BEGIN
		SELECT @LabelUseId = LabelUseId FROM Telecom.LabelUse WHERE [Value] = 'Subdirectory';
		SELECT @Now = GETDATE();

		INSERT INTO Telecom.UrlLabel
			(UrlId, LabelId, LabelUseId, SortOrder, ValidTime, Active, [Current], SystemUserId, SystemTime)
		SELECT	@UrlId, l.LabelId, @LabelUseId, labels.SortOrder, @Now, 1, 1, @UserId, @Now
			FROM Telecom.[Label] l
		INNER JOIN @SubdirectoriesSet labels
			ON	l.[Value] = labels.Subdirectory
		LEFT OUTER JOIN Telecom.UrlLabel urlLabel
			ON		@UrlId = urlLabel.UrlId
				AND	urlLabel.LabelUseId = @LabelUseId
				AND	urlLabel.LabelId = l.LabelId
				AND	urlLabel.SortOrder = labels.SortOrder
				AND	urlLabel.Active = 1
		WHERE	urlLabel.UrlId IS NULL;

		SELECT @LabelUseId = LabelUseId FROM Telecom.LabelUse WHERE [Value] = 'Subdirectory';
		SELECT @Now = GETDATE();

		INSERT INTO Telecom.UrlLabel
			(UrlId, LabelId, LabelUseId, SortOrder, ValidTime, Active, [Current], SystemUserId, SystemTime)
		SELECT	@UrlId, l.LabelId, @LabelUseId, labels.SortOrder, @Now, 1, 1, @UserId, @Now
			FROM Telecom.[Label] l
		INNER JOIN @SubdirectoriesSet labels
			ON	l.[Value] = labels.Subdirectory
		LEFT OUTER JOIN Telecom.UrlLabel urlLabel
			ON		@UrlId = urlLabel.UrlId
				AND	urlLabel.LabelId = l.LabelId
				AND	urlLabel.SortOrder = labels.SortOrder
				AND	urlLabel.Active = 1
		WHERE		urlLabel.UrlId IS NULL
				AND	labels.Subdirectory IS NOT NULL
				AND	urlLabel.LabelUseId = @LabelUseId
		GROUP BY l.LabelId, labels.SortOrder;
		END;
	
	ENABLE TRIGGER Telecom.UrlLabelNext ON Telecom.UrlLabel; 

	SELECT @Row = @Row + 1;
	END;

END;
BEGIN--Workflow
PRINT '			Workflow'
SET @Now = GETDATE();
IF NOT EXISTS(SELECT 1 FROM Workflow.Task WHERE [Name] = 'Setup Express Scripts')
	BEGIN
	INSERT INTO Workflow.Task
		([Name], SystemUserId, SystemTime)
	SELECT 'Setup Express Scripts', @UserId, @Now
	END;
IF NOT EXISTS(SELECT 1 FROM Workflow.Task WHERE [Name] = '1) Call Huffard Animal Hospital')
	BEGIN
	INSERT INTO Workflow.Task
		([Name], SystemUserId, SystemTime)
	SELECT '1) Call Huffard Animal Hospital', @UserId, @Now
	END;

--select * from Workflow.Task
END;
BEGIN--AUDITING
PRINT '			**Auditing**'
SET @Now = GETDATE();

SELECT @User = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name]))
	FROM sys.server_principals 
WHERE principal_id = SUSER_ID()

SELECT @UserId = UserId FROM Security.[User] u INNER JOIN Security.[Name] n ON u.NameId = n.NameId WHERE n.[Value] = @User AND DomainId = 1;

SELECT @ParentExecutionId = ExecutionId 
	FROM Auditing.Execution
WHERE		EventName = 'DML'
		AND	SystemTime = (SELECT MAX(SystemTime) FROM Auditing.Execution WHERE EventName = 'DML')

UPDATE #Scripts SET EndTime = @Now WHERE [Name] = 'DML';

SELECT @Difference = DATEDIFF_BIG(millisecond, StartTime, EndTime) 
	FROM #Scripts;
	
INSERT INTO Auditing.ExecutionStatus
	(ExecutionId, StatusId, SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 1, @UserId, @Now)
END;
SELECT @Message = CONVERT(varchar(32), DATEADD(millisecond, @Difference, 0), 114);
PRINT '___________________________________________________________________________________________';
PRINT '___________________________________________________________________________________________';
PRINT 'Time elapsed: ' + ISNULL(@Message, '');
PRINT 'SCRIPT END_________________________________________________________________________________';


--SELECT * FROM Telecom.TopLevelDomain
--SELECT * FROM Telecom.Label
--SELECT * FROM Telecom.LabelUse
--SELECT * FROM Telecom.Scheme

--SELECT * FROM Telecom.Label
--SELECT * FROM Telecom.Domain
--SELECT * FROM Security.Domain
--SELECT * FROM Security.[Users]

--SELECT * FROM Configuration.Objects

--SELECT e.ExecutionId, e.SystemTime, o.Object
--	FROM Auditing.Executions E
--INNER JOIN Configuration.Objects o
--	ON	e.ObjectId = o.ObjectId



--SELECT * FROM Auditing.ExecutionDescription
--SELECT * FROM Auditing.ExecutionStatus
--SELECT * FROM Auditing.ExecutionError
--SELECT * FROM Institution.Organizations
--SELECT * FROM Telecom.Place
