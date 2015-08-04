USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DisputPaymentStatus]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_DisputPaymentStatus]
@ChainId varchar(10),
@SupplierId varchar(10),
@InvoiceNo varchar(255),
@PaymentDate varchar(50)
-- exec [usp_DisputPaymentStatus] 50964,50729,'679', '1900-01-01'
as

Begin

Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'select C.ChainName as [Retailer Name]
					, PM.PaymentID
					, S.SupplierName as [Distributor Name]
					, IR.RetailerInvoiceID as [Invoice ID]
					, convert(varchar(10),PM.DateTimePaid,101) as [Payment Date]
					, cast(PM.AmountOriginallyBilled as numeric(10,2)) as [Payment Amount] 
					from Payments PM
						inner Join Chains C on PM.PayerEntityId=C.ChainId
						inner Join Suppliers S on PM.PayeeEntityId=S.SupplierId
						INNER JOIN invoiceDetails ID on Id.PaymentID=PM.PaymentID
						INNER JOIN InvoicesRetailer IR on IR.RetailerInvoiceID=ID.RetailerInvoiceID
					where DateTimePaid is not NUll '
                 
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId

    if(@SupplierId<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId

    if(@InvoiceNo<>'')
        set @sqlQuery = @sqlQuery + ' and IR.RetailerInvoiceID =' + @InvoiceNo

    if(convert(date, @PaymentDate ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and PM.DateTimePaid = ''' + @PaymentDate + ''''    
	
	set @sqlQuery = @sqlQuery + ' order by 1, 2, 3 desc '        
    exec (@sqlQuery)
End
GO
