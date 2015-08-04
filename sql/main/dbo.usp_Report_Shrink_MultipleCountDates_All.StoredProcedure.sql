USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Shrink_MultipleCountDates_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Shrink_MultipleCountDates_All]
	-- exec usp_Report_Shrink_MultipleCountDates '40393','2','All','','-1','','530','1900-01-01','1900-01-01'
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @SQLQuery varchar(5000)
declare @attvalue int

select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 begin try
    Drop Table [#tmpShrinkSettlement]
end try
begin catch
end catch

        select MR.SupplierId, MR.SupplierName, MR.ChainName,MR.StoreNo,MR.supplieracctno,MR.StoreID, MR.ChainID,
				MR.Banner, MR.[LastInventoryCountDate],MR.[LastSettlementDate],MR.UPC , MR.SupplierUniqueProductID,
				MR.[BI Count], MR.[BI$], MR.[Net Deliveries], MR.[Net Deliveries$],MR.[Net POS], MR.[POS$],
				MR.[Expected EI], MR.[Expected EI$], MR.[LastCountQty], MR.[LastCount$], MR.[ShrinkUnits],
				MR.NetUnitCostLastCountDate, MR.[Shrink$], MR.[SharedShrinkUnits], MR.WeightedAvgCost
        into [#tmpShrinkSettlement]
        from [InventoryReport_New_FactTable_Active] as MR
        Left Join InventorySettlementRequests IR on IR.SupplierId=MR.SupplierId and IR.retailerId=MR.ChainID
        and IR.StoreID=MR.StoreID and MR.ProductID=IR.ProductID and IR.Settle ='Pending'
											 
        where IR.supplierId  is null
		
		union all
		
		select MR.SupplierId, MR.SupplierName, MR.ChainName,MR.StoreNo,MR.supplieracctno,MR.StoreID, MR.ChainID,
				MR.Banner, MR.[LastInventoryCountDate],MR.[LastSettlementDate],MR.UPC , MR.SupplierUniqueProductID,
				MR.[BI Count], MR.[BI$], MR.[Net Deliveries], MR.[Net Deliveries$],MR.[Net POS], MR.[POS$],
				MR.[Expected EI], MR.[Expected EI$], MR.[LastCountQty], MR.[LastCount$], MR.[ShrinkUnits],
				MR.NetUnitCostLastCountDate, MR.[Shrink$], MR.[SharedShrinkUnits], MR.WeightedAvgCost

        from [InventoryReport_New_FactTable_Active] as MR
        inner Join InventorySettlementRequests IR on IR.SupplierId=MR.SupplierId and IR.retailerId=MR.ChainID
        and IR.StoreID=MR.StoreID and MR.ProductID=IR.ProductID where MR.LastInventoryCountDate > 
									        (Select max(IR1.PhysicalInventoryDate) from InventorySettlementRequests IR1
											 where IR1.SupplierId=MR.SupplierId and IR1.retailerId=MR.ChainID
											 and IR1.StoreID=MR.StoreID and MR.ProductID=IR1.ProductID)
											 and IR.Settle='Pending'
			
        
        union All
	  
	    select IR.SupplierId, S.SupplierName, C.ChainName,ST.StoreIdentifier,IR.SupplierAcctNo,ST.StoreID, C.ChainID,
				St.Custom1, IR.[PhysicalInventoryDate],IR.[PriorInventoryCountDate],IR.UPC, IR.SupplierUniqueProductID,
				IR.[BI Count], IR.[BI$], IR.[Net Deliveries], IR.[Net Deliveries$],IR.[Net POS], IR.[POS$],
				(IR.[BI Count]+IR.[Net Deliveries]-IR.[Net POS]) as  [Expected EI], 
				(IR.BI$+IR.[Net Deliveries$]-IR.[POS$]) as [Expected EI$], IR.[LastCountQty], IR.[LastCount$], IR.[ShrinkUnits],
				IR.NetUnitCostLastCountDate, IR.[Shrink$], IR.[SharedShrinkUnits], IR.WeightedAvgCost
			
			from InventorySettlementRequests as IR 
			Inner Join Suppliers S on S.SupplierID=IR.supplierId
			Inner Join Chains C on C.ChainID=IR.retailerId
			Inner Join Stores ST on ST.StoreID=IR.StoreID
			
										 
        set @sqlQuery = 'Select MR.SupplierName as [Supplier Name], MR.ChainName as [Chain Name], MR.StoreNo as [Store Number],
							MR.Banner, 
							convert(varchar(10),cast(MR.[LastInventoryCountDate] as date),101) as [Last Count Date],
							convert(varchar(10),cast(MR.[LastSettlementDate] as date),101) as [Last Settlement Date], 
							sum(MR.[BI Count]) as [BI Units],
							''$''+ Convert(varchar(50), cast(sum(MR.[BI$]) as numeric(10,2))) as [BI Cost],
							sum(MR.[Net POS]) as [TTLPOS],
							''$''+ Convert(varchar(50), cast(sum(MR.[POS$]) as numeric(10,2))) as [TTLPOS$],
							sum(MR.[Net Deliveries]) as [TTLDelivered],
							''$''+ Convert(varchar(50), cast(sum(MR.[Net Deliveries$]) as numeric(10,2))) as [TTLDelivered$],
							sum(MR.[Expected EI]) as [Expected EI],
							''$''+ Convert(varchar(50), cast(sum(MR.[Expected EI$]) as numeric(10,2))) as [Expected EI$],
							sum(MR.[LastCountQty]) as [Last Count Units],
							''$''+ Convert(varchar(50), cast(sum(MR.[LastCount$]) as numeric(10,2))) as [Last Count$],
							sum(MR.[ShrinkUnits])as [Shrink Units Aggregated Count],
							''$''+ Convert(varchar(50), cast(sum(MR.[Shrink$]) as numeric(10,2))) as [Shrink$ WeightedAvg],
							''$''+ Convert(varchar(50), cast(sum(MR.[SharedShrinkUnits]*MR.WeightedAvgCost) as numeric(10,2))) 
							as [Shared Shrink$ (WeightedAvg)],
							case when sum(MR.[BI$] + MR.[Net Deliveries$]) >0 then
								cast((sum(cast(MR.[Shrink$] as numeric(10,2))))/ sum(MR.[BI$] + MR.[Net Deliveries$]) as numeric(10,2))
							else 0
								end  as [Shrink as % of (BI$+Delivery$)],

							case when sum(MR.[POS$]) >0 then
								cast((sum(cast(MR.[Shrink$] as numeric(10,2))))/ sum(MR.[POS$]) as numeric(10,2))
							else 0
								end  as [Shrink as % of POS$]

							From [#tmpShrinkSettlement] as MR 
							inner join SupplierBanners SB on SB.SupplierId = MR.SupplierID and SB.Status=''Active'' and SB.Banner=MR.banner
							inner join (select  i.StoreID,max(i.LastInventoryCountDate) as MaxDate,i.SupplierID, i.upc
											from InventoryReport_New_FactTable_Active i
											where i.LastInventoryCountDate <= case when ' + cast(@LastxDays as varchar) + ' >0 then dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) else ''' + @StartDate + ''' end
											group by i.StoreID,i.SupplierID, i.upc
										) t
										on t.UPC=MR.UPC and t.StoreID =MR.StoreID and t.MaxDate=MR.LastInventoryCountDate and t.SupplierID =MR.SupplierID '
        
        
		--if @attvalue =17
		--	set @sqlQuery  = @sqlQuery  + ' and MR.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		
		--else if @attvalue = 9
		--	set @sqlQuery  = @sqlQuery  + ' and MR.SupplierId  in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
			
		if(@SupplierId<>'-1') 
			set @sqlQuery  = @sqlQuery  + ' and MR.SupplierId in (' + @SupplierId  +')'
			
		if(@chainID  <>'-1') 
			set @sqlQuery   = @sqlQuery  +  ' and MR.ChainID in (' + @chainID +')'
		
		if(@Banner<>'All') 
			set @sqlQuery  = @sqlQuery + ' and MR.Banner like ''%' + @Banner + '%''' 
	  
		if(@StoreId <>'-1') 
			set @sqlQuery = @sqlQuery  +  ' and MR.StoreNo like ''%' + @StoreId + '%'''
	 	
	 	set @sqlQuery = @sqlQuery +  ' Group by MR.SupplierName, MR.ChainName, MR.StoreNo, MR.Banner, 
                                      MR.[LastInventoryCountDate], MR.[LastSettlementDate]' 

        set @sqlQuery = @sqlQuery +  ' order by MR.Banner asc, MR.StoreNo, MR.LastInventoryCountDate desc, MR.LastSettlementDate desc'
         
		exec (@sqlQuery)
	--print (@sqlQuery )
	
END
GO
