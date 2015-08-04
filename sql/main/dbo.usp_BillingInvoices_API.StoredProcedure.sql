USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_BillingInvoices_API]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_BillingInvoices_API] '40393','40557','','','','','','',''
CREATE procedure [dbo].[usp_BillingInvoices_API]
@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@SaleFromDate varchar(50),
@SaleToDate varchar(50),
@FromInvoiceNumber varchar(255),
@ToInvoiceNumber varchar(255),
@UPC varchar(50),
@StoreNumber varchar(50)

as

Begin

Declare @sqlQuery varchar(4000)
Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
 else
	set @CostFormat=4

set @sqlQuery = 'SELECT dbo.Suppliers.SupplierID as [Supplier No], dbo.Suppliers.SupplierName as [Supplier Name], dbo.Chains.ChainName as [Chain Name], dbo.Stores.StoreName as [Store Name], dbo.stores.storeidentifier as [Store No] , dbo.Stores.Custom2 as [SBT Number],
                    dbo.Stores.custom1 as Banner,dbo.Brands.BrandName as Brand, dbo.Products.ProductName as Product, dbo.ProductIdentifiers.IdentifierValue as [UPC], PD.IdentifierValue as [Supplier Product Code],'

if(@SupplierId=40558)                   
    set @sqlQuery = @sqlQuery + '''01'' as [Issue Code],'

    set @sqlQuery = @sqlQuery + ' dbo.InvoiceDetailTypes.InvoiceDetailTypeName as [Invoice Type], 
					dbo.InvoiceDetails.RetailerInvoiceID as [Invoice No], dbo.InvoiceDetails.TotalQty as [Total Qty], 
					dbo.InvoiceDetails.PromoAllowance as [Allowance],
					cast(dbo.InvoiceDetails.UnitCost as numeric(10,' + @CostFormat + ')) as [Unit Cost], 
					cast(dbo.InvoiceDetails.UnitRetail as numeric(10,2)) as [Unit Retail], 
                    cast((dbo.InvoiceDetails.[UnitCost] -isnull(dbo.InvoiceDetails.PromoAllowance,0))*dbo.InvoiceDetails.TotalQty as numeric(10,' + @CostFormat + ')) as [Total Cost],
                    cast((dbo.InvoiceDetails.[UnitRetail])*dbo.InvoiceDetails.TotalQty as numeric(10,2))  as [Total Retail], 
                    convert(date, dbo.InvoiceDetails.SaleDate,102) as [Sale Date],
                    convert(date, dbo.InvoiceDetails.PaymentDueDate,101) as [Payment Due Date],
                    SUV.DistributionCenter as [Distribution Center], SUV.RegionalMgr as [Regional Manager], SUV.SalesRep as [Sales Representative],
                    SUV.supplieraccountnumber as [Supplier Acct Number], SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number]
            FROM    dbo.Stores INNER JOIN
                    dbo.Chains ON dbo.Stores.ChainID = dbo.Chains.ChainID INNER JOIN
                    dbo.InvoiceDetails ON dbo.Stores.StoreID = dbo.InvoiceDetails.StoreID AND dbo.Chains.ChainID = dbo.InvoiceDetails.ChainID INNER JOIN
                    dbo.Suppliers ON dbo.InvoiceDetails.SupplierID = dbo.Suppliers.SupplierID INNER JOIN
                    dbo.ProductBrandAssignments PB on PB.ProductID=dbo.InvoiceDetails.ProductID INNER JOIN 
                    dbo.Brands ON PB.BrandID = dbo.Brands.BrandID INNER JOIN
                    dbo.InvoiceDetailTypes ON dbo.InvoiceDetails.InvoiceDetailTypeID = dbo.InvoiceDetailTypes.InvoiceDetailTypeID INNER JOIN
                    dbo.Products ON dbo.InvoiceDetails.ProductID = dbo.Products.ProductID INNER JOIN
                    dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeId = 2 Left JOIN
                    dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeId = 3 and PD.OwnerEntityId=dbo.Suppliers.SupplierID INNER JOIN
                    SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 INNER JOIN
                    dbo.ProductIdentifierTypes ON dbo.ProductIdentifiers.ProductIdentifierTypeID = dbo.ProductIdentifierTypes.ProductIdentifierTypeID LEFT OUTER JOIN
                    dbo.StoresUniqueValues SUV ON SUV.SupplierID = dbo.InvoiceDetails.SupplierID AND SUV.StoreID = dbo.InvoiceDetails.StoreID
            WHERE   dbo.Stores.ActiveStatus=''Active'''

if(@ChainId<>'' and @ChainId<>'All')
    set @sqlQuery = @sqlQuery + ' and Chains.ChainID=' + @ChainId

if(@SupplierId<>'' and  @SupplierId<>'All')
    set @sqlQuery = @sqlQuery + ' and Suppliers.SupplierId=' + @SupplierId

if(@BannerId<>'' and  @BannerId<>'All')
    set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @BannerId + ''''

if(len(@FromInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.RetailerInvoiceId >=' + @FromInvoiceNumber

if(len(@ToInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.RetailerInvoiceId <=' + @ToInvoiceNumber  
    
if( convert(date, @SaleFromDate ) > convert(date,'1900-01-01') )
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.SaleDate >= ''' + @SaleFromDate + '''' ;

if( convert(date, @SaleToDate ) > convert(date,'1900-01-01') )
    set @sqlQuery = @sqlQuery + ' and InvoiceDetails.SaleDate <= ''' + @SaleToDate + '''' ;

if(@UPC<>'' and @UPC<>'All')
	set @sqlQuery = @sqlQuery + ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%'''
	
if(@StoreNumber<>'' and @StoreNumber<>'All')         
	set @sqlQuery = @sqlQuery + ' and stores.storeidentifier like ''%' + @StoreNumber + '%'''

set @sqlQuery = @sqlQuery + ' order by Stores.storename,saledate';

exec(@sqlQuery);

End
GO
