USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplySUPStoreTransactionsToInventory]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplySUPStoreTransactionsToInventory]      
      
as      
    
    
declare @errormessage nvarchar(4000)      
declare @errorlocation nvarchar(255)      
declare @errorsenderstring nvarchar(255)        
declare @MyID int      
set @MyID = 7592      
    
begin try      
      
begin transaction      
      
--delivery records      
select distinct StoreTransactionID      
into #tempStoreTransaction      
--select *      
from [dbo].[StoreTransactions]      
where TransactionStatus in (0, 1, 811)      
--where TransactionStatus in (1, 11)      
and TransactionTypeID in (4,5,20)      
and RuleCost is not null      
--and CostMisMatch = 0      
--and RetailMisMatch = 0      
--and TrueCost is not null      
and CAST(Saledatetime as date) >= '12/1/2011'      
--and SupplierID in (40561)      
and SupplierID in (40558, 40562, 40561, 40557, 41464, 41465, 40559, 41440)      
      
--**************************************************************      
MERGE INTO [dbo].[InventoryPerpetual] i      
      
USING (SELECT [ChainID]      
   ,[StoreID]      
      ,[ProductID]      
      ,[BrandID]      
      ,sum([Qty]) as Qty      
      ,max([RuleCost]) as Cost      
      ,max(isnull([RuleRetail], 0.00)) as Retail      
      ,max([SaleDateTime]) as EffectiveDateTime      
  FROM [dbo].[StoreTransactions] t      
  inner join #tempStoreTransaction tmp      
 on t.StoreTransactionID = tmp.StoreTransactionID      
 group by t.chainid, t.storeid, t.productid, t.brandid) S      
 on i.ChainID = s.ChainID      
 and i.StoreID = s.StoreID       
 and i.ProductID = s.ProductID      
 and i.BrandID = s.BrandID      
      
WHEN MATCHED THEN      
      
