USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PaymentStatus_Aggregate]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_PaymentStatus_Aggregate]
@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@InvoiceTypeId varchar(10),
@InvoiceNumber varchar(255),
@SaleFromDate varchar(50),
@SaleToDate varchar(50),
@PaymentDueDate varchar(50),
@PaymentStatus varchar(50),
@StoreNumber varchar(50),
@Summary varchar(10),
@GroupBY int
as
	
Begin 

Declare @sqlQuery varchar(4000)

	IF(@GroupBY=1)
	   set @sqlQuery ='SELECT distinct S.SupplierName AS [Supplier Name],isnull(convert(varchar(10), PM.DateTimePaid, 101),''-'') as [Payment Date], cast(sum(R.OriginalAmount) as numeric(10,2)) as [Payment Amount] '
	   
	Else IF(@GroupBY=2)
	   set @sqlQuery ='SELECT distinct C.ChainName as [Retailer Name],isnull(convert(varchar(10), PM.DateTimePaid, 101),''-'') as [Payment Date], cast(sum(R.OriginalAmount) as numeric(10,2))  as [Payment Amount] '

		set @sqlQuery = @sqlQuery + ' 
									FROM  InvoicesRetailer R
									inner join InvoiceDetails ID on ID.RetailerInvoiceID=R.RetailerInvoiceID
									inner join Products P on ID.ProductId=P.ProductId
									inner join ProductIdentifiers PD ON P.ProductID = PD.ProductID
									inner join Suppliers S on S.SupplierID=ID.SupplierID
									inner join Chains C on C.ChainID=ID.ChainID
									inner join InvoiceTypes IT on IT.InvoiceTypeID=R.InvoiceTypeID
									INNER Join Stores ST on ST.StoreID=ID.StoreID and ST.ActiveStatus=''Active''
									INNER join Payments PM on PM.PaymentID = ID.PaymentID --PM.AppliesToRef=ID.SupplierInvoiceID
									Left join Statuses STAT on STAT.StatusIntValue = PM.PaymentStatus and STAT.StatusTypeID = 14 --STAT.statusid=PM.PaymentStatus
									WHERE  1=1 '
                 
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId

    if(@SupplierId<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId

    if(@BannerId<>'-1')
        set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @BannerId + ''''

    if(@StoreNumber<>'')
        set @sqlQuery = @sqlQuery + ' and ST.StoreIdentifier=''' + @StoreNumber + ''''
        
    if(@InvoiceTypeId<>'-1')
        set @sqlQuery = @sqlQuery + ' and IT.InvoiceTypeID=' + @InvoiceTypeId

    if(len(@InvoiceNumber)>0)
        set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId =' + @InvoiceNumber

    if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.SaleDate>= ''' + @SaleFromDate + ''''

    if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.SaleDate <= ''' + @SaleToDate + ''''
        
    if(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.PaymentDueDate = ''' + @PaymentDueDate + ''''    
        
    if(@PaymentStatus<>'-1')
        set @sqlQuery = @sqlQuery + ' and (STAT.StatusIntValue)=' + @PaymentStatus
    
    if (@GroupBY=1)   
            begin
                set @sqlQuery = @sqlQuery + ' group by S.SupplierName,PM.DateTimePaid ' 
            end
    Else If (@GroupBY=2)   
            begin
                set @sqlQuery = @sqlQuery + ' group by C.ChainName,PM.DateTimePaid ' 
            end

    exec (@sqlQuery)

End
GO
