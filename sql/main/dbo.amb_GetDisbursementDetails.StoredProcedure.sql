USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetDisbursementDetails]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[usp_GetDisbursementDetails]    Script Date: 11/21/2012 11:26:58 ******/

--exec amb_GetDisbursementDetails 'Alcohol5','SV','',0,'10','1900-01-01','1900-01-01','-1','',''
CREATE procedure [dbo].[amb_GetDisbursementDetails]
 @SupplierId varchar(20),
 @ChainId varchar(20),
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


	Set @sqlWhere=''
	Set @sqlGroupBy=''
	
	if(@ItemLevel=0)
		Begin	 
			SET @sqlQuery = ' Select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name],
	                S.SupplierIdentifier as WholeSalerID,
	                C.ChainIdentifier as ChainID,		
			        ss.LegacySystemStoreIdentifier as [Store Number],
					Ir.SupplierInvoiceID as [Invoice No], 
					convert(varchar,IR.InvoiceDate,101) as [InvoiceCreationDate],
					convert(varchar,IR.InvoicePeriodStart,101) as InvoicePeriodStart,
					convert(varchar,IR.InvoicePeriodEnd,101) as InvoicePeriodEnd,
					IR.OriginalAmount as NetInvoice, IR.OriginalAmount as TotalPaid,
				    PD.BatchNo  AS  [Batch Number],
					Pd.Checkno  AS  [Check Number],
					convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
					IT.InvoiceTypeName as InvoiceType,
					convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
					(PH.CheckNoReceived) as RetailerCheckNumber,
					ST.StatusName AS [Payment Status], P.PaymentId 
					from Payments P
					inner join PaymentHistory PH on PH.PaymentID=P.PaymentID and Ph.PaymentStatus=P.Paymentstatus
					inner join Statuses ST on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
					inner join InvoiceDetails ID on ID.PaymentID=P.PaymentID
					inner join InvoicesSupplier IR on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss on ss.StoreID=ID.StoreID  
					inner join Chains c on ID.chainid=c.chainid
					inner join Suppliers S on ID.SupplierID=S.SupplierID
					inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
					left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID    
					where 1=1 '
		End

	if(@ItemLevel=1)
		Begin	 
			SET @sqlQuery = 'select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name],    
	                S.SupplierIdentifier as WholeSalerID,
	                C.ChainIdentifier as ChainID,		
	          		ss.LegacySystemStoreIdentifier as [Store Number],
					'''' as [Invoice No], 
					'''' as [InvoiceCreationDate],
					'''' as InvoicePeriodStart,
					'''' as InvoicePeriodEnd,
					IR.OriginalAmount as NetInvoice, IR.OriginalAmount as TotalPaid,
					PD.BatchNo  AS  [Batch Number],
					Pd.Checkno  AS  [Check Number],
					convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
					'''' as InvoiceType,
					ID.SupplierID,ID.Storeid,convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
					(PH.CheckNoReceived) as RetailerCheckNumber,
					ST.StatusName AS [Payment Status], P.PaymentId 
					into [@tmpInvoices]
					from Payments P
					inner join PaymentHistory PH on PH.PaymentID=P.PaymentID and Ph.PaymentStatus=P.Paymentstatus
					inner join Statuses ST on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
					inner join InvoiceDetails ID on ID.PaymentID=P.PaymentID
					inner join InvoicesSupplier IR on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss on ss.StoreID=ID.StoreID  
					inner join Chains c on ID.chainid=c.chainid
					inner join Suppliers S on ID.SupplierID=S.SupplierID
					inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
					left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID
					where 1=1 '
					
		End
		
		if(@ItemLevel=2)
		Begin	 
			SET @sqlQuery = 'select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], 
	                S.SupplierIdentifier as WholeSalerID,
	                C.ChainIdentifier as ChainID,		
	           		'''' as [Store Number],
					'''' as [Invoice No], 
					'''' as [InvoiceCreationDate],
					'''' as InvoicePeriodStart,
					'''' as InvoicePeriodEnd,
					IR.OriginalAmount as NetInvoice, IR.OriginalAmount as TotalPaid,
					PD.BatchNo  AS  [Batch Number],
					Pd.Checkno AS  [Check Number],
					convert(varchar,Pd.DisbursementDate,101) AS  [DisbursementDate],
					'''' as InvoiceType,
					ID.SupplierID,ID.Storeid,convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
					(PH.CheckNoReceived) as RetailerCheckNumber,
					ST.StatusName AS [Payment Status], P.PaymentId 
					into [@tmpInvoices]
					from Payments P
					inner join PaymentHistory PH on PH.PaymentID=P.PaymentID and Ph.PaymentStatus=P.Paymentstatus
					inner join Statuses ST on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
					inner join InvoiceDetails ID on ID.PaymentID=P.PaymentID
					inner join InvoicesSupplier IR on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					inner join stores ss on ss.StoreID=ID.StoreID  
					inner join Chains c on ID.chainid=c.chainid
					inner join Suppliers S on ID.SupplierID=S.SupplierID
					inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
					left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID
					where 1=1 '
					
		End
	if(CAST(@StartDate AS DATE) > CAST('1900-01-01' AS DATE))
		set @sqlWhere = @sqlWhere + ' and InvoicePeriodStart >= ''' + convert(varchar,@StartDate,101) + ''''
		
	if(CAST(@EndDate AS DATE) > CAST('1900-01-01' AS DATE))
		set @sqlWhere = @sqlWhere + ' and InvoicePeriodEnd <= ''' + convert(varchar,@EndDate,101) + ''''
		
	If(@StartCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno >= ' + @StartCheckNo 
		
	If(@EndStartCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno <= ' + @EndStartCheckNo 
		
	if(@SupplierId <>'-1')
		set @sqlWhere = @sqlWhere + ' and S.SupplierIdentifier= ''' + @SupplierId + ''''
		
	if(@ChainId<>'-1')
		set @sqlWhere = @sqlWhere + ' and C.ChainIdentifier= ''' + @ChainId +''''    
	      	               
	if(@StoreId <>'')
	   set @sqlWhere = @sqlWhere + ' and ss.LegacySystemStoreIdentifier Like ''%' + @StoreId +'%'''
				
	if(@Status <>'-1')
		set @sqlWhere = @sqlWhere + ' and P.PaymentStatus='+ @Status
	
	if(@Status = '10' or @Status = '11')
		set @sqlWhere = @sqlWhere + '  and  PD.CheckNo is not null 		'
	
	if(@InvoiceType <>'-1')
		set @sqlWhere = @sqlWhere + ' and IT.InvoiceTypeId='+ @InvoiceType	
	
	set @sqlQuery = @sqlQuery + @sqlWhere 
	
	print(@sqlQuery);
	exec(@sqlQuery);
	
	if(@ItemLevel>0)
	Begin	 
		Select [Supplier Name], [Retailer Name],[WholeSalerID],[ChainID], [Store Number],
				[Invoice No], 
				[InvoiceCreationDate],
				InvoicePeriodStart,
				InvoicePeriodEnd,
				sum(NetInvoice) as NetInvoice, SUM(TotalPaid) as TotalPaid,
				[Check Number],
				 [Batch Number],[DisbursementDate],
				InvoiceType,
				PayDateFromRetailer,
				RetailerCheckNumber,
				[Payment Status], PaymentId  from [@tmpInvoices]
				group by [Supplier Name], [Retailer Name],[WholeSalerID],[ChainID], [Store Number],		
				 [Invoice No],[InvoiceCreationDate],
				InvoicePeriodStart,	InvoicePeriodEnd,[Check Number],
				[Batch Number],[DisbursementDate], InvoiceType, PayDateFromRetailer,
				RetailerCheckNumber, [Payment Status], PaymentId 
	end		
	
	begin try
		Drop Table [@tmpInvoices]
	end try
	begin catch
	end catch			
End
GO
