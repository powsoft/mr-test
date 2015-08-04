USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_Retailer_Shrink_Adj_Create_RollBack_20120314]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prInvoiceDetail_Retailer_Shrink_Adj_Create_RollBack_20120314]
@saledate date=null--,
--@invoicedetailtype tinyint
/*
prInvoiceDetail_Retailer_Shrink_Create '6/25/2011', 3
select * from invoicedetails where invoicedetailtypeid = 9 and supplierid = 40557
*/
as
--declare @saledate date
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @batchid bigint
declare @batchstring nvarchar(255)
declare @invoicedetailtype tinyint

set @MyID = 24128
set @invoicedetailtype = 9

if @saledate is null
	set @saledate = GETDATE()
	
begin try

begin transaction

/*
select StoreTransactionID
into #tempStoreTransactions
from StoreTransactions
where TransactionStatus = 800
and TransactionTypeID in (17)
and cast(SaleDateTime as date) <= cast(@saledate as date)
--and Qty > 0

if @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end

MERGE INTO [DataTrue_Main].[dbo].[InvoiceDetails] i

--select cast(7 as money) * 50/100 % 1 = 0
--select cast(7 as money) * isnull(null,100)/100
--select 7 * .5 % 1
USING (select t.ChainID
           ,t.StoreID
           ,t.ProductID
           ,t.BrandID
           ,t.SupplierID
           ,case when cast(SUM(Qty) as money) * isnull(s.RetailerShrinkPercent,100)/100 % 1 = 0 then SUM(Qty) * isnull(s.RetailerShrinkPercent,100)/100 else cast(SUM(Qty)*s.RetailerShrinkPercent/100 + 1 as int) end as TotalQty


			,cast(-1 as money) as TotalCost
           --,SUM(Qty * TrueCost) as TotalCost
           --,case when cast(SUM(Qty) as money) * isnull(s.RetailerShrinkPercent,100)/100 % 1 = 0 then SUM(Qty * TrueCost) else cast(SUM(Qty)*s.RetailerShrinkPercent/100 + 1 as int) * TrueCost end as TotalCost
           
           --,case when SUM(Qty) * isnull(s.RetailerShrinkPercent,1) % 1 = 0 then SUM(Qty * TrueRetail) else cast(SUM(Qty)*s.RetailerShrinkPercent/100 + 1 as int) * TrueRetail) end as TotalRetail
           --,SUM(Qty * TrueRetail) as TotalRetail
			,cast(-1 as money) as TotalRetail
			           
           --,case when SUM(Qty) * isnull(s.RetailerShrinkPercent,1) % 1 = 0 then SUM(Qty * TrueCost)/SUM(Qty) else SUM((Qty+1) * TrueCost)/SUM(Qty+1) end as UnitCost
           --,SUM(Qty * TrueCost)/SUM(Qty) as UnitCost
           ,max(RuleCost) as UnitCost
           
           --,SUM(Qty * TrueRetail)/SUM(Qty) as UnitRetail
           ,max(RuleRetail) as UnitRetail
           
           ,CAST(SaleDateTime as DATE) as SaleDate
		FROM [dbo].[StoreTransactions] t
		inner join #tempStoreTransactions tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
		left outer join StoreSetup s
		on t.storeid = s.storeid
		and t.productid = s.productid
		and t.brandid = s.brandid
		where CAST(SaleDateTime as DATE) between s.activestartdate and s.activelastdate
	    group by t.[ChainID]
           ,t.[StoreID]
           ,t.[ProductID]
           ,t.[BrandID]
           ,t.[SupplierID]
           ,CAST(SaleDateTime as DATE)
           ,s.RetailerShrinkPercent--) S
		having SUM(Qty) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.RetailerInvoiceID is null
	and i.SupplierInvoiceID is null
	and i.TotalQty > 0
	and i.InvoiceDetailTypeID = @invoicedetailtype

WHEN MATCHED THEN

update set [TotalQty] = i.[TotalQty] + s.TotalQty
           ,[TotalCost] = cast(-1 as money) --i.[TotalCost] + s.TotalCost
           ,[TotalRetail] = cast(-1 as money) --i.[TotalRetail] + s.TotalRetail
           --,[UnitCost] =  (i.[TotalCost] + s.TotalCost)/(i.[TotalQty] + s.TotalQty)
           --,[UnitRetail] =  (i.[TotalRetail] + s.TotalRetail)/(i.[TotalQty] + s.TotalQty)
           ,[LastUpdateUserID] = @MyID
		   ,[DateTimeLastUpdate] = getdate()
		   ,[BatchID] = isnull([BatchID], '') + ' ' + @batchstring
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[TotalCost]
           ,[TotalRetail]
           ,[UnitCost]
           ,[UnitRetail]
           ,[LastUpdateUserID]
           ,[SaleDate]
           ,[BatchID])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.[SupplierID]
			,@invoicedetailtype
			,s.TotalQty
			,s.TotalCost
			,s.TotalRetail
			,s.UnitCost
			,s.UnitRetail
			,@MyID
			,s.SaleDate
			,@batchstring);

update InvoiceDetails set [TotalCost] = [TotalQty] * [UnitCost], [TotalRetail] = [TotalQty] * [UnitRetail]
where [TotalCost] = -1.00

update t set TransactionStatus = 805, InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID
*/
--***********************
--/*
select StoreTransactionID
into #tempStoreTransactions2
--declare @saledate date='2/16/2012' select *
from StoreTransactions
where TransactionStatus in (800, 801)
and TransactionTypeID in (22,23)
and cast(SaleDateTime as date) <= cast(@saledate as date)
and Qty <> 0
and RuleCost <> 0

if @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end

MERGE INTO [DataTrue_Main].[dbo].[InvoiceDetails] i

--select cast(7 as money) * 50/100 % 1 = 0
--select cast(7 as money) * isnull(null,100)/100
--select 7 * .5 % 1
USING (select t.ChainID
           ,t.StoreID
           ,t.ProductID
           ,t.BrandID
           ,t.SupplierID
           --,case when cast(SUM(Qty) as money) * isnull(s.RetailerShrinkPercent,100)/100 % 1 = 0 then SUM(Qty) * isnull(s.RetailerShrinkPercent,100)/100 else cast(SUM(Qty)*s.RetailerShrinkPercent/100 as int) - 1 end as TotalQty
           ,SUM(Qty) as TotalQty


			,cast(-1 as money) as TotalCost
           --,SUM(Qty * TrueCost) as TotalCost
           --,case when cast(SUM(Qty) as money) * isnull(s.RetailerShrinkPercent,100)/100 % 1 = 0 then SUM(Qty * TrueCost) else cast(SUM(Qty)*s.RetailerShrinkPercent/100 + 1 as int) * TrueCost end as TotalCost
           
           --,case when SUM(Qty) * isnull(s.RetailerShrinkPercent,1) % 1 = 0 then SUM(Qty * TrueRetail) else cast(SUM(Qty)*s.RetailerShrinkPercent/100 + 1 as int) * TrueRetail) end as TotalRetail
           --,SUM(Qty * TrueRetail) as TotalRetail
			,cast(-1 as money) as TotalRetail
			           
           --,case when SUM(Qty) * isnull(s.RetailerShrinkPercent,1) % 1 = 0 then SUM(Qty * TrueCost)/SUM(Qty) else SUM((Qty+1) * TrueCost)/SUM(Qty+1) end as UnitCost
           --,SUM(Qty * TrueCost)/SUM(Qty) as UnitCost
           ,max(RuleCost) as UnitCost
           
           --,SUM(Qty * TrueRetail)/SUM(Qty) as UnitRetail
           ,max(RuleRetail) as UnitRetail
           
           ,CAST(SaleDateTime as DATE) as SaleDate
           ,max(isnull(PromoAllowance, 0.00)) as PromoAllowance
		FROM [dbo].[StoreTransactions] t
		inner join #tempStoreTransactions2 tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
		left outer join StoreSetup s
		on t.storeid = s.storeid
		and t.productid = s.productid
		and t.brandid = s.brandid
		and t.chainid = s.chainid
		and CAST(SaleDateTime as DATE) between s.activestartdate and s.activelastdate
		--where CAST(SaleDateTime as DATE) between s.activestartdate and s.activelastdate
	    group by t.[ChainID]
           ,t.[StoreID]
           ,t.[ProductID]
           ,t.[BrandID]
           ,t.[SupplierID]
           ,CAST(SaleDateTime as DATE)
           ,s.RetailerShrinkPercent
           ,t.transactiontypeid--) S
		having SUM(Qty) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.UnitCost = s.UnitCost
	and isnull(i.PromoAllowance, 0.0) = isnull(s.PromoAllowance, 0.00)
	and i.RetailerInvoiceID is null
	and i.SupplierInvoiceID is null
	and i.TotalQty > 0
	and i.InvoiceDetailTypeID = @invoicedetailtype


WHEN MATCHED THEN

update set [TotalQty] = i.[TotalQty] + s.TotalQty
           ,[TotalCost] = cast(-1 as money) --i.[TotalCost] + s.TotalCost
           ,[TotalRetail] = cast(-1 as money) --i.[TotalRetail] + s.TotalRetail
           --,[UnitCost] =  (i.[TotalCost] + s.TotalCost)/(i.[TotalQty] + s.TotalQty)
           --,[UnitRetail] =  (i.[TotalRetail] + s.TotalRetail)/(i.[TotalQty] + s.TotalQty)
           ,[LastUpdateUserID] = @MyID
		   ,[DateTimeLastUpdate] = getdate()
		   ,[BatchID] = isnull([BatchID], '') + ' ' + @batchstring
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[TotalCost]
           ,[TotalRetail]
           ,[UnitCost]
           ,[UnitRetail]
           ,[LastUpdateUserID]
           ,[SaleDate]
           ,[BatchID]
           ,[PromoAllowance])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.[SupplierID]
			,@invoicedetailtype
			,s.TotalQty
			,s.TotalCost
			,s.TotalRetail
			,s.UnitCost
			,s.UnitRetail
			,@MyID
			,s.SaleDate
			,@batchstring
			,s.PromoAllowance);

update InvoiceDetails 
set [TotalCost] = [TotalQty] * ([UnitCost] - isnull([PromoAllowance], 0.00)), [TotalRetail] = [TotalQty] * [UnitRetail]
where [TotalCost] = -1.00

update t set TransactionStatus = case when transactionstatus = 800 then 805 else 806 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions2 tmp
on t.StoreTransactionID = tmp.StoreTransactionID

--*/
--***********************


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
