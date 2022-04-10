USE RelationalData
GO
PRINT 'SCRIPT BEGIN_______________________________________________________________________________';
/*************************************************************************************************
**************************************************************************************************
Object:			Programmability.sql
Type:			Implementation script
Author:			Jay Quincy Allen
Description:	Drop and create all functions and stored procedures
Version:		1 August, 2021 CE
**************************************************************************************************
************************************ What is data governance? ************************************ 
	consistent and trustworthy and doesn't get misused. It's increasingly critical 
	as organizations face new data privacy regulations and rely more and more on 
	data analytics to help optimize operations and drive business decision-making."
	https://searchdatamanagement.techtarget.com/definition/data-governance
**************************************************************************************************/
PRINT 'PROGRAMMABILITY SCRIPTING'
PRINT '___________________________________________________________________________________________';

SET NOCOUNT ON;
PRINT 'DROPPING ALL PROGRAMMABILITY...';
GO
DECLARE @Now datetime2 = GETDATE();
DECLARE @DatabaseName sysname, @Domain sysname, @DomainId tinyint, @User sysname, @UserId smallint;
DECLARE @Difference bigint, @Message nvarchar(max), @StartTime datetime2, @ParentExecutionId int, @LabelId tinyint;
DROP TABLE IF EXISTS #Scripts;
DECLARE @NameId int, @ObjectId int, @ObjectTypeId tinyint;
CREATE TABLE #Scripts (id int IDENTITY(1,1), [Name] sysname, StartTime datetime2, EndTime datetime2)
PRINT '			**Auditing**'
INSERT INTO #Scripts
	([Name], StartTime, EndTime)
SELECT 'Programmability', @Now, NULL

SELECT @DatabaseName = DB_NAME()
SELECT	@User = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name])),
		@Domain = LEFT([name], PATINDEX('%\%', [name]) - 1)
	FROM sys.server_principals 
WHERE principal_id = SUSER_ID()

SELECT @UserId = UserId
	FROM Security.[Users]
WHERE		[User] = @User
		AND	Domain = @Domain;

IF NOT EXISTS(SELECT 1 FROM Configuration.[Name] WHERE [Value] = 'Programmability')
	BEGIN
	INSERT INTO Configuration.[Name]
		([Value], SystemUserId, SystemTime, ExecutionId)
	VALUES
		('Programmability', @UserId, @Now, 3)
	SELECT @NameId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @NameId = NameId FROM Configuration.[Name] WHERE [Value] = 'Programmability'
	END;
IF NOT EXISTS(SELECT 1 FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId)
	BEGIN
	SELECT @ObjectTypeId = ObjectTypeId FROM Configuration.ObjectType WHERE [Code] = 'SC';
	INSERT INTO Configuration.[Object]
		(ParentObjectId, NameId, ObjectTypeId, SystemUserId, SystemTime, ExecutionId)
	VALUES
		(NULL, @NameId, @ObjectTypeId, @UserId, @Now, 3)
	SELECT @ObjectId = ObjectId FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId;
	END
ELSE
	BEGIN
	SELECT @ObjectId = ObjectId FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId
	END;
INSERT INTO Auditing.Execution
	(ParentExecutionId, ObjectId, EventName, SystemUserId, SystemTime)
VALUES
	(NULL, @ObjectId, 'Programmability', @UserId, @Now)
SELECT @ParentExecutionId = ExecutionId FROM Auditing.Execution
INSERT INTO Auditing.ExecutionDescription
	(ExecutionId, [Value], SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 'Programmability implementation script execution', @UserId, @Now)
INSERT INTO Auditing.ExecutionStatus
	(ExecutionId, StatusId, SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 3, @UserId, @Now)
PRINT '									...									';
DECLARE @Count int, @Row int, @Schema sysname, @Procedure sysname, @Function sysname;
DECLARE @SQL nvarchar(max), @ObjectTypeCode varchar(2), @ObjectTypeName sysname;
DECLARE @Procedures TABLE (id smallint IDENTITY(1,1), SchemaName sysname, ProcedureName sysname)
DECLARE @Functions TABLE (id smallint IDENTITY(1,1), SchemaName sysname, FunctionName sysname)

SET NOCOUNT ON;

INSERT INTO @Procedures
	(SchemaName, ProcedureName)
SELECT	SCHEMA_NAME(schema_id), [name]--, o.type
	FROM sys.procedures

SELECT @Count = @@ROWCOUNT
SET @Row = 1

WHILE @Count >= @Row
	BEGIN
	SELECT	@Procedure = ProcedureName,
			@Schema = SchemaName
		FROM @Procedures
	WHERE id = @Row
	SELECT @SQL = '				DROP PROCEDURE IF EXISTS [' + @Schema + '].[' + @Procedure + ']'
	PRINT @SQL
	EXEC (@SQL)
	SELECT @Row = @Row + 1
	END
SET @Row = 1;

INSERT INTO @Functions
	(SchemaName, FunctionName)
SELECT ROUTINE_SCHEMA, ROUTINE_NAME
	FROM INFORMATION_SCHEMA.ROUTINES
WHERE		ROUTINE_TYPE = 'FUNCTION' 

SELECT @Count = @@ROWCOUNT
SET @Row = 1

WHILE @Count >= @Row
	BEGIN
	SELECT	@Function = FunctionName,
			@Schema = SchemaName
		FROM @Functions
	WHERE id = @Row
	SELECT @SQL = '				DROP FUNCTION IF EXISTS [' + @Schema + '].[' + @Function + ']'
	PRINT @SQL
	EXEC (@SQL)
	SELECT @Row = @Row + 1
	END
GO
PRINT '___________________________________________________________________________________________';
GO
PRINT 'CREATING FUNCTIONS...';
GO
--===========================================Administration======================================================
PRINT '	[Administration]';
GO
PRINT '									...									';
GO
--===========================================Auditing============================================================
PRINT '	[Auditing]';
GO
PRINT '									...									';
GO
--===========================================Configuration=======================================================
PRINT '	[Configuration]';
GO
PRINT '									...									';
GO
PRINT '			CREATE FUNCTION Configuration.ObjectTypeId'
GO
CREATE FUNCTION Configuration.ObjectTypeId (@ObjectTypeCode char(2))
RETURNS tinyint
/**************************************************************************************************
Object:			Configuration.ObjectTypeId
Type:			Inline scalar function
Author:			Jay Quincy Allen
Description:	Takes the [Code] value as input parameter and the identity (PK) value is returned.
Version:		1 August, 2021 CE
**************************************************************************************************/
AS
BEGIN

	DECLARE @ObjectTypeId tinyint

	SELECT @ObjectTypeId  = ObjectTypeId 
		FROM Configuration.ObjectType
	WHERE	[Code] = @ObjectTypeCode
	RETURN @ObjectTypeId;

END
GO
PRINT '			CREATE FUNCTION Configuration.ObjectTypeCode'
GO
CREATE FUNCTION Configuration.ObjectTypeCode (@ObjectTypeId tinyint)
RETURNS varchar(2)
/*
Object:			Configuration.ObjectTypeCode
Type:			Inline scalar function
Author:			Jay Quincy Allen
Description:	Takes the identity(PK) value as input parameter and returns the [Code] value.
Version:		2 August, 2021 CE
*/
AS
BEGIN

	DECLARE @ObjectTypeCode varchar(2);

	SELECT @ObjectTypeCode = Code
		FROM Configuration.ObjectType
	WHERE	ObjectTypeId = @ObjectTypeId
	RETURN @ObjectTypeCode;

END
GO
PRINT '			CREATE FUNCTION Configuration.ObjectTypeName'
GO
CREATE FUNCTION Configuration.ObjectTypeName (@ObjectTypeId tinyint)
RETURNS sysname
/*
Object:			Configuration.ObjectTypeName
Type:			Inline scalar function
Author:			Jay Quincy Allen
Description:	Takes the identity(PK) value as input parameter and returns the ObjectType [Name] value.
Version:		2 August, 2021 CE
*/
AS
BEGIN

	DECLARE @ObjectTypeName sysname;

	SELECT @ObjectTypeName = [Name]
		FROM Configuration.ObjectType
	WHERE	ObjectTypeId = @ObjectTypeId;

	RETURN @ObjectTypeName;

