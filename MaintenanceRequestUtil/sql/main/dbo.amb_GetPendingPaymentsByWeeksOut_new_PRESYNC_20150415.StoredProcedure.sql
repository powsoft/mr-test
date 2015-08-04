USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetPendingPaymentsByWeeksOut_new_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[amb_GetPendingPaymentsByWeeksOut_new_PRESYNC_20150415]
(
   @ChainID varchar(50),
   @SupplierID varchar(50),
   @NoWeeksOut varchar(20),
   @Amount varchar(20)
)
AS
--amb_GetPendingPaymentsByWeeksOut_New '65232','-1','8',''
Begin
	
	IF OBJECT_ID('[@tmpAvgWeeklyBilling]', 'U') IS NOT NULL
		DROP TABLE [@tmpAvgWeeklyBilling]
	
	IF OBJECT_ID('[@tmpPendingPayment]', 'U') IS NOT NULL
		DROP TABLE [@tmpPendingPayment]
		
	-- calculate the average week billing for given supplier and retailer		
    IF(@SupplierID<>'-1' and @ChainID<>'-1')
		Select D.ChainID, D.Supplierid, SUM(OriginalAmount)/count(InvoicePeriodStart) as AvgWeeklyBilling
			INTO [@tmpAvgWeeklyBilling]
				from InvoicesRetailer R with (nolock)
				inner JOIN InvoiceDetails D WITH (NOLOCK) ON D.RetailerInvoiceID=R.RetailerInvoiceID
				Inner Join Chains C on C.ChainID = D.ChainID
				Inner join Suppliers S on S.SupplierID = D.SupplierID
				where D.RetailerInvoiceID is not null and D.RetailerInvoiceID <> -1
				and D.SupplierInvoiceID is not null and D.SupplierInvoiceID <> -1
				and D.SupplierID <> 0 and D.PaymentID is null
				and SaleDate >= '11/18/2013'
				AND S.IsRegulated=0 
				and D.SupplierID= @SupplierID and D.ChainID=@ChainID
				group by D.ChainID, D.SupplierId
	else
	-- calculate the average week billing for all supplier and retailer
		Select D.ChainID, D.Supplierid, SUM(OriginalAmount)/count(InvoicePeriodStart) as AvgWeeklyBilling
			INTO [@tmpAvgWeeklyBilling]
				from InvoicesRetailer R with (nolock)
				inner JOIN InvoiceDetails D WITH (NOLOCK) ON D.RetailerInvoiceID=R.RetailerInvoiceID
				Inner Join Chains C on C.ChainID = D.ChainID
				Inner join Suppliers S on S.SupplierID = D.SupplierID
				where D.RetailerInvoiceID is not null and D.RetailerInvoiceID <> -1
				and D.SupplierInvoiceID is not null and D.SupplierInvoiceID <> -1
				and D.SupplierID <> 0 and D.PaymentID is null
				and SaleDate >= '11/18/2013'
				AND S.IsRegulated=0 
				group by D.ChainID, D.SupplierId
	
	-- calculate the pending payment for given supplier and retailer			
	IF(@SupplierID<>'-1' and @ChainID<>'-1')
		Select C.ChainID, S.SupplierId, C.ChainName, S.SupplierName, S.SupplierIdentifier ,SUM(totalqty*unitcost) as [PendingPayment]
			into [@tmpPendingPayment]
				from InvoicesRetailer r
				inner join InvoiceDetailS d
				on r.RetailerInvoiceID = d.RetailerInvoiceID
				Inner Join Chains C on C.ChainID = d.ChainID
				inner join Suppliers S on S.SupplierID = d.SupplierID
				Where r.ChainID=d.ChainID
				and r.ChainID in (select Distinct EntityIDtoInclude 
		from ProcessStepEntities E 
		where ProcessStepName like 'prBilling_Payment_Create%'
		and E.IsActive = 1)
		and SaleDate >= '11/18/2013'
		and d.RetailerInvoiceID is not null
		and d.RetailerInvoiceID <> -1
		and d.SupplierInvoiceID is not null
		and d.SupplierInvoiceID <> -1
		and d.SupplierID <> 0
		and d.PaymentID is null
		and d.SupplierID= @SupplierID and d.ChainID=@ChainID
		Group by ChainName, S.SupplierName, S.SupplierIdentifier,C.ChainID, S.SupplierId
		Having SUM(totalqty*unitcost) < 0	
	else
	-- calculate the pending payment for all supplier and retailer
		Select C.ChainID, S.SupplierId, C.ChainName, S.SupplierName, S.SupplierIdentifier ,SUM(totalqty*unitcost) as [PendingPayment]
			into [@tmpPendingPayment]
				from InvoicesRetailer r
				inner join InvoiceDetailS d
				on r.RetailerInvoiceID = d.RetailerInvoiceID
				Inner Join Chains C on C.ChainID = d.ChainID
				inner join Suppliers S on S.SupplierID = d.SupplierID
				Where r.ChainID=d.ChainID
				and r.ChainID in (select Distinct EntityIDtoInclude 
		from ProcessStepEntities E 
		where ProcessStepName like 'prBilling_Payment_Create%'
		and E.IsActive = 1)
		and SaleDate >= '11/18/2013'
		and d.RetailerInvoiceID is not null
		and d.RetailerInvoiceID <> -1
		and d.SupplierInvoiceID is not null
		and d.SupplierInvoiceID <> -1
		and d.SupplierID <> 0
		and d.PaymentID is null
		Group by ChainName, S.SupplierName, S.SupplierIdentifier,C.ChainID, S.SupplierId
		Having SUM(totalqty*unitcost) < 0	
				
	Declare @SqlQuery varchar(4000)='';
	Set @SqlQuery=' SELECT P.ChainId,P.SupplierID,P.ChainName, P.SupplierName, P.SupplierIdentifier as [Vendor ID],
						   P.[PendingPayment] as [Pending Payment], 
						   A.AvgWeeklyBilling as [Avg Weekly Billing], 
						   (P.[PendingPayment]/ A.AvgWeeklyBilling) as [# of Weeks Out]
							from [@tmpPendingPayment] P
							inner JOIN [@tmpAvgWeeklyBilling] A ON P.ChainId=A.ChainId and P.SupplierId=A.SupplierID
							where 1=1 '							
	 if(@ChainID<>'-1')
		Set @SqlQuery=@SqlQuery+' AND P.ChainId = '+ @ChainID
		
	 if(@SupplierID<>'-1')
		Set @SqlQuery=@SqlQuery+' AND P.SupplierID = '+ @SupplierID
		
	 if(@NoWeeksOut<>'')
	    Set @SqlQuery=@SqlQuery+' and (P.[PendingPayment]/ A.AvgWeeklyBilling) > ' + @NoWeeksOut
	    				
	 if(@Amount<>'')
	    Set @SqlQuery=@SqlQuery+' and abs([PendingPayment]) < ' + @Amount 
	    
		Set @SqlQuery=@SqlQuery+' order by 6 desc'  
	  
	  print(@SqlQuery);
	  exec(@SqlQuery);   
End
GO
