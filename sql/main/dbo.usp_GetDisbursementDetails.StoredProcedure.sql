USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetDisbursementDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_GetDisbursementDetails] '-1','40393','-1',1,'',0,'4','1900-01-01','1900-01-01','-1','','','','1900-01-01','1900-01-01',-1,1,'','','1','', ''
CREATE  procedure [dbo].[usp_GetDisbursementDetails]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @Custom1 varchar(255),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(250),
 @ItemLevel int,
 @Status varchar(20),
 @StartDate varchar(50),
 @EndDate  varchar(50),
 @InvoiceType varchar(150),
 @CheckNo varchar(50),
 @StartCheckNo varchar(50),
 @EndStartCheckNo varchar(50),
 @InvoiceCreationFromDate varchar(50),
 @InvoiceCreationToDate varchar(50),
 @RegulatedSupplier varchar(10),
 @ChainUser varchar(10),
 @SupplierIdentifierValue varchar(20),
 @RetailerIdentifierValue varchar(20),
 @TotalsMatch varchar(1),
 @PaymentIdFrom varchar(8),
 @PaymentIdTo varchar(8)
as

Begin
 Declare @sqlQuery varchar(5000)
 DECLARE @sqlWhere VARCHAR(5000)
 DECLARE @sqlGroupBy VARCHAR(5000)

	IF object_id('[@tmpInvoices]') is not null
		Drop Table [@tmpInvoices]
		
	IF object_id('[@tmpPaymentsMismatch]') is not null		
		Drop Table [@tmpPaymentsMismatch]
		
	Set @sqlWhere=''
	Set @sqlGroupBy=''
		
	SET @sqlQuery =	'select distinct  P.PaymentId into [@tmpPaymentsMismatch]
					from Payments P  with (nolock)
					inner join (Select I.PaymentID, sum(isnull(TotalCost,0)) - sum(isnull(adjustment1,0))  as [To Pay Amount]
								from InvoiceDetails I  with (nolock)
								inner join InvoicesSupplier SI with (nolock) on SI.SupplierInvoiceId = I.SupplierInvoiceId
								where 1=1 '
					if(@SupplierId <>'-1')
						set @sqlQuery = @sqlQuery + ' and I.SupplierId= ' + @SupplierId
				
					if(@ChainId<>'-1')
						set @sqlQuery = @sqlQuery + ' and I.ChainID= ' + @ChainId 
					
					set @sqlQuery = @sqlQuery + ' group by I.PaymentID
						) I on P.PaymentId=I.PaymentID
						where abs(P.AmountOriginallyBilled-[To Pay Amount])  >1'
					
			if(@SupplierId <>'-1')
				set @sqlQuery = @sqlQuery + ' and P.PayeeEntityID= ' + @SupplierId
		
			if(@ChainId<>'-1')
				set @sqlQuery = @sqlQuery + ' and P.PayerEntityID= ' + @ChainId
			
			if(@Status <>'-1')
				set @sqlQuery = @sqlQuery + ' and P.PaymentStatus='+ @Status
					
	set @sqlQuery = @sqlQuery + ' Order by 1 desc '
	
	print(@sqlQuery)
	exec (@sqlQuery)
	
	if(@ItemLevel=0)
		Begin	 
		   SET @sqlQuery = 'select distinct S.SupplierIdentifier AS [Wholesaler Id],
											S.SupplierName as [Supplier Name], 
											C.ChainName as [Retailer Name], 
											sb.Banner as Banner,
											ss.StoreIdentifier as [Store Number], 
											Ir.SupplierInvoiceId as [Invoice No], 
											convert(varchar,IR.InvoiceDate,101) as [InvoiceCreationDate],
											convert(varchar,IR.InvoicePeriodStart,101) as SupplierBillingFromDate,
											convert(varchar,IR.InvoicePeriodEnd,101) as SupplierBillingToDate,
											IR.OriginalAmount as NetInvoice, 
											SUM(ID.TotalRetail) as Retail, 
											case when S.IsRegulated=0 then  SUM(ID.TotalCost-isnull(ID.Adjustment1,0)) else SUM(ID.TotalCost) end as [To Pay], 
											Pd.BatchNo  AS  [Batch Number],
											Pd.Checkno  AS  [Check Number],
											convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
											IT.InvoiceTypeName as InvoiceType,
											convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
											(PH.CheckNoReceived) as RetailerCheckNumber,
											ST.StatusName AS [Payment Status], 
											P.PaymentId, 
											ID.SupplierID,
											ID.Storeid,
											S.SupplierIdentifier AS [Supplier ID]
					
					from InvoicesSupplier IR with (nolock) 
					inner join InvoiceDetails ID with (nolock) on ID.SupplierInvoiceID=IR.SupplierInvoiceID
					inner join Suppliers S with (nolock) on ID.SupplierID=S.SupplierID
					inner join Chains c with (nolock) on ID.chainid=c.chainid
					inner join stores ss with (nolock) on ID.StoreID=ss.StoreID 
					inner join supplierbanners sb with (nolock) on sb.supplierid=ID.supplierid AND ss.Custom1=sb.Banner AND ss.Custom1=sb.Banner AND sb.Status=''Active''
					inner join Payments P with (nolock) on P.PaymentID=ID.PaymentID
					inner join PaymentHistory PH with (nolock) on PH.PaymentID=ID.PaymentID and Ph.PaymentStatus=P.Paymentstatus
					inner join (Select PaymentId, MAX(DateTimeCreated) as DateTimeCreated
									from PaymentHistory with (nolock) 
									group by PaymentId
								) P1 on P1.PaymentId=PH.PaymentId  and P1.DateTimeCreated=PH.DateTimeCreated 
					inner join Statuses ST with (nolock) on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
					inner join InvoiceTypes IT with (nolock) on IR.InvoiceTypeID=IT.InvoiceTypeID
					left join PaymentDisbursements PD with (nolock) on PD.DisbursementId=PH.DisbursementID and isnull(PD.VoidStatus,0)<>1 
					where 1=1 '
				
			if(@RegulatedSupplier<>'-1')
				set @sqlQuery = @sqlQuery + ' and S.IsRegulated=' + @RegulatedSupplier
							
			Set @sqlGroupBy =' group by S.SupplierName,S.SupplierIdentifier, C.ChainName,sb.Banner, ss.StoreIdentifier, Ir.SupplierInvoiceId,S.IsRegulated, 
					convert(varchar,IR.InvoiceDate,101), convert(varchar,IR.InvoicePeriodStart,101), convert(varchar,IR.InvoicePeriodEnd,101), 
					Pd.BatchNo, Pd.Checkno, convert(varchar,Pd.DisbursementDate,101), IT.InvoiceTypeName, IR.OriginalAmount,
					convert(varchar,PH.DatePaymentReceived,101), PH.CheckNoReceived, ST.StatusName, P.PaymentID, ID.SupplierID,ID.Storeid'					
		End

	if(@ItemLevel=1)
		Begin	 
		   SET @sqlQuery = 'select distinct S.SupplierIdentifier AS [Wholesaler Id],
											S.SupplierName as [Supplier Name], 
											C.ChainName as [Retailer Name], 
											sb.Banner as Banner,
											ss.StoreIdentifier as [Store Number],
											'''' as [Invoice No], 
											'''' as [InvoiceCreationDate],
											'''' as SupplierBillingFromDate,
											'''' as SupplierBillingToDate,
											SUM(ID.TotalCost) as NetInvoice, 
											case when S.IsRegulated=0 then SUM(ID.TotalCost-isnull(ID.Adjustment1,0)) else SUM(ID.TotalCost) end as TotalPaid, SUM(ID.TotalRetail) as Retail, 
											Pd.BatchNo  AS  [Batch Number],
											Pd.Checkno  AS  [Check Number],
											convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
											'''' as InvoiceType,
											convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
											(PH.CheckNoReceived) as RetailerCheckNumber,
											ST.StatusName AS [Payment Status], 
											P.PaymentId, 
											ID.SupplierID,
											ID.Storeid
					
					into [@tmpInvoices]
					from InvoicesSupplier IR with (nolock)
					inner join InvoiceDetails ID with (nolock) on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss with (nolock) on ID.StoreID=ss.StoreID  
					inner join supplierbanners sb with (nolock) on sb.supplierid=ID.supplierid AND ss.Custom1=sb.Banner AND sb.Status=''Active''
					inner join Chains c with (nolock) on ID.chainid=c.chainid
					inner join Suppliers S with (nolock) on ID.SupplierID=S.SupplierID
					inner join Payments P with (nolock) on P.PaymentID=ID.PaymentID
					inner join PaymentHistory PH with (nolock) on PH.PaymentID=ID.PaymentID and Ph.PaymentStatus=P.Paymentstatus
					inner join (Select PaymentId, MAX(DateTimeCreated) as DateTimeCreated
									from PaymentHistory with (nolock) 
									group by PaymentId
								) P1 on P1.PaymentId=PH.PaymentId  and P1.DateTimeCreated=PH.DateTimeCreated 
					inner join Statuses ST with (nolock) on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
					inner join InvoiceTypes IT with (nolock) on IR.InvoiceTypeID=IT.InvoiceTypeID
					left join PaymentDisbursements PD with (nolock) on PD.DisbursementId=PH.DisbursementID and isnull(PD.VoidStatus,0)<>1 
					where 1=1 '
			
			if(@RegulatedSupplier<>'-1')
				set @sqlQuery = @sqlQuery + ' and S.IsRegulated=' + @RegulatedSupplier
								
			Set @sqlGroupBy =' group by S.SupplierName,S.SupplierIdentifier, C.ChainName,sb.Banner, ss.StoreIdentifier, Ir.SupplierInvoiceId, S.IsRegulated,
					convert(varchar,IR.InvoiceDate,101), convert(varchar,IR.InvoicePeriodStart,101), convert(varchar,IR.InvoicePeriodEnd,101), 
					Pd.BatchNo, Pd.Checkno, convert(varchar,Pd.DisbursementDate,101), IT.InvoiceTypeName, 
					convert(varchar,PH.DatePaymentReceived,101), PH.CheckNoReceived, ST.StatusName, P.PaymentID, ID.SupplierID,ID.Storeid'
					
		End
		if(@ItemLevel=2)
		Begin	 
		   SET @sqlQuery = 'select S.SupplierIdentifier AS [Wholesaler Id],
											S.SupplierName as [Supplier Name], 
											C.ChainName as [Retailer Name],
											'''' as Banner, 
											'''' as [Store Number],
											'''' as [Invoice No], 
											'''' as [InvoiceCreationDate],
											'''' as SupplierBillingFromDate,
											'''' as SupplierBillingToDate,
											SUM(ID.TotalCost) as NetInvoice, 
											case when S.IsRegulated=0 then SUM(ID.TotalCost-isnull(ID.Adjustment1,0)) else SUM(ID.TotalCost) end as TotalPaid, SUM(ID.TotalRetail) as Retail, 
											Pd.BatchNo AS  [Batch Number],
											Pd.Checkno AS  [Check Number],
											convert(varchar,Pd.DisbursementDate,101) AS  [DisbursementDate],
											'''' as InvoiceType,
											convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
											(PH.CheckNoReceived) as RetailerCheckNumber,
											ST.StatusName AS [Payment Status], 
											P.PaymentId, 
											ID.SupplierID,
											ID.Storeid
					into [@tmpInvoices]
					from InvoicesSupplier IR with (nolock)
					inner join InvoiceDetails ID with (nolock) on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss with (nolock) on ID.StoreID=ss.StoreID  
					inner join supplierbanners sb with (nolock) on sb.supplierid=ID.supplierid AND ss.Custom1=sb.Banner AND sb.Status=''Active''
					inner join Chains c with (nolock) on ID.chainid=c.chainid
					inner join Suppliers S with (nolock) on ID.SupplierID=S.SupplierID
					inner join Payments P with (nolock) on P.PaymentID=ID.PaymentID
					inner join PaymentHistory PH with (nolock) on PH.PaymentID=ID.PaymentID and Ph.PaymentStatus=P.Paymentstatus
					inner join (Select PaymentId, MAX(DateTimeCreated) as DateTimeCreated
									from PaymentHistory with (nolock)
									group by PaymentId
								) P1 on P1.PaymentId=PH.PaymentId  and P1.DateTimeCreated=PH.DateTimeCreated 	
					inner join Statuses ST with (nolock) on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
					inner join InvoiceTypes IT with (nolock) on IR.InvoiceTypeID=IT.InvoiceTypeID
					left join PaymentDisbursements PD with (nolock) on PD.DisbursementId=PH.DisbursementID and isnull(PD.VoidStatus,0)<>1 
					where 1=1 '
			if(@RegulatedSupplier<>'-1')
				set @sqlQuery = @sqlQuery + ' and S.IsRegulated=' + @RegulatedSupplier
									
			Set @sqlGroupBy =' group by S.SupplierName,S.SupplierIdentifier, C.ChainName,sb.Banner, ss.StoreIdentifier, Ir.SupplierInvoiceId, S.IsRegulated,
					convert(varchar,IR.InvoiceDate,101), convert(varchar,IR.InvoicePeriodStart,101), convert(varchar,IR.InvoicePeriodEnd,101), 
					Pd.BatchNo, Pd.Checkno, convert(varchar,Pd.DisbursementDate,101), IT.InvoiceTypeName, 
					convert(varchar,PH.DatePaymentReceived,101), PH.CheckNoReceived, ST.StatusName, P.PaymentID, ID.SupplierID,ID.Storeid'
					
		End
	
	set @sqlWhere = @sqlWhere + 'and P.AmountOriginallyBilled<>0 '
	
	if(convert(date, @StartDate ) > convert(date,'1900-01-01'))
		set @sqlWhere = @sqlWhere + ' and InvoicePeriodEnd >= ''' + @StartDate + ''''
		
	if(convert(date, @EndDate ) > convert(date,'1900-01-01'))
		set @sqlWhere = @sqlWhere + ' and InvoicePeriodEnd <= ''' + @EndDate + ''''
	
	if(convert(date, @InvoiceCreationFromDate ) > convert(date,'1900-01-01'))
		set @sqlWhere = @sqlWhere + ' and convert(date, IR.InvoiceDate) >= ''' + @InvoiceCreationFromDate + ''''
	
	if(convert(date, @InvoiceCreationToDate ) > convert(date,'1900-01-01'))
		set @sqlWhere = @sqlWhere + ' and convert(date, IR.InvoiceDate) <= ''' + @InvoiceCreationToDate + ''''
	
	If(@CheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno = ' + @CheckNo 
		
	If(@StartCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno >= ' + @StartCheckNo 
		
	If(@EndStartCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno <= ' + @EndStartCheckNo 
		
	if(@SupplierId <>'-1')
		set @sqlWhere = @sqlWhere + ' and ID.SupplierId= ' + @SupplierId
		
	if(@ChainId<>'-1')
		set @sqlWhere = @sqlWhere + ' and ID.ChainID= ' + @ChainId      
	
	if(@custom1<>'-1')
           set @sqlWhere = @sqlWhere + ' and sb.Banner=''' + @custom1 + ''''
          
	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = StoreNo
		if (@StoreIdentifierType=1) 
				set @sqlQuery = @sqlQuery + ' and SS.StoreIdentifier ' + @StoreIdentifierValue 
		else if (@StoreIdentifierType=2) 
				set @sqlQuery = @sqlQuery + ' and SS.Custom2 ' + @StoreIdentifierValue 
		else if (@StoreIdentifierType=3) 
				set @sqlQuery = @sqlQuery + ' and SS.StoreName ' + @StoreIdentifierValue 
	end
				
	if(@Status <>'-1')
		set @sqlWhere = @sqlWhere + ' and P.PaymentStatus='+ @Status
	
	if(@Status = '10' or @Status = '11')
		set @sqlWhere = @sqlWhere + '  and  PD.CheckNo is not null 		'
	
	if(@TotalsMatch='1')
		set @sqlWhere = @sqlWhere + ' and P.PaymentId not in (Select PaymentID from [@tmpPaymentsMismatch])'
	
	else if(@TotalsMatch='0')
		set @sqlWhere = @sqlWhere + ' and P.PaymentId in (Select PaymentID from [@tmpPaymentsMismatch])'
				
	if(@InvoiceType <>'-1')
		set @sqlWhere = @sqlWhere + ' and IT.InvoiceTypeId in ('+ @InvoiceType	+ ')'
		
	if(@SupplierIdentifierValue<>'')
		set @sqlWhere = @sqlWhere + ' and S.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
		
	if(@RetailerIdentifierValue<>'')
		set @sqlWhere = @sqlWhere + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
		
	if(@PaymentIdFrom <> '')
		set @sqlWhere = @sqlWhere + ' and P.PaymentId > =' + @PaymentIdFrom
		
	if(@PaymentIdTo <> '')
		set @sqlWhere = @sqlWhere + ' and P.PaymentId < =' + @PaymentIdTo
	
	set @sqlQuery = @sqlQuery + @sqlWhere + @sqlGroupBy
	
	print (@sqlQuery);
	exec(@sqlQuery);
	
	if(@ItemLevel>0)
	Begin	 
		 Select [Wholesaler Id] AS [Wholesaler Id],
		        [Supplier Name], 
				[Retailer Name], 
				[Banner],
				[Store Number],
				[Invoice No], 
				[InvoiceCreationDate],
				SupplierBillingFromDate,
				SupplierBillingToDate,
				sum(NetInvoice) as NetInvoice, 
				SUM(Retail) as Retail, 
				SUM(TotalPaid) as [To Pay], 
				[Batch Number],[Check Number],
				[DisbursementDate],
				InvoiceType,
				PayDateFromRetailer,
				RetailerCheckNumber,
				[Payment Status], 
				PaymentId  
				
				
				from [@tmpInvoices]
				group by [Supplier Name],[Wholesaler Id], [Retailer Name],[Banner], [Store Number],[Invoice No],[InvoiceCreationDate],
				SupplierBillingFromDate,	SupplierBillingToDate, [Batch Number],[Check Number],
				 [DisbursementDate], InvoiceType, PayDateFromRetailer,
				RetailerCheckNumber, [Payment Status], PaymentId 
				order by PaymentId
	end		
	
	begin try
		Drop Table [@tmpInvoices]
	end try
	begin catch
	end catch			
End
GO
