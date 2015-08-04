USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetails_InventorySettlement_SharedShrink_Create_Debug_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetails_InventorySettlement_SharedShrink_Create_Debug_PRESYNC_20150329]
as

/*
select * into import.dbo.inventorysettlementrequests_BeforeDetailCreate_20130225 from  InventorySettlementRequests

*/

update t set t.ShrinkUnits = t.SharedShrinkUnits, t.Shrink$ = SharedShrinkUnits * t.WeightedAvgCost
--select * --into zztemp_InventorySettlementRequests_Bashas_TwoStores_20150120
from  InventorySettlementRequests t 
where 1 = 1
--and t.Settle ='Y'
and t.SettlementFinalized =0 
and t.UPC = '999999999999'
and ShrinkUnits is null
and SharedShrinkUnits is not null
and supplierId not in (40559)
and StoreID in (62477,62549)

--Last Settlment Date by Store and product and Supplier drop table #tmpDate
select t.supplierid, t.storeid , t.productid, max(t.PhysicalInventoryDate  ) as LastSettlmentDate
into #tmpDate
--select t.supplierid, t.storeid , t.productid, max(t.PhysicalInventoryDate  ) as LastSettlmentDate
from  InventorySettlementRequests t 
where t.Settle ='Y'
and t.SettlementFinalized =0 
and t.ApprovingPersonID is not null
--and t.ShrinkUnits <> 0
and supplierId not in (40559)
and StoreID in (62477,62549)
group by t.supplierid, t.storeid, t.productid 


update r set InvoiceAmount = -333, SettlementFinalized = 1
--select *
from InventorySettlementRequests r
inner join #tmpDate t
on r.StoreID = t.StoreID
and r.ProductID = t.ProductID
and r.supplierId = t.supplierId
and r.PhysicalInventoryDate <> T.LastSettlmentDate
AND r.Settle ='Y'
and r.SettlementFinalized =0 
and r.ApprovingPersonID is not null
and r.supplierId not in (40559)
and r.StoreID in (62477,62549)
--and r.ShrinkUnits <> 0

select InventorySettlementRequestID
into #tempISR
--select *
--select distinct supplierid 
--update i set i.SettlementFinalized = -2
from InventorySettlementRequests i
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
and StoreID in (62477,62549)
and i.ShrinkUnits <> 0
--and i.SharedShrinkUnits is not null
and i.[WeightedAvgCost] is not null
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
*/

INSERT INTO [DataTrue_Main].[dbo].[InvoiceDetails]
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
           ,case when supplierid in (40562) then [ShrinkUnits] * [BaseCostLastCountDate] else SharedShrink$ end --[SharedShrinkUnits] * [WeightedAvgCost] end
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
           ,case when supplierid in (40562) then round([ShrinkUnits] * [BaseCostLastCountDate] * .5, 2) else SharedShrink$ end --[SharedShrinkUnits] * [WeightedAvgCost] end
  --select sum([BI Count]),sum([Net Deliveries]),sum([Net Pos]),sum([LastCountQty]),sum(SharedShrink$)
  --select sr.*
  FROM Stores s
  inner join [DataTrue_Main].[dbo].[InventorySettlementRequests] sr
  on s.StoreID = sr.StoreID
  inner join #tempISR t
  on sr.InventorySettlementRequestID = t.InventorySettlementRequestID
  where sr.supplierId not in (40559)
  and sr.SettlementFinalized = 0
  --and sr.StoreID in (62477)  
  --and sr.supplierId = 62596
  and sr.StoreID in (62477,62549)

if @@rowcount > 0
	begin

		exec dbo.prSendEmailNotification_PassEmailAddresses 'New Shrink Invoices Are Being Billed'
		,'New Shrink Invoices Are Being Billed'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;tatiana.alperovitch@icontroldsd.com'


	end
	
  update sr set sr.InvoiceAmount = CAST(invoicedetailid as money)
  ,sr.SettlementFinalized = 1, sr.SharedShrink$ = d.FinalInvoiceTotalCost
  FROM [DataTrue_Main].[dbo].[InventorySettlementRequests] sr
  inner join #tempISR t
  on sr.InventorySettlementRequestID = t.InventorySettlementRequestID
  inner join InvoiceDetailS d
  on t.InventorySettlementRequestID = d.InventorySettlementID
  where sr.supplierId not in (40559)
  and sr.StoreID in (62477,62549)
    and sr.supplierId = 62596
  
  If CAST(getdate() as DATE) = '11/8/2014'
	begin --select * from suppliers where suppliername like '%sch%' select * from suppliers where supplierid = 40562
	
		delete from InvoiceDetailS where supplierid = 40562 and InvoiceDetailTypeID = 11 and StoreID in (40497) and CAST(datetimecreated as DATE) = '11/8/2014'
		--delete from InvoiceDetailS where supplierid = 40561 and InvoiceDetailTypeID = 11 and StoreID in (40464,40474,40488,40508) and CAST(datetimecreated as DATE) = '10/16/2014'

	end
/*

select *
  FROM [DataTrue_Main].[dbo].[InventorySettlementRequests]
  where supplierid = 40557
  and settlementfinalized = 0
  and settle = 'Y'
  and shrinkunits is not null
  and shrinkunits <> 0
  order by weightedavgcost

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

select sum(totalcost)
from invoicedetails
where invoicedetailtypeid = 11
and cast(datetimecreated as date) = '11/30/2012'


select * into import.dbo.settlementSchmidt_20121213
--select sum(sharedshrink$)   --Schmidt 20121213 $28430.27
--update i set  i.SettlementFinalized = 1
--select distinct upc
--select distinct supplierid
from InventorySettlementRequests i
where i.Settle ='y' 
and i.SettlementFinalized =0 
and shrinkunits is not null
and shrinkunits <> 0
and weightedavgcost is null
*/
return
GO
