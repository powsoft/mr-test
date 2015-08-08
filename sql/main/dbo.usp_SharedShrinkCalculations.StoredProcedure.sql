USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SharedShrinkCalculations]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[usp_SharedShrinkCalculations_temp] 40561,40393
CREATE Procedure [dbo].[usp_SharedShrinkCalculations]
	@ForSupplierId varchar(10), 
	@ForChainId varchar(10)
as 
begin 
	begin try
        Drop Table #tmpSharedShrinkCal
    end try
    begin catch
    end catch
      
    delete from InventorySettlementRequests where ProductID = 27992 and [SettlementFinalized] = 0
    
    --Method 1: Calculate Shared Shrink Units for Suppliers with single layer distribution.
	Update I 	
	set I.SharedShrinkUnits = (round((I.ShrinkUnits * S.RetailerShrinkRatio),2)), 
		I.SharedShrink$ = (round((I.Shrink$ * S.RetailerShrinkRatio),2))
	from InventorySettlementRequests I
	inner join SharedShrinkTerms S on S.SupplierID=I.supplierId and S.ChainID=I.retailerId
	where I.SupplierId like case when @ForSupplierId='-1' then '%' else @ForSupplierId end
	and  I.retailerId like case when @ForChainId='-1' then '%' else @ForChainId end
	 and SettlementFinalized =0 and ProductID <>27992 and S.CalculationMethod='PartialUnits'
	 and getdate() between S.ActiveStartDate and S.ActiveLastDate

	--Method 2: Calculate Shared Shrink values for agreements with Multiple Layers
			
	declare @SupplierId varchar(10), @ChainId varchar(10), @Banner varchar(50), @ForStoreId varchar(50), @GroupOn varchar(50),  @RetailerShrinkRatio as numeric(10,3), 
		 @FromShrinkUnitsDIVPOSUnits as numeric(10,3), @ToShrinkUnitsDIVPOSUnits as numeric(10,3),@ShrinkMethod nvarchar(50)

	Select IR.InventorySettlementRequestID, IR.SupplierId, IR.retailerId as ChainID, ST.Custom1 as Banner, IR.StoreID, IR.ProductID, IR.[Net Deliveries$], IR.ShrinkUnits, IR.WeightedAvgCost, IR.Shrink$, IR.POS$, 
				IR.PhysicalInventoryDate, cast('0.00' as numeric(10,2)) as TotalSharedShrink
				into #tmpSharedShrinkCal
				from InventorySettlementRequests IR with(NOLOCK)
				inner join Stores ST with(NOLOCK) on ST.StoreID = IR.StoreID
				where SettlementFinalized =0 and IR.SupplierId like case when @ForSupplierId='-1' then '%' else @ForSupplierId end 
				and IR.retailerId like case when @ForChainId='-1' then '%' else @ForChainId end 
				and IR.ProductID <>27992
				and IR.supplierId<>40562
		
--Getting the Records from SharedShrinkTerms Table
	DECLARE cursor_1 CURSOR FOR 
		
		Select  SSV.SupplierID, SSV.ChainID, 
				SSV.ShrinkPercentRangeAggregationMethod as GroupOn , 
				case when SSV.ShrinkPercentRangeAggregationMethod='Banner' then SSV.ShrinkPercentRangeAggregationValue else NULL end as ForBanner,
				case when SSV.ShrinkPercentRangeAggregationMethod='Store' then SSV.ShrinkPercentRangeAggregationValue else NULL end as ForStoreId,
				(SSV.RetailerShrinkRatio * 100) as RetailerShrinkRatio, 
				(SSV.FromShrinkUnitsDIVPOSUnits * 100) as FromShrinkUnitsDIVPOSUnits, 
				(SSV.ToShrinkUnitsDIVPOSUnits * 100) as ToShrinkUnitsDIVPOSUnits,
				SSV.ShrinkMethod
		
		from SharedShrinkTerms SSV  with(NOLOCK)
		where SSV.CalculationMethod='FullUnits' and SSV.ActiveStartDate<=GETDATE() and SSV.ActiveLastDate>=GETDATE()
