USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPromoLiftData]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetPromoLiftData]
 @StoreId varchar(20),
 @ProductId varchar(20),
 @NoOfDays int,
 @FromDate datetime,
 @ToDate datetime

as

Begin

	begin try
		drop table #tmpPromoLift
		drop table #tmpPromoToReview
	end try
	begin catch
	end catch

	SET DATEFIRST 1
	
	DECLARE @StartDate datetime, 
			@EndDate datetime
			
	SELECT @StartDate=GETDATE()-@NoOfDays,
		   @EndDate=GETDATE()
		   
	;with AllDates AS
	(
		SELECT @StartDate AS DateOf, datename(weekday,@StartDate) AS WeekDayName, datepart(weekday,@StartDate) AS WeekDayNumber
		UNION ALL
		SELECT DateOf+1, datename(weekday,DateOf+1), datepart(weekday,DateOf+1)
			FROM AllDates
		WHERE DateOf<@EndDate
	)
	
	SELECT isnull(isnull(PP.StoreId,p3.storeid),st.storeid) as StoreID, isnull(isnull(PP.ProductId,p3.productid),st.productid) as ProductID, cast(DateOf as date) as OnDate, WeekDayName, isnull(SUM(qty),0) as TotalSales, count(PP.ProductPriceID) as PromoDay, PP.UnitPrice as Promo$, St.RuleCost as Cost$
	into #tmpPromoLift

	FROM AllDates AD
	left join DataTrue_Report.dbo.StoreTransactions ST  on cast(ST.SaleDateTime as date) =cast(AD.DateOf as date)
	and ST.ProductID= @ProductId 
	and ST.StoreID =@StoreId and cast(ST.SaleDateTime as date)>='12/1/2011'

	left join ProductPrices PP on cast(AD.DateOf as date) between cast(PP.ActiveStartDate as date) and cast(PP.ActiveLastDate as date)
	and PP.ProductID= @ProductID 
	and PP.StoreID =@StoreId and PP.ProductPriceTypeID=8 and pp.ActiveStartDate >='12/1/2011'

	left join ProductPrices P3 on cast(AD.DateOf as date) between cast(P3.ActiveStartDate as date) and cast(P3.ActiveLastDate as date)
	and P3.ProductID= @ProductId 
	and P3.StoreID =@StoreId and P3.ProductPriceTypeID=3 and p3.ActiveStartDate >='12/1/2011'

	where isnull(isnull(PP.StoreId,p3.storeid),st.storeid) is not null 

	group by isnull(isnull(PP.StoreId,p3.storeid),st.storeid), isnull(isnull(PP.ProductId,p3.productid),st.productid), cast(DateOf as date),WeekDayName, st.RuleCost,pp.UnitPrice
	order by  cast(DateOf as date) asc,  isnull(isnull(PP.StoreId,p3.storeid),st.storeid), isnull(isnull(PP.ProductId,p3.productid),st.productid)

	OPTION (MAXRECURSION 0)

--Create a tmp table to hold the promo dates requested to be reviewed by the end user

	select * 
		into #tmpPromoToReview
		from #tmpPromoLift 
		where ondate between @FromDate and @ToDate and promoday=1

--shows the non-promo dates that were before the min(ondate) chosen by the end user
	select count(ondate) as [#OfAvailableNO_PromoSaleDays], sum(totalsales)/count(ondate) as AvgDailyUnitSales,sum(totalsales) as UnitSales, SUM(Totalsales*Cost$) as TotalSales$, SUM(Totalsales*Cost$)/sum(totalsales)as AvgUnitCost, 0 as Promo 
		from #tmpPromoLift 
		where weekdayname in (select weekdayname from #tmpPromoToReview) 
		and promoday=0 and ondate<(select min(ondate) from #tmpPromoToReview) 
		

--shows the performance for the promotion chosen date range
	select count(ondate) as [#OfAvailablePromoSaleDays], sum(totalsales)/count(ondate) as AvgDailyUnitSales,SUM(Totalsales) as UnitSales, SUM(Totalsales*(Cost$-Promo$)) as TotalNetSales$, SUM(Totalsales*(Cost$))/sum(totalsales)as AvgUnitCost,SUM(Totalsales*(Promo$))/sum(totalsales)as AvgUnitPromo from #tmpPromoToReview

End
GO
