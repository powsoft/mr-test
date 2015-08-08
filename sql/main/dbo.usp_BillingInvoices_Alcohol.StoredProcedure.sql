USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_BillingInvoices_Alcohol]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_BillingInvoices_Alcohol '50964','73507','-1','2','','1900-01-01','1900-01-01','','1','','1','','1','1900-01-01','','','',''
CREATE procedure [dbo].[usp_BillingInvoices_Alcohol]

@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@InvoiceTypeId varchar(10),
@InvoiceNumber varchar(255),
@SaleFromDate varchar(50),
@SaleToDate varchar(50),
@ProductIdentifierType int,
@ProductIdentifierValue varchar(50),
@StoreIdentifierType int,
@StoreIdentifierValue varchar(50),
@OtherOption int,
@Others varchar(50),
@PaymentDueDate varchar(50),
@FromInvoiceNumber varchar(255),
@ToInvoiceNumber varchar(255),
@RetailerInvoiceNumber varchar(255),
@SupplierInvoiceNumber varchar(255)
as

Begin

Declare @sqlQuery varchar(8000)
Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1')
 if (Exists(Select  Costformat  from SupplierFormat with(nolock)  where SupplierID = @supplierID))
	Select @CostFormat = Costformat  from SupplierFormat with(nolock)  where SupplierID = @supplierID
	else 
	set @CostFormat=4
 else
	set @CostFormat=4
	 
	
 
