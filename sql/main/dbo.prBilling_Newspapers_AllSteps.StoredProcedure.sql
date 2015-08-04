USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_AllSteps]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Newspapers_AllSteps]
as

exec [dbo].[prGetInboundPOSTransactions_Newspapers]

select *
from StoreTransactions_Working
where ChainIdentifier = 'DQ'
and CAST(datetimecreated as date) = '9/12/2013'
order by storeid

exec [dbo].[prValidateStoresInStoreTransactions_Working_Newspapers]

exec [dbo].[prValidateProductsInStoreTransactions_Working_Newspapers]

exec [dbo].[prValidateSuppliersInStoreTransactions_Working_Newpapers]

select *
--update w set w.supplierid = 26922
from StoreTransactions_Working w
where chainid = 62362
--and ChainIdentifier = 'DQ'
and CAST(datetimecreated as date) = '9/19/2013'
and SupplierID = 0
order by supplierid

SELECT *
  FROM [Import].[dbo].[DQ_Master_list]
  where productid = 37906
  order by storeidentifier

select *
from storesetup
where ProductID = 37906
and StoreID in (62396,62376)

exec [dbo].[prValidateSourceInStoreTransactions_Working_Newspapers]

exec [dbo].[prValidateTransactionTypeInStoreTransactions_Working_Newspapers]

select *
--select l.Retail, d.RuleRetail, * 
--select l.Cost, d.ruleCost, *
--update d set d.UnitRetail = l.Retail
--update d set d.UnitCost = l.Cost
from import.dbo.DQ_Master_list l
inner join storetransactions d
on l.storeid = d.storeid
and l.supplierid = d.supplierid
and ltrim(rtrim(l.UPC)) = ltrim(rtrim(d.ProductIdentifier))
and cast(d.datetimecreated as date) > '9/19/2013'
and d.chainid = 62362
and (d.ruleretail <> l.retail or d.RuleCost <> l.Cost)

select * from chains
select * from stores where ChainID = 62362 and StoreIdentifier = '109'

select RuleCost as cost, RuleRetail as retail, *
--update t set rulecost = 1.90, ruleretail = 2.00
--select distinct UPC, productid
--select distinct storeid, UPC, productid
from storetransactions t
where ChainID = 62362
--and CAST(datetimecreated as date) = '9/19/2013'
and CAST(saledatetime as date) between '9/25/2013' and '10/1/2013'
--and RuleRetail = .10
--and (RuleRetail = .10 or ProductID = 37906)
--order by RuleCost
--order by RuleRetail
order by saledatetime
--and (RuleCost = RuleRetail or RuleCost > Ruleretail)
--order by RuleRetail
--and SupplierID = 0
--and StoreID = 62372
--and ProductID = 20479

select *
--
from storetransactions t
inner join ProductPrices p
on t.StoreID = p.StoreID
and t.ProductID = p.ProductID
and t.SupplierID = p.SupplierID
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate
and p.ProductPriceTypeID = 3
where t.ChainID = 62362
--and CAST(datetimecreated as date) = '9/19/2013'
and CAST(t.saledatetime as date) between '9/25/2013' and '10/1/2013'
and t.RuleCost <> p.UnitPrice

exec [prInvoiceDetail_ReleaseStoreTransactions_Newspapers]

exec [dbo].[prInvoiceDetail_POS_Create_Newspapers]

exec prInvoices_POS_Retailer_Create_Newspapers 'Weekly'

select *
--update b set NextBillingPeriodEndDateTime = '2013-09-29 00:00:00.000' ,NextBillingPeriodRunDateTime = '2013-10-2 00:00:00.000'
from BillingControl b
where ChainID = 62362
and EntityIDToInvoice <> 62362


select *
from InvoiceDetailS [No Lock]
where ChainID = 62362
and (CAST(datetimecreated as date) = '10/2/2013' or SaleDate in ('9/23/2013','9/24/2013'))
order by saledate
--order by retailerinvoiceid



exec prInvoices_POS_Supplier_Create_Weekly_Newspapers 'Weekly'



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

select * from DataTrue_EDI..InvoicesRetailer
where 1 = 1
and CAST(datetimecreated as date) = '10/2/2013'

