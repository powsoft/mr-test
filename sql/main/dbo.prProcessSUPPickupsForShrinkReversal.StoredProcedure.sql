USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProcessSUPPickupsForShrinkReversal]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProcessSUPPickupsForShrinkReversal]
as

declare @rec cursor
declare @newstoretransid bigint
declare @newqty int
declare @newtruecost money
declare @newtrueretail money
declare @newdatetime datetime
declare @shrinktransid bigint
declare @shrinkqty int
declare @shrinkcost money
declare @shrinkretail money
declare @shrinkdatetime datetime
declare @currentstoretransactionid bigint
declare @chainid int
declare @storeid int
declare @productid int
declare @brandid int
declare @supplierid int
declare @productpricetypeid int
declare @productidentifier nvarchar(100)
declare @MyID int
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @datediffindays	int
declare @shrinktransidclosest bigint
declare @shrinktruecostclosest money
declare @shrinktrueretailclosest money
declare @transactiontypeid int

set @MyID = 24125

begin try

begin transaction

set @rec = CURSOR local fast_forward FOR
	select t1.ChainID,t1.StoreID,t1.ProductID,t1.BrandID,t1.SupplierID,
	t1.StoreTransactionID as NewStoreTransactionID, 
	t1.Qty as NewQty, t1.TrueCost as NewTrueCost, t1.TrueRetail as NewTrueRetail,
	t1.SaleDateTime as NewDateTime,
	t2.StoreTransactionID as ShrinkTransactionID, 
	t2.Qty, t2.TrueCost as ShrinkCost, t2.TrueRetail as ShrinkRetail,
	t2.SaleDateTime as ShrinkDateTime,
	t1.ProductPriceTypeID, t1.UPC, t1.transactiontypeid as NewTransactionTypeId
	from StoreTransactions t1
	inner join StoreTransactions t2
	on t1.StoreID = t2.StoreID
	and t1.ProductID = t2.ProductID
	and t1.BrandID = t2.BrandID
	where t1.TransactionTypeID in (8,13,14,21)
	and t2.TransactionTypeID in (17)
	and t1.SaleDateTime < t2.SaleDateTime
	and t1.TransactionStatus = 0
	--and t1.CostMisMatch = 0
	--and t1.RetailMisMatch = 0
	and t1.RuleCost is not null
	--and t1.TrueCost is not null
	--and t1.TrueRetail is not null
	and t1.supplierid in (40561, 40562, 40558, 40557, 41464, 41464,41440)
		and CAST(t1.saledatetime as date) >= '12/1/2011'
	order by t1.StoreTransactionID, t2.SaleDateTime
	
open @rec

fetch next from @rec into 
	@chainid
	,@storeid
	,@productid
	,@brandid
	,@supplierid
	,@newstoretransid
	,@newqty
	,@newtruecost
	,@newtrueretail
	,@newdatetime
	,@shrinktransid
	,@shrinkqty
	,@shrinkcost
	,@shrinkretail
	,@shrinkdatetime
	,@productpricetypeid
	,@productidentifier
	,@transactiontypeid

set @datediffindays	= ABS(datediff(day, @newdatetime, @shrinkdatetime))
set @shrinktransidclosest = @shrinktransid
set @shrinktruecostclosest = @shrinkcost
set @shrinktrueretailclosest = @shrinkretail

set @currentstoretransactionid = 0 --@newstoretransid
	
