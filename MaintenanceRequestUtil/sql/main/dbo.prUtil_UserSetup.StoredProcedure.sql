USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_UserSetup]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_UserSetup]
as


INSERT INTO [DataTrue_Main].[dbo].[AttributeValues]
           ([OwnerEntityID]
           ,[AttributeID]
           ,[AttributeValue]
           ,[IsActive]
           ,[LastUpdateUserID])
SELECT [PersonID]
		,15
		,'FULL'
		,1
		,2

  FROM [DataTrue_Main].[dbo].[Persons]
where personid >= 41359

return
GO
