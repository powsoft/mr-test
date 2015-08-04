USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_Newspapers]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery9.sql|7|0|C:\Users\vince.moore\AppData\Local\Temp\7\~vs38A6.sql


CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_Newspapers]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @transidtable StoretransactionIDTable
declare @newqtyadded bit

set @MyID = 7420

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'Daily Move EDI to Main'

select distinct StoreTransactionID, saledatetime
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 4
--and ChainID = 40393
and WorkingSource in ('POS')
and ChainID in (select EntityIDToInclude 
				from ProcessStepEntities 
				where ProcessStepName In ('prValidateTransactionTypeInStoreTransactions_Working_Newspapers',
										'prValidateTransactionTypeInStoreTransactions_Working_Newspapers_PDI'))
--and ProcessID = @ProcessID

declare @recremovedupes cursor
declare @remtransactionid bigint
declare @remstoreid int
declare @remproductid int
declare @rembrandid int
declare @remsaledate date
declare @curstoreid int
declare @curproductid int
declare @curbrandid int
declare @cursaledate date
declare @firstrowpassed bit
declare @dupecount int
--/*

 select storeid, productid, storeidentifier, upc, cast(w.SaleDateTime as date), ltrim(rtrim(PONO)),qty
from StoreTransactions_Working w
inner join #tempStoreTransaction t
on w.StoreTransactionID = t.StoreTransactionID
where 1 = 1
and WorkingStatus = 4
group by storeid, productid, storeidentifier, upc, cast(w.SaleDateTime as date), ltrim(rtrim(PONO)),qty
having COUNT(w.storetransactionid) > 1

if @@ROWCOUNT > 0 and 1 = 1 
	begin
set @recremovedupes = CURSOR local fast_forward FOR
	select distinct w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
	from storetransactions_working w
	inner join #tempStoreTransaction tmp
	on w.storetransactionid = tmp.storetransactionid
	where tmp.StoreTransactionID in
	(
	select storetransactionid
	from storetransactions_working w
	inner join
		(select storeid, productid, brandid, cast(saledatetime as date) as [date], qty, ltrim(rtrim(isnull(PONO, ''))) as PONO, ltrim(rtrim(isnull(SupplierInvoiceNumber, ''))) as SupplierInvoiceNumber, UPC
		from storetransactions_working
		where workingstatus = 4
		and ChainID in (select EntityIDToInclude 
				from ProcessStepEntities 
				where ProcessStepName Not In ('prValidateTransactionTypeInStoreTransactions_Working_Newspapers_PDI'))
		group by storeid, productid, brandid, cast(saledatetime as date), qty, ltrim(rtrim(isnull(PONO, ''))), ltrim(rtrim(isnull(SupplierInvoiceNumber, ''))), UPC
		having count(storetransactionid) > 1) s
	on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date) and w.Qty = s.qty and ltrim(rtrim(isnull(w.SupplierInvoiceNumber, ''))) = ltrim(rtrim(isnull(s.SupplierInvoiceNumber, ''))) and ltrim(rtrim(isnull(w.PONO, ''))) = ltrim(rtrim(isnull(s.PONO, ''))) and ltrim(rtrim(isnull(w.UPC, ''))) = ltrim(rtrim(isnull(s.UPC, '')))
	)
	order by w.storeid
		,w.productid
		,w.brandid
		,cast(w.saledatetime as date)
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate
										
	while @@FETCH_STATUS = 0
		begin

			delete from #tempStoreTransaction
			where StoreTransactionID in
			(
				select StoreTransactionID from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and CAST(saledatetime as DATE) =  @remsaledate
				and WorkingStatus = 4
			 )
			and StoreTransactionID not in
			(
				select top 1 StoreTransactionID from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and CAST(saledatetime as DATE) =  @remsaledate
				and WorkingStatus = 4
				order by StoreTransactionID
			 )
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@remsaledate	

		end
		
	close @recremovedupes
	deallocate @recremovedupes
--******************Remove Dupes End**********************************
	end --@@rowcount > 0

insert @transidtable
select StoreTransactionID from #tempStoreTransaction


begin transaction

set @loadstatus = 5

update t set t.TransactionTypeID = 2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID

--***************Promo Lookup Start**************************

update t set t.PromoAllowance = p.UnitPrice,
t.PromoTypeID = P.ProductPriceTypeID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where p.ProductPriceTypeID in 
(8, 9, 10)
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

----***************Cost Lookup Start**************************

----First look for exact match for all entities
--update t set t.SetupCost = p.UnitPrice,
--t.SetupRetail = p.UnitRetail,
--t.ProductPriceTypeID = p.ProductPriceTypeID
--from #tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
--inner join [dbo].[ProductPrices] p
--on t.ProductID = p.ProductID 
--and t.BrandID = p.BrandID
--and t.ChainID = p.ChainID 
--and t.StoreID = p.StoreID 
--and t.SupplierID = p.SupplierID 
--where t.SetupCost is null
--and p.ProductPriceTypeID in (3)
--and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate


----update CostMisMatch
--update t set t.CostMisMatch = 1
--from #tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
--where t.SetupCost <> t.ReportedCost
--or t.SetupCost is null or t.ReportedCost is null
----or (t.SetupCost is null and t.ReportedCost is null)

----update RetailMisMatch
--update t set t.RetailMisMatch = 1
--from #tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
--where t.SetupRetail <> t.ReportedRetail
--or t.SetupRetail is null or t.ReportedRetail is null

--***************Cost Lookup End****************************

exec prApplyCostRules_Newspapers @transidtable, 1 --1=POS, 2=SUP, 3=INV

exec [dbo].[prApplySupplierRules_NewsPapers] @transidtable, 1 --1=POS, 2=SUP, 3=INV

		DECLARE @storetransactionsids TABLE (storetransactionID int);
if 1 = 1
	begin
			
		select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, ProcessingErrorDesc, PONo, Reversed, CAST(4 as int) as Workingstatus, qty, UPC
		into #tempsup		
		from DataTrue_Main.dbo.StoreTransactions_Working w
		where charindex('POS', WorkingSource) > 0
		and WorkingStatus = 4
		and ProcessID = @ProcessID

		select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, ProcessingErrorDesc, PONo, Reversed, qty, UPC
		into #tempsup2
		from DataTrue_Main.dbo.StoreTransactions
		where 1 = 1
		and TransactionTypeID in (2, 6)
		and CAST(SaleDateTime as date) in 
		(select distinct CAST(SaleDateTime as date) from #tempsup)	
		and ProcessID = @ProcessID
	
		update t set t.ProcessingErrorDesc=ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))
		OUTPUT INSERTED.ProcessingErrorDesc INTO @storetransactionsids
		from #tempsup2 t join
		(select w.* from #tempsup w join #tempStoreTransaction tmp
		on w.StoreTransactionID=tmp.StoreTransactionID ) s
		on t.StoreID = s.StoreID 
		and t.ProductID = s.ProductID
		and t.BrandID = s.BrandID
		and DATEDIFF(D,t.SaleDateTime,s.SaleDateTime)=0
		and t.TransactionTypeID in (2, 6, 16)
		and isnull(t.PoNo, '') = isnull(s.PONO, '')
		and t.Reversed = 0
		and cast(s.saledatetime as date) < cast(DATEADD(day,-1,getdate()) as date)
		and t.Qty = s.qty
		and LTRIM(rtrim(t.UPC)) = LTRIM(rtrim(s.UPC))
		
		update t set t.ProcessingErrorDesc = tmp.ProcessingErrorDesc
		from #tempsup2 tmp
		inner join storetransactions t
		on tmp.StoreTransactionID = t.StoreTransactionID
		and tmp.ProcessingErrorDesc is not null
		
		drop table #tempsup
		drop table #tempsup2
	end		
		
		 INSERT into StoreTransactions
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
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[RuleCost]
           ,[RuleRetail]
           ,[CostMisMatch]
           ,[RetailMisMatch]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[LastUpdateUserID]
           ,[WorkingTransactionID]
           ,[TrueCost]
           ,[TrueRetail]
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
           ,ProcessID)
		select 
		   S.[ChainID]
		   ,S.[StoreID]
           ,S.[ProductID]
           ,S.[SupplierID]
           ,s.[TransactionTypeID]
           --,case when S.[WorkingSource] = 'POS' then 2 when S.[WorkingSource] = 'SUP' then 5 else 0 end 
           ,S.[ProductPriceTypeID]
           ,S.[BrandID]
           ,S.[Qty]
           ,S.[SetupCost]
           ,S.[SetupRetail]
           ,S.[SaleDateTime]
           ,S.[UPC]
           ,S.[SupplierInvoiceNumber]
           ,S.[ReportedCost]
           ,S.[ReportedRetail]
           ,S.[RuleCost]
           ,S.[RuleRetail]
           ,S.[CostMisMatch]
           ,S.[RetailMisMatch]
           ,0
           ,0
           ,S.[ProcessingErrorDesc]
           ,S.[SourceID]
           ,S.[Comments]
           ,S.[InvoiceID]
           ,@MyID
           ,S.[StoreTransactionID]
           ,case when S.[CostMisMatch] = 0 then S.[SetupCost] else S.[TrueCost] end
           ,case when S.[RetailMisMatch] = 0 then S.[SetupRetail] else S.[TrueRetail] end
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,S.StoreIdentifier
           ,S.StoreName
           ,S.ProductQualifier
           ,S.RawProductIdentifier
           ,S.SupplierName
           ,S.SupplierIdentifier
           ,S.BrandIdentifier
           ,s.DivisionIdentifier
           ,s.UOM
           ,s.SalePrice
           ,s.InvoiceNo
           ,s.PONo
           ,s.CorporateName
           ,s.CorporateIdentifier
           ,s.Banner
           ,s.PromoTypeID
           ,s.PromoAllowance
           ,s.SBTNumber
           ,@ProcessID
           from StoreTransactions_Working s join #tempStoreTransaction tmp
           on s.StoreTransactionID=tmp.StoreTransactionID
           and tmp.StoreTransactionID not in (select storetransactionID from @storetransactionsids)

		commit transaction


delete from CDCControl where ProcessID = @MyID
	
declare @rec cursor
declare @workingtransactionidstring nvarchar(100)
declare @transactionid bigint
declare @relatedcount smallint
declare @existingpostransactionupdatelimitstring nvarchar(10)
declare @existingpostransactionupdatelimit tinyint
declare @oldsetupcost money
declare @oldsetupretail money
declare @oldreportedcost money
declare @oldreportedretail money
declare @oldqty int
declare @oldsupplierid int
declare @newsetupcost money
declare @newsetupretail money
declare @newreportedcost money
declare @newreportedretail money
declare @newqty int
declare @newsupplierid int
declare @reversingtransactionid bigint
declare @lastprocessingerrordesc nvarchar(255)

set @rec = CURSOR local fast_forward FOR

	select t.StoreTransactionID, t.ProcessingErrorDesc,
	isnull(t.SetupCost,0), isnull(t.SetupRetail,0), isnull(t.ReportedCost,0), isnull(t.ReportedRetail,0),
	t.Qty, t.SupplierID
	from StoreTransactions t
	inner join #tempStoreTransaction tmp
	on cast(t.ProcessingErrorDesc as bigint) = tmp.StoreTransactionID
	where len(t.ProcessingErrorDesc) > 0
	and isnumeric(t.ProcessingErrorDesc) > 0
	
open @rec

fetch next from @rec into @transactionid
	,@workingtransactionidstring
	,@oldsetupcost
	,@oldsetupretail
	,@oldreportedcost
	,@oldreportedretail
	,@oldqty
	,@oldsupplierid


if @@FETCH_STATUS = 0
	begin
		select @existingpostransactionupdatelimitstring = v.AttributeValue
		from AttributeDefinitions d
		inner join AttributeValues v
		on d.AttributeID = v.AttributeID
		where d.AttributeName = 'ExistingPOSTransactionUpdateLimit'
		
		set @existingpostransactionupdatelimit = cast(@existingpostransactionupdatelimitstring as tinyint)

	end

set @lastprocessingerrordesc = ''

while @@FETCH_STATUS = 0
	begin
	
	if @workingtransactionidstring <> @lastprocessingerrordesc
	begin
	begin transaction
		set @newqtyadded = 0
		set @relatedcount = 0
		
		select @relatedcount = COUNT(StoreTransactionID) from RelatedTransactions where StoreTransactionID = @transactionid
		
		If @relatedcount < @existingpostransactionupdatelimit
			begin

				INSERT INTO [dbo].[RelatedTransactions]
						   ([WorkingTransactionID]
						   ,[StoreTransactionID]
						   ,[Status]
						   ,[RelationshipTypeID])
					 VALUES
						   (CAST(@workingtransactionidstring as bigint)
						   ,@transactionid
						   ,0 --<Status, smallint,>
						   ,1)
					   
				select @newsetupcost = isnull(setupcost,0)
						,@newsetupretail = isnull(setupretail,0)
						,@newreportedcost = isnull(reportedcost,0)
						,@newreportedretail = isnull(reportedretail,0)
						,@newqty = isnull(qty,0)
						,@newsupplierid = isnull(supplierid,0)
				from StoreTransactions_Working
				where StoreTransactionID = CAST(@workingtransactionidstring as bigint)
				
				if @newsetupcost = @oldsetupcost
						and @newsetupretail = @oldsetupretail
						and @newreportedcost = @oldreportedcost
						and @newreportedretail = @oldreportedretail
						--and @newqty = @oldqty
						and @newsupplierid = @oldsupplierid	
					begin
						if @newqty <> @oldqty --Qty to add to saledate
							begin
								set @newqtyadded = 1
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
											,ProcessID	
											,ProductIdentifier									   
										   )
									 select Top 1 [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,6 --Updated POS transaction
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
										   ,case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
										   ,case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,CAST(@workingtransactionidstring as bigint)
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
										   ,@ProcessID
										   ,UPC
										   from StoreTransactions_Working w
										where w.StoreTransactionID = CAST(@workingtransactionidstring as bigint)
										
								update t set t.ProcessingErrorDesc = ''
								from StoreTransactions t
								where t.StoreTransactionID = @transactionid							
							end
						else --exact duplicate
							begin
								update t set t.ProcessingErrorDesc = ''
								from StoreTransactions t
								where t.StoreTransactionID = @transactionid
								
								update StoreTransactions_Working set WorkingStatus = -6 where StoreTransactionID = CAST(@workingtransactionidstring as bigint)
							end
					
					end			   
						   
				if (@newsetupcost <> @oldsetupcost
						or @newsetupretail <> @oldsetupretail
						or @newreportedcost <> @oldreportedcost
						or @newreportedretail <> @oldreportedretail
						or @newsupplierid <> @oldsupplierid)
						and @newqtyadded = 0	
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
													   
										   
										   
										   )
									 select [ChainID]
										   ,[StoreID]
										   ,[ProductID]
										   ,[SupplierID]
										   ,6 --16
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
										   ,case when [CostMisMatch] = 0 then [SetupCost] else [TrueCost] end
										   ,case when [RetailMisMatch] = 0 then [SetupRetail] else [TrueRetail] end
										   ,[SourceID]
										   ,[InvoiceID]
										   ,[LastUpdateUserID]
										   ,[StoreTransactionID]
										   
										   

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
													   
										   
										   
										   
										   from StoreTransactions_Working w
										where w.StoreTransactionID = CAST(@workingtransactionidstring as bigint)
					
					
					end
									
				insert into CDCControl
					(StoreTransactionID, ProcessID)
					values(@transactionid,@MyID)
									
			end
		else
			begin

				--declare @errormessage varchar(4500)
				--declare @errorlocation varchar(255)
				
				update StoreTransactions_Working set WorkingStatus = -5 where StoreTransactionID = CAST(@workingtransactionidstring as bigint)

				update t set t.ProcessingErrorDesc = ''
				from StoreTransactions t
				where t.StoreTransactionID = @transactionid

				set @errormessage = 'Warning: It appears that working transaction ' + ltrim(rtrim(@workingtransactionidstring)) + ' is an update of transaction ' + ltrim(rtrim(cast(@transactionid as nvarchar(50)))) + ' but this would violate the update limit of ' + @existingpostransactionupdatelimitstring + '.  This new transaction has not been processed into the StoreTransactions table.'
				set @errorlocation = 'prValidateTransactionTypeInStoreTransactions_Working'
				set @errorsenderstring = 'prValidateTransactionTypeInStoreTransactions_Working'
				
				exec dbo.prLogExceptionAndNotifySupport
				2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,@MyID
				
			end	
					commit transaction
		end --if workingtransactionid <> @lastprocessingerrordesc

			set @lastprocessingerrordesc = @workingtransactionidstring
			
			fetch next from @rec into @transactionid
				,@workingtransactionidstring
				,@oldsetupcost
				,@oldsetupretail
				,@oldreportedcost
				,@oldreportedretail
				,@oldqty
				,@oldsupplierid				
	end
	
close @rec
deallocate @rec

          
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID

		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueit@icucsolutions.com' --;edi@icontroldsd.com'		
		
end catch

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where WorkingStatus = 4
and WorkingSource = 'POS'
and ChainID <> 44199
	
return
GO
