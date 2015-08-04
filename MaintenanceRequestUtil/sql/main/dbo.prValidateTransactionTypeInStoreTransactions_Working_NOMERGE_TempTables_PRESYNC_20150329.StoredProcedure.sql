USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_NOMERGE_TempTables_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateTransactionTypeInStoreTransactions_Working_NOMERGE_TempTables_PRESYNC_20150329]

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

select distinct StoreTransactionID, saledatetime
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working] with (index(71))
where WorkingStatus = 4
--and ChainID = 40393
and WorkingSource in ('POS')
and ChainID in (select EntityIDToInclude from ProcessStepEntities where ProcessStepName = 'prValidateTransactionTypeInStoreTransactions_Working_NOMERGE_TempTables')
and Isnull(ProcessID, 0) = 0

--******************Remove Dupes Begin*******************************
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

 select top 1 storeid, productid, storeidentifier, upc, cast(w.SaleDateTime as date), ltrim(rtrim(PONO))
from StoreTransactions_Working w
inner join #tempStoreTransaction t
on w.StoreTransactionID = t.StoreTransactionID
where 1 = 1
and WorkingStatus = 4
group by storeid, productid, storeidentifier, upc, cast(w.SaleDateTime as date), ltrim(rtrim(PONO))
having COUNT(w.storetransactionid) > 1

if @@ROWCOUNT > 0 
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
		(select storeid, productid, brandid, cast(saledatetime as date) as [date]
		from storetransactions_working
		where workingstatus = 4
		group by storeid, productid, brandid, cast(saledatetime as date)
		having count(storetransactionid) > 1) s
	on w.storeid = s.storeid and w.productid = s.productid and w.brandid = s.brandid and cast(w.saledatetime as date) = cast(s.date as date)
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
--*/
--declare @transidtable StoretransactionIDTable
insert @transidtable
select StoreTransactionID from #tempStoreTransaction
--exec prApplyCostRules @transidtable, 1 --1=POS, 2=SUP, 3=INV

begin transaction

set @loadstatus = 5

update t set t.TransactionTypeID = 2
--select t.*
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

--***************Cost Lookup Start**************************

--First look for exact match for all entities
update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
--select t.*
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where t.SetupCost is null
and p.ProductPriceTypeID in (3)
--(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2) --2 is Chain Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate



--update CostMisMatch
update t set t.CostMisMatch = 1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupCost <> t.ReportedCost
or t.SetupCost is null or t.ReportedCost is null
--or (t.SetupCost is null and t.ReportedCost is null)

--update RetailMisMatch
update t set t.RetailMisMatch = 1
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.SetupRetail <> t.ReportedRetail
or t.SetupRetail is null or t.ReportedRetail is null
--or (t.SetupRetail is null and t.ReportedRetail is null)

--***************Cost Lookup End****************************

exec prApplyCostRules @transidtable, 1 --1=POS, 2=SUP, 3=INV

--select CAST(getdate() as DATE)

--if CAST(getdate() as DATE) = '1/29/2015'
--	begin
		update t set t.RuleCost = t.RuleCost + t.PromoAllowance
		from #tempStoreTransaction tmp
		inner join [dbo].[StoreTransactions_Working] t
		on tmp.StoreTransactionID = t.StoreTransactionID
		where t.storeid in (select storeid from stores where custom3 = 'SS')
		and t.SetupCost is null
		and t.RuleCost is not null
		and ISNULL(t.PromoAllowance, 0) > 0
	--end

		DECLARE @storetransactionsids TABLE (storetransactionID bigint);
if 1 = 1
	begin
			
		select w.storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, w.saledatetime, ProcessingErrorDesc, PONo, Reversed, CAST(4 as int) as Workingstatus
		into #tempsup		
		from DataTrue_Main.dbo.StoreTransactions_Working w
		inner join #tempStoreTransaction t
		on w.StoreTransactionID = t.StoreTransactionID
		--where charindex('POS', WorkingSource) > 0
		--and WorkingStatus = 4

		select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, ProcessingErrorDesc, PONo, Reversed
		into #tempsup2
		from DataTrue_Main.dbo.StoreTransactions
		where 1 = 1
		and TransactionTypeID in (2, 6)
		and CAST(SaleDateTime as date) in 
		(select distinct CAST(SaleDateTime as date) from #tempsup)	
	
		update t set t.ProcessingErrorDesc=ltrim(rtrim(cast(s.[StoreTransactionID] as nvarchar(50))))
		OUTPUT INSERTED.ProcessingErrorDesc INTO @storetransactionsids
		--select * 
		from #tempsup2 t join
		(select w.* from #tempsup w join #tempStoreTransaction tmp
		on w.StoreTransactionID=tmp.StoreTransactionID ) s
		on t.StoreID = s.StoreID 
		and t.ProductID = s.ProductID
		and t.BrandID = s.BrandID
		--and cast(t.SaleDateTime as date) = cast(s.SaleDateTime as date)
		and DATEDIFF(D,t.SaleDateTime,s.SaleDateTime)=0
		and t.TransactionTypeID in (2, 6, 16)
		and isnull(t.PoNo,'') = isnull(s.PONO, '')
		and t.Reversed = 0
		and cast(s.saledatetime as date) < cast(DATEADD(day,-1,getdate()) as date)
		
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
           ,SBTNumber)
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
           from #tempStoreTransaction tmp join StoreTransactions_Working s
           on s.StoreTransactionID=tmp.StoreTransactionID
           and tmp.StoreTransactionID not in (select storetransactionID from @storetransactionsids)
           option (force order)


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
	--CHECK WITH NIK B BEFORE MAKING MODIFICATIONS TO THIS QUERY
	select t.StoreTransactionID, t.ProcessingErrorDesc,
	isnull(t.SetupCost,0), isnull(t.SetupRetail,0), isnull(t.ReportedCost,0), isnull(t.ReportedRetail,0),
	t.Qty, t.SupplierID
	from StoreTransactions t with (index(3))
	inner join #tempStoreTransaction tmp
	on t.transactiontypeid in (2,6)
	and t.SaleDateTime  > DATEADD(day, -60, getdate())
	and ProcessingErrorDesc = convert(nvarchar(100),tmp.StoreTransactionID)
	where --len(t.ProcessingErrorDesc) > 0
	--and isnumeric(t.ProcessingErrorDesc) > 0
	ProcessingErrorDesc<'A'
	
	
/*20110912 added join above since there could be supplier records
	select StoreTransactionID, ProcessingErrorDesc,
	isnull(SetupCost,0), isnull(SetupRetail,0), isnull(ReportedCost,0), isnull(ReportedRetail,0),
	Qty, SupplierID
	from StoreTransactions
	where len(ProcessingErrorDesc) > 0
	and isnumeric(ProcessingErrorDesc) > 0
20110912*/
	
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
		--select *
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
			
			--select * from [dbo].[RelatedTransactions]
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
--print @workingtransactionidstring						   
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
--print @relatedcount

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

          
--		commit transaction
						
	
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
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	

update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
--from [dbo].[StoreTransactions_Working] t
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID


	
return
GO
