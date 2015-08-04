USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetDisbursementDetails_Old]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_GetDisbursementDetails_old '-1','42491','-1','',1,'3','1900-01-01','1900-01-01','-1','',''
CREATE procedure [dbo].[usp_GetDisbursementDetails_Old]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @Custom1 varchar(255),
 @StoreId varchar(20),
 @ItemLevel int,
 @Status varchar(20),
 @StartDate varchar(50),
 @EndDate  varchar(50),
 @InvoiceType varchar(50),
 @StartCheckNo varchar(50),
 @EndStartCheckNo varchar(50)
as

Begin
 Declare @sqlQuery varchar(5000)
 DECLARE @sqlWhere VARCHAR(5000)
 DECLARE @sqlGroupBy VARCHAR(5000)
 begin try
        Drop Table [@tmpInvoices]
end try
begin catch
end catch

	Set @sqlWhere=''
	Set @sqlGroupBy=''
	
	if(@ItemLevel=0)
		Begin	 
			SET @sqlQuery = 'select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], ss.StoreIdentifier as [Store Number],
					 Ir.SupplierInvoiceId as [Invoice No], 
					convert(varchar,IR.InvoiceDate,101) as [InvoiceCreationDate],
					convert(varchar,IR.InvoicePeriodStart,101) as InvoicePeriodStart,
					convert(varchar,IR.InvoicePeriodEnd,101) as InvoicePeriodEnd,
					IR.OriginalAmount as NetInvoice, ipfr.RetailerPaymentAmount as TotalPaid,
					case '''+@Status+''' when ''10'' then Pd.Checkno end AS  [Check Number],
					case '''+@Status+''' when ''10'' then convert(varchar,Pd.DisbursementDate,101) end AS  [DisbursementDate],
					IT.InvoiceTypeName as InvoiceType,
					convert(varchar,IPFR.DateTimeCreated,101) as PayDateFromRetailer,
					(IPFR.RetailerCheckNumber) as RetailerCheckNumber,
					case '''+@Status+'''
					WHEN ''0'' then ''Pending''
					when ''1'' then ''Transmitted''
					when ''2'' then ''Acknowledged''
					when ''3'' then ''Released By Funding''
					when ''4'' then ''Released By 820''
					when ''10'' then ''Disbursed By Check''
					when ''11'' then ''Disbursed By Check And Report Sent''
					end AS [Payment Status], P.PaymentId 
					from InvoicesSupplier IR
					inner join InvoiceDetails ID on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss on ID.StoreID=ss.StoreID  
					inner join supplierbanners sb on sb.supplierid=ID.supplierid
					inner join Chains c on ID.chainid=c.chainid
					inner join Suppliers S on ID.SupplierID=S.SupplierID
					inner join Payments P on P.PaymentID=ID.PaymentID
					inner join PaymentHistory PH on PH.PaymentID=ID.PaymentID
					inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
					inner join datatrue_edi.dbo.InvoicePaymentsFromRetailer IPFR 
					on IPFR.RetailerInvoiceID=ID.RetailerInvoiceID
					left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID  
					where 1=1 '
		End

	if(@ItemLevel=1)
		Begin	 
			SET @sqlQuery = 'select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], ss.StoreIdentifier as [Store Number],
					'''' as [Invoice No], 
					'''' as [InvoiceCreationDate],
					'''' as InvoicePeriodStart,
					'''' as InvoicePeriodEnd,
					(IR.OriginalAmount) as NetInvoice, (ipfr.RetailerPaymentAmount) as TotalPaid,
					case '''+@Status+''' when ''10'' then Pd.Checkno end AS  [Check Number],
					case '''+@Status+''' when ''10'' then convert(varchar,Pd.DisbursementDate,101) end AS  [DisbursementDate],
					'''' as InvoiceType,
					ID.SupplierID,ID.Storeid,convert(varchar,IPFR.DateTimeCreated,101) as PayDateFromRetailer,
					(IPFR.RetailerCheckNumber) as RetailerCheckNumber,
					case '''+@Status+'''
					WHEN ''0'' then ''Pending''
					when ''1'' then ''Transmitted''
					when ''2'' then ''Acknowledged''
					when ''3'' then ''Released By Funding''
					when ''4'' then ''Released By 820''
					when ''10'' then ''Disbursed By Check''
					when ''11'' then ''Disbursed By Check And Report Sent''
					end AS [Payment Status], P.PaymentId 
					into [@tmpInvoices]
					from InvoicesSupplier IR
					inner join InvoiceDetails ID on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss on ID.StoreID=ss.StoreID  
					inner join supplierbanners sb on sb.supplierid=ID.supplierid
					inner join Chains c on ID.chainid=c.chainid
					inner join Suppliers S on ID.SupplierID=S.SupplierID
					inner join Payments P on P.PaymentID=ID.PaymentID
					inner join PaymentHistory PH on PH.PaymentID=ID.PaymentID
					inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
					inner join datatrue_edi.dbo.InvoicePaymentsFromRetailer IPFR 
					on IPFR.RetailerInvoiceID=ID.RetailerInvoiceID
					left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID  
					where 1=1 '
					
		End
		if(@ItemLevel=2)
		Begin	 
			SET @sqlQuery = 'select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], '''' as [Store Number],
					'''' as [Invoice No], 
					'''' as [InvoiceCreationDate],
					'''' as InvoicePeriodStart,
					'''' as InvoicePeriodEnd,
					(IR.OriginalAmount) as NetInvoice, (ipfr.RetailerPaymentAmount) as TotalPaid,
					case '''+@Status+''' when ''10'' then Pd.Checkno end AS  [Check Number],
					case '''+@Status+''' when ''10'' then convert(varchar,Pd.DisbursementDate,101) end AS  [DisbursementDate],
					'''' as InvoiceType,
					ID.SupplierID,ID.Storeid,convert(varchar,IPFR.DateTimeCreated,101) as PayDateFromRetailer,
					(IPFR.RetailerCheckNumber) as RetailerCheckNumber,
					case '''+@Status+'''
					WHEN ''0'' then ''Pending''
					when ''1'' then ''Transmitted''
					when ''2'' then ''Acknowledged''
					when ''3'' then ''Released By Funding''
					when ''4'' then ''Released By 820''
					when ''10'' then ''Disbursed By Check''
					when ''11'' then ''Disbursed By Check And Report Sent''
					end AS [Payment Status], P.PaymentId 
					into [@tmpInvoices]
					from InvoicesSupplier IR
					inner join InvoiceDetails ID on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss on ID.StoreID=ss.StoreID  
					inner join supplierbanners sb on sb.supplierid=ID.supplierid
					inner join Chains c on ID.chainid=c.chainid
					inner join Suppliers S on ID.SupplierID=S.SupplierID
					inner join Payments P on P.PaymentID=ID.PaymentID
					inner join PaymentHistory PH on PH.PaymentID=ID.PaymentID
					inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
					inner join datatrue_edi.dbo.InvoicePaymentsFromRetailer IPFR 
					on IPFR.RetailerInvoiceID=ID.RetailerInvoiceID
					left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID  
					where 1=1 '
					
		End
	if(convert(date, @StartDate ) > convert(date,'1900-01-01'))
		set @sqlWhere = @sqlWhere + ' and InvoicePeriodEnd >= ''' + @StartDate + ''''
		
	if(convert(date, @EndDate ) > convert(date,'1900-01-01'))
		set @sqlWhere = @sqlWhere + ' and InvoicePeriodEnd <= ''' + @EndDate + ''''
		
	If(@StartCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno >= ' + @StartCheckNo 
		
	If(@EndStartCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno <= ' + @EndStartCheckNo 
		
	if(@SupplierId <>'-1')
		set @sqlWhere = @sqlWhere + ' and ID.SupplierId= ' + @SupplierId
		
	if(@ChainId<>'-1')
		set @sqlWhere = @sqlWhere + ' and ID.ChainID= ' + @ChainId      
	
	if(@custom1<>'-1')
           set @sqlWhere = @sqlWhere + 'and sb.Banner=''' + @custom1 + ''''
           	               
	if(@StoreId <>'')
	   set @sqlWhere = @sqlWhere + ' and ID.StoreId= ' + @StoreId
				
	if(@Status <>'-1')
		set @sqlWhere = @sqlWhere + ' and P.PaymentStatus='+ @Status
	
	if(@Status = '10' or @Status = '11')
		set @sqlWhere = @sqlWhere + '  and  PD.CheckNo is not null 		'
	
	if(@InvoiceType <>'-1')
		set @sqlWhere = @sqlWhere + ' and IT.InvoiceTypeId='+ @InvoiceType	
	
	set @sqlQuery = @sqlQuery + @sqlWhere 
	
	exec(@sqlQuery);
	
	if(@ItemLevel>0)
	Begin	 
		Select [Supplier Name], [Retailer Name], [Store Number],
				[Invoice No], 
				[InvoiceCreationDate],
				InvoicePeriodStart,
				InvoicePeriodEnd,
				sum(NetInvoice) as NetInvoice, SUM(TotalPaid) as TotalPaid,
				[Check Number],
				 [DisbursementDate],
				InvoiceType,
				PayDateFromRetailer,
				RetailerCheckNumber,
				[Payment Status], PaymentId  from [@tmpInvoices]
				group by [Supplier Name], [Retailer Name], [Store Number],[Invoice No],[InvoiceCreationDate],
				InvoicePeriodStart,	InvoicePeriodEnd, [Check Number],
				 [DisbursementDate], InvoiceType, PayDateFromRetailer,
				RetailerCheckNumber, [Payment Status], PaymentId 
	end					
End
GO
