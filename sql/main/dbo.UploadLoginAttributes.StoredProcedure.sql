USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[UploadLoginAttributes]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UploadLoginAttributes]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    update AttributeValues 
    set AttributeValue ='40562'
    where OwnerEntityID =41539 and AttributeValue ='41562'
    
	declare @personid int
	declare @banner varchar(255)
	declare @supplierid int

	set @personid= 41542
	set @banner ='Full'
	set @supplierid =40562

	 
	  select* from dbo.AttributeValues 
	  where OwnerEntityID=@personid 

	INSERT INTO dbo.AttributeValues ( ownerentityid,attributeid,AttributeValue,isactive,datetimecreated,LastUpdateUserID ,DateTimeLastUpdate )
	SELECT @personid , 15 , 'FULL',1 ,'12/1/2011',40384,'12/1/2011'


	INSERT INTO dbo.AttributeValues ( ownerentityid,attributeid,AttributeValue,isactive,datetimecreated,LastUpdateUserID ,DateTimeLastUpdate )
	SELECT @personid , 16 , 'FULL',1 ,'12/1/2011',40384,'12/1/2011'
	  
	  
	INSERT INTO dbo.AttributeValues ( ownerentityid,attributeid,AttributeValue,isactive,datetimecreated,LastUpdateUserID ,DateTimeLastUpdate )
	SELECT @personid , 9 , @supplierid ,1 ,'12/1/2011',40384,'12/1/2011'

	INSERT INTO dbo.AttributeValues ( ownerentityid,attributeid,AttributeValue,isactive,datetimecreated,LastUpdateUserID ,DateTimeLastUpdate )
	SELECT @personid , 20 , @banner ,1 ,'12/1/2011',40384,'12/1/2011'
	  
	INSERT INTO dbo.AttributeValues ( ownerentityid,attributeid,AttributeValue,isactive,datetimecreated,LastUpdateUserID ,DateTimeLastUpdate )
	SELECT @personid , 21 , @personid  ,1 ,'12/1/2011',40384,'12/1/2011'
	  
	  select* from dbo.AttributeValues 
	  where OwnerEntityID=@personid 
	

END
GO
