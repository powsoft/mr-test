USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ServiceFees_Retailer_InvoiceDetails_Create_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_ServiceFees_Retailer_InvoiceDetails_Create_PRESYNC_20150329]
@startdate date,
@enddate date
as

--declare @startdate date = '8/1/2013' declare @enddate date = '8/31/2013'
declare @paymentduedate date='9/9/2013'
declare @currentdate date
declare @lastmonthdate date
declare @lastmonthyear int
declare @lastmonthmonth tinyint
declare @batchid int
declare @retailerinvoiceid int
declare @myid int = 44278
declare @recchains cursor
declare @recsuppliers cursor
declare @chainid int
declare @supplierid int
--select * from servicefeetypes

set @currentdate = GETDATE()
set @lastmonthdate = DATEADD(month, -1, @currentdate)
set @lastmonthyear = YEAR(@lastmonthdate)
set @lastmonthmonth = MONTH(@lastmonthdate)


set @recchains = CURSOR local fast_forward FOR
select ChainID
--select *
from ServiceFees
where ServiceFeeTypeID = 2
and ChainID <> 0
and ChainID in (50964)

open @recchains

fetch next from @recchains into @chainid

while @@FETCH_STATUS = 0
	begin

		set @recsuppliers = CURSOR local fast_forward FOR
			select distinct supplierid
			--select *
			from ServiceFees
			where ServiceFeeTypeID = 3
			and SupplierID <> 0
			and SupplierID in (50729, 60653, 62342)
/*
select * from Suppliers 
where SupplierID in
(			select distinct supplierid
			from ServiceFees
			where ServiceFeeTypeID = 3
			and SupplierID <> 0
)	
select *
from invoicedetails
where invoicedetailtypeid = 2
and supplierid = 62342
and month(saledate) = 8
*/
		open @recsuppliers
		
		fetch next from @recsuppliers into @supplierid
		
		while @@fetch_status = 0
			begin
		
				select chainid, ServiceFeeFactorValue as FeePerInvoice, 
				CAST(null as int) as InvoiceCountLastMonth, CAST(null as money) as FeeTotalLastMonth
				,ActiveStartDate, ActiveLastDate
				into #tempfees
				from ServiceFees
				where ServiceFeeTypeID = 2
				and ChainID = @chainid



				update t set t.InvoiceCountLastMonth = InvoiceCount
				from #tempfees t
				inner join 
				(select chainid, count(distinct RetailerInvoiceID) as InvoiceCount
				from invoicedetails where YEAR(DateTimeCreated) = @lastmonthyear 
				and MONTH(DateTimeCreated) = @lastmonthmonth and InvoiceDetailTypeID = 2
				and SupplierID = @supplierid --60653
				--and CAST(DateTimeCreated as date) between 
				group by ChainID) s
				on t.chainid = s.chainid

				update t set t.FeeTotalLastMonth = InvoiceCountLastMonth * FeePerInvoice
				from #tempfees t

				select * 
				from #tempfees

				--update t set t.FeeTotalLastMonth = InvoiceCountLastMonth * FeePerInvoice
				--from #tempfees t

				--select * from batch order by batchid desc

				INSERT INTO [DataTrue_Main].[dbo].[Batch]
						   ([ProcessEntityID]
						   ,[DateTimeCreated])
					 VALUES
						   (@myid --<ProcessEntityID, int,>
						   ,GETDATE()) --<DateTimeCreated, datetime,>)

				set @batchid = SCOPE_IDENTITY()

				print @batchid

				select * 
				from #tempfees

INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
           ([ChainID]
           ,[InvoiceDate]
           ,[InvoicePeriodStart]
           ,[InvoicePeriodEnd]
           ,[OriginalAmount]
           ,[InvoiceTypeID]
           ,[OpenAmount]
           ,[LastUpdateUserID]
           ,[PaymentDueDate])
     select
           chainid --<ChainID, int,>
           ,GETDATE() --<InvoiceDate, datetime,>
           ,@startdate --<InvoicePeriodStart, datetime,>
           ,@enddate --<InvoicePeriodEnd, datetime,>
           ,FeeTotalLastMonth --<OriginalAmount, money,>
           ,14 --<InvoiceTypeID, int,>
           ,FeeTotalLastMonth --<OpenAmount, money,>
           ,0 --<LastUpdateUserID, int,>
           ,@paymentduedate
			from #tempfees

		set @retailerinvoiceid = SCOPE_IDENTITY()

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
				select 
							@retailerinvoiceid
						   ,null --[SupplierInvoiceID]
						   ,@chainid --[ChainID] 
						   ,0 --[StoreID]
						   ,0 --[ProductID]
						   ,0 --[BrandID]
						   ,@supplierid --[SupplierID]
						   ,14 --[InvoiceDetailTypeID]
						   ,1 --[TotalQty]
						   ,FeePerInvoice --[UnitCost]
						   ,0 --[UnitRetail]
						   ,FeeTotalLastMonth --[TotalCost]
						   ,0 --[TotalRetail]
						   ,@enddate --[SaleDate]
						   ,0 --[RecordStatus]
						   ,getdate() --[DateTimeCreated]
						   ,0 --[LastUpdateUserID]
						   ,getdate() --[DateTimeLastUpdate]
						   ,@batchid --[BatchID]
						   ,null --[ChainIdentifier]
						   ,null --[StoreIdentifier]
						   ,null --[StoreName]
						   ,null --[ProductIdentifier]
						   ,null --[ProductQualifier]
						   ,null --[RawProductIdentifier]
						   ,null --[SupplierName]
						   ,null --[SupplierIdentifier]
						   ,null --[BrandIdentifier]
						   ,null --[DivisionIdentifier]
						   ,null --[UOM]
						   ,null --[SalePrice]
						   ,0 --[Allowance]
						   ,null --[InvoiceNo]
						   ,null --[PONo]
						   ,null --[CorporateName]
						   ,null --[CorporateIdentifier]
						   ,null --[Banner]
						   ,null --[PromoTypeID]
						   ,0 --[PromoAllowance]
						   ,null --[InventorySettlementID]
						   ,null --[SBTNumber]
						   ,null --[FinalInvoiceUnitCost]
						   ,null --[FinalInvoiceUnitPromo]
						   ,null --[FinalInvoiceTotalCost]
						   ,null --[FinalInvoiceQty]
						   ,null --[OriginalShrinkTotalQty]
						   ,'8/9/2013' --[PaymentDueDate]
						   ,null --[PaymentID]
				from #tempfees
				
				drop table #tempfees
				
				fetch next from @recsuppliers into @supplierid
			
			end
	
		fetch next from @recchains into @chainid	
	end
	
close @recchains
deallocate @recchains

/*
Spartan 201306 BatchID = 5843

GLWINE 50729
50964	0.215	883	189.845
MOD Craft 60653
50964	0.215	1	0.215

select * from suppliers 
--where supplierid = 51068
order by supplierid desc
select chainid, count(distinct RetailerInvoiceID) as InvoiceCount
--select distinct RetailerInvoiceID
from invoicedetails where YEAR(DateTimeCreated) = 2013
and MONTH(DateTimeCreated) = 5 and InvoiceDetailTypeID = 2
and SupplierID = 50729
and chainid = 50964

select * 
--update d set paymentid = null
from invoicedetails d 
where 1 = 1
and invoicedetailtypeid in (14, 15)
and cast(datetimecreated as date) = '7/5/2013'
and invoicedetailid in (56507330,
56507331)

select *
--update r set r.paymentid = null
from invoicesretailer r
where 1 = 1
and invoicetypeid in (14, 15)
and cast(datetimecreated as date) = '7/5/2013'

5716
*/

/*
select * from ServiceFees
where ServiceFeeTypeID = 2
--select ChainID, ServiceFeeFactorValue as FeePerInvoice, 
--CAST(null as int) as InvoiceCountLastMonth, CAST(null as money) as FeeTotalLastMonth
--into #tempfees
--from ServiceFees f
--inner join ServiceFeeTypes t
--on f.ServiceFeeTypeID = t.ServiceFeeTypeID
--and t.ServiceFeeTypeName = 'iControlFeeToRetailer_PerInvoice'
--select * from suppliers where supplierid = 50729
select * from invoicedetails where invoicedetailtypeid in (14, 15)
select 
*/
return
GO
