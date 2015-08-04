USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetRemittanceDetails_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_Report_StoreActivities_POS_All '75221','59977','Maverik','-1','-1','-1','0','11/17/2014','11/17/2014'
CREATE  procedure [dbo].[usp_Report_GetRemittanceDetails_All_PRESYNC_20150524]
@chainID varchar(1000),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(1000),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
  
as
Begin
Declare @sqlQuery varchar(4000)
Declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(1000)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat WITH(NOLOCK)  where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4	
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
 select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
 set @sqlQuery =  ' SELECT distinct ' + @MaxRowsCount + ' IR.SupplierInvoiceId as [Invoice No],
									S.SupplierIdentifier AS [Wholesaler Id],
									S.SupplierName as [Supplier Name], 
									C.ChainName as [Retailer Name], 
									ss.StoreIdentifier as [Store Number], 
									convert(varchar,IR.InvoiceDate,101) as [InvoiceCreationDate],
									convert(varchar,ID.SaleDate,101) as [Sale Date],
									convert(varchar,IR.InvoicePeriodStart,101) as SupplierBillingFromDate,
									convert(varchar,IR.InvoicePeriodEnd,101) as SupplierBillingToDate,
									PI.IdentifierValue as [UPC Code],
									PR.ProductName as Title,
									SUM(Cast(ID.TotalQty as Int)) as [Qty],
									SUM(ID.UnitCost) as [Unit Cost],
									SUM(IR.OriginalAmount) as NetInvoice, 
									SUM(ID.TotalRetail) as Retail, 
									case when S.IsRegulated=0 then SUM(ID.TotalCost-isnull(ID.Adjustment1,0)) else SUM(ID.TotalCost) end as [To Pay],
									case when S.IsRegulated=0 then SUM(((ID.TotalCost-isnull(ID.Adjustment1,0))*3)/100) else SUM(((ID.TotalCost)*3)/100) end as [Fee],
									case when S.IsRegulated=0 then SUM(((ID.TotalCost-isnull(ID.Adjustment1,0))*97)/100) else SUM(((ID.TotalCost)*97)/100) end as [PaidnCheckFee],
									Pd.BatchNo  AS  [Batch Number],
									Pd.Checkno  AS  [Check Number],
									convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
									IT.InvoiceTypeName as InvoiceType,
									convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
									(PH.CheckNoReceived) as RetailerCheckNumber '
   
 set @sqlQuery = @sqlQuery +  ' from InvoicesSupplier IR with (nolock) 
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
								Inner JOIN Products PR ON ID.ProductID=PR.ProductID
								INNER JOIN ProductIdentifiers PI ON PI.ProductID=ID.ProductID AND PI.ProductIdentifierTypeID IN (2,8)
								left join PaymentDisbursements PD with (nolock) on PD.DisbursementId=PH.DisbursementID and isnull(PD.VoidStatus,0)<>1 
								where 1=1 and P.AmountOriginallyBilled<>0 '
								                      
	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and ID.ChainID in (' + @ChainId +')'
  
	if(@SupplierID <>'-1') 
		set @sqlQuery = @sqlQuery + ' and ID.SupplierId in (' + @SupplierId +')'

	if(@Banner<>'All')
		set @sqlQuery = @sqlQuery + ' and sb.Banner like ''%' + @Banner + '%'''
 
	if(@ProductUPC<>'-1')
		set @sqlQuery = @sqlQuery + ' and PI.IdentifierValue like ''%' + @ProductUPC + '%''';
	
	if(@StoreId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and ss.StoreIdentifier like ''%' + @StoreId + '%'''
	
	if (@LastxDays > 0)
		set @sqlQuery = @sqlQuery + ' and (InvoicePeriodEnd >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',cast(getdate() as date)) and InvoicePeriodEnd <=cast(getdate() as date)) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and InvoicePeriodEnd >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and InvoicePeriodEnd <= ''' + @EndDate  + '''';
	
	set @sqlQuery = @sqlQuery + ' group by IR.SupplierInvoiceId,S.SupplierIdentifier,S.SupplierName,C.ChainName,ss.StoreIdentifier,
										   convert(varchar,IR.InvoiceDate,101),ID.SaleDate,convert(varchar,IR.InvoicePeriodStart,101),
										   convert(varchar,IR.InvoicePeriodEnd,101),PI.IdentifierValue,PR.ProductName,S.IsRegulated,Pd.BatchNo,
										   Pd.Checkno,convert(varchar,Pd.DisbursementDate,101),IT.InvoiceTypeName,
										   convert(varchar,PH.DatePaymentReceived,101),(PH.CheckNoReceived)'	
	set @sqlQuery = @sqlQuery + ' order by 1,2,3,11'

	print(@sqlQuery);
	execute(@sqlQuery); 
 
End
GO
