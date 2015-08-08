USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_Run_20120131_Without_Bashas_BetweenDates]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_Run_20120131_Without_Bashas_BetweenDates]
as
/*
************************************************************
--Several updates below by C&M on 20120314
--**********************************************************
select * from zztemp_ADJs_Look
select sum(qty * ((CurrentCost - CurrentPromoAllowance) - (rulecost - promoallowance)))
from zztemp_ADJs_Look
*/
declare @startdate date= dateadd(month, -4, getdate()) --'12/1/2011'
declare @enddate date= getdate()
--declare @enddate date=cast(dateadd(day,-1,getdate()) as date)
declare @currentdate date
declare @dummy bit
declare @reversedatestring nvarchar(50)

set @reversedatestring = 'SBTb-' + cast(year(getdate()) as varchar) + case when len(cast(month(getdate()) as varchar)) = 1 then '0' + cast(month(getdate()) as varchar) else cast(month(getdate()) as varchar) end + case when len(cast(day(getdate()) as varchar)) = 1 then '0' + cast(day(getdate()) as varchar) else cast(day(getdate()) as varchar) end

--update t set rulecost = p.UnitPrice, ruleretail = p.UnitRetail
--from storetransactions t
--inner join productprices p
--on t.storeid = p.storeid
--and t.productid = p.productid
--and t.supplierid = p.supplierid
--and t.saledatetime between p.ActiveStartDate and p.ActiveLastDate
--and p.ProductPriceTypeID = 3
--and (t.rulecost = 0 or t.rulecost is null)
--and cast(t.saledatetime as date) >= cast(@startdate as date)
----and t.saledatetime > dateadd(day, -90, getdate())
--and t.transactiontypeid in (2,6)
--and isnull(t.reversed, 0) <> 1
--and t.transactionstatus in (0, 2)

set @currentdate = @startdate
	
		--begin transaction
		
		begin try
			DROP TABLE #temptransactions
		end try
		begin catch
			set @dummy = 0
		end catch	
		
		select t.chainid, storetransactionid, cast(UnitPrice as DECimal(12,2)) As CurrentCost, 
		cast(0 as DECimal(12,2)) as CurrentPromoAllowance,
		cast(Setupcost as DECimal(12,2)) as Setupcost, cast(PromoAllowance as DECimal(12,2)) as PromoAllowance, 
		cast(RuleCost as DECimal(12,2)) as RuleCost, 
		cast(ReportedCost as DECimal(12,2)) as ReportedCost, cast(ReportedAllowance as DECimal(12,2)) as ReportedAllowance, 
		CAST(0 as smallint) as NeedAdjustment,
		cast(t.saledatetime as date) as SaleDate, CAST(0 as smallint) as Processed,
		getdate() as datetimecreated, t.SupplierID, 
		p.SupplierID as NewSupplierID, cast('' as varchar(50)) as newsuppliername, cast('' as varchar(50)) as newsupplieridentifier,
		cast(UnitRetail as DECimal(12,2)) As CurrentRetail, t.productid, t.StoreID, t.Qty
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
		--and cast(t.RuleCost as DECimal(12,2)) <> cast(p.UnitPrice as DECimal(12,2)) --Flaw Bug this prevents promotion changes from being seen if cost remains the same
		--and t.ChainID in (40393)
		--and t.ChainID in (60624,74628)
		and t.ChainID not in (60620)
		and t.ProductID not in (select ProductID from productidentifiers where productidentifiertypeid = 8)
		--and t.productid = 3566792
		--and t.storeid in (76225, 76226)		
		--and t.SupplierID = 74813
		--and t.Productid = 7318   
		--and t.SupplierID not in (40559)
		--and t.ChainID not in (select EntityIDToInclude from ProcessStepEntities where ltrim(rtrim(ProcessStepName)) in ('prUtil_Price_Corrections_Adjustments_Newspapers','prGetInboundPOSTransactions_Newspapers','prGetInboundPOSTransactions_PDI_Newspapers'))				
		--and t.ChainID in (select EntityIDToInclude from ProcessStepEntities where ltrim(rtrim(ProcessStepName)) in ('prUtil_Price_Corrections_Adjustments_Newspapers','prGetInboundPOSTransactions_Newspapers','prGetInboundPOSTransactions_PDI_Newspapers'))		
		--and t.ChainID in (select EntityIDToInclude from ProcessStepEntities where ProcessStepName = 'prUtil_Price_Corrections_Adjustments_Run_20120131_Without_Bashas')
		--and t.ChainID not in (64010, 65151, 65232, 62362,60624, 74628)
		--and t.ChainID not in (62362, 60620)
		--and t.SupplierID <> 40558
		--and t.StoreID in 
		--(Select MemberEntityID
		--		From Memberships
		--		where OrganizationEntityID = 63464)
		and t.StoreID in (select StoreID from stores where Custom3 = 'SS')
		--and t.Productid not in (31018, 3488939 )		


