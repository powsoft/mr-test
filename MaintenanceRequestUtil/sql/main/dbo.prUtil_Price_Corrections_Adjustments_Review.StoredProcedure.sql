USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Price_Corrections_Adjustments_Review]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Price_Corrections_Adjustments_Review]
as


--12/1

select t.supplierid, t.banner, a.* 
--update a set a.NeedAdjustment = 1
from Import.dbo.tmpAdjustments20111213 a
inner join StoreTransactions t
on a.storetransactionid = t.StoreTransactionID
and t.TransactionTypeID = 2
where CurrentCost is not null 
and a.NeedAdjustment = 1
and a.rulecost - a.promoallowance <> a.reportedcost
and t.Banner = 'SS'


--12/2

select t.supplierid, t.banner, a.* 
--update a set a.NeedAdjustment = 1
from Import.dbo.tmpAdjustments20111213_1202 a
inner join StoreTransactions t
on a.storetransactionid = t.StoreTransactionID
and t.TransactionTypeID = 2
where CurrentCost is not null 
and a.NeedAdjustment <> 1
and a.rulecost - a.promoallowance <> a.reportedcost
and t.Banner = 'SS'

--12/3

select t.supplierid, t.banner, a.* 
--update a set a.NeedAdjustment = 1
from Import.dbo.tmpAdjustments20111213_1203 a
inner join StoreTransactions t
on a.storetransactionid = t.StoreTransactionID
and t.TransactionTypeID = 2
where CurrentCost is not null 
and a.NeedAdjustment <> 1
and a.rulecost - a.promoallowance <> a.reportedcost
and t.Banner = 'SS'





--pull base record data
select storetransactionid, cast(UnitPrice as DECimal(12,2)) As CurrentCost, 
cast(0 as DECimal(12,2)) as CurrentPromoAllowance,
cast(Setupcost as DECimal(12,2)) as Setupcost, cast(PromoAllowance as DECimal(12,2)) as PromoAllowance, 
cast(RuleCost as DECimal(12,2)) as RuleCost, 
cast(ReportedCost as DECimal(12,2)) as ReportedCost, cast(ReportedAllowance as DECimal(12,2)) as ReportedAllowance, 
CAST(0 as smallint) as NeedAdjustment,
cast(t.saledatetime as date) as SaleDate, CAST(0 as smallint) as Processed
into Import.dbo.tmpAdjustments20111213_1211
from StoreTransactions t
left join ProductPrices p
on t.StoreID = p.StoreID
and t.ProductID = p.ProductID
and t.BrandID = p.BrandID
and t.SupplierID = p.SupplierID
and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
and p.ProductPriceTypeID = 3
where CAST(t.saledatetime as date) = '12/11/2011'

/*
--populate Current Allowance
--alter table Import.dbo.tmpAdjustments20111213 add banner nvarchar(50)
--update Import.dbo.tmpAdjustments20111213 set Import.dbo.tmpAdjustments20111213.banner = t.banner from storetransactions t where t.storetransactionid = Import.dbo.tmpAdjustments20111213.storetransactionid
select top 1000 * from Import.dbo.tmpAdjustments20111213 where setupcost is null and ltrim(rtrim(banner)) <> 'SS' and rulecost <> reportedcost

select top 10 * from storetransactions order by storetransactionid desc
*/

select *
--update  a set a.CurrentPromoAllowance = p.UnitPrice
from Import.dbo.tmpAdjustments20111213_1211 a
inner join StoreTransactions t
on a.storetransactionid = t.storetransactionid
inner join ProductPrices p
on t.StoreID = p.StoreID
and t.ProductID = p.ProductID
and t.BrandID = p.BrandID
and t.SupplierID = p.SupplierID
and p.productpricetypeid = 8
and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate

select * from Import.dbo.tmpAdjustments20111213_1207 where currentpromoallowance > 0
select * from Import.dbo.tmpAdjustments20111213_1207 where NeedAdjustment = 1

select * 
--update a set a.NeedAdjustment = 1
from Import.dbo.tmpAdjustments20111213_1211 a
where CurrentCost is not null 
and CurrentCost - CurrentPromoAllowance <> rulecost - promoallowance
and CurrentCost - CurrentPromoAllowance = ReportedCost

declare @rec cursor
declare @recordid bigint
declare @transactionidtoreverse bigint
declare @correctsetupcost money
declare @correctpromoallowance money
declare @reversingtransactionid bigint

set @rec = CURSOR local fast_forward FOR
	select recordid, storetransactionid, currentcost, currentpromoallowance
	from Import.dbo.tmpAdjustments20111213_1211
	where NeedAdjustment = 1
	and Processed = 0


open @rec

fetch next from @rec into 
		@recordid
		,@transactionidtoreverse
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
										   ,16
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
										
			update Import.dbo.tmpAdjustments20111213_1211 set Processed = 1 where recordid = @recordid									
										
			fetch next from @rec into 
				@recordid
				,@transactionidtoreverse
				,@correctsetupcost
				,@correctpromoallowance
		
		end
		
close @rec
deallocate @rec									
										
										















/*
and SetupCost is not null
and RuleCost - PromoAllowance <> ReportedCost

select UnitPrice, Setupcost, RuleCost, PromoAllowance, ReportedCost, ReportedAllowance, *
from StoreTransactions t
inner join ProductPrices p
on t.StoreID = p.StoreID
and t.ProductID = p.ProductID
and t.BrandID = p.BrandID
and t.SupplierID = p.SupplierID
and CAST(t.saledatetime as date) between p.ActiveStartDate and p.ActiveLastDate
and p.ProductPriceTypeID = 3
where CAST(t.saledatetime as date) = '12/1/2011'
and SetupCost is null
and RuleCost - PromoAllowance <> ReportedCost


and SetupCost <> Unitprice

*/







return
GO
