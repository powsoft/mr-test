USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetStoreAndVendorActivityDetails]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_Report_GetStoreAndVendorActivityDetails] '50964','50729','All','-1','-1','-1','180','1900-01-01','1900-01-01'
CREATE procedure [dbo].[usp_Report_GetStoreAndVendorActivityDetails] 
 
@chainID varchar(20),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(10),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20), 
@MaxRowsCount varchar(20) = ' Top 2500000 ' 

AS
BEGIN

Declare @Query varchar(8000)

  set @Query = 'Select * from Datatrue_CustomResultSets..tmpStoreAndVendorActivity where 1=1 '
      
	--if(@chainID <>'-1') 
	--	set @Query  = @Query  +  ' and ChainId = ' + @chainID 

exec (@query)
END
GO
