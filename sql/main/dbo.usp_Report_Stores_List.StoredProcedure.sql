USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Stores_List]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: <Create Date,,>12/12/2011
-- Description:	<Description,,> ADDED FIELD LastScanDate
-- =============================================
CREATE  procedure [dbo].[usp_Report_Stores_List] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
declare @AttValue int

 select @attvalue = (AttributeID)  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID =17
 
Declare @Query varchar(8000)

		set @Query = ' Select top 1 ''SystemNo'',''Store Name'',''Store No'',''SBT No'',''Banner'',''Active Start'',
					''Active Last'',''Address'',''City'',''County'',''State'',''Zip Code'' from Chains union all

					SELECT   cast(Stores.StoreID as varchar) AS SystemNo, Stores.StoreName,
					cast(Stores.StoreIdentifier as varchar) AS [Store No], 
					cast(Stores.Custom2 as varchar), Stores.Custom1 AS Banner, 
					convert(varchar(10),Stores.ActiveFromDate,101) as [Active Start], 
					convert(varchar(10),Stores.ActiveLastDate,101) as [Active Last], 
					Addresses.Address1, Addresses.City, Addresses.CountyName, Addresses.State, cast(Addresses.PostalCode as varchar)
						FROM   Stores  WITH(NOLOCK)  INNER JOIN
						Addresses WITH(NOLOCK)  ON Stores.StoreID = Addresses.OwnerEntityID 
						Where   Stores.ActiveStatus=''Active'''
	
		if @AttValue =17
			set @Query = @Query +  ' and Stores.ChainID in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'

		if(@chainID  <>'-1') 
			set @Query  = @Query  +  ' and stores.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	exec (@Query )
END
GO
