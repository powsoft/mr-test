USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Stores_List_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: <Create Date,,>12/12/2011
-- Description:	<Description,,> ADDED FIELD LastScanDate
-- =============================================
CREATE procedure [dbo].[usp_Report_Stores_List_All_PRESYNC_20150524] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(1000),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(1000),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
declare @AttValue int

 select @attvalue = (AttributeID)  from AttributeValues where OwnerEntityID=@PersonID and AttributeID =17
 
Declare @Query varchar(8000)

		set @Query = ' Select top 1 ''SystemNo'',''Store Name'',''Store No'',''SBT No'',''Banner'',''Active Start'',
					''Active Last'',''Address'',''City'',''County'',''State'',''Zip Code'' from Chains union all

		SELECT   cast(dbo.Stores.StoreID as varchar) AS SystemNo, dbo.Stores.StoreName, cast(dbo.Stores.StoreIdentifier as varchar) AS [Store No], cast(dbo.Stores.Custom2 as varchar), dbo.Stores.Custom1 AS Banner, cast(dbo.Stores.ActiveFromDate as varchar), cast(dbo.Stores.ActiveLastDate as varchar), 
               dbo.Addresses.Address1, dbo.Addresses.City, dbo.Addresses.CountyName, dbo.Addresses.State, cast(dbo.Addresses.PostalCode as varchar)
        FROM   dbo.Stores INNER JOIN
               dbo.Addresses ON dbo.Stores.StoreID = dbo.Addresses.OwnerEntityID 
		Where   dbo.Stores.ActiveStatus=''Active'''
	
		--if @AttValue =17
		--	set @Query = @Query +  ' and dbo.Stores.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'

		if(@chainID  <>'-1') 
			set @Query  = @Query  +  ' and dbo.stores.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	exec (@Query )
END
GO
