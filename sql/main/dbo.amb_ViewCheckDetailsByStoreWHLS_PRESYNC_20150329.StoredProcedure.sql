USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewCheckDetailsByStoreWHLS_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Exec [amb_ViewCheckDetailsByStoreWHLS] 'ENT','24178','109220','BN'
-- Exec [amb_ViewCheckDetailsByStoreWHLS] 'WR1428','24178','','CVS'
-- Exec [amb_ViewCheckDetailsByStoreWHLS] 'CLL','24164','764846','DQ'
-- Exec [amb_ViewCheckDetailsByStoreWHLS] 'WR333','25455','827131','LG'
-- Exec [amb_ViewCheckDetailsByStoreWHLS] 'NYDNW','28822','863887','CF'
-- Exec [amb_ViewCheckDetailsByStoreWHLS] 'WR580','34435','-1','LG'

CREATE proc [dbo].[amb_ViewCheckDetailsByStoreWHLS_PRESYNC_20150329]
(
	@SupplierIdentifier varchar(10),
	@SupplierId varchar(20),
	@CheckNum varchar(40),
	@ChainId varchar(20)
)
AS

DECLARE @sqlQueryNew varchar (8000)
DECLARE @chain_migrated_date date


BEGIN

	IF(@ChainID<>'-1')
    BEGIN
			SELECT @chain_migrated_date = cast(datemigrated AS date)
			FROM
				dbo.chains_migration
			WHERE
				chainid = @chainID;
		END


	SET @sqlQueryNew = 'select s.SupplierIdentifier AS WholesalerID,
					   c.ChainIdentifier AS ChainID,
					   st.LegacySystemStoreIdentifier as StoreID,
					   t.InvoiceDetailTypeName AS InvType,
					   t.InvoiceDetailTypeName AS InvType1,
					   Convert(varchar(12),inv.InvoicePeriodEnd,101) as WeekEnding,	
					   sum(isnull(i.TotalCost,0)) - sum(isnull(adjustment1,0)) AS SumOfTotalCheck,
					   Convert(varchar(12),d.DisbursementDate,101) AS DateIssued,
					   CONVERT(VARCHAR,d.CheckNo) AS CheckNumber,
					   IsNull(ns.SupplierAccountNumber,'''') as WHLS_StoreID
					   
				    from InvoicesSupplier inv  WITH (NOLOCK) 
					    join InvoiceDetails i  WITH (NOLOCK) on inv.SupplierInvoiceID=i.SupplierInvoiceID and RetailerInvoiceid<> 0 
					    join Payments p  WITH (NOLOCK) on i.PaymentID=p.PaymentID
					    join (Select distinct DisbursementID, PaymentID, PaymentStatus from dbo.PaymentHistory WITH (NOLOCK)) h  on p.PaymentID=h.PaymentID and h.PaymentStatus=10
					    join PaymentDisbursements d  WITH (NOLOCK) on h.DisbursementID=d.DisbursementID and d.VoidStatus is null
					    join Suppliers s  WITH (NOLOCK) on inv.SupplierID=s.SupplierID
					    join Chains c  WITH (NOLOCK) on i.ChainID=c.ChainID
					    JOIN dbo.InvoiceDetailTypes t WITH (NOLOCK)  ON i.InvoiceDetailTypeID = t.InvoiceDetailTypeID
					    join Stores st  WITH (NOLOCK) on i.StoreID=st.StoreID and i.ChainID=st.ChainID
					    left join StoresUniqueValues ns  WITH (NOLOCK) on st.StoreID=ns.StoreID and i.SupplierID=ns.SupplierID'
					    
						
	 SET @sqlQueryNew += ' where inv.SupplierID=' + @SupplierId
     	
	 IF(@CheckNum<>'' and @CheckNum<>'-1')
			SET @sqlQueryNew += ' AND d.CheckNo =''' + @CheckNum + ''''
	     
	 IF(@ChainId<>'-1')
			SET @sqlQueryNew += ' AND C.ChainIdentifier =''' + @ChainId + ''''
	     
	 IF(CAST(@chain_migrated_date AS DATE) is not null)
			SET @sqlQueryNew += ' AND cast(Inv.InvoicePeriodEnd as date) >=CAST('''+cast(@chain_migrated_date as varchar) +''' AS DATE) '
			
	   --set @sqlQueryNew += ' and i.TotalCost > 0 '

	   set @SqlQueryNew +=' group by s.SupplierIdentifier,
							  t.InvoiceDetailTypeName,
							  c.ChainIdentifier,
							  Convert(varchar(12),inv.InvoicePeriodEnd,101),
							  Convert(varchar(12),d.DisbursementDate,101),
							  CONVERT(VARCHAR,d.CheckNo),
							  st.LegacySystemStoreIdentifier,
							  ns.SupplierAccountNumber '
	PRINT (@sqlQueryNew);  
	EXEC (@sqlQueryNew);    
	    
End
GO
