USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_Newspapers_BetweenDates_Debug]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_Newspapers_BetweenDates_Debug]
as
/*
select cast(year(getdate()) as varchar) + case when len(cast(month(getdate()) as varchar)) = 1 then '0' + cast(month(getdate()) as varchar) else cast(month(getdate()) as varchar) end + case when len(cast(day(getdate()) as varchar)) = 1 then '0' + cast(day(getdate()) as varchar) else cast(day(getdate()) as varchar) end
*/
declare @startdate date= dateadd(month, -4, getdate()) --'1/24/2015' --dateadd(month, -4, getdate()) --'10/01/2014' --dateadd(month, -3, getdate()) --'12/1/2011'
declare @enddate date= cast(dateadd(day, -1, getdate()) as date)
--declare @enddate date=cast(dateadd(day,-1,getdate()) as date)
declare @currentdate date
declare @dummy bit
declare @reversedatestring nvarchar(50)

set @reversedatestring = 'NewsPaper_1 ' + cast(year(getdate()) as varchar) + case when len(cast(month(getdate()) as varchar)) = 1 then '0' + cast(month(getdate()) as varchar) else cast(month(getdate()) as varchar) end + case when len(cast(day(getdate()) as varchar)) = 1 then '0' + cast(day(getdate()) as varchar) else cast(day(getdate()) as varchar) end

--update t set rulecost = p.UnitPrice, ruleretail = p.UnitRetail
--from storetransactions t
--inner join productprices p
--on t.storeid = p.storeid
--and t.productid = p.productid
--and t.supplierid = p.supplierid
--and t.saledatetime between p.ActiveStartDate and p.ActiveLastDate
--and p.ProductPriceTypeID = 3
--and (t.rulecost = 0 or t.rulecost is null)
--and t.saledatetime >= @startdate
--and t.transactiontypeid in (2,6)
--and isnull(t.reversed, 0) <> 1
--and t.transactionstatus in (0, 2)

--update t set ruleretail = p.UnitRetail
--from storetransactions t
--inner join productprices p
--on t.storeid = p.storeid
--and t.productid = p.productid
--and t.supplierid = p.supplierid
--and t.saledatetime between p.ActiveStartDate and p.ActiveLastDate
--and p.ProductPriceTypeID = 3
--and (t.ruleretail = 0 or t.ruleretail is null)
--and t.saledatetime >= @startdate
--and t.transactiontypeid in (2,6)
--and isnull(t.reversed, 0) <> 1
--and t.transactionstatus in (0, 2)

truncate table DataTrue_Main.dbo.Temp_POS_Adjustments

set @currentdate = @startdate
		--begin transaction
		
		------begin try
		------	DROP TABLE #temptransactions
		------end try
		------begin catch
		------	set @dummy = 0
		------end catch
		--select * from DataTrue_Main.dbo.Temp_POS_Adjustments	
		
		print @currentdate
			
		insert DataTrue_Main.dbo.Temp_POS_Adjustments
		select t.chainid, storetransactionid, cast(UnitPrice as DECimal(12,2)) As CurrentCost, 
		cast(0 as DECimal(12,2)) as CurrentPromoAllowance,
		cast(Setupcost as DECimal(12,2)) as Setupcost, cast(PromoAllowance as DECimal(12,2)) as PromoAllowance, 
		cast(RuleCost as DECimal(12,2)) as RuleCost, 
		cast(ReportedCost as DECimal(12,2)) as ReportedCost, cast(ReportedAllowance as DECimal(12,2)) as ReportedAllowance, 
		CAST(0 as smallint) as NeedAdjustment,
		cast(t.saledatetime as date) as SaleDate, CAST(0 as smallint) as Processed,
		getdate() as datetimecreated, t.SupplierID, 
		p.SupplierID as NewSupplierID, '', '', 
		cast(UnitRetail as DECimal(12,2)) As CurrentRetail, t.productid, t.StoreID, t.qty, t.RuleRetail
		--into DataTrue_Main.dbo.Temp_POS_Adjustments --#temptransactions
		from StoreTransactions t
		inner join ProductPrices p
		on t.StoreID = p.StoreID
		and t.ProductID = p.ProductID
		--and t.BrandID = p.BrandID
		and t.SupplierID <> p.SupplierID
		and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
		and p.ProductPriceTypeID = 3
		--added to prevent records with no current unit cost on 20120314 by C&M
		and p.UnitPrice is not null
		where t.transactiontypeid in (2, 6, 16)
		and t.Reversed = 0
		--and CAST(t.saledatetime as date) = @currentdate
		and CAST(t.saledatetime as date) between @startdate and @enddate
		--and t.ChainID in (select EntityIDToInclude from ProcessStepEntities where ltrim(rtrim(ProcessStepName)) in ('prUtil_Price_Corrections_Adjustments_Newspapers','prGetInboundPOSTransactions_Newspapers','prGetInboundPOSTransactions_PDI_Newspapers'))
		--and t.ChainID not in (64010, 65232)
		--and t.ChainID in (64010, 65232)
		--and t.ChainID in (64010)
		--and t.ChainID not in (64010,65232)
		--and t.ChainID in (42490)
		--and t.StoreID in (60634)
		--and t.ChainID in (60624, 74628)
		--and t.chainid not in (63613, 63614, 60626) --, 42490)
		--and t.SupplierID in (0)
		--and t.SupplierID not in (76816) --50726,74813)
		--and p.SupplierID not in (91718,26194,64422,26529) --50726,74813)
		and t.ProductID in (select distinct ProductID from ProductIdentifiers where ProductIdentifierTypeID = 8)
		--and p.ProductID = 38547 --38883
		--and CAST(t.saledatetime as date) >= '7/1/2014'

		update  a set a.CurrentPromoAllowance = 0
		from DataTrue_Main.dbo.Temp_POS_Adjustments a
				
	
