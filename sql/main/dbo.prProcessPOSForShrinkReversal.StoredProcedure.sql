USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProcessPOSForShrinkReversal]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProcessPOSForShrinkReversal]
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
declare @newtransactiontypeid int

set @MyID = 24123

begin try

begin transaction

set @rec = CURSOR local fast_forward FOR
	select t1.ChainID,t1.StoreID,t1.ProductID,t1.BrandID,t1.SupplierID,
	t1.StoreTransactionID as NewStoreTransactionID, 
	t1.Qty as NewQty, t1.RuleCost as NewTrueCost, t1.RuleRetail as NewTrueRetail,
	t1.SaleDateTime as NewDateTime,
	t2.StoreTransactionID as ShrinkTransactionID, 
	t2.Qty, t2.ruleCost as ShrinkCost, t2.ruleRetail as ShrinkRetail,
	t2.SaleDateTime as ShrinkDateTime,
	t1.ProductPriceTypeID, t1.UPC, t1.transactiontypeid as NewTransactionTypeId
	from StoreTransactions t1
	inner join StoreTransactions t2
	on t1.StoreID = t2.StoreID
	and t1.ProductID = t2.ProductID
	and t1.BrandID = t2.BrandID
	where t1.TransactionTypeID in (2, 6)--, 7, 16)
	and t2.TransactionTypeID in (17)
	and t1.SaleDateTime < t2.SaleDateTime
	and t1.TransactionStatus in (0, 811)
	--and t1.CostMisMatch = 0
	--and t1.RetailMisMatch = 0
	and cast(t1.SaleDateTime as date) >= '12/1/2011'
	--and t1.StoreID = 41340
	--and t1.ProductID = 5135
	and t1.TransactionTypeID not in ('11','10')
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
	,@newtransactiontypeid

set @datediffindays	= ABS(datediff(day, @newdatetime, @shrinkdatetime))
set @shrinktransidclosest = @shrinktransid
set @shrinktruecostclosest = @shrinkcost
set @shrinktrueretailclosest = @shrinkretail

set @currentstoretransactionid = @newstoretransid
	
while @@FETCH_STATUS = 0
	begin
	/*
		if @currentstoretransactionid = @newstoretransid
			begin
				if @datediffindays > ABS(datediff(day, @newdatetime, @shrinkdatetime))
					begin
						set @datediffindays	= ABS(datediff(day, @newdatetime, @shrinkdatetime))
						set @shrinktransidclosest = @shrinktransid
						set @shrinktruecostclosest = @shrinkcost
						set @shrinktrueretailclosest = @shrinkretail
					end
			end
		else
			begin
*/			
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
						   ,case when @newtransactiontypeid in (2,6) then 18 else 22 end --18--<TransactionTypeID, int,>
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
						   ,136--<SourceID, int,>
						   ,@MyID
						   ,0)
/*						
							set @currentstoretransactionid = @newstoretransid
							set @datediffindays	= ABS(datediff(day, @newdatetime, @shrinkdatetime))
							set @shrinktransidclosest = @shrinktransid
							set @shrinktruecostclosest = @shrinkcost
							set @shrinktrueretailclosest = @shrinkretail
			end
*/

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
			,@newtransactiontypeid

		set @currentstoretransactionid = @newstoretransid
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
					   ,case when @newtransactiontypeid in (2,6) then 18 else 22 end --18--<TransactionTypeID, int,>
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
					   ,136--<SourceID, int,>
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
		
end catch

return
GO
