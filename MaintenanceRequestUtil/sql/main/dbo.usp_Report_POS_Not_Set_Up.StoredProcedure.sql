USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_POS_Not_Set_Up]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_POS_Not_Set_Up] 
	-- exec usp_Report_POS_Not_Set_Up '60620','41713','All','','-1','-1','-1','1900-01-01','1900-01-01'
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
Declare @Query varchar(max)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
	
	set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @Query ='SELECT DISTINCT  ' + @MaxRowsCount + ' dbo.Chains.ChainName as [Retailer Name], dbo.Suppliers.SupplierName as [Supplier Name], 
									  dbo.Stores.custom1 as Banner, 
									  dbo.Stores.StoreName as Store,
									  dbo.Stores.Custom2 as [SBT Number],  
									  dbo.Stores.StoreIdentifier as [Store No], 
									  dbo.Products.ProductName as Product, 
									  dbo.ProductIdentifiers.IdentifierValue as UPC,
									  s.RuleRetail as [Retail Price],
									  case when dbo.ProductIdentifiers.ProductIdentifierTypeId=2 then S.SupplierItemNumber  else 
									  (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C with (nolock) where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end as [Vendor Item Number],  
									  dbo.Brands.BrandName as Brand,
									  dbo.TransactionTypes.TransactionTypeName as Type,
									  convert(varchar(10),S.SaleDateTime, 101) as [Transaction Date],  
									  case when dbo.TransactionTypes.transactiontypeid in (21,8,14) then -sum(S.Qty) else sum(S.Qty) end as Qty,  
									  cast(S.rulecost as numeric(10, 4)) as Cost, S.Promoallowance as Promo,
									  cast((isnull(S.rulecost,0)-isnull(S.Promoallowance,0)) as numeric(10, 4)) as [Net Cost]  ,
									  isnull(S.SupplierInvoiceNumber,'''') as [Supplier Doc No], 
									  WH.WarehouseName as [Distribution Center], 
									  SUV.RegionalMgr as [Regional Manager], 
									  SUV.SalesRep as [Sales Representative], 
									  SUV.supplieraccountnumber as [Supplier Acct Number], 
									  SUV.DriverName as [Driver Name], 
									  SUV.RouteNumber as [Route Number]   

						FROM dbo.Chains  WITH(NOLOCK) 
								INNER JOIN StoreTransactions S WITH(NOLOCK) ON dbo.Chains.ChainID = S.ChainID 
								INNER JOIN dbo.Stores  WITH(NOLOCK) ON S.StoreID = dbo.Stores.StoreID 
								INNER JOIN  dbo.Products  WITH(NOLOCK) ON S.ProductID = dbo.Products.ProductID 
								INNER JOIN dbo.Suppliers  WITH(NOLOCK) ON dbo.Suppliers.SupplierID = S.SupplierID 
								INNER JOIN dbo.TransactionTypes  WITH(NOLOCK) on dbo.TransactionTypes.TransactionTypeId = S.TransactionTypeID 
								inner join SupplierBanners SB  WITH(NOLOCK) on SB.SupplierId = Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.Custom1 
								inner join dbo.ProductIdentifiers  WITH(NOLOCK) ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.IdentifierValue = s.UPC
								left join dbo.ProductBrandAssignments PB  WITH(NOLOCK) on PB.ProductID=dbo.Products.ProductID and PB.CustomOwnerEntityId= S.SupplierID 
								left join dbo.Brands  WITH(NOLOCK) ON PB.BrandID = dbo.Brands.BrandID 
								left outer join dbo.ProductIdentifiers PD  WITH(NOLOCK) on dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=S.SupplierID 
								LEFT OUTER JOIN  dbo.StoresUniqueValues SUV  WITH(NOLOCK) ON S.SupplierID = SUV.SupplierID AND S.StoreID=SUV.StoreID
								left JOIN Warehouses WH  WITH(NOLOCK) ON WH.ChainID=Chains.ChainID and WH.WarehouseId=SUV.DistributionCenter
				 WHERE     1=1 and Cast(S.SaleDateTime as date) between Cast(Stores.ActiveFromDate as date) and Cast(Stores.ActiveLastDate as date) and S.TransactionTypeID in (24,26,25)   and ProductIdentifiers.ProductIdentifierTypeId in (2,8)  '
 
	if @AttValue =17
		set @query = @query + ' and Chains.ChainID in (select attributepart from [fnGetRetailersTable](' +  cast(@PersonID as varchar) + '))'
	else
		set @query = @query + ' and Suppliers.SupplierID in (select attributepart from [fnGetSupplierTable](' +  cast(@PersonID as varchar) + '))'
		

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and chains.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and Suppliers.SupplierId=' + @SupplierId  

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (S.SaleDateTime between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
			
	set @Query = @Query + 'group by dbo.Chains.ChainName, dbo.Suppliers.SupplierName, dbo.TransactionTypes.transactiontypeid, 
									Suppliers.SupplierId, dbo.Brands.BrandName, dbo.ProductIdentifiers.ProductIdentifierTypeID, 
									S.SaleDateTime,dbo.TransactionTypes.TransactionTypeName,  WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep, SUV.supplieraccountnumber, 
									SUV.DriverName, SUV.RouteNumber, dbo.Stores.custom1, dbo.Stores.StoreName,S.rulecost, S.Promoallowance,dbo.Stores.Custom2, dbo.Stores.StoreIdentifier, 
									isnull(S.SupplierInvoiceNumber,''''),WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep, SUV.supplieraccountnumber, SUV.DriverName, SUV.RouteNumber, 
									dbo.Products.ProductName, Products.ProductID, dbo.ProductIdentifiers.IdentifierValue, s.RuleRetail,  dbo.ProductIdentifiers.ProductIdentifierTypeId, S.SupplierItemNumber  

							ORDER BY [Transaction Date] ASC ; '
	
	exec  (@Query )
	print (@Query)
	
END
GO
