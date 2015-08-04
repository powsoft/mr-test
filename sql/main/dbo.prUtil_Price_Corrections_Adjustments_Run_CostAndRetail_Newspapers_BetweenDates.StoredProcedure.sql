USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_Run_CostAndRetail_Newspapers_BetweenDates]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_Run_CostAndRetail_Newspapers_BetweenDates]
as
/*
************************************************************
--Several updates below by C&M on 20120314
--**********************************************************
*/
declare @startdate date= dateadd(month, -4, getdate()) --'12/1/2011'
declare @enddate date= dateadd(day, -2, getdate())
--declare @enddate date=cast(dateadd(day,-1,getdate()) as date)
declare @currentdate date
declare @dummy bit
declare @reversedatestring nvarchar(50)

set @reversedatestring = 'NewsPaper_2' + cast(year(getdate()) as varchar) + case when len(cast(month(getdate()) as varchar)) = 1 then '0' + cast(month(getdate()) as varchar) else cast(month(getdate()) as varchar) end + case when len(cast(day(getdate()) as varchar)) = 1 then '0' + cast(day(getdate()) as varchar) else cast(day(getdate()) as varchar) end

--update t set rulecost = p.UnitPrice, ruleretail = p.UnitRetail
--from storetransactions t
--inner join productprices p
--on t.storeid = p.storeid
--and t.productid = p.productid
--and t.supplierid = p.supplierid
--and t.saledatetime between p.ActiveStartDate and p.ActiveLastDate
--and p.ProductPriceTypeID = 3
--and (t.rulecost = 0 or t.rulecost is null)
--and t.saledatetime > dateadd(day, -90, getdate())
--and t.transactiontypeid in (2,6)
--and isnull(t.reversed, 0) <> 1
--and t.transactionstatus in (0, 2)
/*
select * from storetransactions where storeid = 62371 and productid = 39440 and cast(saledate as date) = '3/22/2014'
*/

set @currentdate = @startdate
	
		--begin transaction
		
		begin try
			DROP TABLE #temptransactions
		end try
		begin catch
			set @dummy = 0
		end catch	
		
		select t.upc, t.chainid, t.storeid, t.productid, t.supplierid, storetransactionid, cast(UnitPrice as DECimal(12,2)) As CurrentCost, 
		cast(0 as DECimal(12,2)) as CurrentPromoAllowance,
		cast(Setupcost as DECimal(12,2)) as Setupcost, cast(PromoAllowance as DECimal(12,2)) as PromoAllowance, 
		cast(RuleCost as DECimal(12,2)) as RuleCost, 
		cast(ReportedCost as DECimal(12,2)) as ReportedCost, cast(ReportedAllowance as DECimal(12,2)) as ReportedAllowance, 
		CAST(0 as smallint) as NeedAdjustment,
		cast(t.saledatetime as date) as SaleDate, CAST(0 as smallint) as Processed,
		getdate() as datetimecreated,
		p.SupplierID as NewSupplierID, '' as Char1, '' as Char2, 
		cast(RuleRetail as DECimal(12,2)) As RuleRetail, cast(UnitRetail as DECimal(12,2)) As CurrentRetail, Qty
		into #temptransactions
		from StoreTransactions t
		left join ProductPrices p
		on t.StoreID = p.StoreID
		and t.ProductID = p.ProductID
		--and t.BrandID = p.BrandID
		and t.SupplierID = p.SupplierID
		and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
		and p.ProductPriceTypeID = 3
		--added to prevent records with no current unit cost on 20120314 by C&M
		and p.UnitPrice is not null
		where t.transactiontypeid in (2, 6, 16)
		and t.Reversed = 0
		--and CAST(t.saledatetime as date) = @currentdate
		and CAST(t.saledatetime as date) Between @startdate and @enddate
		--and t.StoreID = 78610 and t.ProductID = 37698 and t.SupplierId = 28792
		--and t.ChainID in (select EntityIDToInclude from ProcessStepEntities where ltrim(rtrim(ProcessStepName)) in ('prUtil_Price_Corrections_Adjustments_Newspapers','prGetInboundPOSTransactions_Newspapers','prGetInboundPOSTransactions_PDI_Newspapers'))		
		--and t.ChainID in (62362) --40393)
		--and t.ChainID in (60624,74628) --,60634)
		--and t.ChainID not in (60624) --64010) --42490, 64010, 62362) --, 65232) --, 62362)
		--and t.ChainID in (74628)
		--and t.ChainID not in (62362)		
		--and t.ChainID in (42490)
		--and ltrim(rtrim(t.upc)) = '780939000073'
		--and t.ChainID in (60624,74628)
		--and t.ChainID in (60624,74628)
		--and t.chainid not in (62362, 63613, 63614, 60626, 42490)
		--and t.SupplierID not in  (50726,74813)
		--and p.SupplierID not in  (50726,74813)
		and t.ProductID in (select distinct ProductID from ProductIdentifiers where ProductIdentifierTypeID = 8)
		--and t.ChainID in (select EntityIDToInclude from ProcessStepEntities where ProcessStepName = 'prUtil_Price_Corrections_Adjustments_Run_20120131_Without_Bashas')
		--and t.ChainID not in (64010, 65151, 65232, 62362,60624, 74628)
		--and t.ChainID not in (64010) --62362, 60620)
		--and t.SupplierID not in (26188,25712)
		--and t.StoreID in 
		--(select StoreID from stores where Custom1 = 'Shop N Save Warehouse Foods Inc')
		--and t.StoreID in (select StoreID from stores where Custom3 = 'SS')
		--and t.Productid in (38027)	
		--and t.StoreId = 62408
		--and p.ProductID = 38547
		--and t.productid = 38883
		--and cast(t.saledatetime as date) = '7/16/2014'	


