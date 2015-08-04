USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SharedShrinkCalculationAll]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SharedShrinkCalculationAll]
as 
begin 

	begin try
        Drop Table #tmpSharedShrink
    end try
    begin catch
    end catch
      
    delete from InventorySettlementRequests where ProductID = 27992 and [SettlementFinalized] = 0
    
    --Method 1: Calculate Shared Shrink Units for Suppliers with single layer distribution.
	Update I 
	set I.SharedShrinkUnits = (round((I.ShrinkUnits * S.RetailerShrinkRatio),2)), 
		I.SharedShrink$ = (round((I.Shrink$ * S.RetailerShrinkRatio),2))
	from InventorySettlementRequests I
	inner join SharedShrinkValues S on S.SupplierID=I.supplierId and S.ChainID=I.retailerId
	where SettlementFinalized =0 and ProductID <>27992 and S.CalculationMethod='PartialUnits'

	--Method 2: Calculate Shared Shrink values for agreements with Multiple Layers
			
	declare @SupplierId varchar(10), @ChainId varchar(10), @Banner varchar(50),  @GroupOn varchar(50),  @RetailerShrinkRatio as numeric(10,3), 
		 @FromShrinkUnitsDIVPOSUnits as numeric(10,3), @ToShrinkUnitsDIVPOSUnits as numeric(10,3)

	Select IR.InventorySettlementRequestID, IR.SupplierId, IR.retailerId as ChainID, ST.Custom1 as Banner, IR.StoreID, IR.ProductID, IR.ShrinkUnits, IR.WeightedAvgCost, IR.Shrink$, IR.POS$, 
				cast('0.00' as numeric(10,2)) as TotalSharedShrink
				into #tmpSharedShrink
				from InventorySettlementRequests IR
				inner join Stores ST on ST.StoreID = IR.StoreID
				where SettlementFinalized =0 
				and IR.ProductID <>27992
				and IR.supplierId<>40562
