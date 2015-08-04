USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPOS_Deletion_ByStore_BySaleDate_Create]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPOS_Deletion_ByStore_BySaleDate_Create]

as




declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint=11
declare @MyID int
set @MyID = 0
declare @createzerocountrecords bit
declare @storeid int
declare @saledate date
declare @RecordID_EDI_852 bigint
declare @recdeletions cursor

begin try

	select distinct StoreTransactionID
	into #tempStoreTransaction
	--select *
	--update w set workingstatus = 1
	from [dbo].[StoreTransactions_Working] w
	where 1 = 1
	and charindex('POS', WorkingSource) > 0
	and RecordType = 1 --Deletion Record
	and WorkingStatus = 1


	begin transaction


	set @recdeletions = CURSOr local fast_forward FOR
		select distinct StoreID, CAST(saledatetime as date), RecordID_EDI_852
		from StoreTransactions_Working w
		inner join #tempStoreTransaction t
		on w.StoreTransactionID = t.StoreTransactionID
		--and w.StoreID = 41922
		order by CAST(saledatetime as date)
		
	open @recdeletions

	fetch next from @recdeletions into @storeid, @saledate, @RecordID_EDI_852

	while @@FETCH_STATUS = 0
		begin

			select workingtransactionid --storestoretransactionid 
			into #temptransactionstoreverse
			  FROM [DataTrue_Main].[dbo].[StoreTransactions] w
			  --FROM [DataTrue_Main].[dbo].[StoreTransactions_Working] w
				where w.StoreID = @storeid
				and CAST(w.saledatetime as date) = @saledate
				--and WorkingStatus = 5
				and TransactionTypeID in (2,6)
				and Reversed = 0
				
			If @@ROWCOUNT > 0
				begin
				
			INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Working]
					   ([ChainID]
					   ,[ChainIdentifier]
					   ,[StoreIdentifier]
					   ,[SourceIdentifier]
					   ,[SupplierIdentifier]
					   ,[DateTimeSourceReceived]
					   ,[StoreID]
					   ,[ProductID]
					   ,[SupplierID]
					   ,[TransactionTypeID]
					   ,[ProductPriceTypeID]
					   ,[BrandID]
					   ,[Qty]
					   ,[SetupCost]
					   ,[SetupRetail]
					   ,[SaleDateTime]
					   ,[UPC]
					   ,[ProductIdentifierType]
					   ,[ProductCategoryIdentifier]
					   ,[BrandIdentifier]
					   ,[SupplierInvoiceNumber]
					   ,[ReportedCost]
					   ,[ReportedRetail]
					   ,[ReportedPromotionPrice]
					   ,[ReportedAllowance]
					   ,[RuleCost]
					   ,[RuleRetail]
					   ,[CostMisMatch]
					   ,[RetailMisMatch]
					   ,[TrueCost]
					   ,[TrueRetail]
					   ,[ActualCostNetFee]
					   ,[TransactionStatus]
					   ,[Reversed]
					   ,[ProcessingErrorDesc]
					   ,[SourceID]
					   ,[Comments]
					   ,[InvoiceID]
					   ,[DateTimeCreated]
					   ,[LastUpdateUserID]
					   ,[DateTimeLastUpdate]
					   ,[WorkingSource]
					   ,[WorkingStatus]
					   ,[RecordID_EDI_852]
					   ,[Banner]
					   ,[StoreName]
					   ,[ProductQualifier]
					   ,[RawProductIdentifier]
					   ,[SupplierName]
					   ,[DivisionIdentifier]
					   ,[UOM]
					   ,[SalePrice]
					   ,[InvoiceNo]
					   ,[PONo]
					   ,[CorporateName]
					   ,[CorporateIdentifier]
					   ,[PromoTypeID]
					   ,[PromoAllowance]
					   ,[SBTNumber]
					   ,[TempStoreIDTest]
					   ,[EDIBanner]
					   ,[EDIName]
					   ,[StoreIDCorrection]
					   ,[SourceOrDestinationID]
					   ,[RecordType])	
			SELECT [ChainID]
				  ,[ChainIdentifier]
				  ,[StoreIdentifier]
				  ,[SourceIdentifier]
				  ,[SupplierIdentifier]
				  ,[DateTimeSourceReceived]
				  ,[StoreID]
				  ,[ProductID]
				  ,[SupplierID]
				  ,7 --[TransactionTypeID]
				  ,[ProductPriceTypeID]
				  ,[BrandID]
				  ,[Qty] * -1
				  ,[SetupCost]
				  ,[SetupRetail]
				  ,[SaleDateTime]
				  ,[UPC]
				  ,[ProductIdentifierType]
				  ,[ProductCategoryIdentifier]
				  ,[BrandIdentifier]
				  ,[SupplierInvoiceNumber]
				  ,[ReportedCost]
				  ,[ReportedRetail]
				  ,[ReportedPromotionPrice]
				  ,[ReportedAllowance]
				  ,[RuleCost]
				  ,[RuleRetail]
				  ,[CostMisMatch]
				  ,[RetailMisMatch]
				  ,[TrueCost]
				  ,[TrueRetail]
				  ,[ActualCostNetFee]
				  ,[TransactionStatus]
				  ,[Reversed]
				  ,[ProcessingErrorDesc]
				  ,[SourceID]
				  ,[Comments]
				  ,[InvoiceID]
				  ,[DateTimeCreated]
				  ,[LastUpdateUserID]
				  ,[DateTimeLastUpdate]
				  ,[WorkingSource]
				  ,4
				  ,@RecordID_EDI_852
				  ,[Banner]
				  ,[StoreName]
				  ,[ProductQualifier]
				  ,[RawProductIdentifier]
				  ,[SupplierName]
				  ,[DivisionIdentifier]
				  ,[UOM]
				  ,[SalePrice]
				  ,[InvoiceNo]
				  ,[PONo]
				  ,[CorporateName]
				  ,[CorporateIdentifier]
				  ,[PromoTypeID]
				  ,[PromoAllowance]
				  ,[SBTNumber]
				  ,[TempStoreIDTest]
				  ,[EDIBanner]
				  ,[EDIName]
				  ,[StoreIDCorrection]
				  ,[SourceOrDestinationID]
				  ,[RecordType]
			  --FROM [DataTrue_Main].[dbo].[StoreTransactions] w
			  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working] w
			  inner join #temptransactionstoreverse t
			  on w.StoreTransactionID = t.WorkingTransactionID
				--where w.StoreID = @storeid
				----and CAST(w.saledatetime as date) = @saledate
				--and WorkingStatus = 5
				--and TransactionTypeID in (2,6)
				--and Reversed = 0
			end
				

			drop table #temptransactionstoreverse
			update w set w.Reversed = 1
			from #temptransactionstoreverse t
			inner join [DataTrue_Main].[dbo].[StoreTransactions] w
			--inner join [DataTrue_Main].[dbo].[StoreTransactions_Working] w
			on t.WorkingTransactionID = w.WorkingTransactionID

					
				fetch next from @recdeletions into @storeid, @saledate, @RecordID_EDI_852

		end
		
