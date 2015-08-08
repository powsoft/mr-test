USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DisputPaymentStatus_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_DisputPaymentStatus_New]
@ChainId varchar(10),
@SupplierId varchar(10),
@InvoiceNo varchar(255),
@PaymentDate varchar(50),
@Payment varchar(10),
@ShowDifferences varchar(1)

-- exec [usp_DisputPaymentStatus_New] 81651,'-1','', '-1','-1','0'
as

Begin

Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'select DISTINCT s.SupplierName as [Distributor Name],
									 InvoiceNumber as [Receiving Invoice#],
									 SupplierInvoiceNumber as [Delivery Invoice#],
									 IC.PaymentId as [Payment Id],
									 convert(varchar(101),InvoiceDate,101) as [Invoice Date],
									 RetailerInvoiceQty,
									 RetailerInvoiceTotal,
									 RetailerInvoiceLineItemCount,
									 SupplierInvoiceQty,
									 SupplierInvoiceTotal,
									 SupplierInvoiceLineItemCount,
									 SupplierProductMatch 
						from DataTrue_main..iCAM_POMatch IC WITH(NOLOCK)
						inner JOIN Suppliers S WITH(NOLOCK) on S.SupplierID=IC.SupplierID
						INNER JOIN Chains C WITH(NOLOCK) on c.ChainID=IC.ChainID
						where 1=1 '
							
	if(@Payment = '0' )
        set @sqlQuery = @sqlQuery + ' and IC.PaymentID IS NULL'						
    
    else if(@Payment = '1' )
        set @sqlQuery = @sqlQuery + ' and IC.PaymentID IS NOT NULL'						
                 
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and IC.ChainId=' + @ChainId

    if(@SupplierId<>'-1')
        set @sqlQuery = @sqlQuery + ' and IC.SupplierId=' + @SupplierId

    if(@InvoiceNo<>'')
        set @sqlQuery = @sqlQuery + ' and isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) = ' + @InvoiceNo 
         
   if(@PaymentDate<>'-1' and @PaymentDate<>'' and @PaymentDate<>'1900-01-01')
        set @sqlQuery = @sqlQuery + ' and IC.InvoiceDate = ''' + @PaymentDate + ''''    
   
   if(@ShowDifferences = '1')
		set @sqlQuery = @sqlQuery + ' AND RetailerInvoiceTotal <> SupplierInvoiceTotal'
		
	set @sqlQuery = @sqlQuery + ' order by 1, 3 desc '
	        
    exec (@sqlQuery)
    print(@sqlQuery)
End
GO
