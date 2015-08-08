USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_tmpShrinkSettlement_SubsReports]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_Generate_tmpShrinkSettlement_SubsReports]
as
begin

truncate  Table [tmpShrinkSettlement_SubsReports]
 
insert into  [tmpShrinkSettlement_SubsReports]
        select MR.SupplierId, MR.SupplierName, MR.ChainName,MR.StoreNo,MR.supplieracctno,MR.StoreID, MR.ChainID,
				MR.Banner, MR.[LastInventoryCountDate],MR.[LastSettlementDate],MR.UPC , MR.SupplierUniqueProductID,
				MR.[BI Count], MR.[BI$], MR.[Net Deliveries], MR.[Net Deliveries$],MR.[Net POS], MR.[POS$],
				MR.[Expected EI], MR.[Expected EI$], MR.[LastCountQty], MR.[LastCount$], MR.[ShrinkUnits],
				MR.NetUnitCostLastCountDate, MR.[Shrink$], MR.[SharedShrinkUnits], MR.WeightedAvgCost
        
        from [InventoryReport_New_FactTable_Active] as MR  with (nolock)  
        Left Join InventorySettlementRequests IR on IR.SupplierId=MR.SupplierId and IR.retailerId=MR.ChainID
        
        and IR.StoreID=MR.StoreID and MR.ProductID=IR.ProductID and IR.Settle ='Pending'
											 
        where IR.supplierId  is null and MR.[BI Count] IS Not NULL
		
		union all
		
		select MR.SupplierId, MR.SupplierName, MR.ChainName,MR.StoreNo,MR.supplieracctno,MR.StoreID, MR.ChainID,
				MR.Banner, MR.[LastInventoryCountDate],MR.[LastSettlementDate],MR.UPC , MR.SupplierUniqueProductID,
				MR.[BI Count], MR.[BI$], MR.[Net Deliveries], MR.[Net Deliveries$],MR.[Net POS], MR.[POS$],
				MR.[Expected EI], MR.[Expected EI$], MR.[LastCountQty], MR.[LastCount$], MR.[ShrinkUnits],
				MR.NetUnitCostLastCountDate, MR.[Shrink$], MR.[SharedShrinkUnits], MR.WeightedAvgCost

        from [InventoryReport_New_FactTable_Active] as MR with (nolock)
        inner Join InventorySettlementRequests IR on IR.SupplierId=MR.SupplierId and IR.retailerId=MR.ChainID
        and IR.StoreID=MR.StoreID and MR.ProductID=IR.ProductID 
        where MR.LastInventoryCountDate > 
									        (Select max(IR1.PhysicalInventoryDate) from InventorySettlementRequests IR1
											 where IR1.SupplierId=MR.SupplierId and IR1.retailerId=MR.ChainID
											 and IR1.StoreID=MR.StoreID and MR.ProductID=IR1.ProductID)
											 and IR.Settle='Pending' 
		and MR.[BI Count] IS Not NULL
											 
			
        
        union All
	  
	    select IR.SupplierId, S.SupplierName, C.ChainName,ST.StoreIdentifier,IR.SupplierAcctNo,ST.StoreID, C.ChainID,
				St.Custom1, IR.[PhysicalInventoryDate],IR.[PriorInventoryCountDate],IR.UPC, IR.SupplierUniqueProductID,
				IR.[BI Count], IR.[BI$], IR.[Net Deliveries], IR.[Net Deliveries$],IR.[Net POS], IR.[POS$],
				(IR.[BI Count]+IR.[Net Deliveries]-IR.[Net POS]) as  [Expected EI], 
				(IR.BI$+IR.[Net Deliveries$]-IR.[POS$]) as [Expected EI$], IR.[LastCountQty], IR.[LastCount$], IR.[ShrinkUnits],
				IR.NetUnitCostLastCountDate, IR.[Shrink$], IR.[SharedShrinkUnits], IR.WeightedAvgCost
			
			from InventorySettlementRequests as IR  with (nolock)
			Inner Join Suppliers S on S.SupplierID=IR.supplierId
			Inner Join  Chains C on C.ChainID=IR.retailerId
			Inner Join Stores ST on ST.StoreID=IR.StoreID
			Where IR.[BI Count] IS Not NULL
	
END
GO