--			and SSV.ShrinkPercentRangeAggregationValue=40975
			and SSV.ShrinkPercentRangeAggregationValue in (case when SSV.ShrinkPercentRangeAggregationMethod='Banner' 
														then (select distinct Custom1 from Stores S where S.ChainId=SSV.ChainID and S.Custom1=SSV.ShrinkPercentRangeAggregationValue)
												    when SSV.ShrinkPercentRangeAggregationMethod='Store' 
														then (select distinct S.StoreId from Stores S  with(NOLOCK)
																inner join InventorySettlementRequests R  with(NOLOCK) on R.StoreID=S.StoreID and R.retailerId=S.ChainID and R.supplierId=SSV.SupplierID
																where S.ChainId=SSV.ChainID and S.StoreID = SSV.ShrinkPercentRangeAggregationValue
																and R.SettlementFinalized =0  and R.ProductID <>27992 and R.supplierId<>40562) 
												end )
		and SSV.SupplierId like case when @ForSupplierId='-1' then '%' else @ForSupplierId end
		and SSV.ChainID like case when @ForChainId='-1' then '%' else @ForChainId end
		and SSV.RetailerShrinkRatio >0
		group by SSV.SupplierID, SSV.ChainID, SSV.ShrinkPercentRangeAggregationMethod,SSV.ShrinkPercentRangeAggregationMethod,SSV.ShrinkPercentRangeAggregationValue,
		SSV.RetailerShrinkRatio, SSV.FromShrinkUnitsDIVPOSUnits, SSV.ToShrinkUnitsDIVPOSUnits,SSV.ShrinkMethod
		order by SSV.SupplierID, SSV.ChainID, SSV.ShrinkPercentRangeAggregationMethod, SSV.ShrinkPercentRangeAggregationValue, SSV.FromShrinkUnitsDIVPOSUnits
		
	OPEN cursor_1;
	
	FETCH NEXT FROM cursor_1 INTO @SupplierId, @ChainId, @GroupOn, @Banner, @ForStoreId, @RetailerShrinkRatio, @FromShrinkUnitsDIVPOSUnits, @ToShrinkUnitsDIVPOSUnits,@ShrinkMethod
	
	declare @LayerCount int
	set @LayerCount=1;
	
	while @@FETCH_STATUS = 0
	begin
		declare @TotalShrinkPer numeric(10,3)
		declare @ThresholdProp numeric(10,3)
		declare @PhysicalInventoryDate datetime
		
			DECLARE cursor_2 CURSOR FOR 
			Select distinct PhysicalInventoryDate from #tmpSharedShrinkCal
			OPEN cursor_2;
			
			FETCH NEXT FROM cursor_2 INTO @PhysicalInventoryDate
			while @@FETCH_STATUS = 0
			begin
			
				if( @GroupOn='Store')
					begin
						select @TotalShrinkPer = --sum(Shrink$)*100/SUM(POS$) 
						sum(Shrink$)*100/SUM(case when @ShrinkMethod='POS' then POS$ else IsNull(BI$,0)+ISNULL([Net Deliveries$],0) end)
						from InventorySettlementRequests as IR1  with(NOLOCK)
						inner join Stores ST with(NOLOCK) on ST.StoreID=IR1.StoreID
						where IR1.supplierId=@SupplierId and ST.StoreId= @ForStoreId and SettlementFinalized =0  
						and IR1.PhysicalInventoryDate=@PhysicalInventoryDate and IR1.retailerId=@ChainId
						--group by ST.Custom1, ST.StoreId
						having isnull(sum(Shrink$),0)<>0 and isnull(SUM(case when @ShrinkMethod='POS' then POS$ else IsNull(BI$,0)+ISNULL([Net Deliveries$],0) end),0)<>0
						
						if(abs(@TotalShrinkPer)>=@ToShrinkUnitsDIVPOSUnits)
							set @ThresholdProp =  ((@ToShrinkUnitsDIVPOSUnits - @FromShrinkUnitsDIVPOSUnits) *100 / abs(@TotalShrinkPer))
						else if(abs(@TotalShrinkPer)>0)
							set @ThresholdProp =  ((abs(@TotalShrinkPer) - @FromShrinkUnitsDIVPOSUnits) *100 / abs(@TotalShrinkPer))

						if (@RetailerShrinkRatio*abs(@ThresholdProp)>0)
							Begin
								
								Update #tmpSharedShrinkCal set TotalSharedShrink=TotalSharedShrink + (@RetailerShrinkRatio*@ThresholdProp*Shrink$/10000) 
								where SupplierId=@SupplierId and StoreId=@ForStoreId and PhysicalInventoryDate=@PhysicalInventoryDate and ChainID=@ChainId
							end
					end
				else if( @GroupOn='Banner')
					begin
						select @TotalShrinkPer =-- sum(Shrink$)*100/SUM(POS$) 
						sum(Shrink$)*100/SUM(case when @ShrinkMethod='POS' then POS$ else IsNull(BI$,0)+ISNULL([Net Deliveries$],0) end)
						from InventorySettlementRequests as IR1 with(NOLOCK)
						inner join Stores ST with(NOLOCK) on ST.StoreID=IR1.StoreID
						where IR1.supplierId=@SupplierId and ST.Custom1=@Banner and SettlementFinalized =0  
						and IR1.PhysicalInventoryDate=@PhysicalInventoryDate and IR1.retailerId=@ChainId
						--group by ST.Custom1
						having isnull(sum(Shrink$)*100/SUM(case when @ShrinkMethod='POS' then POS$ else IsNull(BI$,0)+ISNULL([Net Deliveries$],0) end),0)<>0
						
						if(abs(@TotalShrinkPer)>=@ToShrinkUnitsDIVPOSUnits)
							set @ThresholdProp =  ((@ToShrinkUnitsDIVPOSUnits - @FromShrinkUnitsDIVPOSUnits) *100 / abs(@TotalShrinkPer))
						else if(abs(@TotalShrinkPer)>0)
							set @ThresholdProp =  ((abs(@TotalShrinkPer) - @FromShrinkUnitsDIVPOSUnits) *100 / abs(@TotalShrinkPer))
							
						if (@RetailerShrinkRatio*abs(@ThresholdProp)>0)
							Begin
								Update #tmpSharedShrinkCal set TotalSharedShrink=TotalSharedShrink + (@RetailerShrinkRatio*@ThresholdProp*Shrink$/10000) 
								where SupplierId=@SupplierId and Banner=@Banner and PhysicalInventoryDate=@PhysicalInventoryDate and ChainID=@ChainId
							end
					end			
				else
					begin

						select @TotalShrinkPer = sum(Shrink$)*100/SUM(case when @ShrinkMethod='POS' then POS$ else IsNull(BI$,0)+ISNULL([Net Deliveries$],0) end)
						from InventorySettlementRequests as IR1 with(NOLOCK)
						where IR1.supplierId=@SupplierId and IR1.retailerId=@ChainId and SettlementFinalized =0 
						and IR1.PhysicalInventoryDate=@PhysicalInventoryDate
						--group by IR1.retailerId
						having isnull(sum(Shrink$)*100/SUM(case when @ShrinkMethod='POS' then POS$ else IsNull(BI$,0)+ISNULL([Net Deliveries$],0) end),0)<>0
						
						if(abs(@TotalShrinkPer)>=@ToShrinkUnitsDIVPOSUnits)
							set @ThresholdProp =  ((@ToShrinkUnitsDIVPOSUnits - @FromShrinkUnitsDIVPOSUnits) *100 / abs(@TotalShrinkPer))
						else if(abs(@TotalShrinkPer)>0)
							set @ThresholdProp =  ((abs(@TotalShrinkPer) - @FromShrinkUnitsDIVPOSUnits) *100 / abs(@TotalShrinkPer))
						
						if (@RetailerShrinkRatio*abs(@ThresholdProp)>0)
							Begin
								Update #tmpSharedShrinkCal set TotalSharedShrink=TotalSharedShrink + (@RetailerShrinkRatio*@ThresholdProp*Shrink$/10000) 
								where SupplierId=@SupplierId and ChainID=@ChainId  and PhysicalInventoryDate=@PhysicalInventoryDate
							end
					end
			
			FETCH NEXT FROM cursor_2 INTO @PhysicalInventoryDate
			end 
			CLOSE cursor_2;
			DEALLOCATE cursor_2;
			
			set @LayerCount = @LayerCount+ 1;
		
		FETCH NEXT FROM cursor_1 INTO @SupplierId, @ChainId, @GroupOn, @Banner, @ForStoreId, @RetailerShrinkRatio, @FromShrinkUnitsDIVPOSUnits, @ToShrinkUnitsDIVPOSUnits,@ShrinkMethod			
		
	end
	CLOSE cursor_1;
	DEALLOCATE cursor_1;
	
	Update s set s.SharedShrinkUnits = (round(((t.TotalSharedShrink)/t.WeightedAvgCost),4)), s.SharedShrink$=(round(((t.TotalSharedShrink)),4))
	from InventorySettlementRequests s
	inner join 	#tmpSharedShrinkCal t
	on s.InventorySettlementRequestID = t.InventorySettlementRequestID	
	where t.WeightedAvgCost>0 and s.SettlementFinalized =0 
	--Commeted the following block as suggetsed by Gilad on FB 18133 dated 12/20
	--------Added following block to round the units to integer value and amount to 2 decimal places for Lewis( By Vishal on 5/21 per Gilad's request)
	--Update s set s.SharedShrinkUnits = ceiling(t.TotalSharedShrink/t.WeightedAvgCost), s.SharedShrink$=(round(((t.TotalSharedShrink)),2))
	--from InventorySettlementRequests s
	--inner join 	#tmpSharedShrinkCal t
	--on s.InventorySettlementRequestID = t.InventorySettlementRequestID	
	--where t.WeightedAvgCost>0 and S.SupplierId=41464 and s.Banner='Shop N Save Warehouse Foods Inc' and s.SettlementFinalized =0 
	
	
	
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
	--from #tmpSharedShrinkCal t
	--inner join InventorySettlementRequests I on I.InventorySettlementRequestID=t.InventorySettlementRequestID
	--where t.WeightedAvgCost>0
	--group by I.StoreNumber, t.StoreID, i.supplierId, i.retailerId, I.SupplierAcctNo
begin try
        Drop Table #tmpSharedShrinkCal
    end try
    begin catch
    end catch

End
GO