END
GO
--===========================================Geographic===============================================================
PRINT '	[Geographic]';
GO
PRINT '									...									';
GO
--===========================================Individual===============================================================
PRINT '	[Individual]';
GO
PRINT '			CREATE FUNCTION Individual.PersonName'
GO
CREATE FUNCTION Person.IndividualName (@IndividualId int, @NameCategoryId tinyint, @NameDelimiter char(1))
RETURNS nvarchar(max)
AS
/**********************************************************************************************************************
Object:			Person.IndividualName
Type:			Inline scalar function
Author:			Jay Quincy Allen
Description:	Returns a delimited string of the name elements constituting a person's name for a particular category.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
BEGIN
--=========================DEBUG============================================================================
--DECLARE @IndividualId int = 44, @NameCategoryId tinyint = 1, @NameDelimiter char(1) = ' '
--DECLARE @Name dbo.Name64
------EXEC Person.IndividualSelect @PersonId, @NameCategoryId, @NameDelimiter, @Name output
------SELECT @Name
--SELECT Person.IndividualName(@PersonId, @NameCategoryId, @NameDelimiter) AS 'Name'
--=========================DEBUG============================================================================
	DECLARE @Name nvarchar(max);

	SELECT @Name = STUFF(
(
	SELECT	@NameDelimiter + [Name]
		FROM
		(SELECT ne.[Value] AS [Name]
			FROM Person.IndividualNameElement pne
		INNER JOIN Person.NameElement ne
			ON	pne.NameElementId = ne.NameElementId
		WHERE		pne.NameCategoryId = @NameCategoryId
				AND	pne.IndividualId = @IndividualId
		GROUP BY ne.[Value]
		) AS N FOR XML PATH('')
	)
	,1,1,'');

	RETURN(@Name);
END;
GO
PRINT '									...									';
GO
PRINT '			CREATE FUNCTION Individual.PersonsNames'
GO
CREATE FUNCTION Person.IndividualsNames (@NameCategoryId tinyint = 1, @NameDelimiter char(1) = ' ')
RETURNS @Names TABLE (IndividualId int, NameCategory Name32, [Name] nvarchar(max))
AS
/**********************************************************************************************************************
Object:			Person.IndividualsNames
Type:			Table-valued function
Author:			Jay Quincy Allen
Description:	Returns a table of persons' names as a delimited strings of name elements.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
BEGIN
--=========================DEBUG============================================================================
--DECLARE @NameCategoryId tinyint = 1, @NameDelimiter char(1) = ' '
--SELECT * FROM Person.IndividualsNames(@NameCategoryId, @NameDelimiter) ORDER BY PersonId
--=========================DEBUG============================================================================
	INSERT INTO @Names
		(IndividualId, NameCategory, [Name])
	SELECT p.IndividualId, nc.[Value], ISNULL(STUFF(
	(
		SELECT	@NameDelimiter + COALESCE(ne.[Value], '')
			FROM Person.IndividualNameElement pne
		INNER JOIN Person.NameElement ne
			ON	pne.NameElementId = ne.NameElementId
		WHERE		pne.NameCategoryId = @NameCategoryId
				AND	pne.IndividualId = p.IndividualId
				AND	ne.[Value] <> ''
			GROUP BY ne.[Value], pne.SortOrder
		ORDER BY pne.SortOrder
			FOR XML PATH(''), TYPE).value('.[1]', 'nvarchar(max)')
		,1,1,''), ''
	) AS [Name]
		FROM Person.Individual p
	INNER JOIN Person.IndividualNameElement pne
		ON	p.IndividualId = pne.IndividualId
	INNER JOIN Person.NameCategory nc
		ON	pne.NameCategoryId = nc.NameCategoryId
	WHERE	pne.NameCategoryId = @NameCategoryId
		GROUP BY p.IndividualId, nc.[Value]
	RETURN;
END;
GO
PRINT '	[Telecom]';
GO
CREATE FUNCTION Telecom.UrlLabelCoalesced(@UrlId int, @LabelUseId tinyint)
RETURNS varchar(2048)
/**************************************************************************************************
Object:			Telecom.UrlLabelCoalesced
Type:			Inline scalar function
Author:			Jay Quincy Allen
Description:	Takes the @UrlId value as input parameter and returns each label 
				of the Url coalesced into a '.' delimited string.
				https://www.sitemaps.org/protocol.html
				select len('https://support.microsoft.com/en-us/topic/maximum-url-length-is-2-083-characters-in-internet-explorer-174e7c8a-6666-f4e0-6fd6-908b53c12246#:~:text=Summary,path%20length%20of%202%2C048%20characters.')
				If anyone who reads this gets the humor in why I did a SELECT LEN() on the Url 
				for MicrosofT's page on maximum Url lengths, then you should immediately be promoted.
				Promoted to what, I'm not sure. But definitely promoted.
Version:		25 August, 2021 CE
**************************************************************************************************/
/*====================================DEBUG=======================================================
SELECT Telecom.UrlLabelCoalesced(6,2)  
select * from telecom.urllabel where urlid = 5, so 5 would return NULL.
select * from telecom.label
EXEC Telecom.UrlLabelSelect null
**************************************DEBUG*******************************************************/
AS
BEGIN
	DECLARE @LabelsCoalesced varchar(2048);
	IF @LabelUseId = 1--If the coalesce is being called for the domain label list, then add the top level domain name to the end.
		BEGIN
		SELECT	@LabelsCoalesced = COALESCE(@LabelsCoalesced + '.' + l.[Value], l.[Value])
			FROM Telecom.UrlLabel u
		INNER JOIN Telecom.[Label] l
			ON	u.LabelId = l.LabelId
		WHERE		u.UrlId = @UrlId
				AND	u.LabelUseId = @LabelUseId
		ORDER BY u.SortOrder;
		SELECT	@LabelsCoalesced = @LabelsCoalesced + '.' + tld.[Value]
			FROM Telecom.[Url] turl
		INNER JOIN Telecom.Domain d
			ON	turl.DomainId = d.DomainId
		INNER JOIN Telecom.TopLevelDomain tld
			ON	d.TopLevelDomainId = tld.TopLevelDomainId
		WHERE		turl.UrlId = @UrlId;
		END
	ELSE
		BEGIN
		SELECT	@LabelsCoalesced = COALESCE(@LabelsCoalesced + '/' + l.[Value], l.[Value])
			FROM Telecom.UrlLabel u
		INNER JOIN Telecom.[Label] l
			ON	u.LabelId = l.LabelId
		WHERE		u.UrlId = @UrlId
				AND	u.LabelUseId = @LabelUseId
		ORDER BY u.SortOrder;
		END;
	RETURN @LabelsCoalesced;
END
GO
CREATE FUNCTION Telecom.TopLevelDomainId(@TopLevelDomain Name16)
RETURNS tinyint
/**************************************************************************************************
Object:			Telecom.TopLevelDomainId
Type:			Inline scalar function
Author:			Jay Quincy Allen
Description:	Takes the @TopLevelDomain value as input parameter and the identity (PK) value is returned.
Version:		24 August, 2021 CE
**************************************************************************************************/
AS
BEGIN

	DECLARE @TopLevelDomainId tinyint

	SELECT @TopLevelDomainId = TopLevelDomainId
		FROM Telecom.TopLevelDomain
	WHERE	[Value] = @TopLevelDomain
	RETURN @TopLevelDomainId;

END
GO
PRINT 'CREATING STORED PROCEDURES...';
GO
PRINT '									...									';
GO
--===========================================Security===============================================================
PRINT '	[Security]';
GO
PRINT '			CREATE PROCEDURE [Security].NameInsert'
GO
CREATE PROCEDURE [Security].NameInsert
	(@Name sysname, @SystemUserId smallint, @ExecutionId int, @NameId int output)
