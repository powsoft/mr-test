USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPromoLiftDataNew]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetPromoLiftDataNew]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreId varchar(20),
 @ProductId varchar(20),
 @NoOfDays int,
 @FromDate datetime,
 @ToDate datetime

as

Begin

	begin try
		Drop Table #tmpAllDates
		Drop Table #tmpPromoLiftSales
		Drop Table #tmpPromoLift
		Drop Table #tmpPromoToReview
		Drop Table #tmpAllPriceDates
		Drop Table #tmpAllPPDates
	end try
	begin catch
	end catch

	SET DATEFIRST 1
	
	DECLARE @StartDate datetime, 
			@EndDate datetime
			
	SELECT @StartDate=GETDATE()-@NoOfDays,
		   @EndDate=GETDATE()
		   
	-- Get all dates with Weekdayname  between Start and EndDates			   
	;with AllDates AS
	(
		SELECT @StartDate AS DateOf, datename(weekday,@StartDate) AS WeekDayName, datepart(weekday,@StartDate) AS WeekDayNumber
		UNION ALL
		SELECT DateOf+1, datename(weekday,DateOf+1), datepart(weekday,DateOf+1)
			FROM AllDates
		WHERE DateOf<@EndDate
	)

	--Insert dates in a temp table.	
	select * into #tmpAllDates 	from AllDates where DateOf>'12/1/2011'
	OPTION (MAXRECURSION 0)

	
	--Insert the data for all sale transaction dates into a temp table
	SELECT ST.SupplierID, ST.ChainID, ST.StoreID, ST.ProductID,
		 cast(SaleDateTime as date) as OnDate,isnull(SUM(qty),0) as TotalSales, St.RuleCost as Cost$
	into #tmpPromoLiftSales
	FROM DataTrue_Report.dbo.StoreTransactions ST  
	where st.TransactionTypeID in (2,6,7,16)
	and ST.SaleDateTime>='12/1/2011'
	and ST.SupplierId like ''  + @SupplierId + ''
	and ST.ChainId like '' + @ChainId + ''
	and ST.ProductID like '' + @ProductId + ''
	and ST.StoreID like '' + @StoreId + ''
	group by ST.SupplierID, ST.ChainID, ST.StoreID, ST.ProductID, cast(SaleDateTime as date), st.RuleCost
	order by  cast(SaleDateTime as date) asc, SupplierID, ChainID, StoreID, ProductID

	--select * from #tmpPromoLiftSales
	
--Fetch the data for all prices between the dates collected in Step 1 and store in a temp table
	SELECT  SupplierID, ChainID, StoreID, ProductID, 
		cast(DateOf as date) as OnDate, WeekDayName, WeekDayNumber, 
		case when PP.ProductPriceTypeID=8 then 1 else 0 end as PromoDay, 
		case when PP.ProductPriceTypeID=8 then PP.UnitPrice else 0 end as Promo$,
		case when PP.ProductPriceTypeID=3 then PP.UnitPrice else 0 end as Cost$
	into #tmpAllPPDates

	FROM #tmpAllDates AD
	Left join ProductPrices PP on cast(AD.DateOf as date) between cast(PP.ActiveStartDate as date) 
	and cast(PP.ActiveLastDate as date)
	and PP.ProductPriceTypeID in (3,8) 
	and PP.SupplierId like ''  + @SupplierId + ''
	and PP.ChainId like '' + @ChainId + ''
	and PP.ProductID like '' + @ProductId + ''
	and PP.StoreID like '' + @StoreId + ''
	order by  cast(DateOf as date) asc, SupplierID, ChainID, StoreID, ProductID
	
	--select * from #tmpAllPPDates
	
	Select SupplierID, ChainID, StoreID, ProductID, OnDate, WeekDayName, WeekDayNumber,
	SUM(PromoDay) as Promoday,
	SUM(Promo$) as Promo$,
	SUM(Cost$) as Cost$
	
	into #tmpAllPriceDates
	from #tmpAllPPDates
	group by SupplierID, ChainID, StoreID, ProductID, OnDate, WeekDayName, WeekDayNumber
	
	--select * from #tmpAllPriceDates
	
