USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_Shrink_Review_20120215]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_Shrink_Review_20120215]
as

declare @startdate date='12/1/2011'
declare @enddate date  --='12/15/2011'
declare @currentdate date
declare @dummy bit

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
		cast(t.saledatetime as date) as SaleDate, CAST(0 as smallint) as Processed,
		getdate() as datetimecreated
		into #temptransactions
		from StoreTransactions t
		left join ProductPrices p
		on t.StoreID = p.StoreID
		and t.ProductID = p.ProductID
		and t.BrandID = p.BrandID
		and t.SupplierID = p.SupplierID
		and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
		and p.ProductPriceTypeID = 3
		--added to prevent records with no current unit cost on 20120314 by C&M
		and p.UnitPrice is not null
		where t.transactiontypeid in (17, 18, 19, 23)
		and t.Reversed = 0
		and CAST(t.saledatetime as date) = @currentdate
		--and t.SupplierID = 41464
		--and t.SaleDateTime < '2/3/2012'
--/*	
/*	
select * from storetransactions where transactiontypeid = 17 and reversed = 1
Commented out to follow fogbugz cas 12876 on 20120314
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
	*/
--*/		
--***************************************************************************		

			update a set a.NeedAdjustment = 1
			from #temptransactions a
			where CurrentCost is not null 
--			and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) <> isnull(rulecost, 0.00) - isnull(promoallowance, 0.00)
--			above row has been commented out and replace with the below one for fogbugz case 12876 on 20140314 by C&M
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
