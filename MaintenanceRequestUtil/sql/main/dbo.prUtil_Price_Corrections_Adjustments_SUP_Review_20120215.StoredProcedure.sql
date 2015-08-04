USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_SUP_Review_20120215]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_SUP_Review_20120215]
as

declare @startdate date= dateadd(day, -120, getdate())
declare @enddate date= dateadd(day, -2, getdate())
--declare @enddate date=cast(dateadd(day,-1,getdate()) as date)
declare @currentdate date
declare @dummy bit
if CAST(@startdate as date)<'12/1/2011'
	set @currentdate = '12/1/2011'
else
	set @currentdate = @startdate


set @enddate = DATEADD(day, -1, getdate())

set @currentdate = @startdate

While @currentdate between @startdate and @enddate
	begin
	
		--begin transaction
		
		begin try
			DROP TABLE #temptransactions
		end try
		begin catch
			set @dummy = 0
		end catch	
		
		select storetransactionid, cast(UnitPrice as DECimal(12,2)) As CurrentCost, 
		cast(0 as DECimal(12,2)) as CurrentPromoAllowance,
		cast(Setupcost as DECimal(12,2)) as Setupcost, cast(PromoAllowance as DECimal(12,2)) as PromoAllowance, 
		cast(RuleCost as DECimal(12,2)) as RuleCost, 
		cast(ReportedCost as DECimal(12,2)) as ReportedCost, cast(ReportedAllowance as DECimal(12,2)) as ReportedAllowance, 
		CAST(0 as smallint) as NeedAdjustment,
		cast(t.saledatetime as date) as SaleDate, CAST(0 as smallint) as Processed
		into #temptransactions
		from StoreTransactions t
		left join ProductPrices p
		on t.StoreID = p.StoreID
		and t.ProductID = p.ProductID
		and t.BrandID = p.BrandID
		and t.SupplierID = p.SupplierID
		and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
		and p.ProductPriceTypeID = 3
		where t.transactiontypeid in (5, 8)
		and t.Reversed = 0
		and CAST(t.saledatetime as date) = @currentdate
		and p.UnitPrice is not null
		--and t.SupplierID = 40557
		
		update  a set a.CurrentPromoAllowance = p.UnitPrice
		from #temptransactions a
		inner join StoreTransactions t
		on a.storetransactionid = t.storetransactionid
		inner join ProductPrices p
		on t.StoreID = p.StoreID
		and t.ProductID = p.ProductID
		and t.BrandID = p.BrandID
		and t.SupplierID = p.SupplierID
		and p.productpricetypeid = 8
		and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
		
--***************************************************************************		

			update a set a.NeedAdjustment = 1
			from #temptransactions a
			where CurrentCost is not null 
--and CurrentCost - CurrentPromoAllowance <> rulecost - promoallowance
--and CurrentCost - CurrentPromoAllowance = ReportedCost
			--and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) <> isnull(rulecost, 0.00) - isnull(promoallowance, 0.00)
			--and isnull(RuleCost, 0.00) - isnull(promoallowance, 0.00) <> isnull(ReportedCost, 0.00)
			--and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) = isnull(ReportedCost, 0.00)
			and CurrentCost <> isnull(rulecost, 0.00)
			
			/*
			--select *
			update t set t.NeedAdjustment = 0
			from #temptransactions t
			inner join StoreTransactions st
			on t.StoreTransactionID = st.StoreTransactionID
			inner join import.dbo.TempStoreProductsWithDupeCosts_20120131 d
			on st.storeid = d.storeid
			and st.productid = d.productid
			and st.supplierid = d.supplierid
*/

			delete from #temptransactions where NeedAdjustment = 0 and SaleDate = @currentdate
			

			
			select t.*, tr.* 
			from #temptransactions t
			inner join storetransactions tr
			on t.storetransactionid = tr.storetransactionid

--*/		
		
		
		
--****************************************************************************	

		--commit transaction
			
		set @currentdate = DATEADD(day, 1, @currentdate)
	end




return
GO
