USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UnauthorizedInventoryRecords]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UnauthorizedInventoryRecords]
 @ChainId varchar(5),
 @SupplierID varchar(5),
 @custom1 varchar(255),
 @ActivityType varchar(50),
 @BrandId varchar(5),
 @TransFromDate varchar(50),
 @TransToDate varchar(50),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50)

as
Begin
 Declare @sqlQuery varchar(4000)
 Declare @CostFormat varchar(10)
 
 if(@SupplierId<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @SupplierID
 else
	set @CostFormat=3
 
     set @sqlQuery = 'SELECT  S.StoreTransactionId ,dbo.Suppliers.SupplierName as [Supplier Name], dbo.Stores.											custom1 as Banner, dbo.Stores.StoreName as Store,
                      dbo.Stores.Custom2 as [SBT Number], dbo.Stores.StoreIdentifier as [Store No],
                      dbo.Products.ProductName as [Product Name], dbo.ProductIdentifiers.IdentifierValue as UPC, 
					  convert(varchar(10), S.SaleDateTime, 101) as [Transaction Date], 
					  S.Qty as [Quantity],
					  cast(S.rulecost as decimal(10,' + @CostFormat + ')) as Cost, 
					  S.Promoallowance as Promo 
					  FROM dbo.Chains INNER JOIN
                      datatrue_report.dbo.StoreTransactions S ON dbo.Chains.ChainID = S.ChainID INNER JOIN
                      dbo.Stores ON S.StoreID = dbo.Stores.StoreID INNER JOIN
                      dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
                      dbo.Brands ON S.BrandID = dbo.Brands.BrandID INNER JOIN
                      dbo.Suppliers ON dbo.Suppliers.SupplierID = S.SupplierID inner join
                      dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID  and ProductIdentifiers.ProductIdentifierTypeId in (2,8)
                      WHERE  1=1 '

    if(@ChainId <>'-1')
        set @sqlQuery = @sqlQuery +  ' and dbo.chains.ChainID=' + @ChainId
 
    if(@SupplierID <>'-1')
        set @sqlQuery = @sqlQuery +  ' and Suppliers.SupplierId=' + @SupplierId
 
    if(@custom1='')
        set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'
    else if(@custom1<>'-1')
        set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''
 
    if(@ActivityType <>'-1')
        set @sqlQuery = @sqlQuery +  ' and S.TransactionTypeID in (' + @ActivityType + ')'
   
    if(@BrandId<>'-1')
        set @sqlQuery = @sqlQuery +  ' and Brands.BrandId=' + @BrandId
 
       
    if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and S.SaleDateTime  >= ''' + @TransFromDate  + ''''
 
    if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and S.SaleDateTime  <=''' + @TransToDate  + ''''

    if(@ProductIdentifierValue<>'')
		 begin

				--if(@ProductIdentifierType<>3)
				--	set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
				
				if(@ProductIdentifierType=2)
					set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.ProductIdentifierTypeId in (2,8)'
				else if(@ProductIdentifierType<>3)
					set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
				
				-- 2 = UPC, 3 = Product Name 
				if (@ProductIdentifierType=2)
					 set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
			         
				else if (@ProductIdentifierType=3)
					set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @ProductIdentifierValue + '%'''
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
    set @sqlQuery = @sqlQuery +  ' order by saledatetime asc, upc desc     '
	
	print @sqlQuery
	
	execute(@sqlQuery);
	
End
GO
