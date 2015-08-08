USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SavePOSeasons]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SavePOSeasons]
     @StoreSetupId varchar(20),
     @StartDate VarChar(20),
     @EndDate varchar(20),
     @FillRate varchar(20),
     @ChangeInSales varchar(10)
    
as
begin
    	INSERT INTO PO_Seasonality (StoreSetupId,StartDate,EndDate, ChangeInAvgSales,FillRate)
		VALUES		(@StoreSetupId, convert(varchar(10),@StartDate, 101), convert(varchar(10),@EndDate, 101), @ChangeInSales,@FillRate)
end
GO
