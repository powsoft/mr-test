USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Inventory_Count_Subscription]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

exec [usp_Report_Inventory_Count_Subscription] '40393','-1','All','','-1','','0','07/25/2014','08/01/2014'
*/
CREATE  procedure [dbo].[usp_Report_Inventory_Count_Subscription] 
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
Declare @Query varchar(6000)
 
    set @query = 'SELECT  distinct  ' + @MaxRowsCount + '
				   C.ChainName as [Retailer Name], SP.SupplierName as [Supplier Name], 
				   ST.custom1 as Banner, ST.StoreName as Store, ST.Custom2 as [SBT Number],ST.StoreIdentifier as [Store No], 
				   isnull(S.SupplierInvoiceNumber,'''') as [Supplier Doc No], 
				   P.ProductName as Product, PD.IdentifierValue as UPC,S.RuleRetail as [Retail Price],
				   case when PD.ProductIdentifierTypeId=2 then 
						 S.SupplierItemNumber  
					   else 
						 (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C with (nolock)
						  where c.ProductId=P.ProductID and C.SupplierID=SP.SupplierId) 
					   end as [Vendor Item Number],  
				   B.BrandName as Brand, TT.TransactionTypeName as Type,
				   convert(varchar(10),S.SaleDateTime, 101) as [Transaction Date],  
				   sum(S.Qty) as Qty,  cast(sum(S.rulecost) as numeric(10, 4)) as Cost, sum(S.Promoallowance) as Promo,
				   cast((isnull(sum(S.rulecost),0)-isnull(sum(S.Promoallowance),0)) as numeric(10, 4)) as [Net Cost], 
				   WH.WarehouseName as [Distribution Center], SUV.RegionalMgr as [Regional Manager], 
				   SUV.SalesRep as [Sales Representative], SUV.SupplierAccountNumber as [Supplier Acct Number], 
				   SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number]  
			    FROM dbo.Chains C  WITH(NOLOCK) 
			    INNER JOIN dbo.StoreTransactions S WITH(NOLOCK) ON C.ChainID = S.ChainID 
			    INNER JOIN dbo.TransactionTypes  TT WITH(NOLOCK) on TT.TransactionTypeId = S.TransactionTypeID 
			    INNER JOIN dbo.Stores ST  WITH(NOLOCK) ON S.StoreID = ST.StoreID and S.ChainId=ST.ChainID
			    INNER JOIN dbo.Products P WITH(NOLOCK) ON S.ProductID = P.ProductID 
			    INNER JOIN dbo.Suppliers SP WITH(NOLOCK) ON SP.SupplierID = S.SupplierID 
			    INNER JOIN SupplierBanners SB  WITH(NOLOCK) on SB.SupplierId = SP.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1 
			    INNER JOIN dbo.ProductIdentifiers PD WITH(NOLOCK) ON P.ProductID = PD.ProductID 
				   and PD.ProductIdentifierTypeId in (2,8) and PD.IdentifierValue = S.UPC
			    LEFT JOIN dbo.ProductBrandAssignments PB  WITH(NOLOCK) on PB.ProductID=P.ProductID and PB.CustomOwnerEntityId= S.SupplierID 
			    LEFT JOIN dbo.Brands B WITH(NOLOCK) ON PB.BrandID = B.BrandID 
			    LEFT JOIN  dbo.ProductIdentifiers PD1  WITH(NOLOCK) on P.ProductID = PD1.ProductID 
				   and PD1.ProductIdentifierTypeId =3 and PD1.OwnerEntityId=S.SupplierID 
			    LEFT JOIN  StoresUniqueValues SUV  WITH(NOLOCK) ON S.SupplierID = SUV.SupplierID AND S.StoreID=SUV.StoreID
			    LEFT JOIN  Warehouses WH  WITH(NOLOCK) ON WH.ChainID=C.ChainID and WH.WarehouseId=SUV.DistributionCenter
			    WHERE  Cast(S.SaleDateTime as date) between Cast(ST.ActiveFromDate as date) and Cast(ST.ActiveLastDate as date)						
					 and S.TransactionTypeID in (10,11) '
						
	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and SP.SupplierID=' + @SupplierId  

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and C.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and ST.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and ST.StoreIdentifier like ''%' + @StoreId + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and PD.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and S.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + ''''

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + ''''
	
	Set @Query = @Query + ' GROUP BY C.ChainName, SP.SupplierName, TT.TransactionTypeId, 
					    SP.SupplierId, B.BrandName, PD.ProductIdentifierTypeID, 
					    S.SaleDateTime, TT.TransactionTypeName, WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep, 
					    SUV.SupplierAccountNumber, SUV.DriverName, SUV.RouteNumber, ST.custom1, ST.StoreName,S.rulecost, 
					    S.Promoallowance, ST.Custom2, ST.StoreIdentifier, isnull(S.SupplierInvoiceNumber,''''), 
					    P.ProductName, P.ProductID, PD.IdentifierValue, S.RuleRetail, PD.ProductIdentifierTypeId, S.SupplierItemNumber'
	print(@Query)							  	
	exec(@Query )
	
END
GO
