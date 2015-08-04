USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_BillingInvoices_Supplier_13April2015]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [usp_BillingInvoices_Supplier] '50964','50729','-1','-1','','1900-01-01','1900-01-01',2,'',1,'','1','','1900-01-01','','','','','','','dbo.stores.storeidentifier ASC',0,0,0,'1900-01-01','1900-01-01','-1','1','1900-01-01','SaleDate'
-- [usp_BillingInvoices_Supplier] '50964','50729','-1','-1','','1900-01-01','1900-01-01',2,'',1,'','1','','1900-01-01','','','','','','','dbo.stores.storeidentifier ASC',0,0,0,'1900-01-01','1900-01-01','-1','1','1900-01-01','WeekEndDate'

CREATE procedure [dbo].[usp_BillingInvoices_Supplier_13April2015]

@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@InvoiceTypeId varchar(10),
@InvoiceNumber varchar(255),
@SaleFromDate varchar(50),
@SaleToDate varchar(50),
@ProductIdentifierType int,
@ProductIdentifierValue varchar(250),
@StoreIdentifierType int,
@StoreIdentifierValue varchar(250),
@OtherOption varchar(50),
@Others varchar(250),
@PaymentDueDate varchar(50),
@FromInvoiceNumber varchar(255),
@ToInvoiceNumber varchar(255),
@SupplierInvoiceNumber varchar(255),
@RetailerInvoiceNumber varchar(255),
@SupplierIdentifierValue varchar(10),
@RetailerIdentifierValue varchar(10),
@OrderBy varchar(100),
@StartIndex int,
@PageSize int,
@DisplayMode int,
@FromInvoiceDate varchar(50),
@ToInvoiceDate varchar(50),
@RegulatedSupplier varchar(10),
@ChainUser varchar(10),
@WeekEnd varchar(50),
@ViewBy varchar(20)
as

Begin

