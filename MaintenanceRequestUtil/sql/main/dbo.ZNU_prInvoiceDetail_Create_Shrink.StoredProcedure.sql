USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prInvoiceDetail_Create_Shrink]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prInvoiceDetail_Create_Shrink]
@saledate date

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

set @MyID = 24129

begin try

begin transaction

select StoreTransactionID
into #tempStoreTransactions
from StoreTransactions
where TransactionStatus = 989
and TransactionTypeID in (17, 18)
and cast(SaleDateTime as date) = cast(@saledate as date)

INSERT INTO [DataTrue_Main].[dbo].[InvoiceDetail]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[TotalCost]
           ,[TotalRetail]
           ,[LastUpdateUserID])
     select ChainID
           ,StoreID
           ,ProductID
           ,SupplierID
           ,BrandID
           ,3
           ,SUM(Qty)
           ,SUM(Qty * TrueCost)
           ,SUM(Qty * TrueRetail)
           ,@MyID
     from StoreTransactions t
     inner join #tempStoreTransactions tmp
     on t.StoreTransactionID = tmp.StoreTransactionID
     group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]

update t set StoreTransactionID = 999
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
