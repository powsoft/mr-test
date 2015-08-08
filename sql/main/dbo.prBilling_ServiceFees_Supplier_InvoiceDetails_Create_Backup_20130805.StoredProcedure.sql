USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ServiceFees_Supplier_InvoiceDetails_Create_Backup_20130805]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prBilling_ServiceFees_Supplier_InvoiceDetails_Create_Backup_20130805]
as

declare @currentdate date
declare @lastmonthdate date
declare @lastmonthyear tinyint
declare @lastmonthmonth tinyint
declare @batchid int
declare @myid int = 44278
--select * from servicefeetypes

set @currentdate = GETDATE()
set @lastmonthdate = DATEADD(month, -1, @currentdate)
set @lastmonthyear = YEAR(@lastmonthdate)
set @lastmonthmonth = MONTH(@lastmonthdate)

select ChainID, ServiceFeeFactorValue as FeePerInvoice, 
CAST(null as int) as InvoiceCountLastMonth, CAST(null as money) as FeeTotalLastMonth
into #tempfees
from ServiceFees f
inner join ServiceFeeTypes t
on f.ServiceFeeTypeID = t.ServiceFeeTypeID
and t.ServiceFeeTypeName = 'iControlFeeToRetailer_PerInvoice'

update t set t.InvoiceCountLastMonth = InvoiceCount
from #tempfees t
inner join 
(select chainid, count(distinct RetailerInvoiceID) as InvoiceCount
from invoicedetails where YEAR(Saledate) = @lastmonthyear 
and MONTH(SaleDate) = @lastmonthmonth and InvoiceDetailTypeID = 2
group by ChainID) s
on t.chainid = s.chainid

update t set t.FeeTotalLastMonth = InvoiceCountLastMonth * FeePerInvoice
from #tempfees t

--select * from batch

INSERT INTO [DataTrue_Main].[dbo].[Batch]
           ([ProcessEntityID]
           ,[DateTimeCreated])
     VALUES
           (@myid --<ProcessEntityID, int,>
           ,GETDATE()) --<DateTimeCreated, datetime,>)

set @batchid = SCOPE_IDENTITY()

INSERT INTO [DataTrue_Main].[dbo].[InvoiceDetails]
           ([RetailerInvoiceID]
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
           ,[PromoTypeID]
           ,[PromoAllowance]
           ,[InventorySettlementID]
           ,[SBTNumber]
           ,[FinalInvoiceUnitCost]
           ,[FinalInvoiceUnitPromo]
           ,[FinalInvoiceTotalCost]
           ,[FinalInvoiceQty]
           ,[OriginalShrinkTotalQty]
           ,[PaymentDueDate]
           ,[PaymentID])
select *
from #tempfees

return
GO
