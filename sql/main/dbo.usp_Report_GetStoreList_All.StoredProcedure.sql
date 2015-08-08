USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetStoreList_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: <Create Date,,>12/12/2011
-- Description:	<Description,,> ADDED FIELD LastScanDate
-- =============================================
--[usp_Report_GetStoreList_all]  '40393','40384','All','-1','-1','-1',100,'2013-05-01','2013-05-31'
CREATE  procedure [dbo].[usp_Report_GetStoreList_All] 
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

 select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 
Declare @Query varchar(max)

	set @Query = 'SELECT distinct Stores.StoreId, Stores.StoreName AS [Store Name], Stores.StoreIdentifier AS [Store Number],
				Stores.Custom1 AS Banner, Stores.Custom2 AS [SBT Number],
				Stores.StoreSize AS Size, (Addresses.Address1 + '' '' + Addresses.Address2) as [Street Address],
				Addresses.City, Addresses.State, Addresses.PostalCode as [Zip Code], 
				convert(varchar(10), Stores.ActiveFromDate, 101) AS [Active From Date], 
				convert(varchar(10), Stores.ActiveLastDate, 101) AS [Active Last Date]
				FROM  Stores 
				INNER JOIN StoreSetup on StoreSetup.StoreId=Stores.StoreID
				Left JOIN Addresses ON Stores.StoreID = Addresses.OwnerEntityID 
				Left JOIN StoreStatus ON Stores.StoreID = StoreStatus.StoreID 
				Where 1=1'
					
	--if @AttValue =17
	--	set @query = @query + ' and Stores.ChainID in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and StoreSetup.SupplierID in (select attributepart from fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
                  
	if(@chainID  <>'-1') 
		set @Query = @Query + ' and Stores.ChainID in ( ' + @ChainId + ')' 

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and StoreSetup.SupplierId in (' + @SupplierId  +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''
	
	if (@LastxDays > 0)
		begin
			set @startDate= convert(varchar(10),dateadd(d, -1 * @LastxDays, { fn NOW()}) , 101)
			set @EndDate=convert(varchar(10),dateadd(d,  @LastxDays, { fn NOW()}) , 101)
		end
		
	if (convert(date, @StartDate  ) >= convert(date,'1900-01-01'))
		set @Query = @Query + ' and ((Stores.ActiveFromDate between ''' + @StartDate  + '''   and ''' + @EndDate  + ''')';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' or  (Stores.ActivelastDate between ''' + @StartDate  + '''   and ''' + @EndDate  + '''))';
	print(@Query)
	Exec(@Query )
END
GO