AS
/*********************************************************************************************************************
Object:			Security.NameInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Security.Name and returns the NameId
				or simply returns the DomainId if the record already exists.
Version:		7 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
			FROM [Security].[Name]
		WHERE	[Value] = @Name)
	BEGIN
	INSERT INTO [Security].[Name]
		([Value], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@Name, @SystemUserId, @Now, @ExecutionId)
	SELECT @NameId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT	@NameId = NameId
		FROM [Security].[Name]
	WHERE		[Value] = @Name
	END

GO
PRINT '			CREATE PROCEDURE [Security].DomainInsert'
GO
CREATE PROCEDURE [Security].DomainInsert
	(@DomainId int, @Domain sysname, @SystemUserId int, @ExecutionId int)
AS
/*********************************************************************************************************************
Object:			Security.DomainInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Security.Domain and returns the DomainId
				or simply returns the DomainId if the record already exists.
Version:		7 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
			FROM [Security].Domain
		WHERE	[Name] = @Domain)
	BEGIN
	INSERT INTO [Security].Domain
		(DomainId, [Name], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@DomainId, @Domain, @SystemUserId, @Now, @ExecutionId)
	END
GO
PRINT '			CREATE PROCEDURE [Security].GroupInsert'
GO
CREATE PROCEDURE [Security].GroupInsert
	(@DomainId int, @NameId int, @Active bit, @SystemUserId int, @ExecutionId int, @GroupId smallint output)
AS
/*********************************************************************************************************************
Object:			Security.GroupInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Security.Group and returns the GroupId
				or simply returns the GroupId if the record already exists.
Version:		7 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
			FROM [Security].[Group]
		WHERE			DomainId = @DomainId
				AND	NameId = @NameId)
	BEGIN
	INSERT INTO [Security].[Group]
		(DomainId, NameId, Active, SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@DomainId, @NameId, @Active, @SystemUserId, @Now, @ExecutionId)
	SELECT @GroupId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT	@GroupId = GroupId
		FROM [Security].[Group]
	WHERE		DomainId = @DomainId
			AND	NameId = @NameId
	END
GO
PRINT '			CREATE PROCEDURE [Security].UserInsert'
GO
CREATE PROCEDURE [Security].UserInsert
	(@DomainId int, @NameId int, @Active bit, @SystemUserId int, @ExecutionId int, @UserId int output)
AS
/*********************************************************************************************************************
Object:			Security.UserInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Security.User and returns the UserId
				or simply returns the UserId if the record already exists.
Version:		7 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime, @Count int, @SystemUser sysname, @Domain varchar(63);

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
			FROM [Security].[User]
		WHERE		DomainId = @DomainId
				AND	NameId = @NameId)
	BEGIN
	IF @SystemUserId IS NULL
		BEGIN
		SELECT	@SystemUser = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name])),
				@Domain = LEFT([name], PATINDEX('%\%', [name]) - 1)
			FROM sys.server_principals 
		WHERE principal_id = SUSER_ID()
		SELECT @SystemUserId = UserId
			FROM Security.[Users] 
		WHERE		[User] = @SystemUser
				AND Domain = @Domain
		
		SELECT @Count = COUNT(1) FROM [Security].[User];
		IF @Count > 0
			BEGIN
			SELECT @SystemUserId = @SystemUserId + 1;
			END
		END
	INSERT INTO [Security].[User]
		(DomainId, NameId, Active, SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@DomainId, @NameId, @Active, @SystemUserId, @Now, @ExecutionId)
	SELECT @UserId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT	@UserId = UserId
		FROM [Security].[User]
	WHERE		DomainId = @DomainId
			AND	NameId = @NameId
	END;
GO
PRINT '			CREATE PROCEDURE [Security].UserCreate'
GO
CREATE PROCEDURE [Security].UserCreate
	(@DomainId int, @UserName sysname, @Active bit, @SystemUserId int, @ExecutionId int, @UserId int output)
AS
/*********************************************************************************************************************
Object:			Security.UserCreate
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Security.Name and Security.User 
				and returns the UserId whether the record existed or is new.
Version:		11 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime, @Count int, @NameId int;

SELECT @Now = GETDATE()

EXEC Security.NameInsert @UserName, @SystemUserId, @ExecutionId, @NameId output
EXEC Security.UserInsert @DomainId, @NameId, @Active, @SystemUserId, @ExecutionId, @UserId output

GO
PRINT '			CREATE PROCEDURE [Security].UserGroupInsert'
GO
CREATE PROCEDURE [Security].UserGroupInsert
	(@UserId smallint, @GroupId smallint, @ValidTime smalldatetime, @Active bit, @SystemUserId smallint, @ExecutionId int)
AS
/*********************************************************************************************************************
Object:			Security.UserGroupInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Security.UserGroup
				Security.UserGroup is temporal. The new record can indicate a logical update or delete.
Version:		7 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
				FROM [Security].UserGroup
			WHERE		UserId = @UserId
					AND	GroupId = @GroupId
					AND Active = @Active
					AND	[Current] = 1)
	BEGIN
	INSERT INTO [Security].UserGroup
		(UserId, GroupId, ValidTime, [Active], [Current], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@UserId, @GroupId, @ValidTime, @Active, 1, @SystemUserId, @Now, @ExecutionId)
	END
GO
PRINT '									...									';
--===========================================Auditing============================================================
PRINT '	[Auditing]';
GO
PRINT '									...									';
GO
PRINT '			CREATE PROCEDURE Auditing.ExecutionInsert'
GO
CREATE PROCEDURE Auditing.ExecutionInsert
	(@ParentExecutionId int, @EventName sysname, @SystemUserId int, @ExecutionId int output)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Auditing.Execution
Version:		3 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

INSERT INTO Auditing.Execution
	(ParentExecutionId, EventName, SystemTime, SystemUserId)
VALUES
	(@ParentExecutionId, @EventName, @Now, @SystemUserId)
SELECT @ExecutionId = SCOPE_IDENTITY();

GO
PRINT '			CREATE PROCEDURE Auditing.ExecutionSelect'
GO
CREATE PROCEDURE Auditing.ExecutionSelect
	(@ExecutionId int, @SystemUserId int)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionSelect
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	SELECT on a deterministic set of execution data
Version:		21 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

SELECT	e.ParentExecutionId, e.ExecutionId, e.EventName,
		e.SystemUserId, e.Domain, e.[User], e.ObjectId, e.[Object], e.SystemTime
	FROM Auditing.Executions e
INNER JOIN Security.[User] u
	ON	e.SystemUserId = u.UserId
WHERE		e.ExecutionId = @ExecutionId
	ORDER BY e.ExecutionId DESC, e.SystemTime DESC
GO
CREATE PROCEDURE Auditing.ExecutionDescriptionSelect
	(@ExecutionId int, @SystemUserId int)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionDescriptionSelect
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	SELECT on a deterministic set of execution description data
Version:		21 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

SELECT	e.ParentExecutionId, e.ExecutionId, e.EventName,
		e.SystemUserId, e.Domain, e.[User], e.ObjectId, e.[Object ], e.SystemTime,
		ed.[Value] AS 'ExecutionDescription', ed.SystemTime AS 'DescriptionSystemTime',
		ed.SystemUserId AS 'DescriptionSystemUserId'
	FROM Auditing.Executions e
INNER JOIN Auditing.ExecutionDescription ed
	ON	e.ExecutionId = ed.ExecutionId
INNER JOIN Security.[User] u
	ON	e.SystemUserId = u.UserId
ORDER BY e.ExecutionId DESC, e.SystemTime DESC, ed.SystemTime DESC
GO
CREATE PROCEDURE Auditing.ExecutionErrorSelect
	(@ExecutionId int, @SystemUserId int)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionErrorSelect
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	SELECT on a deterministic set of execution data
Version:		21 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

SELECT	e.ParentExecutionId, e.ExecutionId, e.EventName,
		e.SystemUserId, e.Domain, e.[User], e.ObjectId, e.[Object ], e.SystemTime,
		er.[Value] AS 'ExecutionDescription', er.SystemTime AS 'DescriptionSystemTime',
		er.SystemUserId AS 'DescriptionSystemUserId'
	FROM Auditing.Executions e
INNER JOIN Auditing.ExecutionError er
	ON	e.ExecutionId = er.ExecutionId
INNER JOIN Security.[User] u
	ON	e.SystemUserId = u.UserId
ORDER BY e.ExecutionId DESC, e.SystemTime DESC, er.SystemTime DESC
GO
CREATE PROCEDURE Auditing.ExecutionStatusSelect
	(@ExecutionId int, @SystemUserId int)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionStatusSelect
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	SELECT on a deterministic set of execution data
Version:		21 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

SELECT	e.ParentExecutionId, e.ExecutionId, e.EventName,
		e.SystemUserId, e.Domain, e.[User], e.ObjectId, e.[Object ], e.SystemTime,
		s.[Value] AS 'ExecutionStatus', es.SystemTime AS 'StatusSystemTime',
		es.SystemUserId AS 'StatusSystemUserId'
	FROM Auditing.Executions e
INNER JOIN Auditing.ExecutionStatus es
	ON	e.ExecutionId = es.ExecutionId
INNER JOIN Configuration.[Status] s
	ON	es.StatusId = s.StatusId
INNER JOIN Security.[User] u
	ON	e.SystemUserId = u.UserId
ORDER BY e.ExecutionId DESC, e.SystemTime DESC, es.SystemTime DESC
GO
PRINT '			CREATE PROCEDURE Auditing.ExecutionDescriptionInsert'
GO
CREATE PROCEDURE Auditing.ExecutionDescriptionInsert
	(@ExecutionId int, @Description nvarchar(max), @SystemUserId int)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionDescriptionInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Auditing.ExecutionDescription
Version:		16 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
				FROM Auditing.ExecutionDescription
			WHERE	ExecutionId = @ExecutionId)
	BEGIN
	INSERT INTO	Auditing.ExecutionDescription
		(ExecutionId, [Value], SystemTime, SystemUserId)
	VALUES
		(@ExecutionId, @Description, @Now, @SystemUserId)
	END
GO
PRINT '			CREATE PROCEDURE Auditing.ExecutionErrorInsert'
GO
CREATE PROCEDURE Auditing.ExecutionErrorInsert
	(@ExecutionId int, @ErrorDescription nvarchar(max), @SystemUserId int)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionErrorInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Auditing.ExecutionError
Version:		16 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
				FROM Auditing.ExecutionError
			WHERE	ExecutionId = @ExecutionId)
	BEGIN
	INSERT INTO	Auditing.ExecutionError
		(ExecutionId, [Value], SystemTime, SystemUserId)
	VALUES
		(@ExecutionId, @ErrorDescription, @Now, @SystemUserId)
	END
GO
PRINT '			CREATE PROCEDURE Auditing.ExecutionStatusInsert'
GO
CREATE PROCEDURE Auditing.ExecutionStatusInsert
	(@ExecutionId int, @StatusId tinyint, @SystemUserId int)
AS
/**********************************************************************************************************************
Object:			Auditing.ExecutionStatusInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Auditing.ExecutionStatus
Version:		16 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
				FROM Auditing.ExecutionStatus
			WHERE	ExecutionId = @ExecutionId)
	BEGIN
	INSERT INTO	Auditing.ExecutionStatus
		(ExecutionId, StatusId, SystemTime, SystemUserId)
	VALUES
		(@ExecutionId, @StatusId, @Now, @SystemUserId)
	END
GO
--===========================================Configuration=======================================================
PRINT '	[Configuration]';
GO
PRINT '			CREATE PROCEDURE Configuration.NameInsert'
GO
CREATE PROCEDURE Configuration.NameInsert
	(@Name sysname, @SystemUserId int, @ExecutionId int, @NameId int output)
AS
/**********************************************************************************************************************
Object:			Configuration.NameInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Configuration.Name simply returns the NameId if it already exists.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
				FROM Configuration.[Name]
			WHERE		[Value] = @Name)
	BEGIN
	INSERT INTO Configuration.[Name]
		([Value], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@Name, @SystemUserId, @Now, @ExecutionId)
	SELECT @NameId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT @NameId = NameId
		FROM Configuration.[Name]
	WHERE		[Value] = @Name
	END;
GO
PRINT '			CREATE PROCEDURE Configuration.ObjectInsert'
GO
CREATE PROCEDURE Configuration.ObjectInsert
	(@ParentObjectId int, @NameId int, @ObjectTypeId tinyint, @SystemUserId int, @ExecutionId int, @ObjectId int output)
AS
/**********************************************************************************************************************
Object:			Configuration.ObjectInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Configuration.Object or simply returns the ObjectId if it already exists.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
				FROM Configuration.[Object]
			WHERE		ParentObjectId = @ParentObjectId
					AND	NameId = @NameId)
	BEGIN
	INSERT INTO Configuration.[Object]
		(ParentObjectId, NameId, ObjectTypeId, SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@ParentObjectId, @NameId, @ObjectTypeId, @SystemUserId, @Now, @ExecutionId)
	SELECT @ObjectId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @ObjectId = ObjectId
		FROM Configuration.[Object]
	WHERE		ParentObjectId = @ParentObjectId
			AND	NameId = @NameId
	END;
GO
PRINT '			CREATE PROCEDURE Configuration.ObjectCreate'
GO
CREATE PROCEDURE Configuration.ObjectCreate
	(@ParentObjectId int, @Object sysname, @ObjectTypeId tinyint,
	@SystemUserId int, @ExecutionId int, @ObjectId int output)
AS
/**********************************************************************************************************************
Object:			Configuration.ObjectCreate
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Configuration.Name and Configuration.Object or 
				returns the ObjectId if it already exists.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
DECLARE @NameId int;

EXEC Configuration.NameInsert @Object, @SystemUserId, @ExecutionId, @NameId output;

EXEC Configuration.ObjectInsert @ParentObjectId, @NameId, @ObjectTypeId, @SystemUserId, @ExecutionId, @ObjectId output;
GO
PRINT '									...									';
GO
PRINT '			CREATE PROCEDURE Configuration.ObjectTypeInsert'
GO
CREATE PROCEDURE Configuration.ObjectTypeInsert
	(@Code char(2), @ObjectType sysname, @Description Description256, @ExecutionId int, @ObjectTypeId tinyint output)
AS
/**********************************************************************************************************************
Object:			Configuration.ObjectTypeInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Configuration.ObjectType or simply returns the ObjectTypeId if it already exists.
Version:		16 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
				FROM Configuration.ObjectType
			WHERE	[Name] = @ObjectType)
	BEGIN
	INSERT INTO Configuration.ObjectType
		([Code], [Name], [Description], SystemTime, ExecutionId)
	VALUES
		(@Code, @ObjectType, @Description, @Now, @ExecutionId)
	SELECT @ObjectTypeId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT @ObjectTypeId = ObjectTypeId
		FROM Configuration.ObjectType
	WHERE	[Name] = @ObjectType
	END;
GO
PRINT '			CREATE PROCEDURE Configuration.ObjectStatusInsert'
GO
CREATE PROCEDURE Configuration.StatusInsert
	(@Status sysname, @SystemUserId int, @ExecutionId int, @StatusId tinyint output)
AS
/**********************************************************************************************************************
Object:			Configuration.StatusInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Inserts a new record in Configuration.Status or simply returns the StatusId if it already exists.
Version:		19 August, 2021 CE
**********************************************************************************************************************/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
				FROM Configuration.[Status]
			WHERE	[Value] = @Status)
	BEGIN
	INSERT INTO Configuration.[Status]
		([Value], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@Status, @SystemUserId, @Now, @ExecutionId)
	SELECT @StatusId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT @StatusId = StatusId
		FROM Configuration.[Status]
	WHERE	[Value] = @Status
	END;
