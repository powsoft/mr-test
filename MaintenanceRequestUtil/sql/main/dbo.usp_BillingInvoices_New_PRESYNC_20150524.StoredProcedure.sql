USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_BillingInvoices_New_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_BillingInvoices_New '62362','26922','Double Quick','-1','','08/12/2013','08/18/2014','2','','1','','1','','1900-01-01','','','','','dbo.stores.storeidentifier','1','1525225','0','1900-01-01'

-- exec [usp_BillingInvoices_New_Aggregation] '75221','26673','Maverik','-1','','1900-01-01','1900-01-01',2,'',1,'','1','','1900-01-01','','','','','','','dbo.stores.storeidentifier ASC',0,0,0,'1900-01-01','1900-01-01','-1','1','1900-01-01','WeekEndDate','1'

CREATE procedure [dbo].[usp_BillingInvoices_New_PRESYNC_20150524]

@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@InvoiceTypeId varchar(10),
@InvoiceNumber varchar(255),
@SaleFromDate varchar(50),
@SaleToDate varchar(50),
@ProductIdentIFierType int,
@ProductIdentIFierValue varchar(250),
@StoreIdentIFierType int,
@StoreIdentIFierValue varchar(250),
@OtherOption varchar(50),
@Others varchar(250),
@PaymentDueDate varchar(50),
@FromInvoiceNumber varchar(255),
@ToInvoiceNumber varchar(255),
@SupplierInvoiceNumber varchar(255),
@RetailerInvoiceNumber varchar(255),
@SupplierIdentIFierValue varchar(20),
@RetailerIdentIFierValue varchar(20),
@OrderBy varchar(100),
@StartIndex int,
@PageSize int,
@DisplayMode int,
@FromInvoiceDate varchar(50),
@ToInvoiceDate varchar(50),
@RegulatedSupplier varchar(10),
@ChainUser varchar(10),
@WeekEND varchar(50),
@ViewBy varchar(20),
@AggregateBy varchar(10)
AS

