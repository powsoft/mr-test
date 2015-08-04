USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Sean_UpdateInventoryFactTable_NewVersion]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sean_UpdateInventoryFactTable_NewVersion]
	
	
as
Begin


--Clean, the populate the Last Settlment Fact Table
truncate table [DataTrue_Main].[dbo].[InventoryCount_LastSettlementDate_FACT_Table]

 

insert into [DataTrue_Main].[dbo].[InventoryCount_LastSettlementDate_FACT_Table]

           select * from InventoryCount_LastSettlementDate_DATA;
           


--Clean the main table

truncate table InventoryReport_New_FactTable


--Populate the main table

insert into InventoryReport_New_FactTable 
select * from [InventoryReport_Dates of Settlement and Counts] 

--update Deliveries

update InventoryReport_New_FactTable 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from dbo.InventoryReport_Deliveries ) a

inner join InventoryReport_New_FactTable
	on InventoryReport_New_FactTable.storeid = a.storeid
	and InventoryReport_New_FactTable.supplierid = a.supplierid	
	and InventoryReport_New_FactTable.ProductID  = a.productid
	and InventoryReport_New_FactTable.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable.LastSettlementDate  =a.LastSettlementDate 
	
--update deliveries for Settlement Dates= Null 
update InventoryReport_New_FactTable 

set [Net Deliveries] = a.NetDeliveries   ,[Net Deliveries$]=a.NetDeliveries$   

from	(select * from dbo.InventoryReport_Deliveries ) a

inner join InventoryReport_New_FactTable
	on InventoryReport_New_FactTable.storeid = a.storeid
	and InventoryReport_New_FactTable.supplierid = a.supplierid	
	and InventoryReport_New_FactTable.ProductID  = a.productid
	and InventoryReport_New_FactTable.LastInventoryCountDate =a.LastInventoryCountDate

where  (a.LastSettlementDate) is null

--update POS

update InventoryReport_New_FactTable

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$  

from	(select * from dbo.InventoryReport_POS ) a

inner join InventoryReport_New_FactTable
	on InventoryReport_New_FactTable.storeid = a.storeid
	and InventoryReport_New_FactTable.supplierid = a.supplierid	
	and InventoryReport_New_FactTable.ProductID  = a.productid
	and InventoryReport_New_FactTable.LastInventoryCountDate =a.LastInventoryCountDate
	and InventoryReport_New_FactTable.LastSettlementDate  =a.LastSettlementDate 

--update POS for Settlement Dates= Null 

update InventoryReport_New_FactTable

set [Net POS]   =a.NetPOS   ,POS$   =a.NetPOS$  

from	(select * from dbo.InventoryReport_POS ) a

inner join InventoryReport_New_FactTable
	on InventoryReport_New_FactTable.storeid = a.storeid
	and InventoryReport_New_FactTable.supplierid = a.supplierid	
	and InventoryReport_New_FactTable.ProductID  = a.productid
	and InventoryReport_New_FactTable.LastInventoryCountDate =a.LastInventoryCountDate	

where  (a.LastSettlementDate) is null

		
--update SupplierUniqueAccounttNumber

update InventoryReport_New_FactTable

set SupplierAcctNo =a.SupplierAccountNumber 

from	(select * from dbo.StoresUniqueValues ) a

inner join InventoryReport_New_FactTable
	on InventoryReport_New_FactTable.storeid = a.storeid
	and InventoryReport_New_FactTable.supplierid = a.supplierid	
	
--update SupplierUniqueProductNumber

update InventoryReport_New_FactTable

set SupplierUniqueProductID  =a.IdentifierValue

from	(select * from dbo.ProductIdentifiers   where ProductIdentifierTypeID=3) a

inner join InventoryReport_New_FactTable
	on InventoryReport_New_FactTable.ProductID = a.ProductID
	and InventoryReport_New_FactTable.supplierid = a.OwnerEntityId	



--update Null values to Zero , 

update InventoryReport_New_FactTable 
set [Net Deliveries] =ISNULL([Net Deliveries] ,0),[Net Deliveries$] =ISNULL([Net Deliveries$],0),[Net POS]=ISNULL([Net POS],0),POS$ =ISNULL(POS$  ,0)

--Next update added 4/19/2012 by charlie and Mandeep to manage Lewis lastsettlement date to 12/10/2011
update InventoryReport_New_FactTable 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/10/2011')
where (ChainID =40393 and SupplierID  = 41464)


	--do not update Bimbo (40557)  Last Settlment Date to 12/1/2011 becuase they have multiple initialization dates based on banners
update InventoryReport_New_FactTable 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'12/1/2011')
where (ChainID =40393 and SupplierID  <> 40557)  or (ChainID =40393 and SupplierID  = 40557 and Banner not like 'Farm Fresh Markets')

	--update Bimbo (40557)  Last Settlment Date to 1/2/2012 (for Farm Fresh) becuase they have multiple initialization dates based on banners
update InventoryReport_New_FactTable 
set [BI Count] =ISNULL([BI Count] ,0),BI$ =ISNULL(BI$,0), LastSettlementDate =isnull(LastSettlementDate,'1/2/2012')
where ChainID =40393 and SupplierID  = 40557 and Banner = 'Farm Fresh Markets'


--update EI , 

update InventoryReport_New_FactTable

