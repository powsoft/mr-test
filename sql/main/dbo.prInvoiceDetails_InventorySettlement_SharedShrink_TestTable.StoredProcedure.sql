USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetails_InventorySettlement_SharedShrink_TestTable]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetails_InventorySettlement_SharedShrink_TestTable]
as

drop table import.dbo.InventorySettlementRequests_TestTable

select *
into import.dbo.InventorySettlementRequests_TestTable
from  InventorySettlementRequests 

update t set t.ShrinkUnits = t.SharedShrinkUnits, t.Shrink$ = SharedShrinkUnits * t.WeightedAvgCost
--select *
from  import.dbo.InventorySettlementRequests_TestTable t 
where 1 = 1
--and t.Settle ='Y'
and t.SettlementFinalized =0 
and t.UPC = '999999999999'
and ShrinkUnits is null
and SharedShrinkUnits is not null
and supplierId not in (40559)

--Last Settlment Date by Store and product and Supplier drop table #tmpDate
select t.supplierid, t.storeid , t.productid, max(t.PhysicalInventoryDate  ) as LastSettlmentDate
into #tmpDate
--select t.supplierid, t.storeid , t.productid, max(t.PhysicalInventoryDate  ) as LastSettlmentDate
from  import.dbo.InventorySettlementRequests_TestTable t 
where t.Settle ='Y'
and t.SettlementFinalized =0 
and t.ApprovingPersonID is not null
--and t.ShrinkUnits <> 0
and supplierId not in (40559)
group by t.supplierid, t.storeid, t.productid 


update r set InvoiceAmount = -333, SettlementFinalized = 1
--select *
from import.dbo.InventorySettlementRequests_TestTable r
inner join #tmpDate t
on r.StoreID = t.StoreID
and r.ProductID = t.ProductID
and r.supplierId = t.supplierId
and r.PhysicalInventoryDate <> T.LastSettlmentDate
AND r.Settle ='Y'
and r.SettlementFinalized =0 
and r.ApprovingPersonID is not null
and r.supplierId not in (40559)
--and r.ShrinkUnits <> 0

select InventorySettlementRequestID
into #tempISR
--select *
--select distinct supplierid 
--update i set i.SettlementFinalized = -2
from import.dbo.InventorySettlementRequests_TestTable i
where i.Settle ='y' 
--and supplierId = 40562 and i.SettlementFinalized = 1 and i.SharedShrinkUnits is not null
--and supplierId = 40562
and i.SettlementFinalized =0 
and i.ShrinkUnits <> 0
--and cast(i.ApprovedDate as date) = '9/21/2012'
--order by i.BaseCostLastCountDate
and i.BaseCostLastCountDate is not null
and i.BaseCostLastCountDate <> 0
and i.ApprovingPersonID is not null
and i.InvoiceAmount <> -333
and i.supplierId not in (40559)
--and i.SharedShrinkUnits is not null
--and i.[WeightedAvgCost] is not null
--and i.SharedShrinkUnits <> 0
--order by i.upc
order by i.ShrinkUnits




/*
select * from #tempISR
select * 
from InventorySettlementRequests i 
where i.Settle ='y' 
and i.SettlementFinalized =0 
and SharedShrinkUnits is not null
--select top 1 * into truncate table import.dbo.InvoiceDetails_TestTable from InvoiceDetails
*/

truncate table import.dbo.InvoiceDetails_TestTable

INSERT INTO import.dbo.InvoiceDetails_TestTable
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[UnitCost]
           ,[UnitRetail]
           ,[TotalCost]
           ,[TotalRetail]
           ,[SaleDate]
           ,[LastUpdateUserID]
           ,[BatchID]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[ProductIdentifier]
           ,[RawProductIdentifier]
           ,[InventorySettlementID]
           ,[Banner]
           ,[SBTNumber]
           ,[PONO]
           ,OriginalShrinkTotalQty
           ,[FinalInvoiceTotalCost])       
	SELECT [RetailerID]
           ,sr.[StoreID]
           ,[ProductID]
           ,0 --[BrandID]
           ,[SupplierID]
           ,11 --[InvoiceDetailTypeID]
           ,case when supplierid in (40562) then [ShrinkUnits] else [SharedShrinkUnits] end --[SharedShrinkUnits]
           ,case when supplierid in (40562) then [BaseCostLastCountDate] else [WeightedAvgCost] end
           ,0 --UnitRetail
           ,case when supplierid in (40562) then [ShrinkUnits] * [BaseCostLastCountDate] else [SharedShrinkUnits] * [WeightedAvgCost] end
--*************************           
           ,0 --[TotalRetail]
           ,[PhysicalInventoryDate] --[SaleDate]
           ,0 --[LastUpdateUserID]
           ,'' --[BatchID]
           ,'SV'
			,[StoreNumber]
           ,UPC --[ProductIdentifier]
           ,UPC --[RawProductIdentifier]
           ,sr.[InventorySettlementRequestID]
           ,s.Custom3
           ,s.Custom2
           ,''
           ,ISNULL(ShrinkUnits, 1)
           ,case when supplierid in (40562) then [ShrinkUnits] * [BaseCostLastCountDate] * .5 else [SharedShrinkUnits] * [WeightedAvgCost] end
  FROM Stores s
  inner join import.dbo.InventorySettlementRequests_TestTable sr
  on s.StoreID = sr.StoreID
  inner join #tempISR t
  on sr.InventorySettlementRequestID = t.InventorySettlementRequestID
  where sr.supplierId not in (40559)


  update sr set sr.InvoiceAmount = CAST(invoicedetailid as money)
  ,sr.SettlementFinalized = 1, sr.SharedShrink$ = d.FinalInvoiceTotalCost
  FROM import.dbo.InventorySettlementRequests_TestTable sr
  inner join #tempISR t
  on sr.InventorySettlementRequestID = t.InventorySettlementRequestID
  inner join import.dbo.InvoiceDetails_TestTable d
  on t.InventorySettlementRequestID = d.InventorySettlementID
  where sr.supplierId not in (40559)
/*

select *
from import.dbo.InvoiceDetails_TestTable

select sum(totalCost)
from import.dbo.InvoiceDetails_TestTable





  update sr set sr.SettlementFinalized = 1
  FROM [DataTrue_Main].[dbo].[InventorySettlementRequests] sr
  inner join #tempISR t
  on sr.InventorySettlementRequestID = t.InventorySettlementRequestID
  
  select * into import.dbo.InventorySettlementRequests_20120515 from InventorySettlementRequests

select * from InventorySettlementRequests where invoiceamount <> 0

select * from Invoicedetails where invoicedetailtypeid = 11 and supplierid = 40562 order by datetimecreated desc

--select *
--update r set r.InvoiceAmount = 0, SettlementFinalized = 0
from InventorySettlementRequests r
where 1 = 1
and InvoiceAmount = -333
and supplierid = 41464
and ApprovedDate = '2012-11-06 00:00:00.000'
*/
return
GO
