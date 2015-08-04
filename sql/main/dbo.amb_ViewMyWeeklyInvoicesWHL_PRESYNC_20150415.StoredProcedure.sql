USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewMyWeeklyInvoicesWHL_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---Exec amb_ViewMyWeeklyInvoicesWHL 'TA','-1','','','05/20/2012','WR1428','24503'
---Exec amb_ViewMyWeeklyInvoicesWHL 'BN','-1','','','01/01/1900','STC','35157'

---Exec amb_ViewMyWeeklyInvoicesWHL 'DQ','-1','','','09/15/2013','CLL','24164'
---Exec amb_ViewMyWeeklyInvoicesWHL 'CF','-1','','','03/09/2014','NYDNW','28822'

---Exec amb_ViewMyWeeklyInvoicesWHL 'MAV','-1','','1360274','02/15/2015','WR715','25391'

---Exec amb_ViewMyWeeklyInvoicesWHL 'SV','-1','','','01/25/2015','WR715','25391'

CREATE procedure [dbo].[amb_ViewMyWeeklyInvoicesWHL_PRESYNC_20150415]
(
	@ChainID varchar(10),
	@State varchar(20),
	@Store varchar(20),
	@Invoice varchar(20),
	@WeekEnd varchar(20),
	@WholesalerIdentifier varchar(10),
    @WholesalerId varchar(10)
)