GO
--===========================================Geographic===============================================================
PRINT '	[Geographic]';
GO
PRINT '			CREATE PROCEDURE Geographic.[Name]'
GO
CREATE PROCEDURE Geographic.NameInsert
	(@Name Name64, @SystemUserId int, @ExecutionId int, @NameId int output)
AS
/**********************************************************************************************************************
Object:			Geographic.NameInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Geographic.NameInsert or simply returns the NameId if it already exists.
Version:		16 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Geographic.[Name]
				WHERE	[Value] = @Name)
	BEGIN
	INSERT INTO Geographic.[Name]
		([Value], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@Name, @SystemUserId, @Now, @ExecutionId)
	SELECT @NameId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @NameId = NameId
		FROM Geographic.[Name]
	WHERE	[Value] = @Name;
	END;
GO
CREATE PROCEDURE Geographic.PlaceInsert
	(@ParentPlaceId int, @NameId int, @AbbreviationNameId int, @SystemUserId int, @ExecutionId int, @PlaceId int output)
AS
/**********************************************************************************************************************
Object:			Individual.PlaceInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Individual.Place or simply returns the PlaceId if it already exists.
Version:		16 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Geographic.Place
				WHERE		ParentPlaceId = @ParentPlaceId
						AND	NameId = @NameId)
	BEGIN
	INSERT INTO Geographic.Place
		(ParentPlaceId, NameId, AbbreviationNameId, SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@ParentPlaceId, @NameId, @AbbreviationNameId, @SystemUserId, @Now, @ExecutionId)
	SELECT @PlaceId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @PlaceId = PlaceId
		FROM Geographic.Place
	WHERE		ParentPlaceId = @ParentPlaceId
			AND	NameId = @NameId;
	END;
GO
PRINT '									...									';
GO
--===========================================Individual===============================================================
PRINT '	[Individual]';
GO
PRINT '			CREATE PROCEDURE Person.NameCategoryInsert'
GO
CREATE PROCEDURE Person.NameCategoryInsert
	(@NameCategory Name32, @SystemUserId int, @ExecutionId int, @NameCategoryId tinyint output)
AS
/**********************************************************************************************************************
Object:			Person.NameCategoryInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Person.NameCategory or simply returns the NameCategoryId if it already exists.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime = GETDATE();

IF NOT EXISTS(SELECT 1
			FROM Person.NameCategory
		WHERE	[Value] = @NameCategory)
	BEGIN
	INSERT INTO Person.NameCategory
		([Value], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@NameCategory, @SystemUserId, @Now, @ExecutionId)
	SELECT @NameCategoryId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT	@NameCategoryId = NameCategoryId
		FROM Person.NameCategory
	WHERE	[Value] = @NameCategory
	END
GO
PRINT '			CREATE PROCEDURE Individual.NameElementInsert'
GO
CREATE PROCEDURE Person.NameElementInsert
	(@NameElement Name64, @SystemUserId int, @ExecutionId int, @NameElementId tinyint output)
AS
/**********************************************************************************************************************
Object:			Person.NameElementInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Individual.NameElement or simply returns the NameElementId if it already exists.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
			FROM Person.NameElement
		WHERE	[Value] = @NameElement)
	BEGIN
	INSERT INTO Person.NameElement
		([Value], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@NameElement, @SystemUserId, @Now, @ExecutionId)
	SELECT @NameElementId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT	@NameElementId = NameElementId
		FROM Person.NameElement
	WHERE	[Value] = @NameElement
	END
GO
PRINT '			CREATE PROCEDURE Individual.PersonInsert'
GO
CREATE PROCEDURE Person.IndividualInsert
	(@NameHASH varbinary(32), @SystemUserId int, @ExecutionId int,  @IndividualId int output)
AS
/**********************************************************************************************************************
Object:			Person.IndividualInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Person.Individual or simply returns the IndividualId if it already exists.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
			FROM Person.Individual
		WHERE	HashName = @NameHASH)
	BEGIN
	INSERT INTO Person.Individual
		(HashName, SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@NameHASH, @SystemUserId, @Now, @ExecutionId)
	SELECT @IndividualId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT	@IndividualId = IndividualId
		FROM Person.Individual
	WHERE	HashName = @NameHASH
	END
GO
PRINT '									...									';
PRINT '			CREATE PROCEDURE Individual.PersonNameElementInsert'
GO
CREATE PROCEDURE Person.IndividualNameElementInsert
	(@IndividualId int, @NameElementId int, @NameCategoryId tinyint,
	@SortOrder tinyint, @Active bit = 1, @SystemUserId int, @ExecutionId int)
AS
/**********************************************************************************************************************
Object:			Person.IndividualNameElementInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Person.IndividualNameElement.
Version:		3 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/

DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
			FROM Person.IndividualNameElement
		WHERE		IndividualId = IndividualId
				AND	NameElementId = @NameElementId
				AND	NameCategoryId = @NameCategoryId
				AND	SortOrder = @SortOrder
				AND	Active = @Active
				AND	[Current] = 1)
	BEGIN
	INSERT INTO	Person.IndividualNameElement
		(IndividualId, NameElementId, NameCategoryId, SortOrder, Active, [Current], SystemUserId, ExecutionId, SystemTime)
	VALUES
		(@IndividualId, @NameElementId, @NameCategoryId, @SortOrder, @Active, 1, @SystemUserId, @ExecutionId, @Now)
	END;
GO
PRINT '			CREATE PROCEDURE Person.IndividualCreate'
GO
CREATE PROCEDURE Person.IndividualCreate
	(@Names dbo.PersonNames READONLY, @NameCategoryId tinyint,
	@Domain nvarchar(253), @UserName sysname, 
	@SystemUserId smallint, @Active bit, @UserId smallint output, @ExecutionId int, @IndividualId int output)
AS
/**********************************************************************************************************************
Object:			Person.IndividualCreate
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Person.Individual or 
				simply returns the PersonId if it already exists.
				Conditionally inserts a new record in Security.User or
				simply returns the UserId if it already exists.
				Wraps the creation of a person as a user,
				using the HASH of the person's name elements and the username.
Version:		9 August, 2021 CE
**********************************************************************************************************************/
--==================================DEBUG=============================================================================