set [Expected EI]=[BI Count]-[Net POS]+[Net Deliveries],[Expected EI$]=BI$-POS$+[Net Deliveries$]
	

--update EI  
update InventoryReport_New_FactTable

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=[Expected EI$]-LastCount$ 
where LastCountQty =0

update InventoryReport_New_FactTable

set 	ShrinkUnits =[Expected EI]-LastCountQty,Shrink$=(LastCount$/LastCountQty )*([Expected EI]-LastCountQty )
where LastCountQty <>0

--Final Clean Up
Delete from InventoryReport_New_FactTable
where LastSettlementDate  is null and LastCountQty =0 and [Net Deliveries] =0


--update Shrink Dollar based on Aggregated amounts from Invoice Details (added on 3/2/2012 to match shrink $ bettter with settlement details)
update InventoryReport_New_FactTable 
set Shrink$ =(SELECT SUM(TotalCost) FROM dbo.InvoiceDetails ID
                     where ID.SaleDate <= InventoryReport_New_FactTable.LastInventoryCountDate  
                     AND ID.StoreID = InventoryReport_New_FactTable.StoreID
                     and id.ProductID =InventoryReport_New_FactTable.ProductID 
                     AND ID.InvoiceDetailTypeID IN (3, 5, 6,9, 10)
                    -- AND ID.InventorySettlementId IS NULL
                     AND ID.SupplierID = InventoryReport_New_FactTable.SupplierID
                     AND Id.ChainId=InventoryReport_New_FactTable.ChainID)
                   
--Update UnitCost at LastCountDate	
		update f set f. NetUnitCostLastCountDate = s.NetCost, f.BaseCostLastCountDate=s.basecost 
		from InventoryReport_New_FactTable f
		inner join
		(
		select i.ProductID ,i.StoreID,i.LastInventoryCountDate  ,p3.UnitPrice-ISNULL(p8.unitprice,0) as NetCost, p3.UnitPrice as basecost
		from InventoryReport_New_FactTable I
		 inner join 		
			  ProductPrices p3 on p3.ProductID=i.ProductID  and p3.StoreID =i.StoreID and p3.SupplierID =i.SupplierID and p3.ProductPriceTypeID =3 
		 left join ProductPrices P8 on p3.ProductID=p8.ProductID  and p3.SupplierID =p8.SupplierID and p3.StoreID =p8.StoreID
					and p3.ActiveStartDate <=p8.ActiveStartDate and p8.ActiveLastDate <=p3.ActiveLastDate 	 and p8.ProductPriceTypeID =8 
					and i.LastInventoryCountDate between p8.ActiveStartDate  and p8.ActiveLastDate 
			 
		 where  i.LastInventoryCountDate between p3.ActiveStartDate  and p3.ActiveLastDate  ) s
		 on f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate

--update POS, Deliveries and BI to be calculated based on the most recent unit cost

--update f
--set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
--from InventoryReport_New_FactTable f
--inner join
--(select i.ProductID,i.StoreID,i.LastInventoryCountDate, i.[Net Deliveries]*i.NetUnitCostLastCountDate  as Deliveries$, i.[Expected EI]*i.NetUnitCostLastCountDate as Expected$,
--i.[BI Count]*i.NetUnitCostLastCountDate as BI$,
--i.[Net POS] *i.NetUnitCostLastCountDate  as POS$,
--i.ShrinkUnits *i.NetUnitCostLastCountDate as Shrink$,
--i.LastCountQty *i.NetUnitCostLastCountDate as LastCount$

-- from InventoryReport_New_FactTable  i ) s
 
-- on f.ProductID = s.ProductID
--		 and f.StoreID = s.StoreID
--		 and f.LastInventoryCountDate = s.LastInventoryCountDate

--update POS, Deliveries and BI to be calculated based on the most recent BASE unit cost
update f
set [Net Deliveries$] = s.Deliveries$, [Expected EI$]=s.Expected$ , [POS$]=s.POS$,[BI$]=s.BI$ ,[Shrink$]=s.Shrink$, [lastcount$]=s.lastcount$ 
from InventoryReport_New_FactTable f
inner join
(select i.ProductID,i.StoreID,i.LastInventoryCountDate, 
i.[Net Deliveries]*i.BaseCostLastCountDate  as Deliveries$, 
i.[Expected EI]*i.BaseCostLastCountDate as Expected$,
i.[BI Count]*i.BaseCostLastCountDate as BI$,
i.[Net POS] *i.BaseCostLastCountDate  as POS$,
i.ShrinkUnits *i.BaseCostLastCountDate as Shrink$,
i.LastCountQty *i.BaseCostLastCountDate as LastCount$

 from InventoryReport_New_FactTable  i ) s
 
 on f.ProductID = s.ProductID
		 and f.StoreID = s.StoreID
		 and f.LastInventoryCountDate = s.LastInventoryCountDate
		 
--revert all Shrink Invoice Type in Invoice Details to calculate total costs based on BASE cost only (ignor promo)
update i
set i.TotalCost=i.TotalQty *i.UnitCost
from invoicedetails i
inner join
(select * from invoicedetails

where

InvoiceDetailTypeID IN (3, 5, 6,9, 10)
and PromoAllowance is not null
) id
on id.InvoiceDetailID =i.InvoiceDetailID  and i.InvoiceDetailTypeID IN (3, 5, 6,9, 10)

END
GO
