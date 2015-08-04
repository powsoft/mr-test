USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetInvoicesDetails]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_GetInvoicesDetails '-1','-1','','3','1900-01-01','1900-01-01','-1','','',''
CREATE procedure [dbo].[amb_GetInvoicesDetails]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreNumber varchar(20),
 @Status varchar(20),
 @StartDate varchar(50),
 @EndDate  varchar(50),
 @InvoiceType varchar(50),
 @RetailerCheckNo varchar(50),
 @SupplierCheckNo varchar(50),
 @InvoiceNumber  varchar(50)
as

Begin
 Declare @sqlQuery varchar(5000)
	
		SET @sqlQuery = ' Select distinct ss.LegacySystemStoreIdentifier as [Store Number],
						Ir.SupplierInvoiceId as [Invoice No], 
						convert(varchar,IR.InvoiceDate,101) as [InvoiceCreationDate],
						convert(varchar,IR.InvoicePeriodStart,101) as InvoicePeriodStart,
						convert(varchar,IR.InvoicePeriodEnd,101) as InvoicePeriodEnd,
						IR.OriginalAmount as NetInvoice, PH.AmountPaid as TotalPaid,
						convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
						(PH.CheckNoReceived) as RetailerCheckNumber,
						IT.InvoiceTypeName as InvoiceType,
						convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
						Pd.BatchNo  AS  [Batch Number],
						Pd.Checkno  AS  [Check Number],
						ST.StatusName AS [Payment Status], P.PaymentId, S.SupplierIdentifier as [Wholesaler Id] 
						from Payments P
						inner join PaymentHistory PH on PH.PaymentID=P.PaymentID and Ph.PaymentStatus=P.Paymentstatus
						inner join Statuses ST on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
						inner join InvoiceDetails ID on ID.PaymentID=P.PaymentID
						inner join InvoicesSupplier IR on IR.SupplierInvoiceID=ID.SupplierInvoiceID
						inner join stores ss on ss.StoreID=Id.StoreID  
						inner join Chains c on ID.chainid=c.chainid
						inner join Suppliers S on ID.SupplierID=S.SupplierID
						inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
						left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID 
						Where 1=1 '
		
		if(convert(varchar, @StartDate,101 ) > convert(varchar,'1900-01-01',101))
			set @sqlQuery = @sqlQuery + ' and InvoicePeriodEnd >= ''' + convert(varchar,@StartDate,101) + ''''
			
		if(convert(varchar, @EndDate,101 ) > convert(varchar,'1900-01-01',101))
			set @sqlQuery = @sqlQuery + ' and InvoicePeriodEnd <= ''' + convert(varchar,@EndDate,101) + ''''
			
		If(@RetailerCheckNo<>'')
			set @sqlQuery = @sqlQuery + ' and PH.CheckNoReceived like ''%' + @RetailerCheckNo  + '%'''
			
		If(@SupplierCheckNo<>'')
			set @sqlQuery = @sqlQuery + ' and PD.Checkno like ''%' + @SupplierCheckNo  + '%'''
			
		If(@InvoiceNumber<>'')
			set @sqlQuery = @sqlQuery + ' and Ir.SupplierInvoiceId like ''%' + @InvoiceNumber  + '%'''
						
		if(@SupplierId <>'-1')
			set @sqlQuery = @sqlQuery + ' and S.SupplierId= ''' + @SupplierId+''''
			
		if(@ChainId<>'-1')
			set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier= ''' + @ChainId +''''    
		      	               
		if(@StoreNumber <>'')
		   set @sqlQuery = @sqlQuery + ' and ss.LegacySystemStoreIdentifier like ''%' + @StoreNumber +'%'''
					
		if(@Status <>'-1')
			set @sqlQuery = @sqlQuery + ' and P.PaymentStatus='+ @Status
		
		if(@Status = '10' or @Status = '11')
			set @sqlQuery = @sqlQuery + '  and PD.CheckNo is not null '
		
		if(@InvoiceType <>'-1')
			set @sqlQuery = @sqlQuery + ' and IT.InvoiceTypeId='+ @InvoiceType	
		
		--set @sqlQuery = @sqlQuery + @sqlQuery 
		
		exec(@sqlQuery);
	--			 Draws/Deleveries--Select * from StoreTransactions_Forwarding
 --Pickup/Returns=Drwas-POS
 --DCR-Actual Shrink Units Billed--- InvoiceDetailTypeID=5
 -- POS-Del
End
GO
