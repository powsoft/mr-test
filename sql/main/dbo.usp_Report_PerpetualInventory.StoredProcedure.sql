USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_PerpetualInventory]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_PerpetualInventory]
    @ChainId varchar(500),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(500),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
as
-- exec [usp_Report_PerpetualInventoryWarning] 60620,'','','','40567','','','',''
-- exec [usp_Report_PerpetualInventory] 60620,'','','','40567','','','',''
Begin
	
	select * from  TempPerpetualInventory P where SupplierId=@SupplierId and ChainId=@ChainId
           
end
GO