--***************************************************************************		
				--select *
				----select storetransactionid, currentcost, currentpromoallowance
				--from DataTrue_Main.dbo.Temp_POS_Adjustments --#temptransactions
				--where 1 = 1
				----and NeedAdjustment = 1
				----and Processed = 0

			update a set a.NeedAdjustment = 1
			from DataTrue_Main.dbo.Temp_POS_Adjustments a
				
------			update a set a.NeedAdjustment = 1
------			from DataTrue_Main.dbo.Temp_POS_Adjustments a --#temptransactions a
------			where CurrentCost is not null 
--------and CurrentCost - CurrentPromoAllowance <> rulecost - promoallowance
--------and CurrentCost - CurrentPromoAllowance = ReportedCost
------			and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) <> isnull(rulecost, 0.00) - isnull(promoallowance, 0.00)
------			--and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) = isnull(ReportedCost, 0.00)
------			--and isnull(RuleCost, 0.00) - isnull(promoallowance, 0.00) <> isnull(ReportedCost, 0.00)



			-------------------------------------20140829-------------------------delete from DataTrue_Main.dbo.Temp_POS_Adjustments where NeedAdjustment = 0 and SaleDate = @currentdate
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


			update a set a.NewSupplierName = left(s.SupplierName, 50), a.NewSupplierIdentifier = left(s.SupplierIdentifier, 50)
			from DataTrue_Main.dbo.Temp_POS_Adjustments a
			inner join DataTrue_Main.dbo.Suppliers s
			on a.newsupplierID = s.SupplierID


