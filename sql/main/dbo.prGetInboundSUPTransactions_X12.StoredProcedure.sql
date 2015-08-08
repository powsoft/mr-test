USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundSUPTransactions_X12]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundSUPTransactions_X12]
/*
RoleID 7415
truncate table StoreTransactions_Working
select * from StoreTransactions_Working
select distinct workingstatus from StoreTransactions_Working
select * from StoreTransactions_Working where workingstatus = 4
update EDI..Inbound852Sales set RecordStatus = 0
*/
As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7427

begin try

--select * from DataTrue_EDI.dbo.X12_SuppliersDeliveriesAndInventories where activitycode = '7341013532'
select RecordID 
into #tempInboundTransactions 
--select *
--select distinct activitycode 
--select distinct suppliername
from DataTrue_EDI.dbo.X12_SuppliersDeliveriesAndInventories
--csc 20111221 change to new table from DataTrue_EDI..InBoundSuppliers 
--INNER JOIN DataTrue_Main.dbo.ProductIdentifiers AS p 
--ON InBoundSuppliers.TitleID = p.IdentifierValue
WHERE 1 = 1
and RecordStatus = 0
and Qty <> 0
and InvoiceDate is not null
and ActivityCode in ('QD', 'QU')
and LTRIM(rtrim(Suppliername)) = 'BIMBO'
--and LTRIM(rtrim(Suppliername)) = 'Lewis Bakery Inc.'
--and p.ProductIdentifierTypeID = 2 --UPC
--and isnumeric(StoreIdentifier) > 0

begin transaction

set @loadstatus = 2 --2 for bimbo



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
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNo))
           ,ltrim(rtrim(SupplierName))
           ,sum(Qty)
           /*
           ,case when TransactionType = 'S' then Qty 
				when TransactionType = 'U' then Qty * -1
				else Qty
			end
			*/
           ,InvoiceDate
           ,ltrim(rtrim(UPC))
           ,null --BrandIdentifier
           ,ltrim(rtrim(isnull(InvoiceNum, '')))
           ,null --UnitPrice
           ,null --CoverPrice
           ,case when ltrim(rtrim(ActivityCode)) = 'QD' then 'SUP-S' 
				when ltrim(rtrim(ActivityCode)) = 'QU' then 'SUP-U' 
				--when TransactionType = 'S' then 'SUP-U' --shortage type
				else 'SUP-X' 
			end
           ,0 --@MyID
           ,'DEFAULT' --isnull(FileName, 'DEFAULT')
           ,cast(DateTimeCreated as date)
     from DataTrue_EDI.dbo.X12_SuppliersDeliveriesAndInventories s
--where InvoiceDate is not null
--and ActivityCode in ('QD', 'QU')
--and LTRIM(rtrim(Suppliername)) = 'BIMBO'

--and StoreNo = '6801'
--and upc = '07313000432'
--and ActivityCode =	'QD'
--and InvoiceDate = '2011-12-15 00:00:00.000'
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId
     group by   ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNo))
           ,ltrim(rtrim(SupplierName))
           ,InvoiceDate
           ,ltrim(rtrim(UPC))
           ,ltrim(rtrim(ActivityCode))
           ,cast(DateTimeCreated as date)
           ,ltrim(rtrim(isnull(InvoiceNum, '')))



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
from DataTrue_EDI.dbo.X12_SuppliersDeliveriesAndInventories s
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
