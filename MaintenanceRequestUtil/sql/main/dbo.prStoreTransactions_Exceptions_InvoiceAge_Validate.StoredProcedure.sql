USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prStoreTransactions_Exceptions_InvoiceAge_Validate]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prStoreTransactions_Exceptions_InvoiceAge_Validate]
as

select storetransactionid
into #tmpTransactions
from StoreTransactions_Working
where 1 = 1
and CHARINDEX('SUP', workingsource) > 0
and WorkingStatus = 4

/*
select *
from StoreTransactions_Management
*/

begin transaction

update t set TransactionTypeID =
case when CHARINDEX('SUP-S', workingsource)>0 then 5
	when CHARINDEX('SUP-U', workingsource)>0 then 8
else null
end
from #tmpTransactions tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID

update W
set workingstatus = -27
from #tmpTransactions t
inner join StoreTransactions_Working w
on t.StoreTransactionID = w.StoreTransactionID
inner join StoreTransactions_Management m
on w.chainid = m.chainid
and w.SupplierID = m.SupplierID
and w.StoreID = m.StoreID
and w.ProductID = m.ProductID
and w.BrandID = m.BrandID
and GETDATE() between m.ActiveStartDate and m.ActiveLastDate
and m.PendSUPRecordsWithInvoiceDateTooOldInDays is not null
and CAST(w.saledatetime as date) > dateadd(day, m.PendSUPRecordsWithInvoiceDateTooOldInDays*-1, GETDATE())

update W
set workingstatus = -27
from #tmpTransactions t
inner join StoreTransactions_Working w
on t.StoreTransactionID = w.StoreTransactionID
inner join StoreTransactions_Management m
on w.chainid = m.chainid
and w.SupplierID = m.SupplierID
and w.StoreID = m.StoreID
and w.ProductID = m.ProductID
and 0 = m.BrandID
and GETDATE() between m.ActiveStartDate and m.ActiveLastDate
and m.PendSUPRecordsWithInvoiceDateTooOldInDays is not null
and CAST(w.saledatetime as date) > dateadd(day, m.PendSUPRecordsWithInvoiceDateTooOldInDays*-1, GETDATE())

update W
set workingstatus = -27
from #tmpTransactions t
inner join StoreTransactions_Working w
on t.StoreTransactionID = w.StoreTransactionID
inner join StoreTransactions_Management m
on w.chainid = m.chainid
and w.SupplierID = m.SupplierID
and w.StoreID = m.StoreID
and 0 = m.ProductID
and 0 = m.BrandID
and GETDATE() between m.ActiveStartDate and m.ActiveLastDate
and m.PendSUPRecordsWithInvoiceDateTooOldInDays is not null
and CAST(w.saledatetime as date) > dateadd(day, m.PendSUPRecordsWithInvoiceDateTooOldInDays*-1, GETDATE())

update W
set workingstatus = -27
from #tmpTransactions t
inner join StoreTransactions_Working w
on t.StoreTransactionID = w.StoreTransactionID
inner join StoreTransactions_Management m
on w.chainid = m.chainid
and w.SupplierID = m.SupplierID
and 0 = m.StoreID
and 0 = m.ProductID
and 0 = m.BrandID
and GETDATE() between m.ActiveStartDate and m.ActiveLastDate
and m.PendSUPRecordsWithInvoiceDateTooOldInDays is not null
and CAST(w.saledatetime as date) > dateadd(day, m.PendSUPRecordsWithInvoiceDateTooOldInDays*-1, GETDATE())

update W
set workingstatus = -27
from #tmpTransactions t
inner join StoreTransactions_Working w
on t.StoreTransactionID = w.StoreTransactionID
inner join StoreTransactions_Management m
on w.chainid = m.chainid
and 0 = m.SupplierID
and 0 = m.StoreID
and 0 = m.ProductID
and 0 = m.BrandID
and GETDATE() between m.ActiveStartDate and m.ActiveLastDate
and m.PendSUPRecordsWithInvoiceDateTooOldInDays is not null
and CAST(w.saledatetime as date) > dateadd(day, m.PendSUPRecordsWithInvoiceDateTooOldInDays*-1, GETDATE())

INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Exceptions]
           ([StoreTransactionExceptionTypeID]
           ,[StoreTransactionID]
           ,[ReportedSupplierIdentifier]
           ,[ExpectedSupplierIdentifier]
           ,[ExpectedSupplierName]
           ,[ReportedSupplierName]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SetupAllowance]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[ExpectedAllowance]
           ,[ReportedAllowance]
           ,[SaleDateTime]
           ,[ProcessingErrorDesc]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[ExceptionStatus]
           ,[ChainID]
           ,[StoreId]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[UPC]
           ,[TransactionTypeId])
     select 4 --<StoreTransactionExceptionTypeID, smallint,>
           ,w.StoreTransactionID --<StoreTransactionID, bigint,>
           ,w.SupplierIdentifier --<ReportedSupplierIdentifier, nvarchar(250),>
           ,null --<ExpectedSupplierIdentifier, nvarchar(250),>
           ,null --<ExpectedSupplierName, nvarchar(50),>
           ,w.SupplierName --<ReportedSupplierName, nvarchar(50),>
           ,Qty --<Qty, int,>
           ,SetupCost
           ,SetupRetail
           ,PromoAllowance
           ,ReportedCost
           ,ReportedRetail
           ,null --<ExpectedAllowance, money,>
           ,ReportedAllowance
           ,SaleDateTime
           ,null --<ProcessingErrorDesc, nvarchar(1000),>
           ,null --<Comments, nvarchar(1000),>
           ,GETDATE() --<DateTimeCreated, datetime,>
           ,0 --<LastUpdateUserID, int,>
           ,GETDATE() --<DateTimeLastUpdate, datetime,>
           ,0 --<ExceptionStatus, smallint,>
           ,w.ChainID --<ChainID, int,>
           ,w.StoreId
           ,w.ProductID
           ,w.BrandID
           ,w.SupplierID
           ,w.UPC
           ,w.TransactionTypeId
		from StoreTransactions_Working w
		inner join #tmpTransactions t
		on w.StoreTransactionID = t.StoreTransactionID
		and w.workingstatus = -27
		
	
commit transaction

return
GO
