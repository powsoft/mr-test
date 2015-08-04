USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_TemplateEmailSettings_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROC [dbo].[usp_TemplateEmailSettings_PRESYNC_20150329]
AS

BEGIN
	 SELECT [ID]
			,[TemplateName] AS [TemplateName]
			,[ContactPersonName] AS [ContactPersonName]
			,[ContactPersonEmail] AS [ContactPersonEmail]
	 FROM [dbo].[TemplateEmailSettings]
END
GO
