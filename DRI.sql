USE RelationalData
GO
SET NOCOUNT ON;
GO
PRINT 'SCRIPT BEGIN_______________________________________________________________________________';
PRINT 'DRI SCRIPTING'
PRINT '___________________________________________________________________________________________';
/************************************************************************************************
*************************************************************************************************
Object:			DRI.sql
Type:			Implementation script
Author:			Jay Quincy Allen
Description:	Drop and create all tables, views.
Version:		1 August, 2021 CE

*************************************************************************************************
***************************** Bill Inmon, What is a data warehouse? *****************************
		"...a subject-oriented, integrated, time-variant and non-volatile collection 
				of data in support of management’s decision making process."
************************************************************************************************/
GO
PRINT 'DROPPING ALL FOREIGN KEY CONSTRAINTS...'
BEGIN TRANSACTION
GO
DECLARE @Now datetime2 = GETDATE();
DECLARE @DatabaseName sysname, @Domain sysname, @DomainId tinyint, @User sysname, @UserId smallint, @LabelId tinyint;
DECLARE @Difference bigint, @Message nvarchar(max), @StartTime datetime2, @ParentExecutionId int;
DROP TABLE IF EXISTS #Scripts;
DECLARE @NameId int, @ObjectId int, @ObjectTypeId tinyint;
PRINT '			**Auditing**'
CREATE TABLE #Scripts (id int IDENTITY(1,1), [Name] sysname, StartTime datetime2, EndTime datetime2, ParentExecutionId int)

INSERT INTO #Scripts
	([Name], StartTime, EndTime)
SELECT 'DRI', @Now, NULL

SELECT @DatabaseName = DB_NAME()

SELECT	@User = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name])),
		@Domain = LEFT([name], PATINDEX('%\%', [name]) - 1)
	FROM sys.server_principals 
WHERE principal_id = SUSER_ID()

SELECT @UserId = UserId
	FROM Security.[Users]
WHERE		[User] = @User
		AND	Domain = @Domain

IF NOT EXISTS(SELECT 1 FROM Configuration.[Name] WHERE [Value] = 'DRI')
	BEGIN
	INSERT INTO Configuration.[Name]
		([Value], SystemUserId, SystemTime)
	VALUES
		('DRI', @UserId, @Now)
	SELECT @NameId = SCOPE_IDENTITY();
	END
ELSE
	BEGIN
	SELECT @NameId = NameId FROM Configuration.[Name] WHERE [Value] = 'DRI'
	END;
IF NOT EXISTS(SELECT 1 FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId)
	BEGIN
	SELECT @ObjectTypeId = ObjectTypeId FROM Configuration.[ObjectType] WHERE [Code] = 'SC'
	INSERT INTO Configuration.[Object]
		(ParentObjectId, NameId, ObjectTypeId, SystemTime, SystemUserId)
	VALUES
		(NULL, @NameId, @ObjectTypeId, @Now, @UserId)
	SELECT @ObjectId = ObjectId FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId;
	END
ELSE
	BEGIN
	SELECT @ObjectId = ObjectId FROM Configuration.[Object] WHERE NameId = @NameId AND ParentObjectId = ObjectId
	END;
INSERT INTO Auditing.Execution
	(ParentExecutionId, ObjectId, EventName, SystemUserId, SystemTime)
VALUES
	(NULL, @ObjectId, 'DRI', @UserId, @Now)
SELECT @ParentExecutionId = ExecutionId 
	FROM Auditing.Execution
WHERE		EventName = 'DRI'
		AND	SystemTime = (SELECT MAX(SystemTime) FROM Auditing.Execution WHERE EventName = 'DRI');

UPDATE #Scripts SET ParentExecutionId = @ParentExecutionId;

INSERT INTO Auditing.ExecutionDescription
	(ExecutionId, [Value], SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 'DRI implementation script execution', @UserId, @Now)
INSERT INTO Auditing.ExecutionStatus
	(ExecutionId, StatusId, SystemUserId, SystemTime)
VALUES
	(@ParentExecutionId, 3, @UserId, @Now)
