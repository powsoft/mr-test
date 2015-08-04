USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtilInventoryAndProductScripts]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtilInventoryAndProductScripts]
/*
truncate table [dbo].[InventoryPerpetual]
*/
as

truncate table [dbo].[InventoryPerpetual]

INSERT INTO [dbo].[InventoryPerpetual]
           ([StoreID]
           ,[ProductID]
           ,[OriginalQty]
           ,[Deliveries]
           ,[SBTSales]
           ,[ShrinkRevision]
           ,[CurrentOnHandQty]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
           select Distinct storeid, ProductId, 
				100, 0, 0, 0, 100, '1/1/2011', 2, '1/1/2011'
			from StoreTransactions
			where TransactionTypeID = 2
    
select top 1000 * from [dbo].[InventoryPerpetual]

/*
select storeid, ProductId, SUM(Qty)
from StoreTransactions
where TransactionTypeID = 2
--and ProductID = 577
group by StoreID, ProductID
order by SUM(Qty) desc

select top 100 * from [ProductCategoryAssignments]
select distinct ProductCategoryID from [ProductCategoryAssignments]
update [ProductCategoryAssignments] set ProductCategoryID = 6
*/
GO
