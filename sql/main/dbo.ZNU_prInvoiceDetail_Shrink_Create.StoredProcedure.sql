USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prInvoiceDetail_Shrink_Create]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prInvoiceDetail_Shrink_Create]
@saledate date=null--,
--@invoicedetailtype tinyint
/*
prInvoiceDetail_Retailer_Shrink_Create '6/25/2011', 3
*/
as

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
from StoreTransactions
where TransactionStatus = 800
and TransactionTypeID in (17,18)
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
		inner join #tempStoreTransactions tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
	    group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,CAST(SaleDateTime as DATE)--) S
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


update t set TransactionStatus = 810, InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID

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
