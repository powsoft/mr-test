USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PaymentStatus]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_PaymentStatus '50964','65138','-1','-1','','1900-01-01','1900-01-01','1900-01-01','-1','','1','1900-01-01','1900-01-01','-1','','','1900-01-01','1900-01-01'
-- exec usp_PaymentStatus '50964','65138','-1','-1','','1900-01-01','1900-01-01','1900-01-01','-1','','0','1900-01-01','1900-01-01','-1','','','1900-01-01','1900-01-01',''

CREATE procedure [dbo].[usp_PaymentStatus]
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
@InvoiceFromDate varchar(50),
@InvoiceToDate varchar(50),
@IsAdmin varchar(10),
@RetailerInvoiceNumber varchar(255),
@SupplierInvoiceNumber varchar(255),
@PaymentFromDate varchar(50),
@PaymentToDate varchar(50)
--,@SupplierAcctNo varchar(50)

as

Begin

Declare @sqlQuery varchar(4000)
Declare @sqlGroupBy varchar(4000)

	set @sqlQuery = 'SELECT distinct C.ChainName as [Retailer Name], S.SupplierName AS [Supplier Name], '
	
	IF(@Summary='0')
		set @sqlQuery = @sqlQuery + '   ST.StoreName AS [Store Name], ST.StoreIdentifier AS [Store Number], ST.Custom1 AS Banner, 
										IT.InvoiceTypeName AS [Invoice Type],
										ID.InvoiceNo AS [Invoice No], 
										R.RetailerInvoiceID as [IC Retailer Invoice No],
										ID.SupplierInvoiceId AS [IC Supplier Invoice No],
										cast(sum(ISNULL(ID.TotalCost,0)) as numeric(10,2)) as [Total Amount], 
										convert(varchar(10), R.InvoiceDate, 101) as [Invoice Date], 
										cast(sum(ISNULL(ID.TotalCost,0)) as numeric(10,2)) as [Payment Amount],
										convert(varchar(10), R.InvoicePeriodStart, 101) as [Invoice Period Start Date],
										convert(varchar(10), R.InvoicePeriodEnd, 101) as [Invoice Period End Date],
										convert(varchar(10), ID.PaymentDueDate, 101) as [Payment Due Date], 
										convert(varchar(10), R.DateTimeCreated, 101) as [Invoice Processing Date],
										--SUV.SupplierAccountNumber as  [Supplier Acct Number], 
										'
										
	ELSE
		set @sqlQuery = @sqlQuery + '  '''' as [Store Name], '''' AS [Store Number], '''' As Banner,
										IT.InvoiceTypeName AS [Invoice Type],
										'''' as [Invoice No],
										'''' as [IC Retailer Invoice No],
										'''' AS [IC Supplier Invoice No],
										'''' AS [Total Amount], 
										'''' as [Invoice Date], 
										cast(PM.AmountOriginallyBilled as numeric(10,2)) as [Payment Amount],
										'''' as [Invoice Period Start Date], 
										'''' as [Invoice Period End Date],
										'''' as [Payment Due Date], 
										convert(varchar(10), max(R.DateTimeCreated), 101) as [Invoice Processing Date], 
										--'''' as  [Supplier Acct Number],
										 '

	set @sqlQuery = @sqlQuery +	'  CASE When PM.AggregatePaymentID IS NULL
										THEN PM.PaymentId
										ELSE PM.AggregatePaymentID END AS [Nacha Id], ' 

	set @sqlQuery = @sqlQuery + ' isnull(convert(varchar(10), PM.DateTimePaid, 101),''-'') as [Payment Date],
								isnull(STAT.StatusName,''Not Available'') as [Payment Status],
								PM.PaymentId

						FROM    dbo.InvoicesRetailer R WITH(NOLOCK) 
								inner join dbo.InvoiceDetails ID WITH(NOLOCK) on ID.RetailerInvoiceID=R.RetailerInvoiceID
								inner join dbo.Suppliers S WITH(NOLOCK) on S.SupplierID=ID.SupplierID
								inner join dbo.Chains C WITH(NOLOCK) on C.ChainID=ID.ChainID
								inner join InvoiceTypes IT WITH(NOLOCK) on IT.InvoiceTypeID=R.InvoiceTypeID 
								INNER Join dbo.Stores ST WITH(NOLOCK) on ST.StoreID=ID.StoreID --and ST.ActiveStatus=''Active''
								INNER join dbo.Payments PM WITH(NOLOCK) on PM.PaymentID = ID.PaymentID and (pm.paymentStatus not in (10,11) or pm.IsPennyTest =1)
								Left join dbo.Statuses STAT WITH(NOLOCK) on STAT.StatusIntValue = PM.PaymentStatus and STAT.StatusTypeID = 14 --STAT.statusid=PM.PaymentStatus
								--LEFT OUTER JOIN dbo.StoresUniqueValues SUV WITH(NOLOCK) ON S.SupplierID = SUV.SupplierID  AND ST.StoreID=SUV.StoreID
								
						WHERE    1=1  '
                 
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
        set @sqlQuery = @sqlQuery + ' and ID.InvoiceNo like ''%' + @InvoiceNumber+ '%'''
    
    if(len(@RetailerInvoiceNumber)>0)
        set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId like ''%' + @RetailerInvoiceNumber+ '%'''
        
    if(len(@SupplierInvoiceNumber)>0)
        set @sqlQuery = @sqlQuery + ' and ID.SupplierInvoiceId like ''%' + @SupplierInvoiceNumber+ '%'''

    if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.SaleDate>= ''' + @SaleFromDate + ''''

    if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.SaleDate <= ''' + @SaleToDate + ''''
	
	if (convert(date, @InvoiceFromDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and cast(R.InvoicePeriodEnd as date)>= ''' + @InvoiceFromDate + ''''

	if(convert(date, @InvoiceToDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and cast(R.InvoicePeriodEnd as date) <= ''' + @InvoiceToDate + ''''
		        
    if(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and ID.PaymentDueDate = ''' + @PaymentDueDate + ''''   
        
    if (convert(date, @PaymentFromDate ) > convert(date,'1900-01-01'))
       set @sqlQuery = @sqlQuery + ' and PM.DateTimePaid>= ''' + @PaymentFromDate + ''''

    if(convert(date, @PaymentToDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and PM.DateTimePaid <= ''' + @PaymentToDate + ''''     
        
    if(@PaymentStatus<>'-1')
        set @sqlQuery = @sqlQuery + ' and (STAT.StatusIntValue)=' + @PaymentStatus
    
     --if(len(@SupplierAcctNo)>0)
     --   set @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber like ''%' + @SupplierAcctNo+ '%'''
    
    if(@IsAdmin<>'1' and @IsAdmin<>'')
        set @sqlQuery = @sqlQuery + ' and IT.InvoiceTypeID not in(14,15)'    
        
    IF(@Summary='0')    
		SET @sqlGroupBy = 'GROUP BY C.ChainName , 
									S.SupplierName , 
									ST.StoreName , 
									ST.StoreIdentifier, 
									ST.Custom1 , 
									IT.InvoiceTypeName , 
									R.RetailerInvoiceID , 
									ID.InvoiceNo ,
									ID.SupplierInvoiceId,
									convert(varchar(10), R.InvoiceDate, 101) , 
									cast(R.OriginalAmount as numeric(10,2)) ,
									convert(varchar(10), R.InvoicePeriodStart, 101) ,
									convert(varchar(10), R.InvoicePeriodEnd, 101) ,
									convert(varchar(10), ID.PaymentDueDate, 101) ,
									convert(varchar(10), R.DateTimeCreated, 101) , 
									convert(varchar(10), PM.DateTimePaid, 101),
									isnull(STAT.StatusName,''Not Available''),
									PM.PaymentId,
									PM.DateTimeCreated,
									PM.AggregatePaymentID
									--,SUV.SupplierAccountNumber 
									'
	ELSE 
	   SET @sqlGroupBy = 'GROUP BY  C.ChainName, 
									S.SupplierName,
									IT.InvoiceTypeName,
									cast(PM.AmountOriginallyBilled as numeric(10,2)),
									isnull(convert(varchar(10), PM.DateTimePaid, 101),''-''),
									isnull(STAT.StatusName,''Not Available''),
									CAST(PM.DateTimeCreated AS DATE),
									PM.AggregatePaymentID,
									PM.PaymentId '
        
   
		
  IF(@Summary='0')
      SET @sqlQuery = @sqlQuery + @sqlGroupBy + ' ORDER BY CASE When PM.AggregatePaymentID IS NULL THEN PM.PaymentId ELSE PM.AggregatePaymentID END'
  ELSE 
      SET @sqlQuery = @sqlQuery + @sqlGroupBy + ' ORDER BY CASE When PM.AggregatePaymentID IS NULL THEN PM.PaymentId ELSE PM.AggregatePaymentID END'
  
  PRINT(@sqlQuery)
  EXEC (@sqlQuery)
--insert into tmpQueryTest values(@sqlQuery)
End
GO
