USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundWHSTransactions]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundWHSTransactions]


As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 0

begin try

select RecordID 
into #tempInboundTransactions  
from DataTrue_EDI..InBoundSuppliers 
WHERE RecordStatus = 0
and Qty <> 0


begin transaction

set @loadstatus = 1



INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[SupplierIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           --,[ReportedUnitPrice]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived])
     select
           ltrim(rtrim(ChainIdentifier))
           ,ltrim(rtrim(StoreIdentifier))
           ,ltrim(rtrim(SupplierIdentifier))
           ,Qty
           /*
           ,case when TransactionType = 'S' then Qty 
				when TransactionType = 'U' then Qty * -1
				else Qty
			end
			*/
           ,SaleDate
           ,TitleID
           ,BrandIdentifier
           ,InvoiceNumber
           ,Price
           ,CoverPrice
           ,case when TransactionType = 'D' then 'SUP-S' 
				when TransactionType = 'P' then 'SUP-U' 
				when TransactionType = 'S' then 'SUP-U' --shortage type
				else 'SUP-X' 
			end
           ,@MyID
           ,isnull(FileName, 'DEFAULT')
           ,DateTimeReceived
     from DataTrue_EDI..InBoundSuppliers s
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId



commit transaction
	
end try
	
begin catch
		rollback transaction

		set @loadstatus = -9998

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
	
update s set RecordStatus = @loadstatus
from DataTrue_EDI..InBoundSuppliers s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID
/*
select distinct TransactionType from DataTrue_EDI..InBoundSuppliers
select StoreTransactionID into #tmpInboundPOS
from StoreTransactions_Working t
where t.WorkingStatus = 0
and WorkingSource = 'POS'

--Retailer's reported cost is iControl's ReportedSalePrice

update t
set t.ReportedUnitPrice = Case when t.ReportedUnitPrice < 0.0001 then t.ReportedUnitCost else t.ReportedUnitPrice end
from #tmpInboundPOS tmp
inner join StoreTransactions_Working t
on tmp.StoreTransactionID = t.StoreTransactionID

*/

return
GO
