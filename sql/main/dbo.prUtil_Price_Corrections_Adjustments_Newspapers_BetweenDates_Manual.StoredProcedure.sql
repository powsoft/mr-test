USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_Newspapers_BetweenDates_Manual]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_Newspapers_BetweenDates_Manual]
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

set @reversedatestring = 'NewsPaper_Manual_TNG_Issue_1 ' + cast(year(getdate()) as varchar) + case when len(cast(month(getdate()) as varchar)) = 1 then '0' + cast(month(getdate()) as varchar) else cast(month(getdate()) as varchar) end + case when len(cast(day(getdate()) as varchar)) = 1 then '0' + cast(day(getdate()) as varchar) else cast(day(getdate()) as varchar) end

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


			set @rec = CURSOR local fast_forward FOR
				select storetransactionid, 2.15, 0.0, 35137, 'National News-NNB', 
				'NNB', 2.50
				--select productid, *
				from storetransactions with (nolock)
				where 1 = 1
				and supplierid = 74813
				and StoreID <> 40771
				and ltrim(rtrim(upc)) in 
				('035400000633',
				'035400000732',
				'078908631411')
				and recordtype = 2
				and ProductID = 38883
				order by saledatetime
				
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
