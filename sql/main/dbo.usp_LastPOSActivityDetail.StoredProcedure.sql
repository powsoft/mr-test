USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_LastPOSActivityDetail]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_LastPOSActivityDetail]
 @ChainId varchar(5),
 @SupplierID varchar(5),
 @custom1 varchar(255),
 @BrandId varchar(5),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @OtherOption int,
 @Others varchar(50)
as
Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'SELECT     TOP (100) PERCENT dbo.LastScanActivity.ChainName, dbo.LastScanActivity.Banner, dbo.LastScanActivity.StoreIdentifier AS [Store No], S.SBTNumber as [SBT Number],
                      dbo.LastScanActivity.SupplierName,B.BrandName as Brand, dbo.Products.ProductName, dbo.ProductIdentifiers.IdentifierValue AS UPC,PD.IdentifierValue as [Vendor Item Number], SUM(S.Qty * dbo.TransactionTypes.QtySign) AS Qty, convert(varchar(10),dbo.LastScanActivity.LastScanDate,101) as [Last Scan Date] 
                      ,dbo.StoresUniqueValues.supplieraccountnumber as [Supplier Acct Number], dbo.StoresUniqueValues.DriverName as [Driver Name], dbo.StoresUniqueValues.RouteNumber as [Route Number]
        FROM         datatrue_report.dbo.StoreTransactions S 
		INNER JOIN dbo.TransactionTypes ON S.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID 
		INNER JOIN dbo.Stores ON S.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active'' 
		INNER JOIN dbo.LastScanActivity ON S.StoreID = dbo.LastScanActivity.StoreID AND S.SupplierID = dbo.LastScanActivity.SupplierID AND  S.SaleDateTime = dbo.LastScanActivity.LastScanDate 
		INNER JOIN dbo.Products ON S.ProductID = dbo.Products.ProductID 
		INNER JOIN ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID 
		INNER JOIN Brands B ON PB.BrandID = B.BrandID 
		INNER JOIN SupplierBanners SB on SB.SupplierId = LastScanActivity.SupplierId and SB.Status=''Active'' and SB.Banner=LastScanActivity.Banner  
		INNER JOIN dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID  AND (dbo.ProductIdentifiers.ProductIdentifierTypeID in (2,8))
		Left JOIN  ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=LastScanActivity.SupplierId
		LEFT OUTER JOIN dbo.StoresUniqueValues ON S.SupplierID = dbo.StoresUniqueValues.SupplierID AND S.StoreID=dbo.StoresUniqueValues.StoreID
        WHERE     (dbo.TransactionTypes.BucketType = 1)  '
        
	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and LastScanActivity.ChainID=' + @ChainId

	if(@SupplierID <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and dbo.LastScanActivity.supplierid=' + @SupplierId
 
	if(@custom1='') 
		set @sqlQuery = @sqlQuery + ' and dbo.LastScanActivity.Banner is Null'

	else if(@custom1<>'-1') 
		set @sqlQuery = @sqlQuery + ' and dbo.LastScanActivity.Banner like ''%' + @custom1 + '%'''
		
	
	if(@ProductIdentifierValue<>'')
	begin
		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
		     
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @ProductIdentifierValue + '%'''
			
		else if (@ProductIdentifierType=7)
			 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''

	end

	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and stores.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and stores.Custom2 like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and stores.StoreName like ''%' + @StoreIdentifierValue + '%'''
	end
 
    if(@Others<>'')
    begin
        -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
        -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                             
        if (@OtherOption=1)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.DistributionCenter like ''%' + @Others + '%'''
		else if (@OtherOption=2)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RegionalMgr like ''%' + @Others + '%'''
		else if (@OtherOption=3)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SalesRep like ''%' + @Others + '%'''
		else if (@OtherOption=4)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.SupplierAccountNumber like ''%' + @Others + '%'''
		else if (@OtherOption=5)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.DriverName like ''%' + @Others + '%'''
		else if (@OtherOption=6)
			set @sqlQuery = @sqlQuery + ' and StoresUniqueValues.RouteNumber like ''%' + @Others + '%'''

    end
 
 set @sqlQuery = @sqlQuery + ' GROUP BY dbo.LastScanActivity.LastScanDate, dbo.LastScanActivity.ChainName, dbo.LastScanActivity.StoreIdentifier, dbo.LastScanActivity.Banner, S.SBTNumber, 
                                              dbo.LastScanActivity.SupplierName,B.BrandName, dbo.Products.ProductName, dbo.ProductIdentifiers.IdentifierValue,PD.IdentifierValue, dbo.StoresUniqueValues.supplieraccountnumber, dbo.StoresUniqueValues.DriverName, dbo.StoresUniqueValues.RouteNumber
                        ORDER BY dbo.LastScanActivity.ChainName, dbo.LastScanActivity.Banner, [Store No], dbo.LastScanActivity.SupplierName'
execute(@sqlQuery); 
 
End
GO
