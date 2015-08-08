USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionOne]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create_VersionOne]
@startdate date,
@enddate date
as
--select * from chains
--declare @startdate date = '4/7/2014' declare @enddate date = '4/13/2014'
declare @paymentduedate date=getdate()
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
declare @invoicecount int
declare @storeid int
declare @recordcount int
--select * from servicefeetypes

set @currentdate = GETDATE()
set @lastmonthdate = DATEADD(month, -1, @currentdate)
set @lastmonthyear = YEAR(@lastmonthdate)
set @lastmonthmonth = MONTH(@lastmonthdate)

INSERT INTO [DataTrue_Main].[dbo].[Batch]
		   ([ProcessEntityID]
		   ,[DateTimeCreated])
	 VALUES
		   (@myid --<ProcessEntityID, int,>
		   ,GETDATE()) --<DateTimeCreated, datetime,>)

set @batchid = SCOPE_IDENTITY()

print @batchid
				
				
set @recchains = CURSOR local fast_forward FOR
select distinct ChainID
--select *
--select sum(servicefeefactorvalue)
from ServiceFees
where ServiceFeeTypeID = 1
--and ChainID <> 0
and ChainID in (60624)
--and ChainID in (64010)
--and ChainID in (65232) --, 65232)
--and SupplierID = 0

open @recchains

fetch next from @recchains into @chainid

			select *
			from ServiceFees
			where ServiceFeeTypeID = 1
			and SupplierID <> 0
			and ChainID = @chainid
			
while @@FETCH_STATUS = 0
	begin

		set @recsuppliers = CURSOR local fast_forward FOR
			select distinct supplierid, StoreID
			--select *
			from ServiceFees
			where ServiceFeeTypeID = 1
			and SupplierID <> 0
			--and ChainID = 60624
			and ChainID = @chainid
			--and '3/9/2014' between ActiveStartDate and ActiveLastDate
			and @enddate between ActiveStartDate and ActiveLastDate

/*

*/
		open @recsuppliers
		
		fetch next from @recsuppliers into @supplierid, @storeid
		
		while @@fetch_status = 0
			begin
		
				select chainid, SupplierID, ServiceFeeFactorValue as FeePerStorePerSupplier, 
				ActiveStartDate, ActiveLastDate
				into #tempfees
				from ServiceFees
				where ServiceFeeTypeID = 1
				and ChainID = @chainid
				and StoreID = @storeid
				and SupplierID = @supplierid
				and @enddate between ActiveStartDate and ActiveLastDate
				
select * from #tempfees				
				
/*
--select * from #tempfees

select * from invoicedetailtypes

--				select * 
--				from #tempfees
*/
				set @recordcount = 0
				
				select @recordcount = COUNT(storetransactionid)
				from StoreTransactions
				where 1 = 1
				and ChainID = @chainid
				and StoreID = @storeid
				and SupplierID = @supplierid 
				and TransactionTypeID in (2,6)
				and CAST(saledatetime as date) between @startdate and @enddate

				if @recordcount is null
					begin
						set @recordcount = 0
					end

				if @recordcount > 0	
					begin
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
								   ,@storeid --0 --[StoreID]
								   ,3487669 --0 --[ProductID]
								   ,0 --[BrandID]
								   ,@supplierid --[SupplierID]
								   ,16 --[InvoiceDetailTypeID]
								   ,1 --InvoiceCountLastMonth --1 --[TotalQty]
								   ,FeePerStorePerSupplier --FeePerInvoice --[UnitCost]
								   ,0 --[UnitRetail]
								   ,FeePerStorePerSupplier --FeeTotalLastMonth --[TotalCost]
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
								   ,'999999999996' --null --[ProductIdentifier]
								   ,null --[ProductQualifier]
								   ,'999999999996' --[RawProductIdentifier]
								   ,null --[SupplierName]
								   ,null --[SupplierIdentifier]
								   ,null --[BrandIdentifier]
								   ,null --[DivisionIdentifier]
								   ,null --[UOM]
								   ,null --[SalePrice]
								   ,0 --[Allowance]
								   ,'' --null --[InvoiceNo]
								   ,'' --null --[PONo]
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
								   ,getdate() --@paymentduedate --'8/9/2013' --[PaymentDueDate]
								   ,null --[PaymentID]
						from #tempfees
						
				end	

				drop table #tempfees
						
				fetch next from @recsuppliers into @supplierid, @storeid
			
			end
	
		fetch next from @recchains into @chainid	
	end
	
close @recchains
deallocate @recchains


select * --324
--delete
--select sum(totalcost) --2596.75
from invoicedetails
where invoicedetailtypeid = 16
and ChainID = 60624
and CAST(datetimecreated as date) = '3/18/2014'
order by invoicedetailid desc

/*
select *
--select chainid, storeid, supplierid, count(ServiceFeeID)
from ServiceFees
where ServiceFeeTypeID = 1
--and ChainID <> 0
and ChainID in (60624)
group by chainid, storeid, supplierid
order by count(ServiceFeeID) desc


select *
--delete
from invoicedetails
where invoicedetailtypeid = 16
--and invoicedetailid = 78191458
order by invoicedetailid desc

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