--and t.storeid in
--(
--select storeid
--from costzonerelations
--where costzoneid = 1839
--)
--and t.productid in 
----(3480006,
----3480056) 
--(3480252,
--3480006,
--3480271,
--3480056)
--and CAST(saledatetime as date) >= '9/23/2013'
		
		update  a set a.CurrentPromoAllowance = p.UnitPrice
		from #temptransactions a
		inner join StoreTransactions t
		on a.storetransactionid = t.storetransactionid
		inner join ProductPrices p
		on t.StoreID = p.StoreID
		and t.ProductID = p.ProductID
		--and t.BrandID = p.BrandID
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

			------------------------------20140829------------------------------------------delete from #temptransactions where NeedAdjustment = 0 and SaleDate = @currentdate
			
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

			update a set a.NewSupplierName = left(s.SupplierName, 50), a.NewSupplierIdentifier = left(s.SupplierIdentifier, 50)
			from #temptransactions a
			inner join DataTrue_Main.dbo.Suppliers s
			on a.newsupplierID = s.SupplierID

			begin try
				drop table zztemp_ADJs_Look
			end try
			begin catch
				set @dummy = 0
			end catch

			select * into zztemp_ADJs_Look
			from #temptransactions
			where NeedAdjustment = 1
			and Processed = 0
			order by Saledate
			
			select sum(qty * ((CurrentCost - CurrentPromoAllowance) - (rulecost - promoallowance)))
			from zztemp_ADJs_Look

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
			
			--set @rec = CURSOR local fast_forward FOR
			select *
			--select storetransactionid, currentcost, currentpromoallowance, newsupplierid, newsuppliername, newsupplieridentifier, CurrentRetail
			
			--select storetransactionid, currentcost, currentpromoallowance
				from #temptransactions
				where NeedAdjustment = 1
				and Processed = 0
				order by Saledate

			/*
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
														,0		   
																   
													   
													   
													   
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
													   ,@currentretail --[SetupRetail]
													   ,[SaleDateTime]
													   ,[UPC]
													   ,[ReportedCost]
													   ,[ReportedRetail]
													   ,@correctsetupcost --[RuleCost]
													   ,@currentretail --[RuleRetail]
													   ,0 --[CostMisMatch]
													   ,0 --[RetailMisMatch]
													   ,@correctsetupcost --case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
													   ,@currentretail --[RuleRetail] --case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
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
														,0		   
													   
													   
													   
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
													
drop table #temptransactions													

--*/		
		
		
		
--****************************************************************************	

		--commit transaction
			
/*
select * from storetransactions where transactiontypeid in (7,16) and cast(datetimecreated as date) = '8/29/2014'
select * from invoicedetails where chainid = 60620 and invoicedetailid = 7 order by retailerinvoiceid
select * from invoicedetails with (nolock) where chainid = 60620
*/



return
GO
