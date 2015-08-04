USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Sean_UpdateInventoryFactTable]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sean_UpdateInventoryFactTable]
	
	
as
Begin

--Clean the main table

truncate table [InventoryCount_MainReport_FactTable]


--insert the last Settlement Records data
Insert into [InventoryCount_MainReport_FactTable](SupplierID,StoreID,[BI Date],[BI Count],[BI $],UPC,ChainID,ChainName )

select SupplierID,StoreID,LastInventorySettelmentDate,LS_TTLUnits ,LS_TTLCost ,UPC  ,(select chainid from stores where StoreID=ft.StoreID ),(select chainname
from Chains where ChainID =(select chainid from stores where StoreID=ft.StoreID ))

from [InventoryCount_LastSettlementDate_FACT_Table] FT


--update Last inventory Count

update InventoryCount_MainReport_FactTable

set [Last Count Date] =a.lastdatecount, [Last Count$] = a.lastcountDollar, [Last Count]=a.lastcount

from
	(select LastInventoryCountDate as lastdatecount,
	LC_TTLCost  as lastcountDollar,
	LC_TTLUnits  as lastcount,
	StoreID as storeid,SupplierID as supplierid,upc as upc from [InventoryCount_LastCountDate_FACT_Table]) a

left join InventoryCount_MainReport_FactTable
	on InventoryCount_MainReport_FactTable.storeid = a.storeid
	and InventoryCount_MainReport_FactTable.supplierid = a.supplierid	
	and InventoryCount_MainReport_FactTable.upc = a.upc


--update Deliveries

update InventoryCount_MainReport_FactTable

set [Total Deliveries]=a.TTLDeliveries ,[Total Deliveries$]=a.TTLDeliveries$  

from	(select TTLDeliveries,[TTLDeliveries$] ,StoreID ,SupplierID ,upc from [InventoryCount_SinceLastSettlement_Deliveries]) a

inner join InventoryCount_MainReport_FactTable
	on InventoryCount_MainReport_FactTable.storeid = a.storeid
	and InventoryCount_MainReport_FactTable.supplierid = a.supplierid	
	and InventoryCount_MainReport_FactTable.upc = a.upc

--update POS

update InventoryCount_MainReport_FactTable

set [Total POS] =a.TTLPOS  ,[Total POS$] =a.TTLPOS$   

from	(select TTLPOS ,TTLPOS$  ,StoreID ,SupplierID ,upc from [InventoryCount_SinceLastSettlement_POS]) a

inner join InventoryCount_MainReport_FactTable
	on InventoryCount_MainReport_FactTable.storeid = a.storeid
	and InventoryCount_MainReport_FactTable.supplierid = a.supplierid	
	and InventoryCount_MainReport_FactTable.upc = a.upc
	
--update store number, banner

update InventoryCount_MainReport_FactTable

set SupplierName =a.SupplierName

from	(select SupplierName,SupplierID  from suppliers) a

inner join InventoryCount_MainReport_FactTable
	on InventoryCount_MainReport_FactTable.SupplierID  = a.SupplierID

--update store number, banner

update InventoryCount_MainReport_FactTable

set StoreNumber =a.StoreIdentifier, Banner=a.Custom1

from	(select StoreIdentifier ,Custom1,StoreID  from stores) a

inner join InventoryCount_MainReport_FactTable
	on InventoryCount_MainReport_FactTable.StoreID  = a.storeid

--update Null values to Zero , 

update InventoryCount_MainReport_FactTable
set [Total Deliveries]=ISNULL([Total Deliveries],0),[Total Deliveries$]=ISNULL([Total Deliveries$],0),[Total POS]=ISNULL([Total POS],0),[Total POS$] =ISNULL([Total POS$] ,0)




--update EI , 

update InventoryCount_MainReport_FactTable

set [Expected EI]=[BI Count]-[Total POS]+[Total Deliveries],[Expected EI$]=[BI $]-[Total POS$]+[Total Deliveries$]
	

--update EI  

update InventoryCount_MainReport_FactTable

set 	[Shrink Units] =[Expected EI]-[Last Count],[Shrink $]=[Expected EI$]-[Last Count$]


END
GO
