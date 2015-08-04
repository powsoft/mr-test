USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetPendingPaymentsByWeeksOut]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[amb_GetPendingPaymentsByWeeksOut]
(
    @ChainID varchar(50),
    @SupplierID varchar(50),
    @NoWeeksOut varchar(20),
    @Amount varchar(20)
)
AS
--amb_GetPendingPaymentsByWeeksOut_New '-1','-1','1',20
--amb_GetPendingPaymentsByWeeksOut '-1','-1','0'
Begin
	
	IF OBJECT_ID('[@tmpAvgWeeklyBilling]', 'U') IS NOT NULL
		DROP TABLE [@tmpAvgWeeklyBilling]
		
    IF(@SupplierID<>'-1' and @ChainID<>'-1')
		Select D.ChainID, D.Supplierid, SUM(OriginalAmount)/count(InvoicePeriodStart) as AvgWeeklyBilling
			INTO [@tmpAvgWeeklyBilling]
				from InvoicesSupplier I with (nolock)
				inner JOIN InvoiceDetails D WITH (NOLOCK) ON D.SupplierInvoiceID=I.SupplierInvoiceID
				where InvoicePeriodStart >GETDATE()-30
				and D.SupplierID= @SupplierID and D.ChainID=@ChainID
				group by D.ChainID, D.SupplierId
	else
		Select D.ChainID, D.Supplierid, SUM(OriginalAmount)/count(InvoicePeriodStart) as AvgWeeklyBilling
			INTO [@tmpAvgWeeklyBilling]
				from InvoicesSupplier I with (nolock)
				inner JOIN InvoiceDetails D WITH (NOLOCK) ON D.SupplierInvoiceID=I.SupplierInvoiceID
				where InvoicePeriodStart >GETDATE()-30
				group by D.ChainID, D.SupplierId
				
	Declare @SqlQuery varchar(4000)='';
	Set @SqlQuery=' select C.ChainID, S.SupplierID, S.SupplierIdentifier as [Vendor ID],C.ChainName, S.SupplierName as [Supplier Name], 
							   SUM(AmountOriginallyBilled) as [Pending Payment], A.AvgWeeklyBilling as [Avg Weekly Billing],
							   case when AvgWeeklyBilling is null then 0 else abs(SUM(AmountOriginallyBilled)/AvgWeeklyBilling) end as [# of Weeks Out]
							from Payments P with (nolock)
							inner join (Select distinct PaymentId, DisbursementId, PaymentStatus from PaymentHistory H with (nolock) 
											where H.DisbursementID is null
										) H on H.PaymentID=P.PaymentID and H.PaymentStatus=P.PaymentStatus
							inner join Suppliers S with (nolock) on S.SupplierId=P.PayeeEntityID
							inner join Chains c with (nolock) on C.ChainID=P.PayerEntityID
							left join [@tmpAvgWeeklyBilling] A on A.SupplierID=S.SupplierID AND A.ChainID=C.ChainID
							where 1=1 AND S.IsRegulated=0 and P.PaymentTypeID<=5'
					
	  if(@ChainID<>'-1')
		Set @SqlQuery=@SqlQuery+' AND C.ChainID= '''+@ChainID + ''''
	  
	  if(@SupplierID<>'-1')
		Set @SqlQuery=@SqlQuery+' AND S.Supplierid = ''' + @SupplierID  + ''''
	    
	    Set @SqlQuery=@SqlQuery+' group by C.ChainID, S.SupplierID, S.SupplierIdentifier, C.ChainName, S.SupplierName, AvgWeeklyBilling '
	  
	    Set @SqlQuery=@SqlQuery+' having SUM(AmountOriginallyBilled)<0 and abs(SUM(AmountOriginallyBilled)/AvgWeeklyBilling)>' + @NoWeeksOut
	  
	 if(@Amount<>'')
	    Set @SqlQuery=@SqlQuery+' and abs(SUM(AmountOriginallyBilled)) > ' + @Amount 
	    
	  Set @SqlQuery=@SqlQuery+' order by 5 desc'  
	  
	  print(@SqlQuery);
	  exec(@SqlQuery);
    
End
GO
