USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPaymentDatesDispute_Summary]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetPaymentDatesDispute_Summary]
@ChainId varchar(10),
@SupplierId varchar(10)

-- exec [usp_GetPaymentDatesDispute] 81651,'-1'
as

Begin

Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'select DISTINCT  convert(varchar(10),PM.DateTimePaid,101) as [PaymentDate]
					
				   FROM Payments PM WITH(NOLOCK) 
						INNER JOIN Chains C WITH(NOLOCK) on PM.PayerEntityId=C.ChainId
						INNER JOIN Suppliers S WITH(NOLOCK) on PM.PayeeEntityId=S.SupplierId
						INNER JOIN invoiceDetails ID WITH(NOLOCK) on Id.PaymentID=PM.PaymentID
						INNER JOIN InvoicesRetailer IR WITH(NOLOCK) on IR.RetailerInvoiceID=ID.RetailerInvoiceID
						Left Join (select distinct ChainId, SupplierId, SupplierInvoiceNumber, PONo
									from StoreTransactions ST With(NoLock) 
									where ST.TransactionTypeId=32
									group by ChainId, SupplierId, SupplierInvoiceNumber, PONo
							  ) PO on PO.SupplierId=ID.SupplierId and ID.ChainId=PO.ChainId and ID.InvoiceNo=PO.SupplierInvoiceNumber
				  where DateTimePaid is not NUll and PM.DateTimePaid>getdate()-190'
                 
    if(@ChainId<>'-1' and @ChainId<> '')
        set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId

    if(@SupplierId<>'-1' and @SupplierId<> '')
        set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId

 
	set @sqlQuery = @sqlQuery + ' order by 1 desc  '        
    
    exec (@sqlQuery)
    print (@sqlQuery)
    
End
GO