while @@FETCH_STATUS = 0
	begin
	--/*
		if @currentstoretransactionid = @newstoretransid
			begin
				if @datediffindays > ABS(datediff(day, @newdatetime, @shrinkdatetime))
					begin
						set @datediffindays	= ABS(datediff(day, @newdatetime, @shrinkdatetime))
						set @shrinktransidclosest = @shrinktransid
						set @shrinktruecostclosest = @shrinkcost
						set @shrinktrueretailclosest = @shrinkretail
					end
				set @currentstoretransactionid = @newstoretransid
			end
		else
			begin
	--*/			
				INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions]
						   ([ChainID]
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
						   ,[ReportedCost]
						   ,[ReportedRetail]
						   ,[RuleCost]
						   ,[RuleRetail]
						   ,[CostMisMatch]
						   ,[RetailMisMatch]
						   ,[TrueCost]
						   ,[TrueRetail]
						   ,[TransactionStatus]
						   ,[SourceID]
						   ,[LastUpdateUserID]
						   ,[WorkingTransactionID])
				 --select * from #tempshrink
					values(@chainid
							,@storeid
							,@productid
						   ,@supplierid--<SupplierID, int,>
						   ,case when @transactiontypeid in (8,13) then 19 else 23 end --19--<TransactionTypeID, int,>
						   ,@productpricetypeid--<ProductPriceTypeID, int,>
						   ,@brandid
						   ,@newqty * -1--<Qty, int,>
						   ,@shrinktruecostclosest--<SetupCost, money,>
						   ,@shrinktrueretailclosest--<SetupRetail, money,>
						   ,@shrinkdatetime --@newdatetime--<SaleDateTime, datetime,>
						   ,@ProductIdentifier--<UPC, nvarchar(50),>
						   ,@shrinktruecostclosest--<ReportedCost, money,>
						   ,@shrinktrueretailclosest--<ReportedRetail, money,>
						   ,@shrinktruecostclosest--<RuleCost, money,>
						   ,@shrinktrueretailclosest--<RuleRetail, money,>
						   ,0--<CostMisMatch, tinyint,>
						   ,0--<RetailMisMatch, tinyint,>
						   ,@shrinktruecostclosest--<TrueCost, money,>
						   ,@shrinktrueretailclosest--<TrueRetail, money,>
						   ,0--<TransactionStatus, smallint,>
						   ,138--<SourceID, int,>
						   ,@MyID
						   ,0)
--/*						   
							set @currentstoretransactionid = @newstoretransid
							set @datediffindays	= ABS(datediff(day, @newdatetime, @shrinkdatetime))
							set @shrinktransidclosest = @shrinktransid
							set @shrinktruecostclosest = @shrinkcost
							set @shrinktrueretailclosest = @shrinkretail
						
			end
--*/
		fetch next from @rec into 
			@chainid
			,@storeid
			,@productid
			,@brandid
			,@supplierid
			,@newstoretransid
			,@newqty
			,@newtruecost
			,@newtrueretail
			,@newdatetime
			,@shrinktransid
			,@shrinkqty
			,@shrinkcost
			,@shrinkretail
			,@shrinkdatetime
			,@productpricetypeid
			,@productidentifier
			,@transactiontypeid
			
			--set @currentstoretransactionid = @newstoretransid
			set @datediffindays	= ABS(datediff(day, @newdatetime, @shrinkdatetime))
			set @shrinktransidclosest = @shrinktransid
			set @shrinktruecostclosest = @shrinkcost
			set @shrinktrueretailclosest = @shrinkretail
			
	end

/*
	if @chainid is not null
		begin
				INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions]
						   ([ChainID]
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
						   ,[ReportedCost]
						   ,[ReportedRetail]
						   ,[RuleCost]
						   ,[RuleRetail]
						   ,[CostMisMatch]
						   ,[RetailMisMatch]
						   ,[TrueCost]
						   ,[TrueRetail]
						   ,[TransactionStatus]
						   ,[SourceID]
						   ,[LastUpdateUserID]
						   ,[WorkingTransactionID])
				 --select * from #tempshrink
					values(@chainid
							,@storeid
							,@productid
						   ,@supplierid--<SupplierID, int,>
						   ,19--<TransactionTypeID, int,>
						   ,@productpricetypeid--<ProductPriceTypeID, int,>
						   ,@brandid
						   ,@newqty * -1--<Qty, int,>
						   ,@shrinktruecostclosest--<SetupCost, money,>
						   ,@shrinktrueretailclosest--<SetupRetail, money,>
						   ,@shrinkdatetime --@newdatetime--<SaleDateTime, datetime,>
						   ,@ProductIdentifier--<UPC, nvarchar(50),>
						   ,@shrinktruecostclosest--<ReportedCost, money,>
						   ,@shrinktrueretailclosest--<ReportedRetail, money,>
						   ,@shrinktruecostclosest--<RuleCost, money,>
						   ,@shrinktrueretailclosest--<RuleRetail, money,>
						   ,0--<CostMisMatch, tinyint,>
						   ,0--<RetailMisMatch, tinyint,>
						   ,@shrinktruecostclosest--<TrueCost, money,>
						   ,@shrinktrueretailclosest--<TrueRetail, money,>
						   ,0--<TransactionStatus, smallint,>
						   ,138--<SourceID, int,>
						   ,@MyID
						   ,0)
		end
*/
						   	
close @rec
deallocate @rec

commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'	
end catch

return
GO