PRINT '									...									';
GO
COMMIT;
GO
BEGIN
DECLARE @Count int, @Row int, @Schema sysname, @ForeignKey sysname, @Table sysname
DECLARE @SQL nvarchar(max)
DECLARE @ForeignKeys TABLE (id smallint IDENTITY(1,1), SchemaName sysname, TableName sysname, ForeignKey sysname)

INSERT INTO @ForeignKeys
	(SchemaName, TableName, ForeignKey)
SELECT	SCHEMA_NAME(schema_id), OBJECT_NAME(parent_object_id), [name]
	FROM sys.foreign_keys
SELECT @Count = @@ROWCOUNT
SET @Row = 1
WHILE @Count >= @Row
	BEGIN
	SELECT	@ForeignKey = ForeignKey,
			@Table = TableName,
			@Schema = SchemaName
		FROM @ForeignKeys
	WHERE ID = @Row
	SELECT @SQL = '
ALTER TABLE [' + @Schema + '].[' + @Table + '] DROP CONSTRAINT IF EXISTS [' + @ForeignKey + ']
'
--	PRINT @SQL
	EXEC (@SQL)
	SELECT @Row = @Row + 1
	END
END;
PRINT '_____________________________________________________________________________________';
PRINT 'CREATING DECLARATIVE REFERENTIAL INTEGRITY...';
GO
PRINT '	FOREIGN KEY CONSTRAINTS...';
GO
BEGIN TRANSACTION;
GO
PRINT '		Auditing...'
BEGIN TRANSACTION
GO
ALTER TABLE Auditing.Execution
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecution_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Auditing.Execution
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecution_Execution]
	FOREIGN KEY(ParentExecutionId)
REFERENCES Auditing.Execution (ExecutionId)
GO
ALTER TABLE Auditing.Execution
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecution_ConfigurationObject]
	FOREIGN KEY(ObjectId)
REFERENCES Configuration.[Object] (ObjectId)
GO
ALTER TABLE Auditing.ExecutionDescription
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecutionDescription_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Auditing.ExecutionDescription
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecutionDescription_AuditingExecution]
	FOREIGN KEY(ExecutionId)
REFERENCES Auditing.Execution (ExecutionId)
GO
ALTER TABLE Auditing.ExecutionStatus
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecutionStatus_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Auditing.ExecutionStatus
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecutionStatus_ConfigurationStatus]
	FOREIGN KEY(StatusId)
REFERENCES Configuration.[Status] (StatusId)
GO
ALTER TABLE Auditing.ExecutionStatus
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecutionStatus_AuditingExecution]
	FOREIGN KEY(ExecutionId)
REFERENCES Auditing.Execution (ExecutionId)
GO
ALTER TABLE Auditing.ExecutionError
	WITH CHECK 
