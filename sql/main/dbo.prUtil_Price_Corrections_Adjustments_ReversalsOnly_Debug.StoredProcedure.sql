USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_ReversalsOnly_Debug]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_ReversalsOnly_Debug]
as
/*
************************************************************
--Several updates below by C&M on 20120314
--**********************************************************
*/
declare @startdate date='3/18/2015'
declare @enddate date= '3/18/2015'
--declare @enddate date=cast(dateadd(day,-1,getdate()) as date)
declare @currentdate date
declare @dummy bit
declare @reversedatestring nvarchar(50)

set @reversedatestring = 'SBT-' + cast(year(getdate()) as varchar) + case when len(cast(month(getdate()) as varchar)) = 1 then '0' + cast(month(getdate()) as varchar) else cast(month(getdate()) as varchar) end + case when len(cast(day(getdate()) as varchar)) = 1 then '0' + cast(day(getdate()) as varchar) else cast(day(getdate()) as varchar) end

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
		
		Select Count(storeTransactionid) COuntofST,StoreId, ProductID, Qty, SaleDateTime INto #TempStFVC
		from StoreTransactions 
		where ChainID = 75230
		And TransactionTypeID in (2, 6)
		and SaleDateTime >= '2014-07-14'
		and SaleDateTime < '2015-03-08'
		Group by StoreId, ProductID, Qty, SaleDateTime
		Having COUNT(storeTransactionid) >1
		
		Select MAX(StoreTransactionID) StoreTransactionID, St.StoreId, St.ProductID, ST.Qty, ST.SaleDateTime into #temptransactions
		from StoreTransactions ST inner join #TempStFVC S
		on S.StoreID= ST.StoreID
		and S.ProductID = ST.ProductID
		and S.Qty = ST.Qty
		and S.SaleDateTime = ST.SaleDateTime
		Group by St.StoreId, St.ProductID, ST.Qty, ST.SaleDateTime

		
		--Select *
		--From #temptransactions
		
		--update  a set a.CurrentPromoAllowance = p.UnitPrice
		--from #temptransactions a
		--inner join StoreTransactions t
		--on a.storetransactionid = t.storetransactionid
		--inner join ProductPrices p
		--on t.StoreID = p.StoreID
		--and t.ProductID = p.ProductID
		--and t.BrandID = p.BrandID
		--and t.SupplierID = p.SupplierID
		--and p.productpricetypeid = 8
		--and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
		
--***************************************************************************		

--			update a set a.NeedAdjustment = 1
--			from #temptransactions a
--			where CurrentCost is not null 
----and CurrentCost - CurrentPromoAllowance <> rulecost - promoallowance
----and CurrentCost - CurrentPromoAllowance = ReportedCost
--			and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) <> isnull(rulecost, 0.00) - isnull(promoallowance, 0.00)
--			--and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) = isnull(ReportedCost, 0.00)
--			--and isnull(RuleCost, 0.00) - isnull(promoallowance, 0.00) <> isnull(ReportedCost, 0.00)

/*commented out update below since duplicate costs had been deleted from productprices table
C&M 20120314
			update t set t.NeedAdjustment = 0
			from #temptransactions t
			inner join StoreTransactions st
			on t.StoreTransactionID = st.StoreTransactionID
			inner join import.dbo.TempStoreProductsWithDupeCosts_20120131 d
			on st.storeid = d.storeid
			and st.productid = d.productid
			and st.supplierid = d.supplierid
*/

			--delete from #temptransactions where NeedAdjustment = 0 and SaleDate = @currentdate
			
			--commented out 20120314 since not needed for production C&M insert into Import.dbo.AdjustmentsMaster select * from #temptransactions
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
				select storetransactionid--, currentcost, currentpromoallowance
				from #temptransactions
				--where NeedAdjustment = 1
				--and Processed = 0


			open @rec

			fetch next from @rec into 
					--@recordid
					@transactionidtoreverse
					--,@correctsetupcost
					--,@correctpromoallowance
					
			while @@FETCH_STATUS = 0
				begin
								
				
					
								
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
														,RecordType	
														,EDIRecordID									   
													   )
												 select Top 1 [ChainID]
													   ,[StoreID]
													   ,[ProductID]
													   ,[SupplierID]
													   ,7
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
														,2	
														,EDIRecordID									   
													   from StoreTransactions
													where StoreTransactionID = @transactionidtoreverse
													
											set @reversingtransactionid = SCOPE_IDENTITY()
											
											update t set t.ProcessingErrorDesc = @reversedatestring + ' - REVERSED BY TRANSACTION: ' + CAST(@reversingtransactionid AS varchar(50))
											,Reversed = 1
											from StoreTransactions t
											where t.StoreTransactionID =@transactionidtoreverse
													
						--update Import.dbo.tmpAdjustments20111213_1211 set Processed = 1 where recordid = @recordid									
													
						fetch next from @rec into 
							--@recordid
							@transactionidtoreverse
							--,@correctsetupcost
							--,@correctpromoallowance
					
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
