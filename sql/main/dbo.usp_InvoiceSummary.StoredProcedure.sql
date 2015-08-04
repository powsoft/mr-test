USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoiceSummary]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_InvoiceSummary]
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
--exec usp_InvoiceSummary '40393','-1','-1','-1','','02/10/2013','02/12/2013','1','','','1','','1900-01-01','','',''
Begin

Declare @sqlQuery varchar(4000)

set @sqlQuery = 'SELECT C.ChainName as [Retailer Name], S.SupplierName AS [Supplier Name], ST.StoreName AS [Store Name], ST.Custom2 AS [SBT Number], ST.Custom1 AS Banner,
                IT.InvoiceTypeName AS Type, R.RetailerInvoiceID as [Invoice No], 
                convert(varchar, R.InvoiceDate, 101) as [Invoice Date], 
                R.OriginalAmount as [Total],
                convert(varchar, R.InvoicePeriodStart, 101) as [Invoice Period Start Date],
                convert(varchar, R.InvoicePeriodEnd, 101) as [Invoice Period End Date],
                convert(varchar, ID.PaymentDueDate, 101) as [Payment Due Date],
                SUV.DistributionCenter as [Distribution Center], SUV.RegionalMgr as [Regional Manager], SUV.SalesRep as [Sales Representative],
                SUV.supplieraccountnumber as [Supplier Acct Number], SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number]
        FROM    InvoicesRetailer R
        inner join InvoiceDetails ID on ID.RetailerInvoiceID=R.RetailerInvoiceID
        inner join Products P on ID.ProductId=P.ProductId
        inner join ProductIdentifiers PD ON P.ProductID = PD.ProductID
        inner join Suppliers S on S.SupplierID=ID.SupplierID
        inner join Chains C on C.ChainID=ID.ChainID
        inner join InvoiceTypes IT on IT.InvoiceTypeID=R.InvoiceTypeID
        INNER Join Stores ST on ST.StoreID=ID.StoreID 
        LEFT OUTER JOIN    dbo.StoresUniqueValues SUV ON SUV.StoreID = ST.StoreID and SUV.SupplierID=S.SupplierID
        WHERE    1=1'
                 
if(@ChainId<>'-1')
    set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId

if(@SupplierId<>'-1')
    set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId

if(@BannerId<>'-1')
    set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @BannerId + ''''

if(@InvoiceTypeId<>'-1')
    set @sqlQuery = @sqlQuery + ' and IT.InvoiceTypeID=' + @InvoiceTypeId

if(len(@InvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId =' + @InvoiceNumber

if(len(@FromInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId >=' + @FromInvoiceNumber

if(len(@ToInvoiceNumber)>0)
    set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId <=' + @ToInvoiceNumber    
    
if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and ID.SaleDate>= ''' + @SaleFromDate + ''''

if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and ID.SaleDate <= ''' + @SaleToDate + ''''
    
if(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
    set @sqlQuery = @sqlQuery + ' and ID.PaymentDueDate = ''' + @PaymentDueDate + ''''    
    
if(@ProductIdentifierType<>3)
  set @sqlQuery = @sqlQuery + ' and PD.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
else
  set @sqlQuery = @sqlQuery + ' and PD.ProductIdentifierTypeId = 2 '
  
if(@ProductIdentifierValue<>'')
begin

 -- 2 = UPC, 3 = Product Name 
 if (@ProductIdentifierType=2)
   set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
         
 else if (@ProductIdentifierType=3)
  set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
end   

if(@StoreIdentifierValue<>'')
begin
  -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
 if (@StoreIdentifierType=1)
  set @sqlQuery = @sqlQuery + ' and ST.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
 else if (@StoreIdentifierType=2)
  set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
 else if (@StoreIdentifierType=3)
  set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
end

if(@Others<>'')
 begin
  -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
  -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                          
  if (@OtherOption=1)
   set @sqlQuery = @sqlQuery + ' and SUV.DistributionCenter like ''%' + @Others + '%'''
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

--set @sqlQuery = @sqlQuery + ' order by ST.storename,convert(date, R.InvoicePeriodStart, 101)'

print(@sqlQuery)
exec(@sqlQuery)
End
GO