--/*
			declare @rec cursor
			declare @recordid bigint
			declare @transactionidtoreverse bigint
			declare @correctsetupcost money
			declare @correctpromoallowance money
			declare @reversingtransactionid bigint
			declare @newsupplierid int
			declare @newsuppliername nvarchar(50)
			declare @newsupplieridentifier nvarchar(50)
			declare @currentretail money

select SUM(qty*CurrentCost) as CostDiff, SUM(qty * CurrentRetail * .03)  as FeeDiff
				from DataTrue_Main.dbo.Temp_POS_Adjustments
				where NeedAdjustment = 1
				and Processed = 0

			set @rec = CURSOR local fast_forward FOR
			--select StoreID s, ProductID p, NewSupplierID n, OldSupplierID o, *
			select storetransactionid, currentcost, currentpromoallowance, newsupplierid, newsuppliername, newsupplieridentifier, CurrentRetail
				from DataTrue_Main.dbo.Temp_POS_Adjustments --#temptransactions
				where NeedAdjustment = 1
				and Processed = 0 --and CurrentCost <> Rulecost
				--and NewSupplierID = 28731
				order by chainid, StoreID, ProductID, saledate, NewSupplierID, OldSupplierID --chainid, SaleDate
				
				--/*
			open @rec

			fetch next from @rec into 
					--@recordid
					@transactionidtoreverse
					,@correctsetupcost
					,@correctpromoallowance
					,@newsupplierid
					,@newsuppliername
					,@newsupplieridentifier
					,@currentretail
					
			while @@FETCH_STATUS = 0
				begin
				
				begin transaction
								
											set @reversingtransactionid = null
					
								
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
														,ChainIdentifier   
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
													   ,Case when SupplierID = 0 and round(@correctsetupcost,2) = round(RuleCost,2) and round(@currentretail,2) = round(RuleRetail,2) then 3 
															when SupplierID <> 0 and round(@correctsetupcost,2) = round(RuleCost,2) and round(@currentretail,2) = round(RuleRetail,2) then 5 
														else 4 end
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
														,ChainIdentifier		   
													    ,EDIRecordID
													   
													   
													   from StoreTransactions
													where StoreTransactionID = @transactionidtoreverse
													
											set @reversingtransactionid = SCOPE_IDENTITY()
											
											update t set t.ProcessingErrorDesc = @reversedatestring + ' REVERSED BY TRANSACTION: ' + CAST(@reversingtransactionid AS varchar(50))
											,Reversed = 1
											from StoreTransactions t
											where t.StoreTransactionID =@transactionidtoreverse
								

																		
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
														,ChainIdentifier		   
													    ,EDIRecordID
													   
													   )
												 select [ChainID]
													   ,[StoreID]
													   ,[ProductID]
													   ,@newsupplierid --[SupplierID]
													   ,16
													   ,[ProductPriceTypeID]
													   ,[BrandID]
													   ,[Qty]
													   ,@correctsetupcost --[SetupCost]
													   ,@currentretail --[SetupRetail]
													   ,[SaleDateTime]
													   ,[UPC]
													   ,[ReportedCost]
													   ,[ReportedRetail]
													   ,@correctsetupcost --[RuleCost]
													   ,@currentretail --[RuleRetail]
													   ,0 --[CostMisMatch]
													   ,0 --[RetailMisMatch]
													   ,null --case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
													   ,null --[RuleRetail] --case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
													   ,Case when SupplierID = 0 and round(@correctsetupcost,2) = round(RuleCost,2) and round(@currentretail,2) = round(RuleRetail,2) then 3 
															when SupplierID <> 0 and round(@correctsetupcost,2) = round(RuleCost,2) and round(@currentretail,2) = round(RuleRetail,2) then 5 
														else 4 end
													   ,[InvoiceID]
													   ,[LastUpdateUserID]
													   ,[WorkingTransactionID]													   													   

													   ,[ReportedAllowance]
													   ,[ReportedPromotionPrice]
													   ,StoreIdentifier
														,StoreName
														,ProductQualifier
														,RawProductIdentifier
														,@newsuppliername --(select SupplierName from suppliers where supplierid = @newsupplierid) --SupplierName
														,@newsupplieridentifier --(select SupplierIdentifier from suppliers where supplierid = @newsupplierid) --SupplierIdentifier
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
														,RecordType		   
													    ,ChainIdentifier
													    ,EDIRecordID
													   
													   from StoreTransactions
													where StoreTransactionID = @transactionidtoreverse
													
			commit transaction

						--update Import.dbo.tmpAdjustments20111213_1211 set Processed = 1 where recordid = @recordid									
													
						fetch next from @rec into 
							--@recordid
							@transactionidtoreverse
							,@correctsetupcost
							,@correctpromoallowance
							,@newsupplierid
							,@newsuppliername
							,@newsupplieridentifier
							,@currentretail
					end
					
			close @rec
			deallocate @rec									
													
--*/													
--truncate table DataTrue_Main.dbo.Temp_POS_Adjustments
		
		
		
		
--****************************************************************************	

		--commit transaction

/*
select processingErrorDesc, *
from storetransactions with (nolock)
where 1 = 1
and storetransactionid in 
(379381969,
379386016) -- REVERSED BY TRANSACTION: 379386016

select * from storetransactions
where 1 = 1
and storeid = 74671
and productid = 3480512
and cast(saledatetime as date) = '5/17/2014'

74628	74671	3480512	24782 5/17/2014

select *
from productprices
where storeid = 74671
and productid = 3480512

select processingErrorDesc, *
from storetransactions
where 1 = 1
--and chainid = 60624
--and cast(datetimecreated as date) = '4/22/2014'
--and transactiontypeid = 16
and reversed = 1
and processingErrorDesc like '%20140519%'
order by storetransactionid desc

select processingErrorDesc, *
--update t set t.processingErrorDesc = null, reversed = 0
from storetransactions t
where 1 = 1
--and chainid = 60624
--and cast(datetimecreated as date) = '4/22/2014'
--and transactiontypeid = 16
and reversed = 1
and processingErrorDesc like '%20140519%'
order by storetransactionid desc

select processingErrorDesc, *
--delete
from storetransactions 
where 1 = 1
--and chainid = 60624
and cast(datetimecreated as date) = '5/19/2014'
and transactiontypeid in (7,16)
and processingErrorDesc like '%20140519%'
order by storetransactionid desc

SELECT *
--update d set d.ProductIdentifier = d.rawproductidentifier, d.ProductQualifier = ''
FROM invoicedetails d
where chainid = 60624
and invoicedetailtypeid = 7
--and cast(datetimecreated as date) = '4/22/2014'
and retailerinvoiceid is null


Select cast(datetimecreated as date), count(storetransactionid)
from storetransactions with (nolock)
where transactiontypeid = 16
group by cast(datetimecreated as date)
order by cast(datetimecreated as date) desc

Select cast(datetimecreated as date), cast(saledatetime as date), count(storetransactionid)
from storetransactions with (nolock)
where transactiontypeid = 16
group by cast(datetimecreated as date), cast(saledatetime as date)
order by cast(datetimecreated as date) desc, cast(saledatetime as date) desc

Select cast(datetimecreated as date), chainid, count(storetransactionid)
from storetransactions with (nolock)
where transactiontypeid = 16
group by cast(datetimecreated as date), chainid
order by cast(datetimecreated as date) desc
*/


return
GO
