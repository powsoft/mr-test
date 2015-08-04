USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetInvoicesDetails_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_GetInvoicesDetails_Beta '-1','-1','','-1','1900-01-01','1900-01-01','-1','','','','[Store Number] ASC',1,25,0
--exec amb_GetInvoicesDetails_Beta 'CLL','DQ','','-1','09/9/2013','09/15/2013','-1','','','','[Store Number] ASC',1,25,0
CREATE procedure [dbo].[amb_GetInvoicesDetails_Beta]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreNumber varchar(20),
 @Status varchar(20),
 @StartDate varchar(50),
 @EndDate  varchar(50),
 @InvoiceType varchar(50),
 @RetailerCheckNo varchar(50),
 @SupplierCheckNo varchar(50),
 @InvoiceNumber  varchar(50),
 @OrderBy varchar(100),
 @StartIndex int,
 @PageSize int,
 @DisplayMode int
as

Begin
 Declare @sqlQuery varchar(8000)
 Declare @sqlQueryFinal varchar(8000)
	
		SET @sqlQuery = ' select t.LegacySystemStoreIdentifier  as [Store Number],i.SupplierInvoiceID as [Invoice No],
							convert(datetime,IR.InvoiceDate,101) as [InvoiceCreationDate],
							convert(datetime,IR.InvoicePeriodStart,101) as InvoicePeriodStart,
							convert(datetime,IR.InvoicePeriodEnd,101) as InvoicePeriodEnd,
							PH.AmountPaid as TotalPaid,
							SUM(TotalCost-Adjustment1) as NetInvoice, 
							convert(datetime,PH.DatePaymentReceived,101) as PayDateFromRetailer,
							(PH.CheckNoReceived) as RetailerCheckNumber,
							IT.InvoiceTypeName as InvoiceType,
							 convert(datetime,Pd.DisbursementDate,101)  AS  [DisbursementDate],
							 Pd.BatchNo  AS  [Batch Number],
							 Pd.Checkno  AS  [Check Number],
							 ST.StatusName AS [Payment Status], P.PaymentId, S.SupplierIdentifier as [Wholesaler Id]
							 from InvoiceDetails i join Suppliers s
							 on i.SupplierID=s.SupplierID
							 join Stores t on i.StoreID=t.StoreID
							 join InvoicesSupplier IR on IR.SupplierInvoiceID=i.SupplierInvoiceID
							 join Payments P on i.PaymentID=p.PaymentID
							 join Statuses ST on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
							 join PaymentHistory PH on PH.PaymentID=P.PaymentID and Ph.PaymentStatus=P.Paymentstatus
							 join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
							 left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID 
							 join Chains c on c.ChainID=i.ChainID and i.SupplierInvoiceID is not null and i.RetailerInvoiceID<>0
							 where 1=1 '
		
		if(CAST(@StartDate as DATE) > CAST('1900-01-01' as DATE))
			set @sqlQuery = @sqlQuery + ' and InvoicePeriodEnd >= ''' + Convert(varchar,+@StartDate,101) + ''''
			
		if(CAST(@EndDate as DATE) > CAST('1900-01-01' as DATE))
			set @sqlQuery = @sqlQuery + ' and InvoicePeriodEnd <= ''' + Convert(varchar,+@EndDate,101) + ''''
			
		If(@RetailerCheckNo<>'')
			set @sqlQuery = @sqlQuery + ' and PH.CheckNoReceived like ''%' + @RetailerCheckNo  + '%'''
			
		If(@SupplierCheckNo<>'')
			set @sqlQuery = @sqlQuery + ' and PD.Checkno like ''%' + @SupplierCheckNo  + '%'''
			
		If(@InvoiceNumber<>'')
			set @sqlQuery = @sqlQuery + ' and Ir.SupplierInvoiceId like ''%' + @InvoiceNumber  + '%'''
						
		if(@SupplierId <>'-1')
			set @sqlQuery = @sqlQuery + ' and S.SupplierIdentifier= ''' + @SupplierId+''''
			
		if(@ChainId<>'-1')
			set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier= ''' + @ChainId +''''    
		      	               
		if(@StoreNumber <>'')
		   set @sqlQuery = @sqlQuery + ' and t.LegacySystemStoreIdentifier like ''%' + @StoreNumber +'%'''
					
		if(@Status <>'-1')
			set @sqlQuery = @sqlQuery + ' and P.PaymentStatus='+ @Status
		
		if(@Status = '10' or @Status = '11')
			set @sqlQuery = @sqlQuery + '  and PD.CheckNo is not null '
		
		if(@InvoiceType <>'-1')
			set @sqlQuery = @sqlQuery + ' and IT.InvoiceTypeId='+ @InvoiceType			
		
		set @sqlQuery = @sqlQuery + ' group by t.LegacySystemStoreIdentifier,i.SupplierInvoiceID,IR.InvoicePeriodStart,IR.InvoicePeriodEnd,IR.InvoiceDate,
										 PH.AmountPaid,PH.DatePaymentReceived,PH.CheckNoReceived, 
										 IT.InvoiceTypeName,convert(datetime,Pd.DisbursementDate,101),Pd.BatchNo,
										 Pd.Checkno, ST.StatusName, P.PaymentId, S.SupplierIdentifier
 
  '

			set @sqlQuery = [dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  (  '+ @sqlQuery+ '	) as temp ', @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
			exec (@sqlQuery)
			print(@sqlQuery)
			
End
GO
