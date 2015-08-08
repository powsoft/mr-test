USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_SUP_Create]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_SUP_Create]
--@invoicedetailtype tinyint,
@saledate date=null
/*
prInvoiceDetail__SUP_Create '6/22/2011'
*/
as
--declare @saledate date=null
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @batchid bigint
declare @batchstring nvarchar(255)
declare @invoicedetailtype tinyint

set @MyID = 24127
set @invoicedetailtype = 2

if @saledate is null
	set @saledate = GETDATE()
	
begin try

begin transaction

--declare @saledate date=getdate()
select StoreTransactionID
into #tempStoreTransactions
--declare @saledate date=getdate() select *
from StoreTransactions
where TransactionStatus in (800, 801)
and TransactionTypeID in (5,8)
--and cast(SaleDateTime as date) <= cast(@saledate as date)
and RuleCost <> 0
and Qty <> 0
and YEAR(SaleDatetime) > 2011


if @@ROWCOUNT > 0
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
 --          ,1 --POSSource
           ,SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end) as TotalQty
           ,SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end * RuleCost) as TotalCost
           ,SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end * RuleRetail) as TotalRetail
           ,SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end * RuleCost)/SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end) as UnitCost
           ,SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end * RuleRetail)/SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end) as UnitRetail
           ,CAST(SaleDateTime as DATE) as SaleDate
           ,InvoiceDueDate
		FROM [dbo].[StoreTransactions] t
		inner join #tempStoreTransactions tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
	    group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,CAST(SaleDateTime as DATE)
           ,InvoiceDueDate
           ,RuleCost
		--having SUM(Qty * RuleCost) <> 0) S
		having SUM(case when Transactiontypeid = 5 then Qty else Qty * -1 end) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.UnitCost = s.UnitCost
	and i.RetailerInvoiceID is null
	and i.SupplierInvoiceID is null
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
           ,[BatchID]
           ,[PaymentDueDate])
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
			,s.[InvoiceDueDate]);

update t set TransactionStatus = case when transactionstatus = 800 then 810 else 811 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID

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
