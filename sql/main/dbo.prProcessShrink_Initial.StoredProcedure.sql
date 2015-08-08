USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProcessShrink_Initial]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProcessShrink_Initial]
/*
drop table #tempshrink
select * from #tempshrink
TransactionTypeID 17 is ShrinkOnCount
select * from inventoryperpetual where shrinkrevision <> 0
update inventoryperpetual set shrinkrevision = 0 where shrinkrevision <> 0
*/
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @shrinkdate datetime
--declare @processtransactionstatus smallint
declare @MyID int

set @MyID = 24122

begin try

select i.RecordID, i.ChainID, i.StoreID, i.ProductID, 
i.BrandID, i.ShrinkRevision, i.Cost, i.Retail, 
dbo.fnGetLastInventoryCountDateTime(i.StoreID, i.ProductID, i.BrandID) as EffectiveDateTime,
p.IdentifierValue as ProductIdentifier, 
dbo.fnGetSupplierID(i.StoreID, i.ProductID, i.BrandID, i.EffectiveDateTime) as SupplierID
--into #tempshrink
from InventoryPerpetual i
inner join
(
select distinct storeid, ProductId from StoreTransactions where TransactionTypeID in (2,11) 
and supplierid = 41465 --********************************
) s
on i.StoreID = s.StoreID and i.ProductID = s.ProductID
inner join ProductIdentifiers p
on s.ProductID = p.ProductID
where i.ShrinkRevision <> 0
and p.ProductIdentifierTypeID = 2 --Unique Identifier (UPC)
--and dbo.fnGetSupplierID(i.StoreID, i.ProductID, i.BrandID, i.EffectiveDateTime) = 40561

begin transaction
/*
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
			select ChainID
           ,StoreID
           ,ProductID
           ,SupplierID--<SupplierID, int,>
           ,17--<TransactionTypeID, int,>
           ,7--<ProductPriceTypeID, int,>
           ,BrandID
           ,ShrinkRevision--<Qty, int,>
           ,Cost--<SetupCost, money,>
           ,Retail--<SetupRetail, money,>
           ,EffectiveDateTime--<SaleDateTime, datetime,>
           ,ProductIdentifier--<UPC, nvarchar(50),>
           ,Cost--<ReportedCost, money,>
           ,Retail--<ReportedRetail, money,>
           ,Cost--<RuleCost, money,>
           ,Retail--<RuleRetail, money,>
           ,0--<CostMisMatch, tinyint,>
           ,0--<RetailMisMatch, tinyint,>
           ,Cost--<TrueCost, money,>
           ,Retail--<TrueRetail, money,>
           ,0--<TransactionStatus, smallint,>
           ,135--<SourceID, int,>
           ,@MyID
           ,0
		from #tempshrink
*/
/*
--select *
update t set t.SetupCost = t2.SetupCost, t.SetupRetail = t2.SetupRetail, 
t.ReportedCost = t2.ReportedCost, t.ReportedRetail = t2.ReportedRetail,
t.RuleCost = t2.RuleCost, t.RuleRetail = t2.RuleRetail,
t.TrueCost = t2.TrueCost, t.TrueRetail = t2.TrueRetail,
t.TransactionStatus = 1
from [DataTrue_Main].[dbo].[StoreTransactions] t
inner join [DataTrue_Main].[dbo].[StoreTransactions] t2
on t.ChainID = t2.ChainID
and t.StoreID = t2.StoreID
and t.ProductID = t2.ProductID
and t.BrandID = t2.BrandID
and CAST(t.SaleDateTime as Date) = CAST(t2.SaleDateTime as Date)
where t.TransactionStatus = 0
and t.TransactionTypeID = 17
and t2.TransactionTypeID in (2,7)
and t2.TrueCost is not null
and t2.TrueRetail is not null

declare @rec cursor
declare @rec2 cursor
declare @transactionid bigint
declare @chainid int
declare @storeid int
declare @productid int
declare @brandid int
declare @effectivedate datetime
declare @transactionid2 bigint
declare @effectivedate2 datetime
declare @transactionidclosest bigint
declare @datediffdays int

set @rec = CURSOR local fast_forward FOR
	select StoreTransactionID, SaleDateTime, 
	ChainID, StoreID, ProductID, BrandID
	from [DataTrue_Main].[dbo].[StoreTransactions]
	where TransactionStatus = 0
	and TransactionTypeID = 17
	
open @rec

fetch next from @rec into 
@transactionid
,@effectivedate
,@chainid
,@storeid
,@productid
,@brandid

while @@FETCH_STATUS = 0
	begin
		set @rec2 = CURSOR local fast_forward FOR
			select StoreTransactionID, SaleDateTime
			from [DataTrue_Main].[dbo].[StoreTransactions]
				where 1 = 1
				and ChainID = @chainid
				and StoreID = @storeid
				and ProductID = @productid
				and BrandID = @brandid
				and TransactionTypeID in (2,7)
				and TrueCost is not null
				and TrueRetail is not null
				order by SaleDateTime desc
				
			open @rec2
				
			if @@ROWCOUNT > 0
				begin
					fetch next from @rec2 into @transactionid2, @effectivedate2
					set @datediffdays = 1000000000
					while @@FETCH_STATUS = 0
						begin
							if @datediffdays > ABS(DATEDIFF(day, @effectivedate, @effectivedate2))
								begin
									set @transactionidclosest = @transactionid2
									set @datediffdays = ABS(DATEDIFF(day, @effectivedate, @effectivedate2))
								end
							fetch next from @rec2 into @transactionid2, @effectivedate2
						end
						
					close @rec2
					deallocate @rec2
				
					update t set t.SetupCost = t2.SetupCost, t.SetupRetail = t2.SetupRetail, 
					t.ReportedCost = t2.ReportedCost, t.ReportedRetail = t2.ReportedRetail,
					t.RuleCost = t2.RuleCost, t.RuleRetail = t2.RuleRetail,
					t.TrueCost = t2.TrueCost, t.TrueRetail = t2.TrueRetail,
					t.TransactionStatus = 1
					from [DataTrue_Main].[dbo].[StoreTransactions] t
					inner join [DataTrue_Main].[dbo].[StoreTransactions] t2
					on t.ChainID = t2.ChainID
					and t.StoreID = t2.StoreID
					and t.ProductID = t2.ProductID
					and t.BrandID = t2.BrandID
					and CAST(t.SaleDateTime as Date) = CAST(t2.SaleDateTime as Date)
					where t.StoreTransactionID = @transactionid
					and t2.StoreTransactionID = @transactionidclosest
				end


		fetch next from @rec into 
		@transactionid
		,@effectivedate
		,@chainid
		,@storeid
		,@productid
		,@brandid
	end
	
close @rec
deallocate @rec
*/
update i set ShrinkRevision = 0
from InventoryPerpetual i
inner join #tempshrink t
on i.RecordID = t.recordid

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
