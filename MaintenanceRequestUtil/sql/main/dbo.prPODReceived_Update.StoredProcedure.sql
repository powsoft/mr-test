USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPODReceived_Update]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPODReceived_Update]
as


begin transaction

select chainid, storeid, supplierid, CAST(saledatetime as date) as SaleDate
into #tempNewPODReceived
from StoreTransactions_Working w
where CHARINDEX('POD', workingsource)>0
and PODReceived is null

update W
set PODReceived = 1
--select *
from StoreTransactions_Working w
inner join #tempNewPODReceived t
on w.StoreID = t.StoreID
and w.SupplierID = t.SupplierID
and CAST(saledatetime as date) = t.SaleDate
and CHARINDEX('SUP', workingsource)>0

update W
set PODReceived = 1
from StoreTransactions w
inner join #tempNewPODReceived t
on w.StoreID = t.StoreID
and w.SupplierID = t.SupplierID
and CAST(saledatetime as date) = t.SaleDate
and TransactionTypeID in (5, 8)

update W
set PODReceived = 1
from dbo.InventoryReport_Newspaper_Shrink_Facts w
inner join #tempNewPODReceived t
on w.StoreID = t.StoreID
and w.SupplierID = t.SupplierID
and CAST(saledatetime as date) = t.SaleDate

INSERT INTO [DataTrue_Main].[dbo].[PODHistory]
           ([ChainID]
           ,[StoreID]
           ,[SupplierID]
           ,[SaleDate]
           ,[LastUpdateUserID])
     select chainid, storeid, supplierid, saledate, 0
     from #tempNewPODReceived


update W
set PODReceived = 1, WorkingStatus = 5
from StoreTransactions_Working w
inner join #tempNewPODReceived t
on w.StoreID = t.StoreID
and w.SupplierID = t.SupplierID
and CAST(saledatetime as date) = t.SaleDate
and CHARINDEX('POD', workingsource)>0

commit transaction


/*

select * from dbo.InventoryReport_Newspaper_Shrink_Facts

select distinct top 400 chainid, storeid, supplierid, cast(saledatetime as date) as saledate from dbo.InventoryReport_Newspaper_Shrink_Facts


select distinct top 400 chainid, storeid, supplierid, cast(saledatetime as date) as saledate into #tempNewPODReceived from dbo.InventoryReport_Newspaper_Shrink_Facts


select * from podhistory
*/



return
GO
