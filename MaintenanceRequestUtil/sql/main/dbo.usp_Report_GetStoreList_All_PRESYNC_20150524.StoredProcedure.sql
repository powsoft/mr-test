USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetStoreList_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: <Create Date,,>12/12/2011
-- Description:	<Description,,> ADDED FIELD LastScanDate
-- =============================================
--[usp_Report_GetStoreList]  '40393','40384','All','-1','-1','-1',100,'2013-05-01','2013-05-31'
CREATE procedure [dbo].[usp_Report_GetStoreList_All_PRESYNC_20150524] 
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

 select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 
Declare @Query varchar(8000)

	set @Query = 'SELECT distinct dbo.Stores.StoreId, dbo.Stores.StoreName AS [Store Name], dbo.Stores.StoreIdentifier AS [Store Number],
				dbo.Stores.Custom1 AS Banner, dbo.Stores.Custom2 AS [SBT Number],
				dbo.Stores.StoreSize AS Size, (dbo.Addresses.Address1 + '' '' + dbo.Addresses.Address2) as [Street Address],
				dbo.Addresses.City, dbo.Addresses.State, dbo.Addresses.PostalCode as [Zip Code], 
				convert(varchar(10), dbo.Stores.ActiveFromDate, 101) AS [Active From Date], 
				convert(varchar(10), dbo.Stores.ActiveLastDate, 101) AS [Active Last Date]
				FROM  dbo.Stores 
				INNER JOIN dbo.StoreSetup on dbo.StoreSetup.StoreId=dbo.Stores.StoreID
				Left JOIN dbo.Addresses ON dbo.Stores.StoreID = dbo.Addresses.OwnerEntityID 
				Left JOIN dbo.StoreStatus ON dbo.Stores.StoreID = dbo.StoreStatus.StoreID 
				Where 1=1'
					
	--if @AttValue =17
	--	set @query = @query + ' and dbo.Stores.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and dbo.StoreSetup.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
                  
	if(@chainID  <>'-1') 
		set @Query = @Query + ' and dbo.Stores.ChainID in ( ' + @ChainId + ')' 

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and dbo.StoreSetup.SupplierId in (' + @SupplierId  +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%'''
	
	if (@LastxDays > 0)
		begin
			set @startDate= convert(varchar(10),dateadd(d, -1 * @LastxDays, { fn NOW()}) , 101)
			set @EndDate= convert(varchar(10), { fn NOW() } ,101)
		end
		
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and ''' + @StartDate  + ''' between dbo.Stores.ActiveFromDate and dbo.Stores.ActiveLastDate';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and ''' + @EndDate  + ''' between dbo.Stores.ActiveFromDate and dbo.Stores.ActiveLastDate';
	
	Exec(@Query )
END
GO
