USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_Supplier_Shrink_Create]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_Supplier_Shrink_Create]
@saledate date=null--,
--@invoicedetailtype tinyint
/*
prInvoiceDetail_Retailer_Shrink_Create '6/25/2011', 3
select * from invoicedetails
*/
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @batchid bigint
declare @batchstring nvarchar(255)
declare @invoicedetailtype tinyint

set @MyID = 40375
set @invoicedetailtype = 5

if @saledate is null
	set @saledate = GETDATE()
	
begin try

begin transaction


select StoreTransactionID
into #tempStoreTransactions
from StoreTransactions
where TransactionStatus in (805, 806)
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
--select cast(cast(7 as money)*50/100 as int) - 1
USING (select t.ChainID
           ,t.StoreID
           ,t.ProductID
           ,t.BrandID
           ,t.SupplierID
           ,-1 * (case when cast(SUM(Qty) as money) * isnull(s.SupplierShrinkPercent,100)/100 % 1 = 0 then SUM(Qty) * isnull(s.SupplierShrinkPercent,100)/100 
           else cast(cast(SUM(Qty) as money)*s.SupplierShrinkPercent/100 as int) - 1 end) as TotalQty
/*
select case when cast(7 as money) * isnull(50,100)/100 % 1 = 0 then 7 * isnull(50,100)/100 
           else cast(cast(7 as money)*50/100 as int) end as TotalQty

*/

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
           ,s.SupplierShrinkPercent--) S
		having SUM(Qty) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.UnitCost = s.UnitCost
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

update InvoiceDetails set [TotalCost] = 1 * ([TotalQty] * ([UnitCost] - [PromoAllowance])), [TotalRetail] = [TotalQty] * [UnitRetail]
where [TotalCost] = -1.00

update t set TransactionStatus = case when transactionstatus = 805 then 810 else 811 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID



select StoreTransactionID
into #tempStoreTransactions2
from StoreTransactions
where TransactionStatus in (805, 806)
and TransactionTypeID in (18,19)
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
           --,case when cast(SUM(Qty) as money) * isnull(s.SupplierShrinkPercent,100)/100 % 1 = 0 then SUM(Qty) * isnull(s.SupplierShrinkPercent,100)/100 else cast(SUM(Qty)*s.SupplierShrinkPercent/100 - 1 as int) end as TotalQty
           ,-1 * (case when cast(SUM(Qty) as money) * isnull(s.SupplierShrinkPercent,100)/100 % 1 = 0 then SUM(Qty) * isnull(s.SupplierShrinkPercent,100)/100 
           else cast(cast(SUM(Qty) as money)*s.SupplierShrinkPercent/100 as int) + 1 end) as TotalQty


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
		inner join #tempStoreTransactions2 tmp
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
           ,s.SupplierShrinkPercent--) S
		having SUM(Qty) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.UnitCost = s.UnitCost
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

update InvoiceDetails set [TotalCost] = 1 * ([TotalQty] * ([UnitCost] - [PromoAllowance])), [TotalRetail] = [TotalQty] * [UnitRetail]
where [TotalCost] = -1.00

update t set TransactionStatus = case when transactionstatus = 805 then 810 else 811 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions2 tmp
on t.StoreTransactionID = tmp.StoreTransactionID
/*
select StoreTransactionID
into #tempStoreTransactions2
from StoreTransactions
where TransactionStatus = 800
and TransactionTypeID in (17,18)
and cast(SaleDateTime as date) <= cast(@saledate as date)
and Qty < 0

if @batchid is null and @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end

MERGE INTO [DataTrue_Main].[dbo].[InvoiceDetails] i

USING (select ChainID
           ,StoreID
           ,ProductID
           ,BrandID
           ,SupplierID
           ,SUM(Qty) as TotalQty
           ,SUM(Qty * TrueCost) as TotalCost
           ,SUM(Qty * TrueRetail) as TotalRetail
           ,SUM(Qty * TrueCost)/SUM(Qty) as UnitCost
           ,SUM(Qty * TrueRetail)/SUM(Qty) as UnitRetail
           ,CAST(SaleDateTime as DATE) as SaleDate
		FROM [dbo].[StoreTransactions] t
		inner join #tempStoreTransactions2 tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
	    group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,CAST(SaleDateTime as DATE)) S
		--having SUM(Qty) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.RetailerInvoiceID is null
	and i.SupplierInvoiceID is null
	and i.TotalQty < 0
	and i.InvoiceDetailTypeID = @invoicedetailtype

WHEN MATCHED THEN

update set [TotalQty] = i.[TotalQty] + s.TotalQty
           ,[TotalCost] = i.[TotalCost] + s.TotalCost
           ,[TotalRetail] = i.[TotalRetail] + s.TotalRetail
           ,[UnitCost] =  (i.[TotalCost] + s.TotalCost)/(i.[TotalQty] + s.TotalQty)
           ,[UnitRetail] =  (i.[TotalRetail] + s.TotalRetail)/(i.[TotalQty] + s.TotalQty)
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

*/


/*
update t set TransactionStatus = 810, InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions2 tmp2
on t.StoreTransactionID = tmp2.StoreTransactionID
*/

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