--Getting the Records from SharedShrinkValues Table
	DECLARE cursor_1 CURSOR FOR 
		
		Select  SSV.SupplierID, SSV.ChainID, 
				case when (SSV.ShrinkPercentRangeAggregationMethod is Null) then 'Chain' else 'Banner' end as GroupOn , 
				SSV.ShrinkPercentRangeAggregationMethod as Banner,
				(SSV.RetailerShrinkRatio * 100) as RetailerShrinkRatio, 
				(SSV.FromShrinkUnitsDIVPOSUnits * 100) as FromShrinkUnitsDIVPOSUnits, 
				(SSV.ToShrinkUnitsDIVPOSUnits * 100) as ToShrinkUnitsDIVPOSUnits
		from SharedShrinkValues SSV
		inner join InventorySettlementRequests as IR1 on SSV.SupplierID=IR1.supplierId and SSV.ChainID=IR1.retailerId 
				and SSV.ActiveStartDate<=GETDATE() and SSV.ActiveLastDate>=GETDATE()
		inner join Stores ST on ST.StoreID = IR1.StoreID and (SSV.ShrinkPercentRangeAggregationMethod=ST.Custom1 or SSV.ShrinkPercentRangeAggregationMethod is null)
		where IR1.SettlementFinalized =0  and IR1.ProductID <>27992 and IR1.supplierId<>40562 and SSV.CalculationMethod='FullUnits'
		group by SSV.SupplierID, SSV.ChainID, SSV.ShrinkPercentRangeAggregationMethod,SSV.ShrinkPercentRangeAggregationMethod,
		SSV.RetailerShrinkRatio, SSV.FromShrinkUnitsDIVPOSUnits, SSV.ToShrinkUnitsDIVPOSUnits
		order by SSV.SupplierID, SSV.ChainID, SSV.ShrinkPercentRangeAggregationMethod, SSV.FromShrinkUnitsDIVPOSUnits
		
	OPEN cursor_1;
	
	FETCH NEXT FROM cursor_1 INTO @SupplierId, @ChainId, @GroupOn, @Banner, @RetailerShrinkRatio, @FromShrinkUnitsDIVPOSUnits, @ToShrinkUnitsDIVPOSUnits
	
	declare @LayerCount int
	set @LayerCount=1;
	
	while @@FETCH_STATUS = 0
	begin
		print (@GroupOn);
		declare @TotalShrinkPer numeric(10,3)
		declare @ThresholdProp numeric(10,3)
		
		if( @GroupOn='Banner')
			begin
				select @TotalShrinkPer = sum(Shrink$)*100/SUM(POS$) 
				from InventorySettlementRequests as IR1
				inner join Stores ST on ST.StoreID=IR1.StoreID
				where IR1.supplierId=@SupplierId and ST.Custom1=@Banner and SettlementFinalized =0  
				and IR1.ProductID <>27992 and IR1.supplierId<>40562
				group by ST.Custom1
				having isnull(SUM(POS$),0)>0
				
				if(@TotalShrinkPer>=@ToShrinkUnitsDIVPOSUnits)
					set @ThresholdProp =  ((@ToShrinkUnitsDIVPOSUnits - @FromShrinkUnitsDIVPOSUnits) *100 / @TotalShrinkPer)
				else if(@TotalShrinkPer>0)
					set @ThresholdProp =  ((@TotalShrinkPer - @FromShrinkUnitsDIVPOSUnits) *100 / @TotalShrinkPer)
					
				if (@RetailerShrinkRatio*@ThresholdProp>0)
					Begin
						Update #tmpSharedShrink set TotalSharedShrink=TotalSharedShrink + (@RetailerShrinkRatio*@ThresholdProp*Shrink$/10000) 
						where SupplierId=@SupplierId and Banner=@Banner
					end
			end
		else
			begin

				select @TotalShrinkPer = sum(Shrink$)*100/SUM(POS$) 
				from InventorySettlementRequests as IR1
				where IR1.supplierId=@SupplierId and IR1.retailerId=@ChainId and SettlementFinalized =0 
				and IR1.ProductID <>27992 and IR1.supplierId<>40562
				group by IR1.retailerId
				having isnull(SUM(POS$),0)>0
				
				if(@TotalShrinkPer>=@ToShrinkUnitsDIVPOSUnits)
					set @ThresholdProp =  ((@ToShrinkUnitsDIVPOSUnits - @FromShrinkUnitsDIVPOSUnits) *100 / @TotalShrinkPer)
				else if(@TotalShrinkPer>0)
					set @ThresholdProp =  ((@TotalShrinkPer - @FromShrinkUnitsDIVPOSUnits) *100 / @TotalShrinkPer)
				
				if (@RetailerShrinkRatio*@ThresholdProp>0)
					Begin
						Update #tmpSharedShrink set TotalSharedShrink=TotalSharedShrink + (@RetailerShrinkRatio*@ThresholdProp*Shrink$/10000) 
						where SupplierId=@SupplierId and ChainID=@ChainId 
					end
			end
			
			set @LayerCount = @LayerCount+ 1;
			
		FETCH NEXT FROM cursor_1 INTO @SupplierId, @ChainId, @GroupOn, @Banner, @RetailerShrinkRatio, @FromShrinkUnitsDIVPOSUnits, @ToShrinkUnitsDIVPOSUnits
	end
	CLOSE cursor_1;
	DEALLOCATE cursor_1;
	
	
	Update s set s.SharedShrinkUnits = (round(((t.TotalSharedShrink)/t.WeightedAvgCost),4)), s.SharedShrink$=(round(((t.TotalSharedShrink)),4))
								
	from InventorySettlementRequests s
	inner join 	#tmpSharedShrink t
	on s.InventorySettlementRequestID = t.InventorySettlementRequestID	
	where t.WeightedAvgCost>0 
	
	--Added following block to round the units to integer value and amount to 2 decimal places for Lewis( By Vishal on 5/21 per Gilad's request)
	Update s set s.SharedShrinkUnits = (round(((t.TotalSharedShrink)/t.WeightedAvgCost),0)), s.SharedShrink$=(round(((t.TotalSharedShrink)),2))
	from InventorySettlementRequests s
	inner join 	#tmpSharedShrink t
	on s.InventorySettlementRequestID = t.InventorySettlementRequestID	
	where t.WeightedAvgCost>0 and S.SupplierId=41464 and s.Banner='Shop N Save Warehouse Foods Inc'
	
	--Commented on Nov 20, 2012 after changing the round to 4 decimal places instead of rounding to 0 in the update above.
	-- Inserting a rounding adjustment entry
	--INSERT INTO InventorySettlementRequests  
	--		([StoreNumber], [StoreID], [PhysicalInventoryDate], [Settle]
 --          ,[RequestDate],[ApprovingPersonID],[ApprovedDate]
 --          ,[supplierId], [retailerId], [UPC], [ProductID]
 --          ,[SettlementFinalized]
 --          ,[NetUnitCostLastCountDate]
 --          ,[BaseCostLastCountDate]
 --          ,[WeightedAvgCost]
 --          ,[SharedShrinkUnits]
 --          ,[SupplierAcctNo], [InvoiceAmount], [UnsettledShrink],[RequestingPersonID], [PriorInventoryCountDate]
 --          ) 
	--select I.StoreNumber, t.Storeid, MAX(I.PhysicalInventoryDate) as [Adjustment Date], max(settle),
	--max(I.RequestDate), MAX(I.ApprovingPersonID), MAX(I.ApprovedDate), i.supplierId, i.retailerId, '999999999999', 27992, 0, 
	--abs(sum(t.TotalSharedShrink)-sum((round(((t.TotalSharedShrink)/t.WeightedAvgCost),0)) * t.WeightedAvgCost)),
	--abs(sum(t.TotalSharedShrink)-sum((round(((t.TotalSharedShrink)/t.WeightedAvgCost),0)) * t.WeightedAvgCost)),
	--abs(sum(t.TotalSharedShrink)-sum((round(((t.TotalSharedShrink)/t.WeightedAvgCost),0)) * t.WeightedAvgCost)), 
	--case when (sum(t.TotalSharedShrink)-sum((round(((t.TotalSharedShrink)/t.WeightedAvgCost),0)) * t.WeightedAvgCost))< 0 then -1 
	--	else 1 end,
	--I.SupplierAcctNo,0,0,0, Max(I.PriorInventoryCountDate)
	--from #tmpSharedShrink t
	--inner join InventorySettlementRequests I on I.InventorySettlementRequestID=t.InventorySettlementRequestID
	--where t.WeightedAvgCost>0
	--group by I.StoreNumber, t.StoreID, i.supplierId, i.retailerId, I.SupplierAcctNo


End
GO