update set  Deliveries = Deliveries + S.Qty      
 ,CurrentOnHandQty = CurrentOnHandQty + s.Qty       
 ,LastUpdateUserID = @MyID      
 ,DateTimeLastUpdate = getdate()      
 ,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end      
 ,Cost =       
  case when i.CurrentOnHandQty > 0 then ((s.Cost * s.Qty) + (i.Cost * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Cost end      
 ,Retail =       
  case when i.CurrentOnHandQty > 0 then ((s.Retail * s.Qty) + (i.Retail * i.CurrentOnHandQty))/(s.Qty + i.CurrentOnHandQty) else s.Retail end      
      
WHEN NOT MATCHED       
      
THEN INSERT       
           ([ChainID]      
           ,[StoreID]      
           ,[ProductID]      
           ,[BrandID]      
           ,[OriginalQty]      
           ,[Deliveries]      
           ,[SBTSales]      
           ,[ShrinkRevision]      
           ,[CurrentOnHandQty]      
           ,[LastUpdateUserID]      
           ,[DateTimeLastUpdate]      
           ,[EffectiveDateTime]      
           ,[Cost]      
           ,[Retail])      
     VALUES      
           (s.[ChainID]      
           ,s.[StoreID]      
   ,s.[ProductID]      
   ,s.[BrandID]      
   ,0      
   ,s.[Qty]      
   ,0      
   ,0      
   ,s.[Qty]      
   ,@MyID      
   ,getdate()      
   ,s.EffectiveDateTime      
   ,s.Cost      
   ,s.Retail);      
--**************************************************************      
update t set TransactionStatus = case when transactionstatus = 0 then 2       
when transactionstatus = 1 then 2       
         else 810 end --@loadstatus      
 ,LastUpdateUserID = @MyID      
 ,DateTimeLastUpdate = GETDATE()      
 from #tempStoreTransaction tmp      
inner join [dbo].[StoreTransactions] t      
on tmp.StoreTransactionID = t.StoreTransactionID      
      
      
      
--delivery records      
select distinct StoreTransactionID      
into #tempStoreTransaction3      
--select *      
from [dbo].[StoreTransactions]      
where TransactionStatus in (0, 1, 811)      
--where TransactionStatus in (1, 11)      
and TransactionTypeID in (9)      
and RuleCost is not null      
--and CostMisMatch = 0      
--and RetailMisMatch = 0      
--and TrueCost is not null      
and CAST(Saledatetime as date) >= '12/1/2011'      
and SupplierID in (40558, 40562, 40561, 40557, 41464, 41465, 40559, 41440)      
      
--**************************************************************      
MERGE INTO [dbo].[InventoryPerpetual] i      
      
USING (SELECT [ChainID]      
   ,[StoreID]      
      ,[ProductID]      
      ,[BrandID]      
      ,sum([Qty]) as Qty      
      ,max([RuleCost]) as Cost      
      ,max(isnull([RuleRetail], 0.00)) as Retail      
      ,max([SaleDateTime]) as EffectiveDateTime      
  FROM [dbo].[StoreTransactions] t      
  inner join #tempStoreTransaction3 tmp      
 on t.StoreTransactionID = tmp.StoreTransactionID      
 group by t.chainid, t.storeid, t.productid, t.brandid) S      
 on i.ChainID = s.ChainID      
 and i.StoreID = s.StoreID       
 and i.ProductID = s.ProductID      
 and i.BrandID = s.BrandID      
      
WHEN MATCHED THEN      
      
update set  Deliveries = Deliveries + S.Qty      
 ,CurrentOnHandQty = CurrentOnHandQty + s.Qty       
 ,LastUpdateUserID = @MyID      
 ,DateTimeLastUpdate = getdate()      
 ,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end      
      
WHEN NOT MATCHED       
      
THEN INSERT       
           ([ChainID]      
           ,[StoreID]      
           ,[ProductID]      
           ,[BrandID]      
           ,[OriginalQty]      
           ,[Deliveries]      
           ,[SBTSales]      
           ,[ShrinkRevision]      
           ,[CurrentOnHandQty]      
           ,[LastUpdateUserID]      
           ,[DateTimeLastUpdate]      
           ,[EffectiveDateTime]      
           ,[Cost]      
           ,[Retail])      
     VALUES      
           (s.[ChainID]      
           ,s.[StoreID]      
   ,s.[ProductID]      
   ,s.[BrandID]      
   ,0      
   ,s.[Qty]      
   ,0      
   ,0      
   ,s.[Qty]      
   ,@MyID      
   ,getdate()      
   ,s.EffectiveDateTime      
   ,s.Cost      
   ,s.Retail);      
--**************************************************************      
update t set TransactionStatus = case when transactionstatus = 0 then 2       
when transactionstatus = 1 then 2       
         else 810 end --@loadstatus      
 ,LastUpdateUserID = @MyID      
 ,DateTimeLastUpdate = GETDATE()      
 from #tempStoreTransaction3 tmp      
inner join [dbo].[StoreTransactions] t      
on tmp.StoreTransactionID = t.StoreTransactionID      
      
--waitfor delay '0:0:5'      
      
--exec DataTrue_Report..prCDCGetINVStoreTransactions      
      
--pickup records      
select distinct StoreTransactionID      
into #tempStoreTransaction2      
--select *      
from [dbo].[StoreTransactions]      
where TransactionStatus in (0, 1, 811)      
--where TransactionStatus in (1, 11)      
and TransactionTypeID in (8,13,14,21)      
and RuleCost is not null      
--and CostMisMatch = 0      
--and RetailMisMatch = 0      
--and TrueCost is not null      
and CAST(Saledatetime as date) >= '12/1/2011'      
--and SupplierID in (40561)      
and SupplierID in (40558, 40562, 40561, 40557, 41464, 41465, 40559, 41440)      
--**************************************************************      
MERGE INTO [dbo].[InventoryPerpetual] i      
      
USING (SELECT [ChainID]      
   ,[StoreID]      
      ,[ProductID]      
      ,[BrandID]      
      ,sum([Qty]) as Qty      
      ,max([RuleCost]) as Cost      
      ,max(isnull([RuleRetail], 0.00)) as Retail      
      ,max([SaleDateTime]) as EffectiveDateTime      
  FROM [dbo].[StoreTransactions] t      
  inner join #tempStoreTransaction2 tmp      
 on t.StoreTransactionID = tmp.StoreTransactionID      
 group by t.chainid, t.storeid, t.productid, t.brandid) S      
 on i.ChainID = s.ChainID      
 and i.StoreID = s.StoreID       
 and i.ProductID = s.ProductID      
 and i.BrandID = s.BrandID      
      
WHEN MATCHED THEN      
      
update set  Pickups = Pickups + S.Qty      
 ,CurrentOnHandQty = CurrentOnHandQty - s.Qty       
 ,LastUpdateUserID = @MyID      
 ,DateTimeLastUpdate = getdate()      
 ,EffectiveDateTime = case when s.EffectiveDateTime > i.EffectiveDateTime then s.EffectiveDateTime else i.EffectiveDateTime end      
       
WHEN NOT MATCHED       
      
THEN INSERT       
           ([ChainID]      
           ,[StoreID]      
           ,[ProductID]      
           ,[BrandID]      
           ,[OriginalQty]      
           ,[Pickups]      
           ,[SBTSales]      
           ,[ShrinkRevision]      
           ,[CurrentOnHandQty]      
           ,[LastUpdateUserID]      
           ,[DateTimeLastUpdate]      
           ,[EffectiveDateTime]      
           ,[Cost]               ,[Retail])      
     VALUES      
           (s.[ChainID]      
           ,s.[StoreID]      
   ,s.[ProductID]      
   ,s.[BrandID]      
   ,0      
   ,s.[Qty]      
   ,0      
   ,0      
   ,0 - s.[Qty]      
   ,@MyID      
   ,getdate()      
   ,s.EffectiveDateTime      
   ,s.Cost      
   ,s.Retail);      
--**************************************************************      
update t set TransactionStatus = case when transactionstatus = 0 then 2      
when transactionstatus = 1 then 2        
         else 810 end --@loadstatus      
 ,LastUpdateUserID = @MyID      
 ,DateTimeLastUpdate = GETDATE()      
 from #tempStoreTransaction2 tmp      
inner join [dbo].[StoreTransactions] t      
on tmp.StoreTransactionID = t.StoreTransactionID      
      
--waitfor delay '0:0:5'      
      
--exec DataTrue_Report..prCDCGetINVStoreTransactions      
      
      
     
 commit transaction      
   
  end try      
   
--if @@ERROR = 0 

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
        
  exec [msdb].[dbo].[sp_stop_job]       
   @job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'      
      
  exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped at [prApplySUPStoreTransactionsToInventory]'      
    ,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'      
    ,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'
      
    return   
end catch      

      
/*      
select * into import.dbo.inventoryperpetual_BeforeGopherSync_20120126 from inventoryperpetual      
      
select storeid, productid      
--select *      
from storetransactions      
where supplierid = 40558      
and transactiontypeid = 11      
      
select t.qty, p.originalqty, p.*      
--update p set p.originalqty = t.qty      
from inventoryperpetual p      
inner join      
(      
select storeid, productid, qty      
from storetransactions      
where supplierid = 40558      
and transactiontypeid = 11      
) t      
on p.storeid = t.storeid      
and p.productid = t.productid      
where t.qty <> p.originalqty      
      
*/
GO
