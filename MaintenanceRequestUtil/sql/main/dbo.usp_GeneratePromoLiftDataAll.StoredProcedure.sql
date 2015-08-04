USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GeneratePromoLiftDataAll]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GeneratePromoLiftDataAll]
 --exec [usp_GeneratePromoLiftDataAll]
as

Begin

	--Drop the temp tables at the begining
begin try
        Drop Table #tmpAllWeeks
        Drop Table #tmpWeeklySaleData
        Drop Table #tmpWeeklyPromoData
       
end try
begin catch
end catch
  
    DECLARE @StartDate datetime,  @EndDate datetime
   
    -- Set Start Date = 18 weeks old and EndDate = 1 week old
    SELECT @StartDate=GETDATE()-180,
           @EndDate=GETDATE()-7
         
    -- Get the WeekBegin dates group by ChainId and Banner for all the sales
    ;with AllDates AS
    (
        SELECT ST.ChainId, S.Custom1 as Banner, 
        case 
			when datename(weekday,min(SaleDateTime))=W.AdWeekEnding then  
				min(SaleDateTime) 
			when datename(weekday,min(SaleDateTime) + 1 )=W.AdWeekEnding then
				min(SaleDateTime)+1 
			when datename(weekday,min(SaleDateTime) + 2 )=W.AdWeekEnding then
				min(SaleDateTime)+2 
			when datename(weekday,min(SaleDateTime) + 3 )=W.AdWeekEnding then
				min(SaleDateTime)+3 
			when datename(weekday,min(SaleDateTime) + 4 )=W.AdWeekEnding then
				min(SaleDateTime)+4 
			when datename(weekday,min(SaleDateTime) + 5 )=W.AdWeekEnding then
				min(SaleDateTime)+5 
			when datename(weekday,min(SaleDateTime) + 6 )=W.AdWeekEnding then
				min(SaleDateTime)+6 
		end as WkBegin
        from DataTrue_Report.dbo.StoreTransactions ST
            Inner Join Stores S on S.StoreID=ST.StoreID and S.ChainID=ST.ChainId and S.ActiveStatus='Active'
            Inner Join ChainAdWeek W on W.ChainId=ST.ChainID and W.Banner=S.Custom1 
        where S.Custom1 is not null  and S.Custom1<>'' and SaleDateTime>@StartDate
            and ST.TransactionTypeID in (2,6,7,16) and ST.ProductPriceTypeID<>8 and ST.Reversed<>1
        group by ST.ChainId, S.Custom1, W.AdWeekEnding
       
        UNION ALL
       
        SELECT ChainId, Banner, WkBegin+7 FROM AllDates WHERE WkBegin<@EndDate
    )

    --Insert dates in a temp table.  
    select ChainId, Banner, convert(date,WkBegin,101) as WkBegin into #tmpAllWeeks from AllDates  order by 1,2,3
  
    OPTION (MAXRECURSION 0)
  
   --select * from #tmpAllWeeks
   -- Calculate the Total Weekly Sales.
    select ST1.ChainId, S.Custom1 as Banner, ST1.ProductID, ST1.UPC,
        W.WkBegin as AdWeekStart,
        DateAdd(DAY,6,W.WkBegin) as [AdWeekEnd],
        isnull(SUM(ST1.Qty),0) as WeeklyUnitSale,
        case when sum(ST1.Qty)>0 then
            (SUM(ST1.Qty * ST1.RuleCost)/SUM(ST1.Qty))
            else 0
        end as AvgUnitCost$
        
    into #tmpWeeklySaleData
    from DataTrue_Report.dbo.StoreTransactions ST1
    Inner Join Stores S on S.StoreID=ST1.StoreID and S.ChainID=ST1.ChainId and S.ActiveStatus='Active'
    inner join #tmpAllWeeks W on W.ChainID=ST1.ChainID and W.Banner=S.Custom1
    where ST1.SaleDateTime between W.WkBegin and DateAdd(DAY,6,W.WkBegin)
		  --and S.Custom1 like '%ACME%' and ST1.ProductID=5122
          and S.Custom1<>'' and S.Custom1 is not null  and ST1.TransactionTypeID in (2,6,7,16) and ST1.ProductPriceTypeID<>8 and ST1.Reversed<>1
    GROUP by ST1.ChainId, S.Custom1, ST1.ProductID, ST1.UPC, W.WkBegin,ST1.RuleCost
    order by 1,2,3,4,5

	-- Calculate the Total Weekly Promo Sales.
	select ST1.ChainId, S.Custom1 as Banner, ST1.ProductID, ST1.UPC,
        W.WkBegin as AdWeekStart,
        DateAdd(DAY,6,W.WkBegin) as [AdWeekEnd],
        isnull(SUM(ST1.Qty),0) as WeeklyPromoUnitSale,
        case when sum(ST1.Qty)>0 then
            (SUM(ST1.Qty * ST1.RuleCost)/SUM(ST1.Qty))
            else 0
        end as AvgUnitCost$,
        case when sum(ST1.Qty)>0 then
            (SUM(ST1.Qty * (isnull(ST1.RuleCost,0)-isnull(ST1.PromoAllowance,0)))/SUM(ST1.Qty))
            else 0
        end as AvgUnitCostNet$, '' as AvgUnitRetailNet$
        
    into #tmpWeeklyPromoData
    from DataTrue_Report.dbo.StoreTransactions ST1
    Inner Join Stores S on S.StoreID=ST1.StoreID and S.ChainID=ST1.ChainId and S.ActiveStatus='Active'
    inner join #tmpAllWeeks W on W.ChainID=ST1.ChainID and W.Banner=S.Custom1
    where ST1.SaleDateTime between W.WkBegin and DateAdd(DAY,6,W.WkBegin) and ST1.PromoAllowance>0
		  --and S.Custom1 like '%ACME%' and ST1.ProductID=5122
          and S.Custom1<>'' and S.Custom1 is not null  and ST1.TransactionTypeID in (2,6,7,16) and ST1.ProductPriceTypeID<>8 and ST1.Reversed<>1
    GROUP by ST1.ChainId, S.Custom1, ST1.ProductID, ST1.UPC, W.WkBegin,ST1.RuleCost
    order by 1,2,3,4,5
    
    --select * from #tmpWeeklySaleData 
    --select * from #tmpWeeklyPromoData 
    
    Truncate Table WeeklyPromoLiftData
    --Storing the Classified sales data in tmp Table for further use.
     Insert into WeeklyPromoLiftData
    select S.ChainId, S.Banner, S.ProductID, S.UPC,
        S.AdWeekStart,s.AdWeekEnd, S.WeeklyUnitSale,P.WeeklyPromoUnitSale,
        isnull((S.WeeklyUnitSale),0)-isnull((P.WeeklyPromoUnitSale),0) as WeeklyNonPromoUnitSale,
        S.AvgUnitCost$,P.AvgUnitCostNet$, '' as AvgUnitRetailNet$,
        case when isnull((P.WeeklyPromoUnitSale),0)< (isnull((S.WeeklyUnitSale),0)-isnull((P.WeeklyPromoUnitSale),0)) Then
                'False'
            else
                'True'
        end as PromoFlag, '' as UpdateHistory
    from #tmpWeeklySaleData S
    Inner Join #tmpWeeklyPromoData P    on
            S.ChainId=P.ChainId and
            S.Banner=P.Banner and
            S.ProductID=P.ProductID  and S.AdWeekStart=P.AdWeekStart
    order by 1,2,3,4,5
        
--   select * from WeeklyPromoLiftData
   
End
GO