ADD CONSTRAINT [FK_AuditingExecutionError_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Auditing.ExecutionError
	WITH CHECK
ADD CONSTRAINT [FK_AuditingExecutionError_AuditingExecution]
	FOREIGN KEY(ExecutionId)
REFERENCES Auditing.Execution (ExecutionId)
GO
COMMIT;
PRINT '		Configuration...'
BEGIN TRANSACTION
GO
ALTER TABLE Configuration.[Object]
	WITH CHECK 
ADD CONSTRAINT [FK_ConfigurationObject_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
ALTER TABLE Configuration.[Object]
	WITH CHECK 
ADD CONSTRAINT [FK_ConfigurationObject_ConfigurationObject]
	FOREIGN KEY(ParentObjectId)
REFERENCES Configuration.[Object] (ObjectId)
GO
ALTER TABLE Configuration.[Object]
	WITH CHECK 
ADD CONSTRAINT [FK_ConfigurationObject_ConfigurationName]
	FOREIGN KEY(NameId)
REFERENCES Configuration.[Name] (NameId)
GO
ALTER TABLE Configuration.[Object]
	WITH CHECK 
ADD CONSTRAINT [FK_ConfigurationObject_ConfigurationObjectType]
	FOREIGN KEY(ObjectTypeId)
REFERENCES Configuration.ObjectType (ObjectTypeId)
GO
ALTER TABLE Configuration.[Name]
	WITH CHECK 
ADD CONSTRAINT [FK_ConfigurationName_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
ALTER TABLE Configuration.[Status]
	WITH CHECK 
ADD CONSTRAINT [FK_ConfigurationStatus_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO

COMMIT;
GO
PRINT '		Geographic...'
BEGIN TRANSACTION
GO
ALTER TABLE Geographic.Place
	WITH CHECK
ADD CONSTRAINT [FK_GeographicPlace_Place]
	FOREIGN KEY(ParentPlaceId)
REFERENCES Geographic.Place(PlaceId)
GO
ALTER TABLE Geographic.Place
	WITH CHECK
ADD CONSTRAINT [FK_GeographicPlace_GeographicName_0]
	FOREIGN KEY(NameId)
REFERENCES Geographic.Name(NameId)
GO
ALTER TABLE Geographic.Place
	WITH CHECK
ADD CONSTRAINT [FK_GeographicPlace_GeographicName_1]
	FOREIGN KEY(AbbreviationNameId)
REFERENCES Geographic.Name(NameId)
GO
ALTER TABLE Geographic.Place
	WITH CHECK
ADD CONSTRAINT [FK_GeographicPlace_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User](UserId)
GO
ALTER TABLE Geographic.[Name]
	WITH CHECK
ADD CONSTRAINT [FK_GeographicName_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User](UserId)
GO
COMMIT;
GO
PRINT '		Person...'
BEGIN TRANSACTION
GO
ALTER TABLE Person.NameCategory
	WITH CHECK 
ADD CONSTRAINT [FK_PersonNameCategory_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Person.NameElement
	WITH CHECK 
ADD CONSTRAINT [FK_PersonNameElement_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Person.Individual
	WITH CHECK 
ADD CONSTRAINT [FK_PersonIndividual_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Person.IndividualNameElement
	WITH CHECK 
ADD CONSTRAINT [FK_PersonIndividualNameElement_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Person.IndividualNameElement
	WITH CHECK 
ADD CONSTRAINT [FK_PersonIndividualNameElement_Person]
	FOREIGN KEY(IndividualId)
REFERENCES Person.Individual (IndividualId)
GO
ALTER TABLE Person.IndividualNameElement
	WITH CHECK 
ADD CONSTRAINT [FK_PersonIndividualNameElement_NameElement]
	FOREIGN KEY(NameElementId)
REFERENCES Person.NameElement (NameElementId)
GO
ALTER TABLE Person.IndividualNameElement
	WITH CHECK 
ADD CONSTRAINT [FK_PersonIndividualNameElement_NameCategory]
	FOREIGN KEY(NameCategoryId)
REFERENCES Person.NameCategory (NameCategoryId)
GO
COMMIT;
GO
PRINT '		Institution...'
BEGIN TRANSACTION
GO
ALTER TABLE Institution.[Level]
	WITH CHECK 
ADD CONSTRAINT [FK_InstitutionLevel_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Institution.[Name]
	WITH CHECK 
ADD CONSTRAINT [FK_InstitutionName_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Institution.Organization
	WITH CHECK 
ADD CONSTRAINT [FK_InstitutionOrganization_InstitutionName]
	FOREIGN KEY(NameId)
REFERENCES Institution.[Name] (NameId)
GO
--There are only two hard things in Computer Science: cache invalidation and naming things.
-- Phil Karlton, https://www.karlton.org/
ALTER TABLE Institution.Organization
	WITH CHECK 
ADD CONSTRAINT [FK_InstitutionOrganiation_InstitutionOrganization]
	FOREIGN KEY(ParentOrganizationId)
REFERENCES Institution.Organization (OrganizationId)
GO
--There are only two hard things in Computer Science: cache invalidation and naming things.
-- Phil Karlton, https://www.karlton.org/
ALTER TABLE Institution.Organization
	WITH CHECK 
ADD CONSTRAINT [FK_InstitutionOrganiation_InstitutionLevel]
	FOREIGN KEY(LevelId)
REFERENCES Institution.Level (LevelId)
GO
--There are only two hard things in Computer Science: cache invalidation and naming things.
-- Phil Karlton, https://www.karlton.org/
ALTER TABLE Institution.Organization
	WITH CHECK
ADD CONSTRAINT [FK_InstitutionOrganization_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
COMMIT;
GO
PRINT '		Postal...'
BEGIN TRANSACTION
GO
ALTER TABLE Postal.[Address]
	WITH CHECK 
ADD CONSTRAINT [FK_PostalAddress_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Postal.[Address]
	WITH CHECK 
ADD CONSTRAINT [FK_PostalAddress_GeographicPlace]
	FOREIGN KEY(PlaceId)
REFERENCES Geographic.Place (PlaceId)
GO
ALTER TABLE Postal.[Address]
	WITH CHECK 
ADD CONSTRAINT [FK_PostalAddress_PostalCode]
	FOREIGN KEY(CodeId)
REFERENCES Postal.[Code] (CodeId)
GO
ALTER TABLE Postal.AddressDeliveryLine
	WITH CHECK 
ADD CONSTRAINT [FK_PostalAddressDeliveryLine_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Postal.AddressDeliveryLine
	WITH CHECK 
ADD CONSTRAINT [FK_PostalAddressDeliveryLine_PostalAddress]
	FOREIGN KEY(AddressId)
REFERENCES Postal.[Address] (AddressId)
GO
ALTER TABLE Postal.AddressDeliveryLine
	WITH CHECK 
ADD CONSTRAINT [FK_PostalAddressDeliveryLine_PostalDeliveryLine]
	FOREIGN KEY(DeliveryLineId)
REFERENCES Postal.DeliveryLine (DeliveryLineId)
GO
ALTER TABLE Postal.Code
	WITH CHECK 
ADD CONSTRAINT [FK_PostalCode_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE Postal.Code
	WITH CHECK 
ADD CONSTRAINT [FK_PostalCode_GeographicPlace]
	FOREIGN KEY(PlaceId)
REFERENCES Geographic.Place (PlaceId)
GO
ALTER TABLE Postal.DeliveryLine
	WITH CHECK 
ADD CONSTRAINT [FK_PostalDeliveryLine_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES [Security].[User] ([UserId])
GO
COMMIT;
GO
PRINT '		Security...'
BEGIN TRANSACTION
GO
ALTER TABLE [Security].Domain
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityDomain_TelecomDomain]
	FOREIGN KEY(DomainId)
REFERENCES Telecom.Domain (DomainId)
GO
ALTER TABLE [Security].[Group]
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityGroup_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE [Security].[Group]
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityGroup_SecurityName]
	FOREIGN KEY(NameId)
REFERENCES [Security].[Name] (NameId)
GO
ALTER TABLE [Security].[Group]
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityGroup_Domain]
	FOREIGN KEY(DomainId)
REFERENCES [Security].Domain (DomainId)
GO
GO
ALTER TABLE [Security].[User]
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityUser_SecurityUser]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE [Security].[User]
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityUser_Domain]
	FOREIGN KEY(DomainId)
REFERENCES [Security].Domain (DomainId)
GO
ALTER TABLE [Security].[User]
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityUser_SecurityName]
	FOREIGN KEY(NameId)
REFERENCES [Security].[Name] (NameId)
GO
ALTER TABLE [Security].[UserGroup]
	WITH CHECK 
ADD CONSTRAINT [FK_SecurityUserGroup_SecurityUser_1]
	FOREIGN KEY([SystemUserId])
REFERENCES [Security].[User] ([UserId])
GO
ALTER TABLE [Security].UserGroup
	WITH CHECK 
ADD CONSTRAINT [FK_SecuritUserGroup_SecurityUser_0]
	FOREIGN KEY(UserId)
REFERENCES [Security].[User] (UserId)
GO
ALTER TABLE [Security].UserGroup
	WITH CHECK 
ADD CONSTRAINT [FK_SecuritUserGroup_Group]
	FOREIGN KEY(GroupId)
REFERENCES [Security].[Group] (GroupId)
GO
COMMIT;
GO
PRINT '		Telecom...'
BEGIN TRANSACTION
GO
ALTER TABLE Telecom.Domain
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomDomain_TelecomLabel]
	FOREIGN KEY(LabelId)
REFERENCES Telecom.[Label] (LabelId)
GO
ALTER TABLE Telecom.Domain
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomDomain_TelecomTopLevelDomain]
	FOREIGN KEY(TopLevelDomainId)
REFERENCES Telecom.TopLevelDomain (TopLevelDomainId)
GO
ALTER TABLE Telecom.Place
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomPlace_GeographicPlace]
	FOREIGN KEY(PlaceId)
REFERENCES Geographic.Place (PlaceId)
GO
ALTER TABLE Telecom.Place
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomPlace_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
ALTER TABLE Telecom.Email
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomEmail_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
ALTER TABLE Telecom.Email
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomEmail_SecurityDomain]
	FOREIGN KEY(DomainId)
REFERENCES Security.Domain (DomainId)
GO
ALTER TABLE Telecom.[LabelUse]
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomLabelUse_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO

ALTER TABLE Telecom.Scheme
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomScheme_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
ALTER TABLE Telecom.TopLevelDomain
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomTopLevelDomain_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
ALTER TABLE Telecom.[Url]
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomUrl_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
ALTER TABLE Telecom.[Url]
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomUrl_TelecomScheme]
	FOREIGN KEY(SchemeId)
REFERENCES Telecom.Scheme (SchemeId)
GO
ALTER TABLE Telecom.[Url]
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomUrl_TelecomDomain]
	FOREIGN KEY(DomainId)
REFERENCES Telecom.Domain (DomainId)
GO
ALTER TABLE Telecom.UrlLabel
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomUrlLabel_TelecomLabel]
	FOREIGN KEY(LabelId)
REFERENCES telecom.[Label] (LabelId)
GO
ALTER TABLE Telecom.UrlLabel
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomUrlLabel_TelecomLabelUse]
	FOREIGN KEY(LabelUseId)
REFERENCES telecom.[LabelUse] (LabelUseId)
GO
ALTER TABLE Telecom.UrlLabel
	WITH CHECK 
ADD CONSTRAINT [FK_TelecomUrlLabel_TelecomUrl]
	FOREIGN KEY(UrlId)
REFERENCES Telecom.[Url] (UrlId)
GO
ALTER TABLE Telecom.UrlLabel
	WITH CHECK
ADD CONSTRAINT [FK_TelecomUrlLabel_SecurityUser]
	FOREIGN KEY(SystemUserId)
REFERENCES Security.[User] (UserId)
GO
--ALTER TABLE Telecom.Phone
--	WITH CHECK 
--ADD CONSTRAINT [FK_TelecomPhone_GeographicPlace]
--	FOREIGN KEY(PlaceId)
--REFERENCES Geographic.Place (PlaceId)
--GO
--ALTER TABLE Telecom.Phone
--	WITH CHECK 
--ADD CONSTRAINT [FK_TelecomPhone_SecurityUser]
--	FOREIGN KEY(SystemUserId)
--REFERENCES Security.[User] (UserId)
--GO
--SELECT object_id, name, schema_id, parent_object_id
--	FROM sys.foreign_keys
PRINT '	FOREIGN KEY CONSTRAINTS CREATED.';
GO
COMMIT
GO
PRINT 'DECLARATIVE REFERENTIAL INTEGRITY APPLIED...';
GO
BEGIN--AUDITING
PRINT '			**Auditing**'
DECLARE @Now datetime2, @Difference bigint, @Message nvarchar(max), @ParentExecutionId int;
DECLARE @User sysname, @UserId smallint;
DECLARE @SQL nvarchar(max)
DECLARE @ForeignKeys TABLE (id smallint IDENTITY(1,1), SchemaName sysname, TableName sysname, ForeignKey sysname)
PRINT ''
PRINT '		...'
PRINT 'TESTING FOR MISSING DRI...'
PRINT '		...'
SELECT @ParentExecutionId = ParentExecutionId FROM #Scripts WHERE Name = 'DRI';
SET @Now = GETDATE();
SELECT @User = RIGHT([name], LEN([name]) - PATINDEX('%\%', [name]))
	FROM sys.server_principals 
WHERE principal_id = SUSER_ID()
SELECT @UserId = UserId FROM Security.[User] u INNER JOIN Security.[Name] n ON u.NameId = n.NameId WHERE n.[Value] = @User AND u.DomainId = 1;
SELECT @ParentExecutionId = ExecutionId 
	FROM Auditing.Execution
WHERE		EventName = 'DRI'
		AND	SystemTime = (SELECT MAX(SystemTime) FROM Auditing.Execution WHERE EventName = 'DRI')
IF EXISTS(SELECT 1 	FROM sys.columns c
			INNER JOIN sys.tables t
				ON	c.object_id = t.object_id
			LEFT OUTER JOIN sys.foreign_key_columns fkc
				ON		c.object_id = fkc.parent_object_id
					AND	c.column_id = fkc.parent_column_id
			LEFT OUTER JOIN sys.foreign_keys fk
				ON	fkc.constraint_object_id = fk.object_id
			WHERE		RIGHT(c.[name], 2) = 'Id'
					AND	c.is_identity <> 1
					AND	fk.[name] IS NULL)
	BEGIN
	SELECT @Message = 'Missing foreign key constraints'
	INSERT INTO Auditing.ExecutionStatus
		(ExecutionId, StatusId, SystemUserId, SystemTime)
	VALUES
		(@ParentExecutionId, 4, @UserId, @Now)
	INSERT INTO Auditing.ExecutionError
		(ExecutionId, [Value], SystemUserId, SystemTime)
	SELECT @ParentExecutionId, @Message, @UserId, @Now
	SELECT	SCHEMA_NAME(t.schema_id) AS 'Schema', t.[name] AS 'Table', c.[name] AS 'Column',
			fk.[name] AS 'Missing Foreign Key'
		FROM sys.columns c
	INNER JOIN sys.tables t
		ON	c.object_id = t.object_id
	LEFT OUTER JOIN sys.foreign_key_columns fkc
		ON		c.object_id = fkc.parent_object_id
			AND	c.column_id = fkc.parent_column_id
	LEFT OUTER JOIN sys.foreign_keys fk
		ON	fkc.constraint_object_id = fk.object_id
	WHERE		RIGHT(c.[name], 2) = 'Id'
			AND	c.is_identity <> 1
			AND	fk.[name] IS NULL
		ORDER BY SCHEMA_NAME(t.schema_id), t.[name], c.[name]
	END
ELSE
	BEGIN
	PRINT ''
	SELECT @Message = 'No missing foreign key constraints found.'
	PRINT @Message;
	INSERT INTO Auditing.ExecutionStatus
		(ExecutionId, StatusId, SystemUserId, SystemTime)
	VALUES
		(@ParentExecutionId, 1, @UserId, @Now)
	INSERT INTO Auditing.ExecutionDescription
		(ExecutionId, SystemTime, [Value], SystemUserId)
	VALUES
		(@ParentExecutionId, @Now, @Message, @UserId)
	END;

UPDATE #Scripts SET EndTime = @Now WHERE [Name] = 'DRI';

SELECT @Difference = DATEDIFF_BIG(millisecond, StartTime, EndTime) 
	FROM #Scripts;

END;
COMMIT;
SELECT @Message = CONVERT(varchar(32), DATEADD(millisecond, @Difference, 0), 114);
PRINT '___________________________________________________________________________________________';
PRINT '___________________________________________________________________________________________';
PRINT 'Time elapsed: ' + @Message;
PRINT 'SCRIPT END_________________________________________________________________________________';
GO



--SELECT * FROM Security.[User]
--SELECT * FROM Configuration.Objects
--SELECT * FROM Auditing.Executions
--SELECT * FROM Auditing.ExecutionDescription
--SELECT * FROM Auditing.ExecutionStatus
--SELECT * FROM Auditing.ExecutionError