Declare @sqlQuery varchar(8000)
Declare @CostFormat varchar(10)

	 if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else if(@ChainId<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @ChainId
	 else
		set @CostFormat=4
	
	set @CostFormat=isnull(@costFormat,4)
	
	set @sqlQuery = 'SELECT dbo.Suppliers.SupplierID as [Supplier No]
					, dbo.Suppliers.SupplierName as [Supplier Name]
					, dbo.Chains.ChainName as [Chain Name]
					, dbo.Stores.StoreName as [Store Name]
					, dbo.stores.storeidentifier as [Store No]
					, dbo.Stores.Custom2 as [SBT Number]
					, dbo.Stores.custom1 as Banner
					, dbo.Brands.BrandName as Brand
					, dbo.Products.ProductName as Product
					, P1.IdentifierValue  AS UPC
					--, case when P1.IdentifierValue is not null then P1.IdentifierValue else (Select E.ProductIdentifier from ProductsSuppliersItemsConversion E  with(nolock) where dbo.Products.ProductID=E.ProductID and E.SupplierId=Suppliers.SupplierId) end as [UPC]
					--, case when P1.ProductIdentifierTypeId=2 then I.VIN else  (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C with(nolock) where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end as [Vendor Item Number]
					, I.VIN  as [Vendor Item Number] '
   if(@SupplierId=40558)                   
		set @sqlQuery = @sqlQuery + ',''01'' as [Issue Code]'

	set @sqlQuery = @sqlQuery + ' ,dbo.InvoiceDetailTypes.InvoiceDetailTypeName as [Invoice Type]
					, I.InvoiceNo as [Invoice No]
					, I.RetailerInvoiceID as [IC Retailer Invoice No]
					, cast(R.SupplierInvoiceId as varchar) as [IC Supplier Invoice No] 
					, convert(varchar(10), R.InvoiceDate, 101) as [Invoice Date] '
	
	IF (@ViewBy = 'SaleDate')
		SET @sqlQuery = @sqlQuery + ' , cast(I.TotalQty as numeric(10,' + @CostFormat + ')) as [Total Qty]
					, cast(I.PromoAllowance as numeric(10,' + @CostFormat + ')) as [Allowance]
					, cast(I.UnitCost as numeric(10,' + @CostFormat + ')) as [Unit Cost]
					, cast(I.UnitRetail as numeric(10,' + @CostFormat + ')) as [Unit Retail]
					, cast((I.[UnitCost] -isnull(I.PromoAllowance,0))*I.TotalQty as numeric(10,' + @CostFormat + ')) as [Total Cost]
					, cast((I.[UnitRetail])*I.TotalQty as numeric(10,' + @CostFormat + '))  as [Total Retail]
					, case when dbo.Suppliers.IsRegulated=0 and ' + @ChainUser + '=0 then 0 
					  else cast(isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0) as numeric(10,' + @CostFormat + ')) 
					  end as [Adjustment]
					, cast((I.TotalQty * I.UnitCost) + case when dbo.Suppliers.IsRegulated=0 and ' + @ChainUser + '=0 then 0 
						else isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0)
						end as numeric(10,' + @CostFormat + ')) as [Extended Cost]
					, I.UOM as [Unit Of Measure]
					, convert(varchar(10), I.SaleDate,101) as [Sale Date] '
					
	ELSE IF (@ViewBy = 'WeekEndDate')
		SET @sqlQuery = @sqlQuery + ', SUM(cast(I.TotalQty as numeric(10,' + @CostFormat + '))) as [Total Qty]
					, SUM(cast(I.PromoAllowance as numeric(10,' + @CostFormat + '))) as [Allowance]
					, cast(I.UnitCost as numeric(10,' + @CostFormat + ')) as [Unit Cost]
					, cast(I.UnitRetail as numeric(10,' + @CostFormat + ')) as [Unit Retail]
					, SUM(cast((I.[UnitCost] -isnull(I.PromoAllowance,0))*I.TotalQty as numeric(10,' + @CostFormat + '))) as [Total Cost]
					, SUM(cast((I.[UnitRetail])*I.TotalQty as numeric(10,' + @CostFormat + ')))  as [Total Retail]
					, case when dbo.Suppliers.IsRegulated=0 and 1=0 then 0 
					  else SUM(cast(isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0) as numeric(10,' + @CostFormat + '))) 
					  end as [Adjustment]
					, cast (sum((I.TotalQty * I.UnitCost)) + case when dbo.Suppliers.IsRegulated=0 and 1=0 then 0  
						else SUM(isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0))
						end as numeric(10,' + @CostFormat + ')) as [Extended Cost]
					, Convert(varchar(12),dbo.GetWeekEnd(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) AS [Week End]   '
					
		SET @sqlQuery = @sqlQuery + ' , convert(varchar(10), I.PaymentDueDate,101) as [Payment Due Date]
					, WH.WarehouseName as [Distribution Center]
					, SUV.RegionalMgr as [Regional Manager]
					, SUV.SalesRep as [Sales Representative]
					, case when Suppliers.IsRegulated=1 and (select COUNT(distinct SupplierAccountNumber) from StoresUniqueValues where StoreID=I.StoreID and SupplierID=I.SupplierID)>1 
						then I.RawStoreIdentifier 
						else (select SupplierAccountNumber from StoresUniqueValues where StoreID=I.StoreID and SupplierID=I.SupplierID) end as [Supplier Acct Number]
					, SUV.DriverName as [Driver Name]
					, SUV.RouteNumber as [Route Number]  
					, dbo.Stores.Custom4 as [Alternative Store #]
					,Convert(varchar(12),dbo.getweekend(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) AS WeekEnd
					, I.RefIDToOriginalInvNo as [Invoice Aggregator Number]
					 
        FROM  dbo.Stores  with (nolock) 
					INNER JOIN dbo.Chains  with (nolock) ON dbo.Stores.ChainID = dbo.Chains.ChainID 
					INNER JOIN dbo.InvoiceDetails I  with (nolock) ON dbo.Stores.StoreID = I.StoreID AND dbo.Chains.ChainID = I.ChainID 
					inner join InvoicesSupplier R  with (nolock) on I.SupplierInvoiceID=R.SupplierInvoiceID 
					INNER JOIN dbo.Suppliers  with (nolock) ON I.SupplierID = dbo.Suppliers.SupplierID 
					INNER JOIN dbo.InvoiceDetailTypes  with (nolock) ON I.InvoiceDetailTypeID = dbo.InvoiceDetailTypes.InvoiceDetailTypeID 
					INNER JOIN dbo.Products  with (nolock) ON I.ProductID = dbo.Products.ProductID
					INNER JOIN SupplierBanners SB  with (nolock) on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 
					Left JOIN dbo.ProductIdentifiers P1  with (nolock) ON dbo.Products.ProductID = P1.ProductID and P1.ProductIdentifierTypeId=2
					--Left JOIN dbo.ProductIdentifiers P2 with(nolock)  ON dbo.Products.ProductID = P2.ProductID and P2.ProductIdentifierTypeId=8
					Left JOIN (Select distinct ProductId, Bipad from ProductIdentifiers P where P.ProductIdentifierTypeID=8) P2 on P2.ProductID=dbo.products.ProductID 
					LEFT OUTER JOIN  (Select distinct SupplierId, StoreId, RouteNumber,DriverName,SalesRep,RegionalMgr,DistributionCenter  from dbo.StoresUniqueValues SUV with(nolock) ) SUV ON SUV.SupplierID = I.SupplierID AND SUV.StoreID = I.StoreID
					LEFT JOIN dbo.ProductBrandAssignments PB  with (nolock) on PB.ProductID=I.ProductID and (PB.CustomOwnerEntityId=dbo.Chains.ChainID or PB.CustomOwnerEntityId=0)
					and PB.CustomOwnerEntityId= dbo.Suppliers.SupplierID and PB.BrandId>0
					LEFT JOIN dbo.Brands  with (nolock) ON PB.BrandID = dbo.Brands.BrandID 
					left JOIN Warehouses WH  with (nolock) ON WH.ChainID=dbo.Chains.ChainID and WH.WarehouseId=SUV.DistributionCenter
        WHERE   1=1 '

if(@ChainId<>'-1')
    set @sqlQuery = @sqlQuery + ' and Chains.ChainID=' + @ChainId

if(@SupplierId<>'-1')
    set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId=' + @SupplierId

if(@BannerId<>'-1')
    set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @BannerId + ''''

if(@InvoiceTypeId<>'-1')
    set @sqlQuery = @sqlQuery + ' and InvoiceDetailTypes.InvoiceDetailTypeID=' + @InvoiceTypeId

if(len(@InvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and I.InvoiceNo like ''%' + @InvoiceNumber + '%'''

if(len(@FromInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and I.InvoiceNo >=''' + @FromInvoiceNumber + ''''

if(len(@ToInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and I.InvoiceNo <=''' + @ToInvoiceNumber  + ''''

if(@SupplierInvoiceNumber<>'')
	set @sqlQuery = @sqlQuery + ' and R.SupplierInvoiceId like ''%' + @SupplierInvoiceNumber + '%'''    
	
if(@RetailerInvoiceNumber<>'')
	set @sqlQuery = @sqlQuery + ' and I.RetailerInvoiceID like ''%' + @RetailerInvoiceNumber + '%'''  
  
if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and I.SaleDate >= ''' + @SaleFromDate + '''';

if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and I.SaleDate <=''' + @SaleToDate + '''';

if(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and I.PaymentDueDate =''' + @PaymentDueDate + '''';    

if(convert(date, @FromInvoiceDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and convert(varchar(10),R.InvoiceDate,101)>= ''' + @FromInvoiceDate + '''';
    
if(convert(date, @ToInvoiceDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and convert(varchar(10),R.InvoiceDate,101)<= ''' + @ToInvoiceDate + '''';    
--week end
if(convert(date, @WeekEnd ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and Convert(varchar(12),dbo.getweekend(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) = ''' + @WeekEnd + '''';       


if(@SupplierIdentifierValue<>'')
	set @sqlQuery = @sqlQuery + ' and dbo.Suppliers.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
		
if(@RetailerIdentifierValue<>'')
	set @sqlQuery = @sqlQuery + ' and dbo.Chains.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
		        
if(@ProductIdentifierValue<>'')
	begin
		-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number,8=bipad
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and  P1.IdentifierValue ' + @ProductIdentifierValue 
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName ' + @ProductIdentifierValue 
			
		else if (@ProductIdentifierType=7)
			 set @sqlQuery = @sqlQuery + ' and case when P1.ProductIdentifierTypeId=2 then I.VIN else 
					 (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C 
						where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end  ' + @ProductIdentifierValue 
						
		else if (@ProductIdentifierType=8)
			set @sqlQuery = @sqlQuery + ' and P2.Bipad ' + @ProductIdentifierValue
	end

if(@StoreIdentifierValue<>'')
	begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
			if (@StoreIdentifierType=1)
					set @sqlQuery = @sqlQuery + ' and stores.storeidentifier ' + @StoreIdentifierValue
			else if (@StoreIdentifierType=2)
					set @sqlQuery = @sqlQuery + ' and stores.Custom2 ' + @StoreIdentifierValue
			else if (@StoreIdentifierType=3)
					set @sqlQuery = @sqlQuery + ' and stores.StoreName ' + @StoreIdentifierValue
	end

if(@Others<>'')
	begin
			-- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
			-- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
	                         
			if (@OtherOption=1)
					set @sqlQuery = @sqlQuery + ' and WH.WarehouseName ' + @Others 
			else if (@OtherOption=2)
					set @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr ' + @Others 
			else if (@OtherOption=3)
					set @sqlQuery = @sqlQuery + ' and SUV.SalesRep ' + @Others 
			else if (@OtherOption=4)
					set @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber ' + @Others 
			else if (@OtherOption=5)
					set @sqlQuery = @sqlQuery + ' and SUV.DriverName  ' + @Others 
			else if (@OtherOption=6)
					set @sqlQuery = @sqlQuery + ' and SUV.RouteNumber  ' + @Others 

	end
	
IF(@RegulatedSupplier <> '-1')
	BEGIN	
		if(@RegulatedSupplier = '2')
			set @sqlQuery = @sqlQuery + ' and I.RecordType = 2 '
		else if(@RegulatedSupplier = '3')
			set @sqlQuery = @sqlQuery + ' and I.RecordType <> 2 and Suppliers.IsRegulated=0  '
		else 
			set @sqlQuery = @sqlQuery + ' and Suppliers.IsRegulated=' + @RegulatedSupplier
	END
			
IF(@ViewBy = 'WeekEndDate')
		SET @sqlQuery = @sqlQuery + ' GROUP BY 
					  dbo.Suppliers.SupplierID 
					, dbo.Suppliers.SupplierName 
					, dbo.Chains.ChainName 
					, dbo.Stores.StoreName 
					, dbo.stores.storeidentifier 
					, dbo.Stores.Custom2 
					, dbo.Stores.custom1 
					, dbo.Brands.BrandName 
					, dbo.Products.ProductName 
					, P1.IdentifierValue  
					, I.VIN  
					, I.StoreID
					, I.SupplierID
					, dbo.Suppliers.IsRegulated
					, I.RawStoreIdentifier
					, dbo.InvoiceDetailTypes.InvoiceDetailTypeName 
					, I.InvoiceNo 
					, I.RetailerInvoiceID 
					, cast(R.SupplierInvoiceId as varchar) 
					, convert(varchar(10), R.InvoiceDate, 101) 
					, cast(I.UnitCost as numeric(10,4)) 
					, cast(I.UnitRetail as numeric(10,4)) 
					, Convert(varchar(12),dbo.GetWeekEnd(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) 
					, convert(varchar(10), I.PaymentDueDate,101) 
					, WH.WarehouseName 
					, SUV.RegionalMgr 
					, SUV.SalesRep 
					, SUV.DriverName 
					, SUV.RouteNumber 
					, dbo.Stores.Custom4
					, I.RefIDToOriginalInvNo
					, I.UnitCost
					, I.UnitRetail '
		
	IF(@ViewBy = 'SaleDate')
		SET @sqlQuery = @sqlQuery + ' order by Stores.storename,convert(varchar(10), I.SaleDate,101)';
	ELSE IF(@ViewBy = 'WeekEndDate')
		SET @sqlQuery = @sqlQuery + ' order by Stores.storename,Convert(varchar(12),dbo.getweekEND(I.SaleDate,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101)';

print (@sqlQuery);
exec (@sqlQuery);

End
GO
