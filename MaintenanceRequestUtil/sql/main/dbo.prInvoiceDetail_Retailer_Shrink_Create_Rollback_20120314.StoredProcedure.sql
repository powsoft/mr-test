USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_Retailer_Shrink_Create_Rollback_20120314]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prInvoiceDetail_Retailer_Shrink_Create_Rollback_20120314]
@saledate date=null--,
--@invoicedetailtype tinyint
/*
prInvoiceDetail_Retailer_Shrink_Create '6/25/2011', 3
select top 1000 * from invoicedetails where invoicedetailtypeid = 3 order by invoicedetailid desc
select * from storetransactions where transactiontypeid = 17 order by datetimecreated desc
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
set @invoicedetailtype = 3

if @saledate is null
	set @saledate = GETDATE()
	
begin try

begin transaction


select StoreTransactionID
into #tempStoreTransactions
--declare @saledate date = getdate() select *
from StoreTransactions
where TransactionStatus in (800, 801)
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
	
--***************Promo Lookup Start**************************

update t set t.PromoAllowance = p.UnitPrice,
t.PromoTypeID = P.ProductPriceTypeID
from #tempStoreTransactions tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

--***************Cost Lookup Start**************************

--First look for exact match for all entities
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
--select t.*
from #tempStoreTransactions tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where 1 = 1
--and t.SetupCost is null
and p.ProductPriceTypeID = 3 
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate	

MERGE INTO [DataTrue_Main].[dbo].[InvoiceDetails] i

--select cast(7 as money) * 50/100 % 1 = 0
--select cast(7 as money) * isnull(null,100)/100
--select 7 * .5 % 1
USING (select t.ChainID
           ,t.StoreID
           ,t.ProductID
           ,t.BrandID
           ,t.SupplierID
           --,case when cast(SUM(Qty) as money) * isnull(s.RetailerShrinkPercent,100)/100 % 1 = 0 then SUM(Qty) * isnull(s.RetailerShrinkPercent,100)/100 else cast(SUM(Qty)*s.RetailerShrinkPercent/100 + 1 as int) end as TotalQty
           ,SUM(Qty)  as TotalQty

/*
select case when cast(7 as money) * isnull(50,100)/100 % 1 = 0 then 7 * isnull(50,100)/100 else cast(7*50/100 + 1 as int) end as TotalQty
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
           ,max(PromoAllowance) as PromoAllowance
		FROM [dbo].[StoreTransactions] t
		inner join #tempStoreTransactions tmp
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

update InvoiceDetails set [TotalCost] = [TotalQty] * ([UnitCost] - Isnull([PromoAllowance], 0.00)), [TotalRetail] = [TotalQty] * [UnitRetail]
where [TotalCost] = -1.00

update t set TransactionStatus = case when transactionstatus = 800 then 805 else 806 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID

--***********************
--/*
select StoreTransactionID
into #tempStoreTransactions2
from StoreTransactions
where TransactionStatus = 800
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
--***************Promo Lookup Start**************************

update t set t.PromoAllowance = p.UnitPrice,
t.PromoTypeID = P.ProductPriceTypeID
from #tempStoreTransactions2 tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

--***************Cost Lookup Start**************************

--First look for exact match for all entities
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
--select t.*
from #tempStoreTransactions2 tmp
inner join [dbo].[StoreTransactions] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where 1 = 1
--and t.SetupCost is null
and p.ProductPriceTypeID = 3 
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate	
	

MERGE INTO [DataTrue_Main].[dbo].[InvoiceDetails] i

--select cast(7 as money) * 50/100 % 1 = 0
--select cast(7 as money) * isnull(null,100)/100
--select 7 * .5 % 1
USING (select t.ChainID
           ,t.StoreID
           ,t.ProductID
           ,t.BrandID
           ,t.SupplierID
           --,case when cast(SUM(Qty) as money) * isnull(s.RetailerShrinkPercent,100)/100 % 1 = 0 then SUM(Qty) * isnull(s.RetailerShrinkPercent,100)/100 else cast(SUM(Qty)*s.RetailerShrinkPercent/100 - 1 as int) end as TotalQty
           ,SUM(Qty) as TotalQty

/*
select case when cast(-4 as money) * isnull(50,100)/100 % 1 = 0 then -4 * isnull(50,100)/100 else cast(-4*50/100 - 1 as int) end as TotalQty
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
           ,max(PromoAllowance) as PromoAllowance
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

update InvoiceDetails set [TotalCost] = [TotalQty] * ([UnitCost] - Isnull([PromoAllowance], 0.00)), [TotalRetail] = [TotalQty] * [UnitRetail]
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
