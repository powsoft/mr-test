USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_SUP_Run_20120215]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_SUP_Run_20120215]
as
/*
select distinct transactiontypeid from storetransactions where cast(saledatetime as date) >= '12/1/2011'

select transactiontypeid, count(storetransactionid)
from storetransactions 
where cast(saledatetime as date) >= '12/1/2011'
group by transactiontypeid

*/
--select * into import.dbo.storetransactions_20120215_BeforeBigAdjustmentRun from storetransactions
declare @startdate date='12/2/2011'
declare @enddate date= dateadd(day, -2, getdate())
--declare @enddate date=cast(dateadd(day,-1,getdate()) as date)
declare @currentdate date
declare @dummy bit

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
		where t.transactiontypeid in (5, 8)
		and t.Reversed = 0
		and CAST(t.saledatetime as date) = @currentdate
		and t.SupplierID = 40557
		--and t.SaleDateTime < '1/29/2012'
		
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
			and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) <> isnull(rulecost, 0.00) - isnull(promoallowance, 0.00)
			--and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) = isnull(ReportedCost, 0.00)
			--and isnull(RuleCost, 0.00) - isnull(promoallowance, 0.00) <> isnull(ReportedCost, 0.00)

--/*
			update t set t.NeedAdjustment = 0
			from #temptransactions t
			inner join StoreTransactions st
			on t.StoreTransactionID = st.StoreTransactionID
			inner join import.dbo.TempStoreProductsWithDupeCosts_20120131 d
			on st.storeid = d.storeid
			and st.productid = d.productid
			and st.supplierid = d.supplierid
--*/

			delete from #temptransactions where NeedAdjustment = 0 and SaleDate = @currentdate
			
			insert into Import.dbo.AdjustmentsMaster select * from #temptransactions
/*
			select * from Import.dbo.AdjustmentsMaster order by datetimecreated desc
			truncate table Import.dbo.AdjustmentsMaster
			
			select t.*, tr.* 
			from #temptransactions t
			inner join storetransactions tr
			on t.storetransactionid = tr.storetransactionid
			
			select top 15000 * from storetransactions order by datetimecreated desc
*/	