--DECLARE @Names dbo.PersonNames, @NameCategoryId tinyint, @Domain nvarchar(253)
--DECLARE @UserName sysname, @SystemUserId smallint, @Active bit, @UserId int, @PersonId int
--SET @NameCategoryId = 1;
--SET @Domain = 'RelationalModels.com'
--SET @UserName = 'michelle'
--SET @SystemUserId = 1
--SET @Active = 1
--INSERT INTO @Names (PersonId, NameElement) VALUES (NULL, 'Michelle')
--INSERT INTO @Names (PersonId, NameElement) VALUES (NULL, 'Lynn')
--INSERT INTO @Names (PersonId, NameElement) VALUES (NULL, 'Allen')
--EXEC Person.IndividualCreate @Names, @NameCategoryId, @Domain, @UserName, @SystemUserId, 1, @UserId output, @PersonId output
--SELECT @UserId
--SELECT @PersonId

--SELECT * FROM Person.IndividualsNames(1, ' ')

--====================================DEBUG===========================================================================
DECLARE @Now datetime = GETDATE();
DECLARE @DomainId tinyint, @Binary32HASH varbinary(32), @StringHASH nvarchar(max);
DECLARE @Count tinyint, @Row tinyint, @NameElement Name64, @NameElementId int;

EXEC Security.DomainInsert @Domain, @SystemUserId, @ExecutionId, @DomainId output;
EXEC Security.UserCreate @DomainId, @UserName, @Active, @SystemUserId, @ExecutionId, @UserId output

SELECT @Count = COUNT(1) FROM @Names;
SET @Row = 1;
SELECT @StringHASH = COALESCE(@StringHASH, '') + NameElement
	FROM @Names
GROUP BY [id], NameElement
	ORDER BY [id];

SELECT @StringHASH = @StringHASH + @Domain + @UserName;
SELECT @Binary32HASH = HASHBYTES('SHA2_256',CONVERT(nvarchar(256), @StringHASH));
EXEC Person.IndividualInsert @Binary32HASH, @SystemUserId, @ExecutionId, @IndividualId output;

WHILE @Count >= @Row
	BEGIN
	SELECT	@NameElement = NameElement
		FROM @Names
	WHERE	[id] = @Row;
	EXEC Person.NameElementInsert @NameElement, @SystemUserId, @ExecutionId, @NameElementId output;
	EXEC Person.IndividualNameElementInsert @IndividualId, @NameElementId, @NameCategoryId, @Row, @Active, @SystemUserId, @ExecutionId

	SELECT @Row = @Row + 1;
	END;
GO
PRINT '			CREATE PROCEDURE Person.IndividualSelect'
GO
CREATE PROCEDURE Person.IndividualSelect
	(@IndividualId int, @NameCategoryId tinyint, @NameDelimiter char(1) = ' ', @SystemUserId int, @Name nvarchar(max) output)
