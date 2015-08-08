USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddPOMustDeliver]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddPOMustDeliver]	

	@StoreSetupId varchar(10),
	@StartDate  varchar(20),
	@EndDate  varchar(20),	
	@MustDeliverUnits  varchar(20),
	@LastUpdateUserID varchar(20)
	
AS
--exec  usp_AddPOMustDeliever '-1','-1','','','1900-01-01'
BEGIN
	set @StartDate=convert(date,@StartDate,101)
	set @EndDate=convert(date,@EndDate,101)
	
	INSERT INTO [PO_MustDeliver]([StoreSetupId], [MustDeliver], [StartDate], [EndDate], [LastUpdateUserID], [DateTimeLastUpdate])
	VALUES (@StoreSetupId, @MustDeliverUnits, @StartDate, @EndDate, @LastUpdateUserID, getdate())
				
		
END
GO
