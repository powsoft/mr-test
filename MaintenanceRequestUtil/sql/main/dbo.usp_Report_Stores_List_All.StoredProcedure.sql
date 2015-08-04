USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Stores_List_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: <Create Date,,>12/12/2011
-- Description:	<Description,,> ADDED FIELD LastScanDate
-- =============================================
-- exec usp_Report_Stores_List_All 65726,59977,'All','-1','74767','-1',0,'06/01/2014','06/30/2014'
CREATE  procedure [dbo].[usp_Report_Stores_List_All] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
declare @AttValue int

 select @attvalue = (AttributeID)  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID =17
 
Declare @Query varchar(max)

		set @Query = ' SELECT   cast(Stores.StoreID as varchar) AS SystemNo, Stores.StoreName as [Store Name], 
							 cast(Stores.StoreIdentifier as varchar) AS [Store No], 
							 cast(Stores.Custom2 as varchar) as [SBT No], Stores.Custom1 AS Banner, 
							 convert(varchar(10),Stores.ActiveFromDate,101) as [Active Start], 
							 convert(varchar(10),Stores.ActiveLastDate,101) as [Active Last], 
						     Addresses.Address1 as [Address], Addresses.City, Addresses.CountyName as [Country], Addresses.State, 
						     cast(Addresses.PostalCode as varchar) as [Zip Code]
					FROM   Stores  WITH(NOLOCK)  INNER JOIN
						   Addresses WITH(NOLOCK)  ON Stores.StoreID = Addresses.OwnerEntityID 
					Where   Stores.ActiveStatus=''Active'''
	
		if(@chainID  <>'-1') 
			set @Query  = @Query  +  ' and stores.ChainID in (' + @chainID +')'

		if(@SupplierId  <>'-1') 
			set @Query  = @Query  +  ' and stores.StoreId in (select distinct StoreId from StoreSetup 
									   where SupplierId in (' + @SupplierId +') and ChainId=Stores.ChainId) '			

		if(@Banner<>'All') 
			set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	exec (@Query )
END
GO
