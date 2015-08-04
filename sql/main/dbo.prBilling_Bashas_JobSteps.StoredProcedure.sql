USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Bashas_JobSteps]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Bashas_JobSteps]
as

exec [prGetInboundPOSTransactions_Debug_BAS]

exec [dbo].[prValidateStoresInStoreTransactions_Working]

exec [dbo].[prValidateProductsInStoreTransactions_Working]

exec [dbo].[prValidateSuppliersInStoreTransactions_Working]

--select workingstatus as stat, *
----select workingstatus as stat, suppliername as supplier, *
----update w set w.supplierid = 40557, w.workingstatus = 3
--from storetransactions_working w
--where 1 = 1
--and ChainIdentifier = 'BAS'
--and CAST(datetimecreated as date) = '9/24/2013'
----and chainid = 60620
----and w.workingstatus = 2
----and charindex('Bimbo', SupplierName) > 0
--order by workingstatus
----order by workingstatus, suppliername

exec [prValidateSourceInStoreTransactions_Working]


exec [dbo].[prValidateTransactionTypeInStoreTransactions_Working_NOMERGE_TempTables_Debug_BAS]

--select *
--from storetransactions_working w
--where 1 = 1
--and ChainId = 60620
--and CAST(datetimecreated as date) = '9/24/2013'

exec [prInvoiceDetail_ReleaseStoreTransactions]

exec [dbo].[prInvoiceDetail_POS_Create_NOMERGE]

exec prInvoices_Retailer_Create_InvoiceNo_GroupBy 'DAILY'

--select *
----select distinct supplierid
--from datatrue_main.dbo.invoicedetails [No Lock]
--where chainid = 60620
--and cast(datetimecreated as date) = '9/26/2013'
--order by RetailerInvoiceID 

--exec [prBilling_EDIDatabase_Sync]


INSERT INTO [DataTrue_EDI].[dbo].[InvoiceDetails]
           ([InvoiceDetailID]
           ,[RetailerInvoiceID]
           ,[SupplierInvoiceID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[UnitCost]
           ,[UnitRetail]
           ,[TotalCost]
           ,[TotalRetail]
           ,[SaleDate]
           ,[RecordStatus]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[BatchID]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[ProductIdentifier]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[BrandIdentifier]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[Allowance]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[Banner]
           ,PromoTypeID
			,PromoAllowance
			,SBTNumber
      ,[FinalInvoiceTotalCost]
      ,[OriginalShrinkTotalQty]
      ,[PaymentDueDate]
      ,[PaymentID]
      ,[Adjustment1]
      ,[Adjustment2]
      ,[Adjustment3]
      ,[Adjustment4]
      ,[Adjustment5]
      ,[Adjustment6]
      ,[Adjustment7]
      ,[Adjustment8]
      ,[PDIParticipant]
      ,[RetailUOM]
      ,[RetailTotalQty]
      ,[VIN]
      ,[RawStoreIdentifier]
      ,[Route]
)
SELECT [InvoiceDetailID]
      ,[RetailerInvoiceID]
      ,[SupplierInvoiceID]
      ,[ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      ,[InvoiceDetailTypeID]
      ,[TotalQty]
      ,[UnitCost]
      ,[UnitRetail]
      ,[TotalCost]
      ,[TotalRetail]
      ,[SaleDate]
      --change here wait
      ,case when upper(banner) = 'SS' then 2 else 0 end
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BatchID]
                 ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[StoreName]
           ,[ProductIdentifier]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[BrandIdentifier]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[Allowance]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[Banner]
           ,PromoTypeID
			,isnull(PromoAllowance, 0)
			,SBTNumber
      ,[FinalInvoiceTotalCost]
      ,[OriginalShrinkTotalQty]
      ,[PaymentDueDate]
      ,[PaymentID]
      ,[Adjustment1]
      ,[Adjustment2]
      ,[Adjustment3]
      ,[Adjustment4]
      ,[Adjustment5]
      ,[Adjustment6]
      ,[Adjustment7]
      ,[Adjustment8]
      ,[PDIParticipant]
      ,[RetailUOM]
      ,[RetailTotalQty]
      ,[VIN]
      ,[RawStoreIdentifier]
      ,[Route]
--select *
  FROM [DataTrue_Main].[dbo].[InvoiceDetails]
	where 1 = 1
	--and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_Main..EDI_InvoiceDetailIDs)
	and InvoiceDetailID not in (select InvoiceDetailID from DataTrue_EDI..InvoiceDetails)
	and RetailerInvoiceID is not null
	and RetailerInvoiceID not in  (-33, -1)
	and CAST(datetimecreated as date) = CAST(GETDATE() as date)
	and InvoiceDetailTypeID = 1
	and isnull(PDIParticipant, 0) <> 1

insert into DataTrue_EDI..InvoicesRetailer 
select * from DataTrue_Main..InvoicesRetailer
where retailerinvoiceid not in (select retailerinvoiceid from DataTrue_EDI..InvoicesRetailer)

update d set d.recordstatus = 1
--select *
from datatrue_edi.dbo.invoicedetails d --[No Lock]
where chainid = 60620
and cast(datetimecreated as date) = CAST(GETDATE() as date)
--order by retailerinvoiceid

--select *
--from datatrue_main.dbo.invoicedetails d --[No Lock]
--where chainid = 62348
--and cast(datetimecreated as date) = CAST(GETDATE() as date)


update s set s.BillingComplete = 1, BillingIsRunning = 1
--select *
from datatrue_edi.dbo.ProcessStatus s
where ChainName = 'BAS'
and CAST(date as date) = CAST(GETDATE() as date)

exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Bashas Billing Job Complete'
,'Bashas invoicing has been completed for today''s POS files'
,'DataTrue System', 0, 'datatrueit@icontroldsd.com;Edi@icontroldsd.com'

update w set w.workingstatus = -8999
--select *
from storetransactions_working w
where 1 = 1
and chainid = 60620
and workingstatus in (1,2,3,4)


--select *
--from storetransactions w
--where 1 = 1
--and chainid = 60620
--and cast(datetimecreated as date) = '8/29/2013'



--select *
--from StoreTransactions_Working
--where ChainIdentifier = 'DQ'
--and CAST(datetimecreated as date) = '9/12/2013'
--order by storeid

exec [dbo].[prGetInboundPOSTransactions_Newspapers]

exec [dbo].[prValidateStoresInStoreTransactions_Working_Newspapers]

exec [dbo].[prValidateProductsInStoreTransactions_Working_Newspapers]

exec [dbo].[prValidateSuppliersInStoreTransactions_Working_Newpapers]

exec [dbo].[prValidateSourceInStoreTransactions_Working_Newspapers]

exec [dbo].[prValidateTransactionTypeInStoreTransactions_Working_Newspapers]

--select *
----update w set w.supplierid = 26922
--from StoreTransactions_Working w
--where chainid = 62362
----and ChainIdentifier = 'DQ'
--and CAST(datetimecreated as date) = '9/12/2013'
--and SupplierID = 0
--order by supplierid

--SELECT *
--  FROM [Import].[dbo].[DQ_Master_list]
--  where productid = 37906
--  order by storeidentifier

--select *
--from storesetup
--where ProductID = 37906
--and StoreID in (62396,62376)




return
GO