close @recdeletions
deallocate @recdeletions

		commit transaction

	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9997
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		

		
		
end catch

		update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
		from #tempStoreTransaction tmp
		inner join [dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
	
/*
--declare @supplierid int=40562 declare @saledate date='12/6/2011'

select top 1000 *
--update w set workingstatus = 11
from StoreTransactions_Working w
where recordtype = 1
and cast(datetimecreated as date) = '5/24/2012'
order by storetransactionid desc

select top 500 *
from StoreTransactions
order by storetransactionid desc

select top 1 *
from StoreTransactions_Working w
where w.WorkingSource = 'INV-BOD'
and w.SupplierID = @supplierid
and CAST(w.SaleDateTime as date) = @saledate

drop table #temp
drop table #temp2

select * from #temp a inner join #temp2 b on a.storeid = b.storeid

select distinct saledatetime
from storetransactions_working
where transactiontypeid = 11
and supplierid = 40562
order by saledatetime

select distinct saledatetime
from storetransactions
where transactiontypeid = 11
and supplierid = 40562
and saledatetime >= '1/20/2012'
and transactionstatus = 0
order by saledatetime

select saledatetime, count(storetransactionid)
from storetransactions_working
where transactiontypeid = 11
and supplierid = 40562
group by saledatetime
order by saledatetime
*/

return
GO
