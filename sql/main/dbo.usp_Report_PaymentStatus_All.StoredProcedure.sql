USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_PaymentStatus_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_Report_PaymentStatus_All] 
 -- exec usp_Report_PaymentStatus_All '40393','2','All','','-1','','430','1900-01-01','1900-01-01'
 @chainID varchar(max),
 @PersonID int,
 @Banner varchar(50),
 @ProductUPC varchar(20),
 @SupplierId varchar(max),
 @StoreId varchar(10),
 @LastxDays int,
 @StartDate varchar(20),
 @EndDate varchar(20)
AS
BEGIN

declare @sqlQuery varchar(max)

  set @sqlQuery = 'SELECT distinct C.ChainName as [Retailer Name], S.SupplierName AS [Supplier Name], 
        ST.StoreName AS [Store Name], ST.StoreIdentifier AS [Store Number], ST.Custom1 AS Banner, 
        IT.InvoiceTypeName AS [Invoice Type], R.RetailerInvoiceID as [Invoice No], 
        convert(varchar(10), R.InvoiceDate, 101) as [Invoice Date], 
        R.OriginalAmount as [Payment Amount],
        convert(varchar(10), R.InvoicePeriodStart, 101) as [Invoice Period Start Date],
        convert(varchar(10), R.InvoicePeriodEnd, 101) as [Invoice Period End Date],
        convert(varchar(10), ID.PaymentDueDate, 101) as [Payment Due Date], PM.PaymentId as [Nacha Id],
        convert(varchar(10), R.DateTimeCreated, 101) as [Invoice Processing Date], 
        isnull(convert(varchar(10), PM.DateTimePaid, 101),''-'') as [Payment Date],
        isnull(STAT.StatusName,''Not Available'') as [Payment Status],PM.PaymentId
       FROM    InvoicesRetailer R WITH(NOLOCK) 
       inner join InvoiceDetails ID WITH(NOLOCK)  on ID.RetailerInvoiceID=R.RetailerInvoiceID
       inner join Products P WITH(NOLOCK)  on ID.ProductId=P.ProductId
       inner join ProductIdentifiers PD WITH(NOLOCK)  ON P.ProductID = PD.ProductID
       inner join Suppliers S WITH(NOLOCK)  on S.SupplierID=ID.SupplierID
       inner join Chains C WITH(NOLOCK)  on C.ChainID=ID.ChainID
       inner join InvoiceTypes IT WITH(NOLOCK)  on IT.InvoiceTypeID=R.InvoiceTypeID
       INNER Join Stores ST WITH(NOLOCK)  on ST.StoreID=ID.StoreID and ST.ActiveStatus=''Active''
       INNER join Payments PM WITH(NOLOCK)  on PM.PaymentID = ID.PaymentID --PM.AppliesToRef=ID.SupplierInvoiceID
       Left join Statuses STAT WITH(NOLOCK)  on STAT.StatusIntValue = PM.PaymentStatus and STAT.StatusTypeID = 14 
       WHERE    1=1 '
       
       
                 
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainId in (' + @ChainId+')'

    if(@SupplierId<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierId in (' + @SupplierId +')'

    if(@Banner<>'All')
        set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @Banner + ''''

    if(@StoreId<>'-1')
        set @sqlQuery = @sqlQuery + ' and ST.StoreIdentifier=''' + @StoreId + ''''

    if (convert(date, @StartDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.SaleDate>= ''' + @StartDate + ''''

    if(convert(date, @EndDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.SaleDate <= ''' + @EndDate + ''''

	if (@LastxDays > 0)
		set @sqlQuery = @sqlQuery + ' and (ID.SaleDate between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })' 
        
    set @sqlQuery = @sqlQuery + ' order by PM.PaymentId'
 print (@sqlQuery)   
 exec (@sqlQuery)
 
END
GO
