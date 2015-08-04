USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_BillingInvoices_Alcohol_Old]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_BillingInvoices_Alcohol '40393','42255','Division1','7','','1900-01-01','1900-01-01','','1','','1','','1','1900-01-01','',''
CREATE procedure [dbo].[usp_BillingInvoices_Alcohol_Old]

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
@ToInvoiceNumber varchar(255)
as

Begin

Declare @sqlQuery varchar(4000)
Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
 else
	set @CostFormat=4

set @sqlQuery = 'SELECT dbo.Suppliers.SupplierID as [Supplier No], dbo.Suppliers.SupplierName as [Supplier Name], dbo.Chains.ChainName as [Chain Name], dbo.Stores.StoreName as [Store Name], dbo.stores.storeidentifier as [Store No] , dbo.Stores.Custom2 as [SBT Number],
                    dbo.Stores.custom1 as Banner,dbo.Brands.BrandName as Brand, dbo.Products.ProductName as Product, dbo.ProductIdentifiers.IdentifierValue as [UPC], PD.IdentifierValue as [Vendor Item Number],'

if(@SupplierId=40558)                   
    set @sqlQuery = @sqlQuery + '''01'' as [Issue Code],'

    set @sqlQuery = @sqlQuery + ' dbo.InvoiceDetailTypes.InvoiceDetailTypeName as [Invoice Type], 
					dbo.InvoiceDetails.RetailerInvoiceID as [Invoice No], dbo.InvoiceDetails.TotalQty as [Total Qty], 
					dbo.InvoiceDetails.PromoAllowance as [Allowance],
					cast(dbo.InvoiceDetails.UnitCost as numeric(10,' + @CostFormat + ')) as [Unit Cost], 
					cast(dbo.InvoiceDetails.UnitRetail as numeric(10,2)) as [Unit Retail], 
                    cast((dbo.InvoiceDetails.[UnitCost] -isnull(dbo.InvoiceDetails.PromoAllowance,0))*dbo.InvoiceDetails.TotalQty as numeric(10,' + @CostFormat + ')) as [Total Cost],
                    cast((dbo.InvoiceDetails.[UnitRetail])*dbo.InvoiceDetails.TotalQty as numeric(10,2))  as [Total Retail], 
                    convert(varchar(10), dbo.InvoiceDetails.SaleDate,101) as [Sale Date],
                    convert(varchar(10), dbo.InvoiceDetails.PaymentDueDate,101) as [Payment Due Date],
                    WH.WarehouseName as [Distribution Center], SUV.RegionalMgr as [Regional Manager], SUV.SalesRep as [Sales Representative],
                    SUV.supplieraccountnumber as [Customer Number], SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number]
            FROM    dbo.Stores INNER JOIN
                    dbo.Chains ON dbo.Stores.ChainID = dbo.Chains.ChainID INNER JOIN
                    dbo.InvoiceDetails ON dbo.Stores.StoreID = dbo.InvoiceDetails.StoreID AND dbo.Chains.ChainID = dbo.InvoiceDetails.ChainID INNER JOIN
                    dbo.Suppliers ON dbo.InvoiceDetails.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                    dbo.InvoiceDetailTypes ON dbo.InvoiceDetails.InvoiceDetailTypeID = dbo.InvoiceDetailTypes.InvoiceDetailTypeID INNER JOIN
                    dbo.Products ON dbo.InvoiceDetails.ProductID = dbo.Products.ProductID INNER JOIN
                    dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeId = 2 Left JOIN
                    dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeId = 3 and PD.OwnerEntityId=dbo.Suppliers.SupplierID INNER JOIN
                    SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 INNER JOIN
                    dbo.ProductIdentifierTypes ON dbo.ProductIdentifiers.ProductIdentifierTypeID = dbo.ProductIdentifierTypes.ProductIdentifierTypeID LEFT OUTER JOIN
                    dbo.StoresUniqueValues SUV ON SUV.SupplierID = dbo.InvoiceDetails.SupplierID AND SUV.StoreID = dbo.InvoiceDetails.StoreID
                    Left Join dbo.ProductBrandAssignments PB on PB.ProductID=dbo.InvoiceDetails.ProductID 
                    Left Join dbo.Brands ON PB.BrandID = dbo.Brands.BrandID 
                    Left JOIN Warehouses WH ON WH.ChainID=Chains.ChainID and WH.WarehouseId=SUV.DistributionCenter
            WHERE   1=1'

if(@ChainId<>'-1')
    set @sqlQuery = @sqlQuery + ' and Chains.ChainID=' + @ChainId

if(@SupplierId<>'-1')
    set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId=' + @SupplierId

if(@BannerId<>'-1')
    set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @BannerId + ''''

if(@InvoiceTypeId<>'-1')
    set @sqlQuery = @sqlQuery + ' and InvoiceDetailTypes.InvoiceDetailTypeID=' + @InvoiceTypeId

if(len(@InvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.RetailerInvoiceId =' + @InvoiceNumber

if(len(@FromInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.RetailerInvoiceId >=' + @FromInvoiceNumber

if(len(@ToInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.RetailerInvoiceId <=' + @ToInvoiceNumber  
    
if( convert(date, @SaleFromDate ) > convert(date,'1900-01-01') and convert(date, @SaleToDate ) > convert(date,'1900-01-01') )
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.SaleDate between ''' + @SaleFromDate + ''' and ''' + @SaleToDate + '''' ;

else if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.SaleDate between ''' + @SaleFromDate + '''';

else if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and ''' + @SaleToDate + '''';

if(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.PaymentDueDate =''' + @PaymentDueDate + '''';    
    
if(@ProductIdentifierValue<>'')
begin

	-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
	if (@ProductIdentifierType=2)
		 set @sqlQuery = @sqlQuery + ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
         
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

set @sqlQuery = @sqlQuery + ' order by Stores.storename,convert(varchar(10), dbo.InvoiceDetails.SaleDate,101)';
print(@sqlQuery);
exec(@sqlQuery);

End
GO