--select * from #temptransactions		
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

			update a set a.NeedAdjustment = 1
			from #temptransactions a
			where CurrentCost is not null 
--and CurrentCost - CurrentPromoAllowance <> rulecost - promoallowance
--and CurrentCost - CurrentPromoAllowance = ReportedCost
			and (
			isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) <> isnull(rulecost, 0.00) - isnull(promoallowance, 0.00)
			or
			(ISNULL(CurrentRetail, 0.00) <> ISNULL(RuleRetail, 0.00) and ISNULL(CurrentRetail, 0.00) <> 0)
			)
			
			--and isnull(CurrentCost, 0.00) - isnull(CurrentPromoAllowance, 0.00) = isnull(ReportedCost, 0.00)
			--and isnull(RuleCost, 0.00) - isnull(promoallowance, 0.00) <> isnull(ReportedCost, 0.00)

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

			delete from #temptransactions where NeedAdjustment = 0 --and SaleDate = @currentdate
			
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

			select distinct ProductID, UPC
				from #temptransactions
				where NeedAdjustment = 1
				and Processed = 0

select SUM(qty*(CurrentCost - RuleCost)) as CostDiff, SUM(qty * CurrentRetail * .03) - SUM(qty * RuleRetail * .03) as FeeDiff
				from #temptransactions
				where NeedAdjustment = 1
				and Processed = 0

--/*
			declare @rec cursor
			declare @recordid bigint
			declare @transactionidtoreverse bigint
			declare @correctsetupcost money
			declare @correctsetupretail money
			declare @correctpromoallowance money
			declare @reversingtransactionid bigint

			--set @rec = CURSOR local fast_forward FOR
			select distinct saledate sdate, RuleCost, CurrentCost, RuleRetail, CurrentRetail,UPC,*
			----select distinct ChainID, SaleDate, StoreID, productid, storetransactionid, currentcost, currentpromoallowance, CurrentRetail
			--select distinct storetransactionid, currentcost, currentpromoallowance, CurrentRetail
				from #temptransactions
				where NeedAdjustment = 1
				and Processed = 0
--order by Saledate
				--order by ChainID, SaleDate, StoreID, productid

			/*
			open @rec

			fetch next from @rec into 
					--@recordid
					@transactionidtoreverse
					,@correctsetupcost
					,@correctpromoallowance
					,@correctsetupretail
					
			while @@FETCH_STATUS = 0
				begin
								
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
														 ,edirecordid  
													   
													   
													   
													   
													   
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
													   ,4 --362638 --[SourceID]
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
														,edirecordid		   
													   
													   
													   
													   from StoreTransactions
													where StoreTransactionID = @transactionidtoreverse
													
											set @reversingtransactionid = SCOPE_IDENTITY()
											
											update t set t.ProcessingErrorDesc = @reversedatestring + ' - REVERSED BY TRANSACTION: ' + CAST(@reversingtransactionid AS varchar(50))
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
													   ,edirecordid
													   
													   )
												 select [ChainID]
													   ,[StoreID]
													   ,[ProductID]
													   ,[SupplierID]
													   ,16
													   ,[ProductPriceTypeID]
													   ,[BrandID]
													   ,[Qty]
													   ,@correctsetupcost --[SetupCost]
													   ,@correctsetupretail --[SetupRetail]
													   ,[SaleDateTime]
													   ,[UPC]
													   ,[ReportedCost]
													   ,[ReportedRetail]
													   ,@correctsetupcost --[RuleCost]
													   ,@correctsetupretail --[RuleRetail]
													   ,0 --[CostMisMatch]
													   ,0 --[RetailMisMatch]
													   ,@correctsetupcost --case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
													   ,@correctsetupretail --[RuleRetail] --case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
													   ,4 --362638 --[SourceID]
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
														,RecordType		   
													   ,edirecordid
													   
													   
													   from StoreTransactions
													where StoreTransactionID = @transactionidtoreverse
													
						--update Import.dbo.tmpAdjustments20111213_1211 set Processed = 1 where recordid = @recordid									
													
						fetch next from @rec into 
							--@recordid
							@transactionidtoreverse
							,@correctsetupcost
							,@correctpromoallowance
							,@correctsetupretail
					
					end
					
			close @rec
			deallocate @rec									
													
													

--*/		
		
		
		
--****************************************************************************	

		--commit transaction
			




return
GO