AS
/**********************************************************************************************************************
Object:			Person.IndividualSelect
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Returns the record of an individual person as a delimited string of name elements.
Version:		4 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
SELECT	@Name = COALESCE(@Name + @NameDelimiter, '') + ne.[Value]
--SELECT ne.[Value], pne.PersonId
	FROM Person.IndividualNameElement pne
INNER JOIN Person.NameElement ne
	ON	pne.NameElementId = ne.NameElementId
WHERE		pne.NameCategoryId = @NameCategoryId
		AND	pne.IndividualId = @IndividualId
GROUP BY ne.[Value], [SortOrder]
	ORDER BY [SortOrder]
GO
--===========================================Organization===============================================================
PRINT '	[Organization]';
GO
PRINT '			CREATE PROCEDURE Institution.LevelInsert'
GO
CREATE PROCEDURE Institution.LevelInsert
	(@Level Name64, @SystemUserId smallint, @ExecutionId int, @LevelId tinyint output)
AS
/*********************************************************************************************************************
Object:			Insitution.LevelInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Institution.Level and returns the OrganizatioId 
				or simply returns the LevelId if the record already exists.
Version:		4 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
				FROM Institution.[Level]
			WHERE		[Name] = @Level)
	BEGIN
	INSERT INTO Institution.[Level]
		([Name], SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@Level, @SystemUserId, @Now, @ExecutionId)
	SELECT @LevelId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT @LevelId = LevelId
		FROM Institution.[Level]
	WHERE	[Name] = @Level	
	END
GO
PRINT '			CREATE PROCEDURE Institution.NameInsert'
GO
CREATE PROCEDURE Institution.NameInsert
	(@Name Name64, @SystemUserId smallint, @ExecutionId int, @NameId tinyint output)
AS
/*********************************************************************************************************************
Object:			Insitution.NameInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Institution.Name and returns the OrganizatioId 
				or simply returns the NameId if the record already exists.
Version:		4 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
				FROM Institution.[Name]
			WHERE		[Value] = @Name)
	BEGIN
	INSERT INTO Institution.[Name]
		([Value], SystemUserId, SystemTime)
	VALUES
		(@Name, @SystemUserId, @Now)
	SELECT @NameId = SCOPE_IDENTITY()
	END
ELSE
	BEGIN
	SELECT @NameId = NameId
		FROM Institution.[Name]
	WHERE	[Value] = @Name
	END
GO
PRINT '			CREATE PROCEDURE Institution.OrganizationInsert'
GO
CREATE PROCEDURE Institution.OrganizationInsert
	(@ParentOrganizationId int = NULL, @NameId int, @LevelId tinyint,
	@Active bit = 1, @SystemUserId smallint = NULL, @ExecutionId int, @OrganizationId int output)
AS
/*********************************************************************************************************************
Object:			Insitution.OrganizationInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Institution.Organization and returns the OrganizatioId 
				or simply returns the OrganizationId if the record already exists.
Version:		4 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime

SELECT @Now = GETDATE()

IF NOT EXISTS(SELECT 1
				FROM Institution.Organization
			WHERE		ParentOrganizationId = ISNULL(@ParentOrganizationId, ParentOrganizationId)
					AND	NameId = @NameId)
	BEGIN
	INSERT INTO Institution.Organization
		(ParentOrganizationId, NameId, LevelId, Active, SystemUserId, SystemTime, ExecutionId)
	VALUES
		(@ParentOrganizationId, @NameId, @LevelId, @Active, @SystemUserId, @Now, @ExecutionId)
	SELECT @OrganizationId = @@IDENTITY
	END
ELSE
	BEGIN
	SELECT @OrganizationId = OrganizationId
		FROM Institution.Organization
	WHERE		ParentOrganizationId = ISNULL(@ParentOrganizationId, OrganizationId)
			AND	NameId = @NameId
	END
GO
PRINT '			CREATE PROCEDURE Institution.OrganizationCreate'
GO
CREATE PROCEDURE Institution.OrganizationCreate
	(@ParentOrganizationId int, @Organization Name64, @LevelId tinyint, @Active bit, @SystemUserId smallint, @ExecutionId int, @OrganizationId int output)
AS
/*********************************************************************************************************************
Object:			Insitution.OrganizationCreate
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Institution.Name and Institution.Organization 
				and returns the OrganizatioId
				or simply returns the OrganizationId if the record already exists.
Version:		4 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @NameId int;

EXEC Institution.NameInsert @Organization, @SystemUserId, @ExecutionId, @NameId output;
--@ParentOrganizationId int = NULL, @NameId int, @LevelId tinyint, @Active bit = 1, @SystemUserId smallint = NULL, @OrganizationId int output)
EXEC Institution.OrganizationInsert @ParentOrganizationId, @NameId, @LevelId, @Active, @SystemUserId, @ExecutionId, @OrganizationId output;
GO
PRINT '									...									';
GO
--===========================================Postal===============================================================
PRINT '	[Postal]';
GO
PRINT '			CREATE PROCEDURE Postal.CodeInsert'
GO
CREATE PROCEDURE Postal.CodeInsert
	(@CodeId int, @CountryPlaceId int, @Code Name16, @SystemUserId int, @ExecutionId int, @IdentityCodeId int output)
AS
/*********************************************************************************************************************
Object:			Postal.CodeInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Postal.Code
				and returns the CodeId or simply returns the 
				CodeId if the record already exists.
Version			19 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/

DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Postal.[Code]
				WHERE		PlaceId = @CountryPlaceId
						AND	[Value] = @Code)
	BEGIN
	IF @CodeId IS NULL
		BEGIN
		INSERT INTO Postal.[Code]
			(PlaceId, [Value], SystemUserId, SystemTime)
		VALUES
			(@CountryPlaceId, @Code, @SystemUserId, @Now)
		SELECT @IdentityCodeId = SCOPE_IDENTITY();
		END
	ELSE
		BEGIN
		SET IDENTITY_INSERT Postal.[Code] ON;
		INSERT INTO Postal.[Code]
			(CodeId, PlaceId, [Value], SystemUserId, SystemTime)
		VALUES
			(@CodeId, @CountryPlaceId, @Code, @SystemUserId, @Now)
		SELECT @IdentityCodeId = @CodeId;
		SET IDENTITY_INSERT Postal.[Code] OFF;
		END
	END
ELSE
	BEGIN
	SELECT @IdentityCodeId = CodeId
		FROM Postal.[Code]
	WHERE		PlaceId = @CountryPlaceId
			AND	[Value] = @Code;
	END;
GO
PRINT '			CREATE PROCEDURE Postal.DeliveryLineInsert'
GO
CREATE PROCEDURE Postal.DeliveryLineInsert
	(@DeliveryLine Name64, @SystemUserId int, @DeliveryLineId int output)
AS
/*********************************************************************************************************************
Object:			Postal.DeliveryLineInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Postal.DeliveryLine
				and returns the DeliveryLineId or simply returns the 
				DeliveryLineId if the record already exists.
Version:		19 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Postal.DeliveryLine
				WHERE	[Value] = @DeliveryLine)
	BEGIN
	INSERT INTO Postal.DeliveryLine
		([Value], SystemUserId, SystemTime)
	VALUES
		(@DeliveryLine, @SystemUserId, @Now)
	SELECT	@DeliveryLineId = SCOPE_IDENTITY();
	END;
ELSE
	BEGIN
	SELECT @DeliveryLineId = DeliveryLineId
		FROM Postal.DeliveryLine
	WHERE	[Value] = @DeliveryLine
	END;
GO
PRINT '									...									';
GO
PRINT '			CREATE PROCEDURE Postal.AddressInsert'
GO
CREATE PROCEDURE Postal.AddressInsert
	(@PlaceId int, @CodeId int, @HashAddress varbinary(32), @SytemUserId int, @AddressId int output)
AS
/*********************************************************************************************************************
Object:			Postal.AddressInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Postal.Address
				and returns the AddressId or simply returns the 
				AddressId if the record already exists.
Version:		19 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Postal.[Address]
				WHERE		HashAddress = @HashAddress)
	BEGIN
	INSERT INTO Postal.[Address]
		(PlaceId, CodeId, HashAddress, SystemUserId, SystemTime)
	VALUES
		(@PlaceId, @CodeId, @HashAddress, @SytemUserId, @Now)
	SELECT @AddressId = SCOPE_IDENTITY();
	END;
ELSE
	BEGIN
	SELECT @AddressId = AddressId
		FROM Postal.[Address]
	WHERE		HashAddress = @HashAddress
	END;
GO
PRINT '			CREATE PROCEDURE Postal.AddressDeliveryLineInsert'
GO
CREATE PROCEDURE Postal.AddressDeliveryLineInsert
	(@AddressId int, @DeliveryLineId int, @ValidTime smalldatetime, @Active bit, @SystemUserId int)
AS
/*********************************************************************************************************************
Object:			Postal.AddressDelieryLineInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Postal.AddressDelieryLine
				if the address does not exist
Version:		19 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Postal.AddressDeliveryLine
				WHERE		AddressId = @AddressId
						AND	DeliveryLineId = @DeliveryLineId
						AND	ValidTime = @ValidTime
						AND	Active = @Active
						AND	[Current] = 1)
	BEGIN
	INSERT INTO Postal.AddressDeliveryLine
		(AddressId, DeliveryLineId, ValidTime, Active, [Current], SystemUserId, SystemTime)
	VALUES
		(@AddressId, @DeliveryLineId, @ValidTime, @Active, 1, @SystemUserId, @Now)
	END;
GO
--===========================================Telecom===============================================================
PRINT '	[Telecom]';
GO
CREATE PROCEDURE Telecom.LabelInsert
	(@Label varchar(63), @LabelId int output)
AS
/*********************************************************************************************************************
Object:			Telecom.LabelInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.Label
				if the address does not exist
Version:		21 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.[Label]
				WHERE	[Value] = @Label)
	BEGIN
	INSERT INTO Telecom.[Label]
		([Value], SystemTime)
	VALUES
		(@Label, @Now)
	SELECT @LabelId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @LabelId = LabelId
		FROM Telecom.[Label]
	WHERE	[Value] = @Label
	END;
GO
PRINT '			CREATE PROCEDURE Telecom.PlaceInsert'
GO
CREATE PROCEDURE Telecom.PlaceInsert
	(@PlaceId int, @Code char(3), @SystemUserId int)
AS
/*********************************************************************************************************************
Object:			Telecom.PlaceInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.Place
				if the address does not exist
Version:		20 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.Place
				WHERE	[Code] = @Code)
	BEGIN
	INSERT INTO Telecom.Place
		(PlaceId, [Code], SystemUserId, SystemTime)
	VALUES
		(@PlaceId, @Code, @SystemUserId, @Now)
	END;
GO
PRINT '			CREATE PROCEDURE Telecom.DomainInsert'
GO
CREATE PROCEDURE Telecom.DomainInsert
	(@LabelId int, @TopLevelDomainId smallint, @DomainId int output)
AS
/*********************************************************************************************************************
Object:			Telecom.DomainInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.Domain
				if the address does not exist
Version:		20 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.Domain
				WHERE		LabelId = @LabelId
						AND	TopLevelDomainId = @TopLevelDomainId)
	BEGIN
	INSERT INTO Telecom.Domain
		(LabelId, TopLevelDomainId, SystemTime)
	VALUES
		(@LabelId, @TopLevelDomainId, @Now)
	SELECT @DomainId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT	@DomainId = DomainId
		FROM Telecom.Domain
	WHERE		LabelId = @LabelId
			AND	TopLevelDomainId = @TopLevelDomainId
	END;
GO
PRINT '			CREATE PROCEDURE Telecom.EmailInsert'
GO
CREATE PROCEDURE Telecom.EmailInsert
	(@DomainId int, @LocalPart Name64, @SystemUserId int, @EmailId int output)
AS
/*********************************************************************************************************************
Object:			Telecom.EmailInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.Email
				if the address does not exist
Version:		21 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.Email
				WHERE		DomainId = @DomainId
						AND	LocalPart = @LocalPart)
	BEGIN
	INSERT INTO Telecom.Email
		(DomainId, LocalPart, SystemUserId, SystemTime)
	VALUES
		(@DomainId, @LocalPart, @SystemUserId, @Now)
	END
ELSE
	BEGIN
	SELECT	@EmailId = EmailId
		FROM Telecom.Email
	WHERE		DomainId = @DomainId
			AND	LocalPart = @LocalPart
	END;
GO
CREATE PROCEDURE Telecom.LabelUseInsert
	(@LabelUse varchar(16), @SystemUserId int, @LabelUseId tinyint output)
AS
/*********************************************************************************************************************
Object:			Telecom.LabelUseInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.LabelUse
				if the LabelUse does not exist
Version:		21 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.LabelUse
				WHERE	[Value] = @LabelUse)
	BEGIN
	INSERT INTO Telecom.LabelUse
		([Value], SystemUserId, SystemTime)
	VALUES
		(@LabelUse, @SystemUserId, @Now)
	SELECT @LabelUseId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @LabelUseId = LabelUseId
		FROM Telecom.LabelUse
	WHERE	[Value] = @LabelUse
	END;
GO
CREATE PROCEDURE Telecom.SchemeInsert
	(@Scheme varchar(16), @SystemUserId int, @SchemeId tinyint output)
AS
/*********************************************************************************************************************
Object:			Telecom.SchemeInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.Scheme
				if the LabelUse does not exist
Version:		22 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.Scheme
				WHERE	[Value] = @Scheme)
	BEGIN
	INSERT INTO Telecom.Scheme
		([Value], SystemUserId, SystemTime)
	VALUES
		(@Scheme, @SystemUserId, @Now)
	SELECT @SchemeId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @SchemeId = SchemeId
		FROM Telecom.Scheme
	WHERE	[Value] = @Scheme
	END;
GO
CREATE PROCEDURE Telecom.TopLevelDomainInsert
	(@TopLevelDomain varchar(63), @TopLevelDomainId smallint output)
AS
/*********************************************************************************************************************
Object:			Telecom.TopLevelDomainInsert
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.TopLevelDomain
				if the TopLevelDomain does not exist
Version:		24 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.TopLevelDomain
				WHERE	[Value] = @TopLevelDomain)
	BEGIN
	INSERT INTO Telecom.TopLevelDomain
		([Value], SystemTime)
	VALUES
		(@TopLevelDomain, @Now)
	SELECT @TopLevelDomain = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @TopLevelDomainId = TopLevelDomainId
		FROM Telecom.TopLevelDomain
	WHERE	[Value] = @TopLevelDomain
	END;
GO
PRINT'			CREATE PROCEDURE Telecom.[Url]'
GO
CREATE PROCEDURE Telecom.UrlInsert
	(@UrlHASH varbinary(32), @DomainId int, @SchemeId tinyint, @SystemUserId smallint, @UrlId int output)
AS
/*********************************************************************************************************************
Object:			Telecom.UrlInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.Url
				if the Url does not exist
Version:		25 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.[Url]
				WHERE	UrlHASH = @UrlHASH)
	BEGIN
	INSERT INTO Telecom.[Url]
		(UrlHASH, DomainId, SchemeId, SystemUserId, SystemTime)
	VALUES
		(@UrlHASH, @DomainId, @SchemeId, @SystemUserId, @Now)
	SELECT @UrlId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @UrlId = UrlId
		FROM Telecom.[Url]
	WHERE	UrlHASH = @UrlHASH
	END;
GO
PRINT '			CREATE PROCEDURE Telecom.UrlLabelInsert'
GO
CREATE PROCEDURE Telecom.UrlLabelInsert
	(@UrlId int, @LabelId int, @LabelUseId tinyint, @SortOrder smallint, @ValidTime smalldatetime, @Active bit, @SystemUserId smallint)
AS
/*********************************************************************************************************************
Object:			Telecom.UrlLabelInsert
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Conditionally inserts a new record in Telecom.UrlLabel
Version:		24 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

IF NOT EXISTS(SELECT 1
					FROM Telecom.UrlLabel
				WHERE		UrlId = @UrlId
						AND	LabelId = @LabelId
						AND	LabelUseId = @LabelUseId
						AND	SortOrder = @SortOrder
						AND	Active = @Active
						AND	[Current] = 1)
	BEGIN
	INSERT INTO Telecom.UrlLabel
		(UrlId, LabelId, LabelUseId, SortOrder, Active, [Current], SystemUserId, SystemTime)
	VALUES
		(@UrlId, @LabelId, @LabelUseId, @SortOrder, @Active, 1, @SystemUserId, @Now)
	END
GO
PRINT '			CREATE PROCEDURE Telecom.UrlSelect'
GO
CREATE PROCEDURE Telecom.UrlSelect
	(@UrlId int)
AS
/*********************************************************************************************************************
Object:			Telecom.UrlSelect
Type:			Stored Procedure (CRUD, Layer 0)
Author:			Jay Quincy Allen
Description:	Returns a deterministic result set of Url information
Version:		24 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================

EXEC Telecom.UrlSelect null
SELECT Domain, TopLevelDomain FROM Telecom.Domains GROUP BY Domain, TopLevelDomain ORDER BY Domain, TopLevelDomain
====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

SELECT	turl.UrlId, turl.UrlHASH, turl.DomainId, l.[Value] AS 'Domain', tld.[Value] AS 'TopLevelDomainName', s.[Value] AS 'Scheme',
		turl.SystemUserId, u.DomainId, u.Domain, u.UserId, u.[User]
	FROM Telecom.Url turl
INNER JOIN Telecom.Domain d
	ON	turl.DomainId = d.DomainId
INNER JOIN Telecom.Label l
	ON	d.LabelId = l.LabelId
INNER JOIN Telecom.TopLevelDomain tld
	ON	d.TopLevelDomainId = tld.TopLevelDomainId
INNER JOIN Telecom.Scheme s
	ON	turl.SchemeId = s.SchemeId
INNER JOIN Security.[Users] u
	ON	turl.SystemUserId = u.UserId
INNER JOIN Security.[Name] n
	ON	u.NameId = n.NameId
WHERE	turl.UrlId = ISNULL(@UrlId, turl.UrlId)
GO
CREATE PROCEDURE Telecom.UrlLabelSelect
	(@UrlId int = NULL)
AS
/*********************************************************************************************************************
Object:			Telecom.UrlLabelSelect
Type:			Stored Procedure (CRUD, Layer 1)
Author:			Jay Quincy Allen
Description:	Returns a non-deterministic result set of Url information
Version:		25 August, 2021 CE
**********************************************************************************************************************/
/*==================================DEBUG=============================================================================
select Telecom.UrlLabelCoalesced(3, 2)
EXEC Telecom.UrlLabelSelect 2
SELECT Domain, TopLevelDomain FROM Telecom.Domains GROUP BY Domain, TopLevelDomain ORDER BY Domain, TopLevelDomain
====================================DEBUG============================================================================*/
DECLARE @Now datetime2 = GETDATE();