--Merge the data of Prices and Sales based on AllDates	
	Select 
	isnull(P.SupplierId,S.SupplierID) as SupplierId,
	isnull(P.ChainID,S.ChainID) as ChainID,
	isnull(P.StoreID,S.StoreID) as StoreID,
	isnull(P.ProductID,S.ProductID) as ProductID, 
	ISNULL(P.OnDate,S.OnDate) as Ondate, WeekDayName, WeekDayNumber, isnull(P.PromoDay,-1) as PromoDay, P.Promo$, P.Cost$,
	Isnull(S.Cost$,0) as SaleCost$, isnull(S.TotalSales, 0) as TotalSales
	into #tmpPromoLift 
	from #tmpAllPriceDates P
	Left join #tmpPromoLiftSales S on S.OnDate=P.OnDate 
	and S.SupplierId=P.SupplierId
	and S.ChainID=p.ChainID 
	and S.StoreID=p.StoreID
	and s.ProductID=p.ProductID
	where  1=1 
	and P.SupplierId like ''  + @SupplierId + ''
	and P.ChainId like '' + @ChainId + ''
	and P.ProductID like ''  + @ProductId + ''
	and P.StoreID  like '' + @StoreId + ''
	order by isnull(P.SupplierId,S.SupplierID) ,
	isnull(P.ChainID,S.ChainID) ,
	isnull(P.StoreID,S.StoreID) ,
	isnull(P.ProductID,S.ProductID), P.OnDate
	select * from #tmpPromoLift
--Create a tmp table to hold the promo dates requested to be reviewed by the end user

	select * 
		into #tmpPromoToReview
		from #tmpPromoLift
		where ondate between '' + @FromDate + '' and '' + @ToDate + '' and promoday=1

--shows the non-promo dates that were before the min(ondate) chosen by the end user
	select SupplierID, ChainId,StoreID, ProductID, WeekDayName, count(ondate) as [#OfAvailableNO_PromoSaleDays], 
		sum(totalsales)/count(ondate) as AvgDailyUnitSales,sum(totalsales) as UnitSales,
		SUM(Totalsales*Cost$) as TotalSales$, 
		Case when sum(totalsales)=0 Then 0
			else
				SUM(Totalsales*Cost$)/sum(totalsales) 
		End as AvgUnitCost, 0 as Promo
	into #tmpFinalNonPromoSales 
	from #tmpPromoLift L
	where weekdayname in 
		(select weekdayname from #tmpPromoToReview R 
			where R.SupplierId=L.SupplierId and R.ChainID=L.ChainID and R.StoreID=L.StoreID and R.ProductID=L.ProductID) 
	and promoday=0 
	and ondate<(select min(ondate) from #tmpPromoToReview R 
			where R.SupplierId=L.SupplierId and R.ChainID=L.ChainID and R.StoreID=L.StoreID and R.ProductID=L.ProductID) 
	group by SupplierID, ChainId,StoreID, ProductID, WeekDayName, WeekDayNumber
	order by SupplierID, ChainId, StoreID, ProductID, WeekDayNumber
	select * from #tmpFinalNonPromoSales
	
--shows the performance for the promotion chosen date range
	select SupplierID, ChainId, StoreID, ProductID, WeekDayName,  count(ondate) as [#OfAvailablePromoSaleDays], 
		sum(totalsales)/count(ondate) as AvgDailyUnitSales,SUM(Totalsales) as UnitSales, 
		SUM(Totalsales*(Cost$-Promo$)) as TotalNetSales$, 
		Case when sum(totalsales)=0 Then 0
			else
				SUM(Totalsales*(Cost$-Promo$))/sum(totalsales)
		End as AvgUnitCost
	into #tmpFinalPromoSales
	from #tmpPromoToReview
	group by SupplierID, ChainId, StoreID, ProductID, WeekDayName, WeekDayNumber
	order by SupplierID, ChainId, StoreID, ProductID, WeekDayNumber

select * from #tmpFinalPromoSales

-- Putting together the final results to come up with the Lift values.
	Select P.SupplierID, P.ChainId, P.StoreID, P.ProductID, 
	ISNULL(P.WeekDayName,NP.WeekDayName) as WeekDayName,
	[#OfAvailableNO_PromoSaleDays], NP.AvgDailyUnitSales as [Non Promo Avg Unit Sales], 
	NP.UnitSales as [Non Promo Unit Sales], NP.TotalSales$ as [Non Promo Unit Sales$],
	NP.AvgUnitCost as  [Non Promo Avg Unit Cost],
	[#OfAvailablePromoSaleDays], P.AvgDailyUnitSales  as [Promo Avg Unit Sales], 
	P.UnitSales as [Promo Unit Sales],  P.TotalNetSales$ as [Promo Unit Sales$], 
	P.AvgUnitCost as  [Promo Avg Unit Cost],
	(P.AvgDailyUnitSales-NP.AvgDailyUnitSales) as [Avg Daily Unit Sales Lift]
	
	from #tmpFinalPromoSales P 
	Full join #tmpFinalNonPromoSales NP on P.SupplierId=NP.SupplierId and P.ChainID=NP.ChainID 
	and P.StoreID=NP.StoreID and P.ProductID=NP.ProductID and P.WeekDayName=NP.WeekDayName
	
	-- We need to look at if the comparision is done by the weekday and to add more columns to final results query.
End
GO