BEGIN
	Declare @sqlQuery varchar(8000)
	Declare @CostFormat varchar(10)

	 IF(@supplierID<>'-1')
		SELECT @CostFormat = Costformat FROM SupplierFormat WITH(NOLOCK) WHERE SupplierID = @supplierID
	 ELSE IF(@ChainId<>'-1')
		SELECT @CostFormat = Costformat FROM SupplierFormat WITH(NOLOCK) WHERE SupplierID = @ChainId
	 ELSE
		SET @CostFormat=4
	
	SET @CostFormat=isnull(@costFormat,4)
	
	SET @sqlQuery = 'SELECT dbo.Suppliers.SupplierID as [Supplier No]
					, dbo.Suppliers.SupplierName as [Supplier Name]
					, dbo.Chains.ChainName as [Chain Name]
					, dbo.Brands.BrandName as Brand '
					
   IF(@AggregateBy = '0')					
	 SET @sqlQuery += ' , dbo.Stores.StoreName as [Store Name]
						, dbo.stores.storeidentIFier as [Store No] 
						, dbo.Stores.Custom2 as [SBT Number]
						, dbo.Stores.custom1 as Banner
						, dbo.Products.ProductName as Product
						, case 
								when P1.IdentIFierValue is not null then 
									P1.IdentIFierValue 
								when I.ProductIdentIFier is not null then
									I.ProductIdentIFier
								ELSE 
									(Select top 1 E.ProductIdentIFier from ProductsSuppliersItemsConversion E with (nolock) where dbo.Products.ProductID=E.ProductID and E.SupplierId=Suppliers.SupplierId) 
						  END as [UPC]
						, CASE WHEN ISNULL(P1.IdentIFierValue,''DEFAULT'') = ''DEFAULT'' OR (P1.IdentIFierValue = '''')
							   THEN I.RawProductIdentIFier
							   ELSE P1.IdentIFierValue END AS [Supplier Raw UPC]
						, case when I.VIN is not null then I.VIN ELSE 
						 (select top 1 C.SupplierProductID from DataTrue_CustomResultSETs.dbo.tmpProductsSuppliersItemsConversion C with (nolock) where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) END as [Vendor Item Number] 
						, dbo.InvoiceDetailTypes.InvoiceDetailTypeName as [Invoice Type]
						, I.InvoiceNo as [Invoice No]
						, I.RetailerInvoiceID as [IC Retailer Invoice No]
						, I.SupplierInvoiceID as [IC Supplier Invoice No]
						, convert(varchar(10), R.InvoiceDate, 101) as [Invoice Creation Date]
						, convert(varchar(10), I.PaymentDueDate,101) as [Payment Due Date] '
						
	ELSE IF(@AggregateBy = '1')
		SET @sqlQuery += '  , dbo.Products.ProductName as Product
							, case 
									when P1.IdentIFierValue is not null then 
										P1.IdentIFierValue 
									when I.ProductIdentIFier is not null then
										I.ProductIdentIFier
									ELSE 
										(Select top 1 E.ProductIdentIFier from ProductsSuppliersItemsConversion E with (nolock) where dbo.Products.ProductID=E.ProductID and E.SupplierId=Suppliers.SupplierId) 
							  END as [UPC]
							, CASE WHEN ISNULL(P1.IdentIFierValue,''DEFAULT'') = ''DEFAULT'' OR (P1.IdentIFierValue = '''')
								   THEN I.RawProductIdentIFier
								   ELSE P1.IdentIFierValue END AS [Supplier Raw UPC]
							, case when I.VIN is not null then I.VIN ELSE 
							 (select top 1 C.SupplierProductID from DataTrue_CustomResultSETs.dbo.tmpProductsSuppliersItemsConversion C with (nolock) where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) END as [Vendor Item Number] '
	ELSE IF (@AggregateBy='2')
		SET @sqlQuery += '  , dbo.Stores.StoreName as [Store Name]
							, dbo.stores.storeidentIFier as [Store No] 
							, dbo.Stores.Custom2 as [SBT Number]
							, dbo.Stores.custom1 as Banner '
   
   IF(@SupplierId=40558)                   
		SET @sqlQuery = @sqlQuery + ',''01'' as [Issue Code]'

	--SET @sqlQuery = @sqlQuery + ' ,dbo.InvoiceDetailTypes.InvoiceDetailTypeName as [Invoice Type]
	--				, I.InvoiceNo as [Invoice No]
	--				, I.RetailerInvoiceID as [IC Retailer Invoice No]
	--				, I.SupplierInvoiceID as [IC Supplier Invoice No]
	--				, convert(varchar(10), R.InvoiceDate, 101) as [Invoice Creation Date] '
					
	IF (@ViewBy = 'SaleDate')
		SET @sqlQuery = @sqlQuery + ' , cast(I.TotalQty as numeric(10,' + @CostFormat + ')) as [Total Qty]
					, cast(I.PromoAllowance as numeric(10,' + @CostFormat + ')) as [Allowance]
					, cast(I.UnitCost as numeric(10,' + @CostFormat + ')) as [Unit Cost]
					, cast(I.UnitRetail as numeric(10,' + @CostFormat + ')) as [Unit Retail]
					, cast((I.[UnitCost] -isnull(I.PromoAllowance,0))*I.TotalQty as numeric(10,' + @CostFormat + ')) as [Total Cost]
					, cast((I.[UnitRetail])*I.TotalQty as numeric(10,' + @CostFormat + '))  as [Total Retail]
					, case when dbo.Suppliers.IsRegulated=0 and ' + @ChainUser + '=0 then 0 
					  ELSE cast(isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0) as numeric(10,' + @CostFormat + ')) 
					  END as [Adjustment]
					, cast((I.TotalQty * (I.[UnitCost] -isnull(I.PromoAllowance,0))) + case when dbo.Suppliers.IsRegulated=0 and ' + @ChainUser + '=0 then 0  
						ELSE isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0)
						END as numeric(10,' + @CostFormat + ')) as [Extended Cost]
					, convert(varchar(10), I.SaleDate,101) as [Sale Date] '
	ELSE IF (@ViewBy = 'WeekEndDate')
		SET @sqlQuery = @sqlQuery + ' , SUM(cast(I.TotalQty as numeric(10,' + @CostFormat + '))) as [Total Qty]
					, SUM(cast(I.PromoAllowance as numeric(10,' + @CostFormat + '))) as [Allowance]
					, cast(I.UnitCost as numeric(10,' + @CostFormat + ')) as [Unit Cost]
					, cast(I.UnitRetail as numeric(10,' + @CostFormat + ')) as [Unit Retail]
					, SUM(cast((I.[UnitCost] -isnull(I.PromoAllowance,0))*I.TotalQty as numeric(10,' + @CostFormat + '))) as [Total Cost]
					, SUM(cast((I.[UnitRetail])*I.TotalQty as numeric(10,' + @CostFormat + ')))  as [Total Retail]
					, case when dbo.Suppliers.IsRegulated=0 and 1=0 then 0 
					  else SUM(cast(isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0) as numeric(10,' + @CostFormat + '))) 
					  end as [Adjustment]
					, cast (sum((I.TotalQty * (I.[UnitCost] -isnull(I.PromoAllowance,0)))) + case when dbo.Suppliers.IsRegulated=0 and 1=0 then 0  
						else SUM(isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0))
						end as numeric(10,' + @CostFormat + ')) as [Extended Cost]
					, Convert(varchar(12),dbo.GetWeekEnd(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) AS [Week End]  '
					
	SET @sqlQuery = @sqlQuery + ' , I.UOM as [Unit Of Measure]
					, I.RefIDToOriginalInvNo as [Invoice Aggregator Number] '
	
	IF(@AggregateBy <> '1')
		SET @sqlQuery += '  , WH.WarehouseName as [Distribution Center]
							, SUV.RegionalMgr as [Regional Manager]
							, SUV.SalesRep as [Sales Representative]
							, case when dbo.Suppliers.IsRegulated=1 and (select count(SupplierAccountNumber) from StoresUniqueValues where StoreID=I.StoreID and SupplierID=I.SupplierID)>1 
								then I.RawStoreIdentIFier 
							  ELSE (select distinct top 1 SupplierAccountNumber from StoresUniqueValues where StoreID=I.StoreID and SupplierID=I.SupplierID) END as [Supplier Acct Number] 
            				, SUV.DriverName as [Driver Name]
							, SUV.RouteNumber as [Route Number] 
							, dbo.Stores.Custom4 as [Alternative Store #]' 
							
	SET @sqlQuery += '  FROM  dbo.Stores  with(nolock) 
					INNER JOIN dbo.Chains  with(nolock) ON dbo.Stores.ChainID = dbo.Chains.ChainID 
					INNER JOIN dbo.InvoiceDetails I  with(nolock) ON dbo.Stores.StoreID = I.StoreID AND dbo.Chains.ChainID = I.ChainID 
					inner join InvoicesRetailer R with(nolock)  on I.RetailerInvoiceID=R.RetailerInvoiceID
					INNER JOIN dbo.Suppliers  with(nolock) ON I.SupplierID = dbo.Suppliers.SupplierID 
					INNER JOIN dbo.InvoiceDetailTypes with(nolock)  ON I.InvoiceDetailTypeID = dbo.InvoiceDetailTypes.InvoiceDetailTypeID 
					INNER JOIN dbo.Products  with(nolock) ON I.ProductID = dbo.Products.ProductID
					INNER JOIN SupplierBanners SB with(nolock)  on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 
					Left JOIN dbo.ProductIdentIFiers P1 with(nolock)  ON dbo.Products.ProductID = P1.ProductID and P1.ProductIdentIFierTypeId =2
					--Left JOIN dbo.ProductIdentIFiers P2 with(nolock)  ON dbo.Products.ProductID = P2.ProductID and P2.ProductIdentIFierTypeId=8
					--Left JOIN (Select distinct ProductId, Bipad from ProductIdentIFiers P where P.ProductIdentIFierTypeID=8) P2 on P2.ProductID=dbo.products.ProductID  
					LEFT OUTER JOIN  (Select distinct SupplierId, StoreId, RouteNumber,DriverName,SalesRep,RegionalMgr,DistributionCenter  from dbo.StoresUniqueValues SUV with(nolock) ) SUV ON SUV.SupplierID = I.SupplierID AND SUV.StoreID = I.StoreID
					LEFT JOIN dbo.ProductBrandAssignments PB with(nolock)  on PB.ProductID=I.ProductID and (PB.CustomOwnerEntityId=dbo.Chains.ChainID or PB.CustomOwnerEntityId=0)
					and PB.CustomOwnerEntityId= dbo.Suppliers.SupplierID and PB.BrandId>0
					LEFT JOIN dbo.Brands ON PB.BrandID = dbo.Brands.BrandID 
					left JOIN Warehouses WH ON WH.ChainID=dbo.Chains.ChainID and WH.WarehouseId=SUV.DistributionCenter
					
        WHERE   1=1 '

	IF(@ChainId<>'-1')
		SET @sqlQuery = @sqlQuery + ' and Chains.ChainID=' + @ChainId

	IF(@SupplierId<>'-1')
		SET @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId=' + @SupplierId

	IF(@BannerId<>'-1')
		SET @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @BannerId + ''''

	IF(@InvoiceTypeId<>'-1')
		SET @sqlQuery = @sqlQuery + ' and InvoiceDetailTypes.InvoiceDetailTypeID=' + @InvoiceTypeId

	IF(len(@InvoiceNumber)>0)
	   SET @sqlQuery = @sqlQuery + ' and I.InvoiceNo ' + @InvoiceNumber 

	IF(len(@FromInvoiceNumber)>0)
		SET @sqlQuery = @sqlQuery + ' and I.InvoiceNo >=''' + @FromInvoiceNumber + ''''

	IF(len(@ToInvoiceNumber)>0)
		SET @sqlQuery = @sqlQuery + ' and I.InvoiceNo <=''' + @ToInvoiceNumber  + ''''

	IF(@SupplierInvoiceNumber<>'')
	  SET @sqlQuery = @sqlQuery + ' and I.SupplierInvoiceID ' + @SupplierInvoiceNumber 
	  
	IF(@RetailerInvoiceNumber<>'')
		SET @sqlQuery = @sqlQuery + ' and I.RetailerInvoiceID ' + @RetailerInvoiceNumber  
	    
	IF (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and I.SaleDate >= ''' + @SaleFromDate + '''';

	IF(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and I.SaleDate <=''' + @SaleToDate + '''';

	IF(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and I.PaymentDueDate =''' + @PaymentDueDate + '''';   

	IF(convert(date, @FromInvoiceDate ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and convert(date,R.InvoiceDate,101) >= convert(date,''' + @FromInvoiceDate + ''',101)';   

	IF(convert(date, @ToInvoiceDate ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and convert(date,R.InvoiceDate,101) <= convert(date,''' + @ToInvoiceDate + ''',101)';     
	    
	IF(convert(date, @WeekEND ) > convert(date,'1900-01-01'))
		SET @sqlQuery = @sqlQuery + ' and Convert(varchar(12),dbo.getweekEND(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) = ''' + @WeekEND + '''';       


	IF(@SupplierIdentIFierValue<>'')
		SET @sqlQuery = @sqlQuery + ' and dbo.Suppliers.SupplierIdentIFier like ''%' + @SupplierIdentIFierValue + '%'''
			
	IF(@RetailerIdentIFierValue<>'')
		SET @sqlQuery = @sqlQuery + ' and dbo.Chains.ChainIdentIFier like ''%' + @RetailerIdentIFierValue + '%'''
			    
	IF(@ProductIdentIFierValue<>'')
		BEGIN
			-- 2 = UPC, 3 = Product Name , 7 = VENDor Item Number,8=bipad
			IF (@ProductIdentIFierType=2)
				 SET @sqlQuery = @sqlQuery + ' and  case when P1.IdentIFierValue is not null then P1.IdentIFierValue ELSE (Select E.ProductIdentIFier from ProductsSuppliersItemsConversion E where dbo.Products.ProductID=E.ProductID and E.SupplierId=Suppliers.SupplierId) END ' + @ProductIdentIFierValue 
		         
			ELSE IF (@ProductIdentIFierType=3)
				SET @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName ' + @ProductIdentIFierValue
				
			ELSE IF (@ProductIdentIFierType=7)
				 SET @sqlQuery = @sqlQuery + '  and case when P1.ProductIdentIFierTypeId=2 then I.VIN ELSE 
						 (select C.SupplierProductID from DataTrue_CustomResultSETs.dbo.tmpProductsSuppliersItemsConversion C  with(nolock) 
							where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) END  ' + @ProductIdentIFierValue 
							
			ELSE IF (@ProductIdentIFierType=8)
				SET @sqlQuery = @sqlQuery + ' and P1.Bipad ' + @ProductIdentIFierValue				
		END

	IF(@StoreIdentIFierValue<>'')
		BEGIN
				-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
				IF (@StoreIdentIFierType=1)
						SET @sqlQuery = @sqlQuery + ' and stores.storeidentIFier ' + @StoreIdentIFierValue 
				ELSE IF (@StoreIdentIFierType=2)
						SET @sqlQuery = @sqlQuery + ' and stores.Custom2 ' + @StoreIdentIFierValue 
				ELSE IF (@StoreIdentIFierType=3)
						SET @sqlQuery = @sqlQuery + ' and stores.StoreName ' + @StoreIdentIFierValue 
		END

	IF(@Others<>'')
		BEGIN
				-- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
				-- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
		                         
				IF (@OtherOption=1)
						SET @sqlQuery = @sqlQuery + ' and WH.WarehouseName ' + @Others 
				ELSE IF (@OtherOption=2)
						SET @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr ' + @Others
				ELSE IF (@OtherOption=3)
						SET @sqlQuery = @sqlQuery + ' and SUV.SalesRep ' + @Others
				--ELSE IF (@OtherOption=4)
				--		SET @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber ' + @Others
				ELSE IF (@OtherOption=5)
						SET @sqlQuery = @sqlQuery + ' and SUV.DriverName ' + @Others
				ELSE IF (@OtherOption=6)
						SET @sqlQuery = @sqlQuery + ' and SUV.RouteNumber ' + @Others

		END

	IF(@RegulatedSupplier <> '-1')
	BEGIN	
		if(@RegulatedSupplier = '2')
			set @sqlQuery = @sqlQuery + ' and I.RecordType = 2 '
		else if(@RegulatedSupplier = '3')
			set @sqlQuery = @sqlQuery + ' and I.RecordType <> 2 and Suppliers.IsRegulated =0 '
		else 
			set @sqlQuery = @sqlQuery + ' and Suppliers.IsRegulated=' + @RegulatedSupplier
	END
			
	
	IF(@ViewBy = 'WeekEndDate')
		BEGIN
			SET @sqlQuery = @sqlQuery + ' GROUP BY dbo.Suppliers.SupplierID , dbo.Suppliers.SupplierName , dbo.Chains.ChainName , dbo.Brands.BrandName '
				
			IF(@AggregateBy = '0')
				SET @sqlQuery += '  , dbo.Stores.StoreName , dbo.stores.storeidentifier, dbo.Stores.Custom2  , dbo.Stores.custom1 , I.StoreID  , dbo.Stores.Custom4 
									, dbo.Products.ProductName , I.ProductIdentifier , dbo.Products.ProductID , P1.IdentifierValue , I.RawProductIdentifier , I.VIN 
									, dbo.InvoiceDetailTypes.InvoiceDetailTypeName , I.InvoiceNo, I.RetailerInvoiceID , I.SupplierInvoiceID , convert(varchar(10), R.InvoiceDate, 101)  
									, convert(varchar(10), I.PaymentDueDate,101)'
			
			ELSE IF (@AggregateBy = '1')
				SET @sqlQuery += ' , dbo.Products.ProductName , I.ProductIdentifier , dbo.Products.ProductID , P1.IdentifierValue , I.VIN , I.RawProductIdentifier  '
			
			ELSE IF(@AggregateBy = '2')
				SET @sqlQuery += '  , dbo.Stores.StoreName , dbo.stores.storeidentifier, dbo.Stores.Custom2 , dbo.Stores.custom1 , I.StoreID  , dbo.Stores.Custom4 , I.StoreID  , dbo.Stores.Custom4  '
			
			IF(@AggregateBy <> '1')
				SET @sqlQuery += ' , WH.WarehouseName  , SUV.RegionalMgr  , SUV.SalesRep  , SUV.DriverName , SUV.RouteNumber , dbo.Suppliers.IsRegulated '
			
			
			SET @sqlQuery += '	, Convert(varchar(12),dbo.GetWeekEnd(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101), I.RawStoreIdentifier , I.UOM 
								, I.UnitCost  , I.UnitRetail, I.Supplierid  , I.RefIDToOriginalInvNo  '
		END
		
	IF(@ViewBy = 'SaleDate')
		SET @sqlQuery = @sqlQuery + ' order by convert(varchar(10), I.SaleDate,101)';
	ELSE IF(@ViewBy = 'WeekEndDate')
		SET @sqlQuery = @sqlQuery + ' order by Convert(varchar(12),dbo.getweekEND(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101)';
		
	PRINT(@sqlQuery);
	EXEC (@sqlQuery);
END
GO
