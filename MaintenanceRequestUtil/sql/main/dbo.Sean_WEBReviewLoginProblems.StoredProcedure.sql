USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Sean_WEBReviewLoginProblems]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: 12/6/2011
-- Description:	To review reason why web users cannot login into the system
-- =============================================
CREATE PROCEDURE [dbo].[Sean_WEBReviewLoginProblems]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	
declare @email as char(100)
declare @userid as char(100)
declare @personid as int

set @userid='E4AC5654-7764-4AB1-B923-A2AA92B3EA61'
set @email='laurie.a.crichton@supervalu.com'
set @personid=41515


SELECT    userid,password,IsLockedOut, FailedPasswordAnswerAttemptCount 
FROM         ASPNETDB.dbo.aspnet_Membership  
WHERE     (UserId = ''+ @userid+'')

select UserId,UserName,LoweredUserName 
from ASPNETDB.dbo.aspnet_Users WHERE     (username  = ''+@email+'')

select OwnerEntityId ,UniqueIdentifier,Login,Password 
 from DataTrue_Main.dbo.Logins 
where      (Login   = ''+@email +'') 
 
 select OwnerEntityID,AttributeID,AttributeValue,IsActive
   from DataTrue_Main.dbo.AttributeValues 
 where (OwnerEntityID     =''+@personid+'')
 
  
END
GO