AS 
BEGIN
	DECLARE @SqlNewDb varchar(max)
	Declare @sqlQuery varchar(4000)

	SET @SqlNewDb = ' SELECT distinct Adjustment1,dbo.GetWeekEnd_TimeOutFix(saledate,bc.BillingControlDay) AS WeekEnd,ID.ChainID,ID.ProductID,ID.SupplierID,ID.StoreID
					Into #tmpAdjustment 
					from InvoiceDetails ID WITH (NOLOCK) 
					LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ID.SupplierID AND BC.ChainID =Id.ChainID
					where 1=1 '
	
	if(@ChainID<>'-1')
	   set @SqlNewDb= @SqlNewDb+ ' AND ID.ChainID = (Select Chains.ChainID From Chains Where ChainIDentifier=''' + @ChainID+''')'

	if(@WholesalerId<>'-1')
	   set @SqlNewDb= @SqlNewDb+ ' AND ID.SupplierID = ''' + @WholesalerId+''' 

	  SELECT DISTINCT convert(varchar,ISup.InvoicePeriodEnd,101) as WeekEnding,
					S.StoreIdentifier as StoreNumber 
					, A.Address1 as Address
					, A.State 
					, CONVERT(varchar(10),ISup.supplierInvoiceID) AS InvoiceNo
					, ''<a href="invoice_whls_pdf.aspx?InvoiceNo=''+  
					CONVERT(varchar(10),ISup.supplierInvoiceID) + ''>'' + C.ChainIdentifier + ''">'' + CONVERT(varchar(10),ISup.supplierInvoiceID)  +'' </a>'' as InvoiceNo1,
					--isnull(dbo.GetAdjustments(ID.ChainID,id.SupplierID,ID.StoreID,''-1'',dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)),0) as Charges,
					''0.00'' as Charges,
					isnull(ISup.OpenAmount,0)-isnull(dbo.GetAdjustments(ID.ChainID,id.SupplierID,ID.StoreID,''-1'',dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)),0)  as Credits,
					--isnull(ISup.OpenAmount,0) - isnull(Sum(tmpAdj.Adjustment1),0)  as Credits,
					0 as Shortages ,
					--ISNULL(SF.ServiceFeeFactorValue,0) as DeliveryFee,
					--''0.00'' as DeliveryFee,
					isnull(dbo.[GetServiceFee](ID.ChainID,id.SupplierID,ID.StoreID,''-1''),0) AS DeliveryFee,
					isnull(ISup.OriginalAmount,0)-isnull(dbo.GetAdjustments(ID.ChainID,id.SupplierID,ID.StoreID,''-1'',dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)),0)  + isnull(dbo.[GetServiceFee](ID.ChainID,id.SupplierID,ID.StoreID,''-1''),0) as NetInvoice,
					--isnull(ISup.OriginalAmount,0)-isnull(Sum(tmpAdj.Adjustment1),0)  + isnull(dbo.[GetServiceFee](ID.ChainID,id.SupplierID,ID.StoreID,''-1''),0) as NetInvoice,
					IT.InvoiceTypeName as InvType,
					''<a href="invoice_whls_combined_pdf.aspx?InvoiceNo=''+ CONVERT(varchar(10), ISup.supplierInvoiceID) + ''>'' + C.ChainIdentifier +''"> POS+DCR Combined </a>'' as InvoiceNo2 
					
					FROM dbo.invoicesSupplier ISup  WITH (NOLOCK) 
				    INNER JOIN dbo.InvoiceDetails ID  WITH (NOLOCK) ON ID.supplierInvoiceID=ISup.SupplierInvoiceID	and RetailerInvoiceID<>0
					INNER JOIN dbo.Stores S  WITH (NOLOCK) ON ID.StoreID=S.StoreID
					INNER JOIN dbo.Addresses A  WITH (NOLOCK) on A.OwnerEntityID=S.StoreId
					INNER JOIN dbo.invoicetypes IT  WITH (NOLOCK) on isup.InvoiceTypeID=IT.InvoiceTypeID and IT.InvoiceTypeID NOT IN (10,16)
					INNER JOIN dbo.Chains C  WITH (NOLOCK) ON S.ChainID = C.ChainID
					LEFT JOIN dbo.PaymentHistory P WITH (NOLOCK) ON ID.PaymentID=p.PaymentID
				    LEFT JOIN dbo.PaymentDisbursements pd  WITH (NOLOCK) ON p.DisbursementID=pd.DisbursementID  and pd.VoidStatus is Null
				    LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ID.SupplierID AND BC.ChainID = C.ChainID
					--INNER JOIN dbo.PaymentDisbursements pd  WITH (NOLOCK) ON p.DisbursementID=pd.DisbursementID
					--Left JOIN dbo.ServiceFees  SF  WITH (NOLOCK) on SF.SupplierID=ISup.SupplierID
					--INNER JOIN #tmpAdjustment tmpAdj WITH(NOLOCK) ON tmpAdj.ChainID=ID.ChainID 
					--							AND tmpADj.SupplierID=ID.SupplierID 
					--							AND tmpAdj.StoreID=ID.StoreID 
					--							AND tmpADj.ProductID=ID.ProductID
					--						   AND dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)=tmpAdj.WeekEnd
					Where ISup.SupplierID='+ @WholesalerId
					
	if(@ChainID<>'-1')
	   set @SqlNewDb= @SqlNewDb+ ' AND C.ChainIdentifier = ''' + @ChainID+''' '
	
	if(@State<>'-1')
	   set @SqlNewDb= @SqlNewDb+ ' AND A.State = ''' + @State+''' '
	
	if(@Store<>'-1')
	   set @SqlNewDb= @SqlNewDb+ ' AND S.StoreIdentifier like ''%'+@Store+'%'''
	
	if(@Invoice<>'')
	   set @SqlNewDb= @SqlNewDb+ ' AND ISup.supplierInvoiceID like ''%'+@Invoice+'%'''
	
	if(CAST(@WeekEnd AS DATE) <> CAST('1900-01-01' AS DATE))
	   set @SqlNewDb= @SqlNewDb+ ' AND ISup.InvoicePeriodEnd  = ''' +CONVERT(VARCHAR,+ @WeekEnd,101)+''''	

	SET @SqlNewDb = @SqlNewDb + ' GROUP BY convert(varchar,ISup.InvoicePeriodEnd,101)
						, S.StoreIdentifier 
						, A.Address1 
						, A.State 
						, CONVERT(varchar(10),ISup.supplierInvoiceID) 
						, C.ChainIdentifier  
						, ISup.OpenAmount
						, IT.InvoiceTypeName
						, ID.ChainID
						, id.SupplierID
						, ID.StoreID 
						, PD.Checkno
						, ISup.OriginalAmount
						,dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)
						 '
 
	SET @SqlNewDb = @SqlNewDb + ' ORDER BY  WeekEnding , S.StoreIdentifier,IT.InvoiceTypeName Desc;'  
	
	print(@SqlNewDb); 
	Exec(@SqlNewDb); 
 End
GO