select d.Adjustment1, e.Adjustment1, *
--update e set e.adjustment1 = d.adjustment1
from InvoiceDetailS d
inner join datatrue_edi.dbo.InvoiceDetails e
on d.InvoiceDetailID = e.invoicedetailid
where d.ChainID = 62362
and CAST(d.datetimecreated as date) = '10/2/2013'

select *
from InvoicesSupplier
order by SupplierInvoiceID desc

exec [prBilling_Inbound820Payments_From_Billing_Create]


select *
--select distinct supplierid
from InvoiceDetailS [No Lock]
where ChainID = 62362
and CAST(datetimecreated as date) = '9/19/2013'
and supplierinvoiceid is not null
order by storeid
--order by saledate
--order by supplierinvoiceid

exec [prBilling_Payment_Create_New]


SELECT *
  FROM [Import].[dbo].[DQ_Master_list]
  where productid = 37906
--20479
--39546

select * into import.dbo.storesetup_38710_updateto_20479
--update s set productid = 280
--select *
from storesetup s
where 1 = 1
--and chainid = 32632
and productid = 20479

select * into import.dbo.productprices_38710_updateto_280
--update s set productid = 280
--select *
from productprices s
where productid = 38710

--1055
--37906


select *
--update t set t.supplierid = s.supplierid 
from storetransactions_working t
inner join storesetup s
on t.productid = s.productid  
and t.storeid = s.storeid
where t.chainid = 62362 
and t.supplierid = 0
and t.productid = 37906

select *
--update t set t.supplierid = s.supplierid 
from storetransactions t
inner join storesetup s
on t.productid = s.productid  
and t.storeid = s.storeid
where t.chainid = 62362 
and t.supplierid = 0
and t.productid = 39711

/*
select *
--select sum(AmountOriginallyBilled)
from payments
where paymentid >= 1038

1043	1	62362	26922	2816.30
1040	1	62362	25909	1167.55

2527.425
6833.10

select adjustment1, *
--select sum(totalqty * unitcost + adjustment1)
--select sum(totalqty * unitcost)
--select sum(totalcost)
--select sum(adjustment1)
from InvoiceDetailS [No Lock]
where ChainID = 62362
and supplierid = 26922 --25909
and productid <> 3480727
--and recordstatussupplier = 0
and CAST(datetimecreated as date) = '9/19/2013'
and (saledate between '9/9/2013' and '9/15/2013')
and (saledate between '9/9/2013' and '9/15/2013' or productid = 3480727)
and supplierinvoiceid is not null
--order by saledate
and paymentid is null
--order by storeid



select *
--
from invoicedetails d
where 1 = 1
and paymentid between 1038 and 1056
order by saledate


select *
from payments
where 1 = 1
and paymentid between 1038 and 1056

select *
from paymenthistory
where 1 = 1
and paymentid between 1038 and 1056
*/

declare @rec cursor
declare @paymentid int
declare @supplierid int
declare @chainid int= 62362
declare @billadj money

set @rec = cursor local fast_forward for
select paymentid, payeeentityid
from payments
where 1 = 1
and paymentid between 1039 and 1056
order by paymentid

open @rec

fetch next from @rec into @paymentid, @supplierid

while @@fetch_Status = 0
	begin
	
		select *
		from invoicedetails
		where supplierid = @supplierid
		and productid = 3480727
		
		select @billadj = sum(TotalQty * UnitCost)
		from invoicedetails
		where supplierid = @supplierid
		and productid = 3480727
		
--select * from payments		
		update p set p.amountOriginallyBilled = p.amountOriginallyBilled + 	@billadj
		from payments p
		where paymentid = @paymentid	
		
		update p set p.amountOriginallyBilled = p.amountOriginallyBilled + 	@billadj
		from datatrue_edi.dbo.payments p
		where paymentid = @paymentid
		
		update d set d.paymentid = @paymentid
		from invoicedetails d
		where supplierid = @supplierid
		and productid = 3480727

		update d set d.paymentid = @paymentid
		from datatrue_edi.dbo.invoicedetails d
		where supplierid = @supplierid
		and productid = 3480727
				
		fetch next from @rec into @paymentid, @supplierid
	end
close @rec
deallocate @rec


return
GO
