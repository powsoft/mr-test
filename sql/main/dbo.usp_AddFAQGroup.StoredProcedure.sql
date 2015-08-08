USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddFAQGroup]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[usp_AddFAQGroup]
  @FAQGroupID varchar(10),
  @FAQGroupName varchar(50)
AS

BEGIN
	if(@FAQGroupID>0)
	
		Update FAQGroups set 
		FAQGroupName=@FAQGroupName
		where FAQGroupId=@FAQGroupID
	else
		Insert INTO FAQGroups
		(FAQGroupName
		) 
		values
		(
		@FAQGroupName
		)
END
GO