--/*
			declare @rec cursor
			declare @recordid bigint
			declare @transactionidtoreverse bigint
			declare @correctsetupcost money
			declare @correctpromoallowance money
			declare @reversingtransactionid bigint

			set @rec = CURSOR local fast_forward FOR
				select storetransactionid, currentcost, currentpromoallowance
				from #temptransactions
				where NeedAdjustment = 1
				and Processed = 0


			open @rec

			fetch next from @rec into 
					--@recordid
					@transactionidtoreverse
					,@correctsetupcost
					,@correctpromoallowance
					
			while @@FETCH_STATUS = 0
				begin
								
											set @reversingtransactionid = null
			--/*					
								
											INSERT INTO [dbo].[StoreTransactions]
													   ([ChainID]
													   ,[StoreID]
													   ,[ProductID]
													   ,[SupplierID]
													   ,[TransactionTypeID]
													   ,[ProductPriceTypeID]
													   ,[BrandID]
													   ,[Qty]
													   ,[SetupCost]
													   ,[SetupRetail]
													   ,[SaleDateTime]
													   ,[UPC]
													   ,[ReportedCost]
													   ,[ReportedRetail]
													   ,[RuleCost]
													   ,[RuleRetail]
													   ,[CostMisMatch]
													   ,[RetailMisMatch]
													   ,[TrueCost]
													   ,[TrueRetail]
													   ,[SourceID]
													   ,[InvoiceID]
													   ,[LastUpdateUserID]
													   ,[WorkingTransactionID]
													   
													   ,[ReportedAllowance]
													   ,[ReportedPromotionPrice]
													   ,StoreIdentifier
														,StoreName
														,ProductQualifier
														,RawProductIdentifier
														,SupplierName
														,SupplierIdentifier
														,BrandIdentifier
														,DivisionIdentifier
														,UOM
														,SalePrice
														,InvoiceNo
														,PONo
														,CorporateName
														,CorporateIdentifier
														,Banner
														,PromoTypeID
														,PromoAllowance
														,SBTNumber										   
																   
														   
													   
													   
													   
													   
													   
													   )
												 select Top 1 [ChainID]
													   ,[StoreID]
													   ,[ProductID]
													   ,[SupplierID]
													   ,case when [TransactionTypeID] IN (5) then 9 else 14 end
													   ,[ProductPriceTypeID]
													   ,[BrandID]
													   ,-1 * [Qty]
													   ,[SetupCost]
													   ,[SetupRetail]
													   ,[SaleDateTime]
													   ,[UPC]
													   ,[ReportedCost]
													   ,[ReportedRetail]
													   ,[RuleCost]
													   ,[RuleRetail]
													   ,[CostMisMatch]
													   ,[RetailMisMatch]
													   ,[TrueCost]
													   ,[TrueRetail]
													   ,[SourceID]
													   ,[InvoiceID]
													   ,[LastUpdateUserID]
													   ,[WorkingTransactionID]
													   
													   

													   ,[ReportedAllowance]
													   ,[ReportedPromotionPrice]
													   ,StoreIdentifier
														,StoreName
														,ProductQualifier
														,RawProductIdentifier
														,SupplierName
														,SupplierIdentifier
														,BrandIdentifier
														,DivisionIdentifier
														,UOM
														,SalePrice
														,InvoiceNo
														,PONo
														,CorporateName
														,CorporateIdentifier
														,Banner
														,PromoTypeID
														,PromoAllowance
														,SBTNumber										   
																   
																   
													   
													   
													   
													   from StoreTransactions
													where StoreTransactionID = @transactionidtoreverse
													
											set @reversingtransactionid = SCOPE_IDENTITY()
											
											update t set t.ProcessingErrorDesc = 'REVERSED BY TRANSACTION: ' + CAST(@reversingtransactionid AS varchar(50))
											,Reversed = 1
											from StoreTransactions t
											where t.StoreTransactionID =@transactionidtoreverse
			--*/					

																		
											INSERT INTO [dbo].[StoreTransactions]
													   ([ChainID]
													   ,[StoreID]
													   ,[ProductID]
													   ,[SupplierID]
													   ,[TransactionTypeID]
													   ,[ProductPriceTypeID]
													   ,[BrandID]
													   ,[Qty]
													   ,[SetupCost]
													   ,[SetupRetail]
													   ,[SaleDateTime]
													   ,[UPC]
													   ,[ReportedCost]
													   ,[ReportedRetail]
													   ,[RuleCost]
													   ,[RuleRetail]
													   ,[CostMisMatch]
													   ,[RetailMisMatch]
													   ,[TrueCost]
													   ,[TrueRetail]
													   ,[SourceID]
													   ,[InvoiceID]
													   ,[LastUpdateUserID]
													   ,[WorkingTransactionID]
													   
													   

													   ,[ReportedAllowance]
													   ,[ReportedPromotionPrice]
													   ,StoreIdentifier
														,StoreName
														,ProductQualifier
														,RawProductIdentifier
														,SupplierName
														,SupplierIdentifier
														,BrandIdentifier
														,DivisionIdentifier
														,UOM
														,SalePrice
														,InvoiceNo
														,PONo
														,CorporateName
														,CorporateIdentifier
														,Banner
														,PromoTypeID
														,PromoAllowance
														,SBTNumber										   
																   
													   
													   
													   )
												 select [ChainID]
													   ,[StoreID]
													   ,[ProductID]
													   ,[SupplierID]
													   ,case when [TransactionTypeID] IN (5) then 20 else 21 end
													   ,[ProductPriceTypeID]
													   ,[BrandID]
													   ,[Qty]
													   ,@correctsetupcost --[SetupCost]
													   ,[SetupRetail]
													   ,[SaleDateTime]
													   ,[UPC]
													   ,[ReportedCost]
													   ,[ReportedRetail]
													   ,@correctsetupcost --[RuleCost]
													   ,[RuleRetail]
													   ,0 --[CostMisMatch]
													   ,0 --[RetailMisMatch]
													   ,@correctsetupcost --case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
													   ,[RuleRetail] --case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
													   ,[SourceID]
													   ,[InvoiceID]
													   ,[LastUpdateUserID]
													   ,[WorkingTransactionID]													   													   

													   ,[ReportedAllowance]
													   ,[ReportedPromotionPrice]
													   ,StoreIdentifier
														,StoreName
														,ProductQualifier
														,RawProductIdentifier
														,SupplierName
														,SupplierIdentifier
														,BrandIdentifier
														,DivisionIdentifier
														,UOM
														,SalePrice
														,InvoiceNo
														,PONo
														,CorporateName
														,CorporateIdentifier
														,Banner
														,1 --PromoTypeID
														,@correctpromoallowance --PromoAllowance
														,SBTNumber										   
																   
													   
													   
													   
													   from StoreTransactions
													where StoreTransactionID = @transactionidtoreverse
													
						--update Import.dbo.tmpAdjustments20111213_1211 set Processed = 1 where recordid = @recordid									
													
						fetch next from @rec into 
							--@recordid
							@transactionidtoreverse
							,@correctsetupcost
							,@correctpromoallowance
					
					end
					
			close @rec
			deallocate @rec									
													
													

--*/		
		
		
		
--****************************************************************************	

		--commit transaction
			
		set @currentdate = DATEADD(day, 1, @currentdate)
	end




return
GO