SELECT	s.[Value] AS 'Scheme', Telecom.UrlLabelCoalesced(turl.UrlId, 2), Telecom.UrlLabelCoalesced(turl.UrlId, 2),
		Telecom.UrlLabelCoalesced(turl.UrlId, 1) + 
		CASE WHEN Telecom.UrlLabelCoalesced(turl.UrlId, 2) IS NULL THEN ''
		ELSE '/' + Telecom.UrlLabelCoalesced(turl.UrlId, 2)
		END
		AS 'Url',
		turl.UrlId, turl.UrlHASH, turl.DomainId, l0.[Value] AS 'Domain', tld.[Value] AS 'TopLevelDomainName',
		turl.SystemUserId, u.DomainId, u.Domain, u.UserId, u.[User]
	FROM Telecom.Url turl
INNER JOIN Telecom.Domain d
	ON	turl.DomainId = d.DomainId
INNER JOIN Telecom.Label l0
	ON	d.LabelId = l0.LabelId
INNER JOIN Telecom.TopLevelDomain tld
	ON	d.TopLevelDomainId = tld.TopLevelDomainId
INNER JOIN Telecom.Scheme s
	ON	turl.SchemeId = s.SchemeId
INNER JOIN Security.[Users] u
	ON	turl.SystemUserId = u.UserId