set @sqlQuery = 'SELECT dbo.Suppliers.SupplierID as [Supplier No], 
					dbo.Suppliers.SupplierName as [Supplier Name], 
					dbo.Chains.ChainName as [Chain Name], 
					dbo.Stores.StoreName as [Store Name], 
					dbo.stores.storeidentifier as [Store No] , 
					dbo.Stores.Custom2 as [SBT Number],
                    dbo.Stores.custom1 as Banner,
					dbo.Brands.BrandName as Brand, 
					dbo.Products.ProductName as Product,  
					ProductIdentifiers.IdentifierValue as [UPC],
					CASE WHEN ISNULL(ProductIdentifiers.IdentifierValue,''DEFAULT'') = ''DEFAULT'' OR (ProductIdentifiers.IdentifierValue = '''')
						 THEN I.RawProductIdentifier
						 ELSE ProductIdentifiers.IdentifierValue END AS [Supplier Raw UPC],
					I.VIN as [Vendor Item Number],'

if(@SupplierId=40558)                   
    set @sqlQuery = @sqlQuery + '''01'' as [Issue Code],'

    set @sqlQuery = @sqlQuery + ' dbo.InvoiceDetailTypes.InvoiceDetailTypeName as [Invoice Type], 
					I.RetailerInvoiceID as [IC Retailer Invoice No], 
					I.SupplierInvoiceID as [IC Supplier Invoice No], 
					I.InvoiceNo as [Invoice No],  
					I.TotalQty as [Total Qty], 
					I.PromoAllowance as [Allowance],
					cast(I.UnitCost as numeric(10,' + @CostFormat + ')) as [Unit Cost]
					, cast(I.UnitRetail as numeric(10,2)) as [Unit Retail]
					, case when dbo.Suppliers.IsRegulated=1 then 
					  cast(isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0) as numeric(10,' + @CostFormat + ')) 
					  else 0 end as [Adjustment]
					, cast((I.TotalQty * I.UnitCost) + case when dbo.Suppliers.IsRegulated=1 then 
						isnull(I.Adjustment1+I.Adjustment2+I.Adjustment3+I.Adjustment4+I.Adjustment5+I.Adjustment6+I.Adjustment7+I.Adjustment8,0)
						else 0 end as numeric(10,' + @CostFormat + ')) as [Extended Cost],
                    convert(varchar(10), I.SaleDate,101) as [Sale Date],
                    convert(varchar(10), I.PaymentDueDate,101) as [Payment Due Date]
                    , WH.WarehouseName as [Distribution Center]
					, SUV.RegionalMgr as [Regional Manager]
					, SUV.SalesRep as [Sales Representative]
					, SUV.supplieraccountnumber as [Supplier Acct Number]
					, SUV.DriverName as [Driver Name]
					, SUV.RouteNumber as [Route Number]  
					, dbo.Stores.Custom4 as [Alternative Store #]
                    
            FROM    dbo.Stores  with(nolock) 
					INNER JOIN dbo.Chains with(nolock)  ON dbo.Stores.ChainID = dbo.Chains.ChainID 
					INNER JOIN dbo.InvoiceDetails I  with(nolock) ON dbo.Stores.StoreID = I.StoreID AND dbo.Chains.ChainID = I.ChainID 
                    INNER JOIN dbo.Suppliers with(nolock)  ON I.SupplierID = dbo.Suppliers.SupplierID 
                    INNER JOIN dbo.InvoiceDetailTypes  with(nolock) ON I.InvoiceDetailTypeID = dbo.InvoiceDetailTypes.InvoiceDetailTypeID 
                    INNER JOIN dbo.Products  with(nolock) ON I.ProductID = dbo.Products.ProductID 
            --        INNER JOIN dbo.ProductIdentifiers with(nolock)  ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID 
											 --and (dbo.ProductIdentifiers.ProductIdentifierTypeId = case when dbo.Suppliers.isRegulated = 1 then 3 else 2 end  
											 --or dbo.ProductIdentifiers.ProductIdentifierTypeId = case when dbo.Suppliers.isRegulated = 1  then 3 else 8 end)
											 -- AND dbo.ProductIdentifiers.OwnerEntityId=(case when dbo.Suppliers.isRegulated = 1 then  Suppliers.SupplierID  else dbo.ProductIdentifiers.OwnerEntityId end )
					INNER JOIN (SELECT DISTINCT pd.ProductID
									  , pd.IdentifierValue
									  , pd.ProductIdentifierTypeID
									  , id.ChainID
									  , SupplierID
						FROM
							ProductIdentifiers pd
							INNER JOIN InvoiceDetails id
								ON id.ProductID = pd.ProductID AND ProductIdentifierTypeID = 2
						UNION ALL
						SELECT DISTINCT pd.ProductID
									  , pd.IdentifierValue
									  , pd.ProductIdentifierTypeID
									  , id.ChainID
									  , SupplierID
						FROM
							ProductIdentifiers pd
							INNER JOIN InvoiceDetails id
								ON id.ProductID = pd.ProductID 
								AND ProductIdentifierTypeID = 3 
								AND id.ProductID NOT IN (SELECT DISTINCT id.ProductID
														 FROM
															ProductIdentifiers pd
															INNER JOIN InvoiceDetails id
																ON id.ProductID = pd.ProductID AND ProductIdentifierTypeID = 2)) ProductIdentifiers
				ON ProductIdentifiers.ProductID = dbo.Products.ProductID AND ProductIdentifiers.ChainID = dbo.Chains.ChainID AND ProductIdentifiers.SupplierID = dbo.Suppliers.SupplierID								 
                    INNER JOIN SupplierBanners SB with(nolock)  on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 
					INNER JOIN dbo.ProductIdentifierTypes  with(nolock) ON  ProductIdentifiers.ProductIdentifierTypeID = dbo.ProductIdentifierTypes.ProductIdentifierTypeID 
					LEFT OUTER JOIN  dbo.StoresUniqueValues SUV with(nolock)  ON SUV.SupplierID = I.SupplierID AND SUV.StoreID = I.StoreID
					LEFT JOIN dbo.ProductBrandAssignments PB with(nolock)  on PB.ProductID=I.ProductID and (PB.CustomOwnerEntityId=dbo.Chains.ChainID or PB.CustomOwnerEntityId=0)
					and PB.CustomOwnerEntityId= dbo.Suppliers.SupplierID 
					LEFT JOIN dbo.Brands with(nolock)  ON PB.BrandID = dbo.Brands.BrandID 
					left JOIN Warehouses WH with(nolock)  ON WH.ChainID=dbo.Chains.ChainID and WH.WarehouseId=SUV.DistributionCenter
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
    set @sqlQuery = @sqlQuery + ' and I.InvoiceNo like ''%' + @InvoiceNumber +'%'''

if(len(@FromInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and I.InvoiceNo >=''' + @FromInvoiceNumber + ''''

if(len(@ToInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and I.InvoiceNo <=''' + @ToInvoiceNumber  + ''''
    
if(len(@RetailerInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and I.RetailerInvoiceId like ''%' + @RetailerInvoiceNumber+ '%'''

if(len(@SupplierInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and I.SupplierInvoiceId like ''%' + @SupplierInvoiceNumber+ '%'''

    
if( convert(date, @SaleFromDate ) > convert(date,'1900-01-01') and convert(date, @SaleToDate ) > convert(date,'1900-01-01') )
    set @sqlQuery = @sqlQuery + ' and I.SaleDate between ''' + @SaleFromDate + ''' and ''' + @SaleToDate + '''' ;

else if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and I.SaleDate >= ''' + @SaleFromDate + '''';

else if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and I.SaleDate <= ''' + @SaleToDate + '''';

if(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and I.PaymentDueDate =''' + @PaymentDueDate + '''';    
    
if(@ProductIdentifierValue<>'')
begin

	-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
	if (@ProductIdentifierType=2)
		 set @sqlQuery = @sqlQuery + ' and  ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
         
	else if (@ProductIdentifierType=3)
		set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @ProductIdentifierValue + '%'''
		
	else if (@ProductIdentifierType=7)
		 set @sqlQuery = @sqlQuery + ' and I.VIN like ''%' + @ProductIdentifierValue + '%'''
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
        set @sqlQuery = @sqlQuery + ' and WH.WarehouseName like ''%' + @Others + '%'''
    else if (@OtherOption=2)
        set @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr like ''%' + @Others + '%'''
    else if (@OtherOption=3)
        set @sqlQuery = @sqlQuery + ' and SUV.SalesRep like ''%' + @Others + '%'''
    else if (@OtherOption=4)
        set @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber like ''%' + @Others + '%'''
    else if (@OtherOption=5)
        set @sqlQuery = @sqlQuery + ' and SUV.DriverName like ''%' + @Others + '%'''
    else if (@OtherOption=6)
        set @sqlQuery = @sqlQuery + ' and SUV.RouteNumber like ''%' + @Others + '%'''

end

set @sqlQuery = @sqlQuery + ' order by Stores.storename,convert(varchar(10), I.SaleDate,101)';
print (@sqlQuery);
exec(@sqlQuery);

End
GO
