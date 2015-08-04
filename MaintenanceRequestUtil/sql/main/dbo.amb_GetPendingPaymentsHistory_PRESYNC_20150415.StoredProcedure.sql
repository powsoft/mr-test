USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetPendingPaymentsHistory_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[amb_GetPendingPaymentsHistory_PRESYNC_20150415]
(
    @ChainID varchar(50),
    @SupplierID varchar(50)
)
AS
--amb_GetPendingPaymentsHistory '-1','-1'
Begin
Declare @SqlQuery varchar(4000)='';

		Set @SqlQuery='select D.SupplierInvoiceID as [Invoice Number], D.StoreIdentifier as [Store Number], D.ProductIdentifier as [UPC],
					  convert(varchar(20),D.SaleDate ,101) as [Sale Date],D.TotalQty as [Total Qty], D.UnitCost as [Unit Cost], D.TotalCost as [Total Cost], 
					  D.Adjustment1 as Adjustment,(D.TotalCost-D.Adjustment1) as [Net Cost]
					  from Payments P with (nolock)
						inner join (Select distinct PaymentId, DisbursementId, PaymentStatus from PaymentHistory H with (nolock) where H.DisbursementID is null) H 
							  on H.PaymentID=P.PaymentID and H.PaymentStatus=P.PaymentStatus
						inner join Suppliers S with (nolock) on S.SupplierId=P.PayeeEntityID
						inner join Chains c with (nolock) on C.ChainID=P.PayerEntityID
						inner JOIN InvoiceDetails D on D.PaymentID=P.PaymentID
						where 1=1 AND S.IsRegulated=0 and P.PaymentTypeID<=5 '
							
  if(@ChainID<>'-1')
	Set @SqlQuery=@SqlQuery+' AND C.ChainID= '''+@ChainID + ''''
  
  if(@SupplierID<>'-1')
	Set @SqlQuery=@SqlQuery+' AND S.SupplierID = ''' + @SupplierID  + ''''
  
  print( @SqlQuery);
  exec(@SqlQuery);
    
End
GO