INNER JOIN Security.[Name] n
	ON	u.NameId = n.NameId
WHERE	turl.UrlId = ISNULL(@UrlId, turl.UrlId)
	GROUP BY	turl.UrlId, turl.UrlHASH, turl.DomainId,
				l0.[Value], tld.[Value], s.[Value], 
				turl.SystemUserId, u.DomainId, u.Domain, 
				u.UserId, u.[User]
ORDER BY turl.UrlId
GO
PRINT '									...									';
GO
PRINT 'STORED PROCEDURES CREATED'
GO
PRINT '			**Auditing**'
BEGIN--AUDITING
DECLARE @Now datetime2, @Difference bigint, @Message nvarchar(max), @ParentExecutionId int;
DECLARE @User sysname, @UserId smallint, @StatusId tinyint, @Domain sysname;

SET @Now = GETDATE();

SELECT	@User = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name])),
		@Domain = LEFT([name], PATINDEX('%\%', [name]) - 1)
	FROM sys.server_principals 
WHERE principal_id = SUSER_ID()

SELECT @UserId = UserId FROM Security.[User] u INNER JOIN Security.[Name] n ON u.NameId = n.NameId WHERE n.[Value] = @User AND DomainId = 1;

SELECT @ParentExecutionId = ExecutionId 
	FROM Auditing.Execution
WHERE		EventName = 'Programmability'
		AND	SystemTime = (SELECT MAX(SystemTime) FROM Auditing.Execution WHERE EventName = 'Programmability')
PRINT ''
PRINT '		...'
PRINT 'TESTING FOR MISSING Programmability (CRUD)...'

IF EXISTS(SELECT 1
				FROM sys.tables t
			LEFT OUTER JOIN sys.procedures p
				ON		SCHEMA_NAME(t.schema_id) = SCHEMA_NAME(p.schema_id)
				AND	t.[Name] = CASE
								WHEN RIGHT(p.[name], 6) = 'Insert' THEN REPLACE(p.[name], 'Insert', '')
								ELSE p.[name]
								END
				OR	t.[name] = CASE
								WHEN RIGHT(p.[name], 6) = 'Select' THEN REPLACE(p.[name], 'Select', '')
								ELSE p.[name]
								END
			INNER JOIN (SELECT t.schema_id, t.[name], COUNT(p.[name]) AS 'Count'
								FROM sys.tables t
							LEFT OUTER JOIN sys.procedures p
								ON		SCHEMA_NAME(t.schema_id) = SCHEMA_NAME(p.schema_id)
									AND	t.[Name] = CASE
													WHEN RIGHT(p.[name], 6) = 'Insert' THEN REPLACE(p.[name], 'Insert', '')
													ELSE p.[name]
													END
									OR	t.[name] = CASE
													WHEN RIGHT(p.[name], 6) = 'Select' THEN REPLACE(p.[name], 'Select', '')
													ELSE p.[name]
													END
							GROUP BY t.schema_id, t.[name]
								HAVING COUNT(p.[name]) <> 2) t0
				ON		t.schema_id = t0.schema_id
					AND	t.[name] = t0.[name]
			GROUP BY t.schema_id, t.[name], p.[name])
	BEGIN
	SELECT @Message = 'Missing CRUD stored procedures';
	SET @StatusId = 4;
	INSERT INTO Auditing.ExecutionStatus
		(ExecutionId, StatusId, SystemUserId, SystemTime)
	VALUES
		(@ParentExecutionId, @StatusId, @UserId, @Now)
	INSERT INTO Auditing.ExecutionDescription
		(ExecutionId, [Value], SystemUserId, SystemTime)
	SELECT @ParentExecutionId, @Message, @UserId, @Now
--Output result set of missing CRUD procedures...
	SELECT SCHEMA_NAME(t.schema_id) AS 'Schema', t.[name] AS 'Table', p.[name] AS 'Procedure'
		FROM sys.tables t
	LEFT OUTER JOIN sys.procedures p
		ON		SCHEMA_NAME(t.schema_id) = SCHEMA_NAME(p.schema_id)
		AND	t.[Name] = CASE
						WHEN RIGHT(p.[name], 6) = 'Insert' THEN REPLACE(p.[name], 'Insert', '')
						ELSE p.[name]
						END
		OR	t.[name] = CASE
						WHEN RIGHT(p.[name], 6) = 'Select' THEN REPLACE(p.[name], 'Select', '')
						ELSE p.[name]
						END
	INNER JOIN (SELECT t.schema_id, t.[name], COUNT(p.[name]) AS 'Count'
					FROM sys.tables t
				LEFT OUTER JOIN sys.procedures p
					ON		SCHEMA_NAME(t.schema_id) = SCHEMA_NAME(p.schema_id)
						AND	t.[Name] = CASE
										WHEN RIGHT(p.[name], 6) = 'Insert' THEN REPLACE(p.[name], 'Insert', '')
										ELSE p.[name]
										END
						OR	t.[name] = CASE
										WHEN RIGHT(p.[name], 6) = 'Select' THEN REPLACE(p.[name], 'Select', '')
										ELSE p.[name]
										END
				GROUP BY t.schema_id, t.[name]
					HAVING COUNT(p.[name]) <> 2) t0
	ON		t.schema_id = t0.schema_id
		AND	t.[name] = t0.[name]
	GROUP BY t.schema_id, t.[name], p.[name]
		ORDER BY SCHEMA_NAME(t.schema_id), t.[name], p.[name]
	END
ELSE
	BEGIN
	SET @StatusId = 5;
	PRINT '';
	PRINT '	No missing CRUD stored procedures found.';
	END;

INSERT INTO Auditing.ExecutionStatus
	(ExecutionId, StatusId, SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 5, @UserId, @Now);

PRINT '		...'

UPDATE #Scripts SET EndTime = @Now WHERE [Name] = 'Programmability';

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
PRINT 'Time elapsed: ' + @Message;
PRINT 'SCRIPT END_________________________________________________________________________________';



--SELECT * FROM Configuration.Objects
--SELECT * FROM Auditing.Executions
--SELECT * FROM Auditing.ExecutionDescription
--SELECT * FROM Auditing.ExecutionStatus