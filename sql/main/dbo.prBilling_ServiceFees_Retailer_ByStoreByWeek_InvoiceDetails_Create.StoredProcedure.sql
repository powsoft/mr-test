USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_ServiceFees_Retailer_ByStoreByWeek_InvoiceDetails_Create]
@startdate date ='2014-01-27',
@enddate date = '2014-02-09'
as

declare @paymentduedate date=getdate()
declare @currentdate date
declare @lastmonthdate date
declare @lastmonthyear int
declare @lastmonthmonth tinyint
declare @batchid int
--declare @retailerinvoiceid int
declare @myid int = 44278
declare @recchains cursor
declare @recsuppliers cursor
declare @chainid int
declare @supplierid int
declare @invoicecount int
declare @storeid int
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
from ServiceFees
where ServiceFeeTypeID = 1
and ChainID in (60624)


open @recchains

fetch next from @recchains into @chainid

while @@FETCH_STATUS = 0
	begin

		set @recsuppliers = CURSOR local fast_forward FOR
			select distinct supplierid, StoreID
			--select *
			from ServiceFees
			where ServiceFeeTypeID = 1
			and SupplierID <> 0
			and ChainID = @chainid

		open @recsuppliers
		
		fetch next from @recsuppliers into @supplierid, @storeid
		
		while @@fetch_status = 0
			begin
		
				select chainid, ServiceFeeFactorValue as FeePerStorePerSupplier, 
				ActiveStartDate, ActiveLastDate
				into #tempfees
				from ServiceFees
				where ServiceFeeTypeID = 1
				and ChainID = @chainid
				and StoreID = @storeid
				and @paymentduedate between ActiveStartDate and ActiveLastDate


--INSERT INTO [DataTrue_Main].[dbo].[InvoicesRetailer]
--           ([ChainID]
--           ,[InvoiceDate]
--           ,[InvoicePeriodStart]
--           ,[InvoicePeriodEnd]
--           ,[OriginalAmount]
--           ,[InvoiceTypeID]
--           ,[OpenAmount]
--           ,[LastUpdateUserID]
--           ,[PaymentDueDate])
--     select
--           chainid --<ChainID, int,>
--           ,GETDATE() --<InvoiceDate, datetime,>
--           ,@startdate --<InvoicePeriodStart, datetime,>
--           ,@enddate --<InvoicePeriodEnd, datetime,>
--           ,FeePerStorePerSupplier --FeeTotalLastMonth --<OriginalAmount, money,>
--           ,16 --<InvoiceTypeID, int,>
--           ,FeePerStorePerSupplier --FeeTotalLastMonth --<OpenAmount, money,>
--           ,0 --<LastUpdateUserID, int,>
--           ,@paymentduedate
--			from #tempfees

--		set @retailerinvoiceid = SCOPE_IDENTITY()

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
							Null
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
						   ,@paymentduedate --'8/9/2013' --[PaymentDueDate]
						   ,null --[PaymentID]
				from #tempfees
				
		

				drop table #tempfees
						
				fetch next from @recsuppliers into @supplierid, @Storeid
			
			end
	
		fetch next from @recchains into @chainid	
	end
	
close @recchains
deallocate @recchains

return
GO
