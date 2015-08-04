USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Supplier_Counts_WorkingStatus4_DupeCheck_Rule]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_Supplier_Counts_WorkingStatus4_DupeCheck_Rule]
as

--*****************************Dupes in this batch*******************************************
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
declare @workingsource nvarchar(50)
declare @workingqty int
declare @supplierid int
declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @IsDuplicateFound int=0

select distinct storeid, productid, brandid, supplierid, cast(saledatetime as date) as [date], workingsource--, Qty
		into #tempbatchdupes
		--select *
		--select distinct storeid, productid, brandid, supplierid, cast(saledatetime as date) as [date], workingsource--, Qty
		from storetransactions_working
		where 1 = 1
		and workingstatus = 4
		and charindex('INV', WorkingSource) > 0
		--and SupplierID = 40559
		--and ProductID = 5523
		group by storeid, productid, brandid, supplierid, cast(saledatetime as date), workingsource--, qty
		having count(storetransactionid) > 1
	
	Set @IsDuplicateFound =0
	
if @@ROWCOUNT > 0
	begin
set @recremovedupes = CURSOR local fast_forward FOR
	select storeid
		,productid
		,brandid
		,supplierid
		,cast([date] as date)
		,workingsource
		--,Qty
	from #tempbatchdupes
	order by storeid
		,productid
		,brandid
		,supplierid
		,cast([DATE] as date)
		,workingsource
		--,qty
	
	open @recremovedupes
	
	fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@supplierid
										,@remsaledate
										,@workingsource
										--,@workingqty
									
	while @@FETCH_STATUS = 0
		begin
-------------------Begins here to check the dupe check with 0 qty--------------------------
----------------Changes done to take care of dupe when one qty is 0 on 30052012 by Mandeep ----------------
			declare @StoreTransactionIDofZeroQty bigint=0;
			
			select StoreTransactionID,Qty into #tempDupes from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and SupplierID = @supplierid
				and CAST(saledatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 4
			
			if(@@ROWCOUNT>1)
				Begin
					select top 1 @StoreTransactionIDofZeroQty=storetransactionID 
					from #tempDupes where Qty=0 order by Qty desc;
					
					if(@StoreTransactionIDofZeroQty<>0)
						Begin
							update storetransactions_working set WorkingStatus = -6
							where StoreTransactionID=@StoreTransactionIDofZeroQty;
						End
					else
						Begin
							--update storetransactions_working set WorkingStatus = -6
							--where StoreTransactionID in
							--(
							--	select StoreTransactionID from StoreTransactions_Working
							--	where StoreID = @remstoreid
							--	and ProductID = @remproductid
							--	and BrandID = @rembrandid
							--	and SupplierID = @supplierid
							--	and CAST(saledatetime as DATE) =  @remsaledate
							--	and workingsource = @workingsource
							--	and WorkingStatus = 4
							-- )
							--	and StoreTransactionID not in
							--(
							--	select top 1 StoreTransactionID from StoreTransactions_Working
							--	where StoreID = @remstoreid
							--	and ProductID = @remproductid
							--	and BrandID = @rembrandid
							--	and SupplierID = @supplierid
							--	and CAST(saledatetime as DATE) =  @remsaledate
							--	and workingsource = @workingsource
							--	and WorkingStatus = 4
							--	and SupplierID in (40561)
							--	order by Qty desc
							--	--order by RecordID_EDI_852
							-- )
							
							declare @RuleId int=0;
							
							select @RuleId=r.RuleId
							from RuleUse u join Rules r
							on u.RuleId=r.RuleId
							and r.RuleTypeId=4 
							where u.RuleUserEntityId=@supplierid
							
							if(@RuleId=13)
								Begin
									--larger quantity is valid
									update storetransactions_working set WorkingStatus = -6
									where StoreTransactionID in
									(
										select StoreTransactionID from StoreTransactions_Working
										where StoreID = @remstoreid
										and ProductID = @remproductid
										and BrandID = @rembrandid
										and SupplierID = @supplierid
										and CAST(saledatetime as DATE) =  @remsaledate
										and workingsource = @workingsource
										and WorkingStatus = 4
									 )
										and StoreTransactionID not in
									(
										select top 1 StoreTransactionID from StoreTransactions_Working
										where StoreID = @remstoreid
										and ProductID = @remproductid
										and BrandID = @rembrandid
										and SupplierID = @supplierid
										and CAST(saledatetime as DATE) =  @remsaledate
										and workingsource = @workingsource
										and WorkingStatus = 4
										order by Qty desc
									 )
									
								End
							else if(@RuleId=14)
								Begin
									--OlderCost
									update storetransactions_working set WorkingStatus = -6
									where StoreTransactionID in
									(
										select StoreTransactionID from StoreTransactions_Working
										where StoreID = @remstoreid
										and ProductID = @remproductid
										and BrandID = @rembrandid
										and SupplierID = @supplierid
										and CAST(saledatetime as DATE) =  @remsaledate
										and workingsource = @workingsource
										and WorkingStatus = 4
									 )
										and StoreTransactionID not in
									(
										select top 1 StoreTransactionID from StoreTransactions_Working
										where StoreID = @remstoreid
										and ProductID = @remproductid
										and BrandID = @rembrandid
										and SupplierID = @supplierid
										and CAST(saledatetime as DATE) =  @remsaledate
										and workingsource = @workingsource
										and WorkingStatus = 4
										order by SaleDateTime desc
									 )
									
								End
							else	
								Begin
									--larger quantity is valid
									update storetransactions_working set WorkingStatus = -6
									where StoreTransactionID in
									(
										select StoreTransactionID from StoreTransactions_Working
										where StoreID = @remstoreid
										and ProductID = @remproductid
										and BrandID = @rembrandid
										and SupplierID = @supplierid
										and CAST(saledatetime as DATE) =  @remsaledate
										and workingsource = @workingsource
										and WorkingStatus = 4
									 )
										and StoreTransactionID not in
									(
										select top 1 StoreTransactionID from StoreTransactions_Working
										where StoreID = @remstoreid
										and ProductID = @remproductid
										and BrandID = @rembrandid
										and SupplierID = @supplierid
										and CAST(saledatetime as DATE) =  @remsaledate
										and workingsource = @workingsource
										and WorkingStatus = 4
										order by Qty desc
									 )
								End
						end
						
				End		
		drop table #tempDupes;
			
-------------------Finish here to check the dupe check with 0 qty--------------------------
			
			 							
			fetch next from @recremovedupes into --@remtransactionid
										@remstoreid
										,@remproductid
										,@rembrandid
										,@supplierid
										,@remsaledate
										,@workingsource	
										--,@workingqty
		end
		Set @IsDuplicateFound =1
	close @recremovedupes
	deallocate @recremovedupes
	
--******************Begin Send Email Notification for Duplicate Records*******************	
--/*
if(@IsDuplicateFound=1)
	Begin
	set @recremovedupes = CURSOR local fast_forward FOR
	select distinct supplierid
		from StoreTransactions_Working where WorkingStatus = -6 and Qty<>0 and CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and charindex('INV', WorkingSource) > 0 
		--from StoreTransactions_Working where WorkingStatus = -6 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and charindex('INV', WorkingSource) > 0 
		
	
	
	open @recremovedupes
	
	fetch next from @recremovedupes into @supplierid
	
	while @@FETCH_STATUS = 0
		Begin
			declare @suppliername nvarchar(100);
			
			select @suppliername = SupplierName from Suppliers where SupplierID=@supplierid;
			
			declare @body varchar(max)='During an inventory count load for supplier "'+ @suppliername +'" duplications were encountered for the Store/UPC/EffectiveDate combinations listed below.  Please inquire about these duplicates and provide instructions on how they should be managed.';
			set @body=@body+'<table style=" border-collapse: collapse;text-align:left; font-family: ''Lucida Sans Unicode'',''Lucida Grande'',Sans-Serif;font-size: 12px;">';
			set @body=@body + '<tr><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Store Number</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">UPC</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Quantity</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Sale Datetime</th></tr>'
			
			select 
				@body=@body + '<tr><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(StoreIdentifier as nvarchar(25)) +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ UPC +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(Qty as nvarchar(10))+'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ cast(SaleDateTime as nvarchar) +'</td></tr>'
			--from StoreTransactions_Working where WorkingStatus = -6 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and SupplierID= @supplierid and charindex('INV', WorkingSource) > 0
			from StoreTransactions_Working where WorkingStatus = -6 and CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and SupplierID= @supplierid and charindex('INV', WorkingSource) > 0
			order by StoreID,ProductID
			
			set @body=@body+'</table>';
				
				set @errormessage = @body;
				set @errorlocation = 'Duplicate found during inventory count load'
				set @errorsenderstring = 'prInventory_Supplier_Counts_WorkingStatus4_DupeCheck'
				
				exec dbo.[prLogExceptionAndNotifySupport_HTML]
				2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,0
				,@supplierid
				,1
					
			fetch next from @recremovedupes into @supplierid

		end
		close @recremovedupes
		deallocate @recremovedupes
	end

--		*/
--********************End Send Email Notification for Duplicate Records*******************	
end
--******************Remove Dupes End**********************************

--*****************************Dupes to StoreTransactions Records*****************************
--declare @recremovedupes cursor
--declare @remtransactionid bigint
--declare @remstoreid int
--declare @remproductid int
--declare @rembrandid int
--declare @remsaledate date
--declare @curstoreid int
--declare @curproductid int
--declare @curbrandid int
--declare @cursaledate date
--declare @firstrowpassed bit
declare @dupecount int
declare @ediname nvarchar(50)
declare @purposecode nvarchar(50)
declare @storenumber nvarchar(50)
declare @productidentifier nvarchar(50)
declare @date as date
declare @qty int
--declare @supplierid int
--declare @workingsource nvarchar(50)
declare @storeid int
declare @productid int
declare @supplierinvoicenumber nvarchar(50)
--/*

update i set TransactionTypeID = 11
--select *
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4 
--and StoreIDCorrection = -27
and SaleDateTime > '11/30/2011'
and TransactionTypeID is null
--and CAST(saledatetime as date) = '3/12/2012'
and charindex('INV', workingsource) > 0


				select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, supplierinvoicenumber, qty, CAST(4 as int) as Workingstatus,SourceIdentifier
				into #tempsup
				from DataTrue_Main.dbo.StoreTransactions_Working w
				where charindex('INV', WorkingSource) > 0
				and WorkingStatus = 4

				select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, supplierinvoicenumber, qty,SourceID
				into #tempsup2
				from DataTrue_Main.dbo.StoreTransactions
				where 1 = 1
				and TransactionTypeID in (11)
				and CAST(SaleDateTime as date) in 
				(select distinct CAST(SaleDateTime as date) from #tempsup)
				
set @recremovedupes = CURSOR local fast_forward FOR
			select distinct w.SupplierID --top 100 * from DataTrue_Main.dbo.StoreTransactions_Working
			from #tempsup w--DataTrue_Main.dbo.StoreTransactions_Working w
			inner join #tempsup2 t--StoreTransactions t
			on w.ChainID = t.ChainID
			and w.StoreID = t.StoreID
			and w.ProductID = t.ProductID
			and w.BrandID = t.BrandID
			and w.SupplierID = t.SupplierID
			and w.TransactionTypeID = t.TransactionTypeID
			and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
			--and charindex('INV', workingsource) > 0
			--and w.supplierId = 40561
			--and cast(w.saledatetime as date)='2/27/2012'
			and t.transactiontypeid=11
			--and w.Qty = t.qty
			and w.WorkingStatus = 4
	
	open @recremovedupes
	
	fetch next from @recremovedupes into @supplierid
																			
	while @@FETCH_STATUS = 0
		begin
			Set @RuleId =0;
		
			select @RuleId=r.RuleId
			from RuleUse u join Rules r
			on u.RuleId=r.RuleId
			and r.RuleTypeId=5 
			where u.RuleUserEntityId=@supplierid

			if(@RuleId=15)
				Begin
				
					update w set w.WorkingStatus = -10
					--select * --top 100 * from DataTrue_Main.dbo.StoreTransactions_Working
					from #tempsup w --DataTrue_Main.dbo.StoreTransactions_Working w
					inner join #tempsup2 t--StoreTransactions t
					on w.ChainID = t.ChainID
					and w.StoreID = t.StoreID
					and w.ProductID = t.ProductID
					and w.BrandID = t.BrandID
					and w.SupplierID = t.SupplierID
					and w.TransactionTypeID = t.TransactionTypeID
					and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
					--and charindex('INV', workingsource) > 0
					and w.supplierId = @supplierid
					--and cast(w.saledatetime as date)='2/27/2012'
					and t.transactiontypeid=11
					--and w.Qty = t.qty
					and w.WorkingStatus = 4
					--and (w.WorkingStatus = 3 or StoreIDCorrection = -27)
					
					update w set w.WorkingStatus = t.Workingstatus
					from DataTrue_Main.dbo.StoreTransactions_Working w
					inner join #tempsup t
					on w.storetransactionid = t.storetransactionid
					and t.Workingstatus = -10

				End
			else if(@RuleId=16)
				Begin
				/*
				select SourceName,SUBSTRING(SourceName,Charindex('2012',SourceName),15),SUBSTRING(SUBSTRING(SourceName,Charindex('2012',SourceName),15),Case When Charindex('_',SourceName) = 0 then Charindex('-',SourceName) else Charindex('_',SourceName) end,6) from Source where SourceID in(select distinct SourceID from StoreTransactions where SupplierID=40559 and TransactionTypeID=11) order by DateTimeCreated
				*/	
					select t.StoreTransactionID as "TransactionID",w.StoreTransactionID as "WorkingTransactionID",
					s.SourceName as "TransactionFileName",w.SourceIdentifier as "WorkingFileName",
					REPLACE( SUBSTRING(s.SourceName,Charindex('2012',SourceName),15),'_','') as "TransactionDate",
					REPLACE(SUBSTRING(w.SourceIdentifier,Charindex('2012',w.SourceIdentifier),15),'_','') as "WorkingDate"
					into #tempdupes_StoreTransactions
					--select *
					from #tempsup w-- DataTrue_Main.dbo.StoreTransactions_Working w
					inner join #tempsup2 t-- StoreTransactions t
					on w.ChainID = t.ChainID
					and w.StoreID = t.StoreID
					and w.ProductID = t.ProductID
					and w.BrandID = t.BrandID
					and w.SupplierID = t.SupplierID
					and w.TransactionTypeID = t.TransactionTypeID
					and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
					--and charindex('INV', workingsource) > 0
					--and w.supplierId = 40559--@supplierid
					and t.transactiontypeid=11
					and w.WorkingStatus = -10--4
					--and CAST(w.DateTimeCreated as date) ='09/17/2012'
					join [Source] s on t.SourceID=s.SourceID
					
					--drop table  #tempdupes_StoreTransactions
					
					--select * 
					update s set s.TransactionTypeID=-31
					from #tempdupes_StoreTransactions t join StoreTransactions s
					on t.TransactionID=s.StoreTransactionID
					where TransactionDate<=WorkingDate
					
					--select t.*
					update s set s.WorkingStatus=-10
					from #tempdupes_StoreTransactions t join StoreTransactions_Working s
					on t.WorkingTransactionID=s.StoreTransactionID
					where TransactionDate>WorkingDate
					
				End
			Else
				Begin
					update w set w.WorkingStatus = -10
					--select * --top 100 * from DataTrue_Main.dbo.StoreTransactions_Working
					from #tempsup w --DataTrue_Main.dbo.StoreTransactions_Working w
					inner join #tempsup2 t--StoreTransactions t
					on w.ChainID = t.ChainID
					and w.StoreID = t.StoreID
					and w.ProductID = t.ProductID
					and w.BrandID = t.BrandID
					and w.SupplierID = t.SupplierID
					and w.TransactionTypeID = t.TransactionTypeID
					and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
					--and charindex('INV', workingsource) > 0
					and w.supplierId = @supplierid
					--and cast(w.saledatetime as date)='2/27/2012'
					and t.transactiontypeid=11
					--and w.Qty = t.qty
					and w.WorkingStatus = 4
					--and (w.WorkingStatus = 3 or StoreIDCorrection = -27)
					
					update w set w.WorkingStatus = t.Workingstatus
					from DataTrue_Main.dbo.StoreTransactions_Working w
					inner join #tempsup t
					on w.storetransactionid = t.storetransactionid
					and t.Workingstatus = -10
				End
			fetch next from @recremovedupes into @supplierid
		end
	close @recremovedupes
	deallocate @recremovedupes
	


--******************Begin Send Email Notification for Duplicate Records*******************	
--/*
if(@@ROWCOUNT>0)
	Begin
	set @recremovedupes = CURSOR local fast_forward FOR
	select distinct supplierid
		from StoreTransactions_Working where WorkingStatus = -10 and CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and charindex('INV', WorkingSource) > 0 
		--from StoreTransactions_Working where WorkingStatus = -10 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and charindex('INV', WorkingSource) > 0 
		
	
	
	open @recremovedupes
	
	fetch next from @recremovedupes into @supplierid
	
	while @@FETCH_STATUS = 0
		Begin
			
			select @suppliername = SupplierName from Suppliers where SupplierID=@supplierid;
			
			Set @body ='During an inventory count load for supplier "'+ @suppliername +'" duplications were encountered for the Store/UPC/EffectiveDate combinations listed below.  Please inquire about these duplicates and provide instructions on how they should be managed.';
			set @body=@body+'<table style=" border-collapse: collapse;text-align:left; font-family: ''Lucida Sans Unicode'',''Lucida Grande'',Sans-Serif;font-size: 12px;">';
			set @body=@body + '<tr><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Store Number</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">UPC</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Quantity</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Sale Datetime</th></tr>'
			
			select 
				@body=@body + '<tr><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(StoreIdentifier as nvarchar(25)) +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ UPC +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(Qty as nvarchar(10))+'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ cast(SaleDateTime as nvarchar) +'</td></tr>'
			--from StoreTransactions_Working where WorkingStatus = -10 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and SupplierID= @supplierid and charindex('INV', WorkingSource) > 0
			from StoreTransactions_Working where WorkingStatus = -10 and CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and SupplierID= @supplierid and charindex('INV', WorkingSource) > 0
			order by StoreID,ProductID
			
			set @body=@body+'</table>';
				
				set @errormessage = @body;
				set @errorlocation = 'Duplicate found during inventory count load'
				set @errorsenderstring = 'prInventory_Supplier_Counts_WorkingStatus4_DupeCheck'
				
				exec dbo.[prLogExceptionAndNotifySupport_HTML]
				2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,0
				,@supplierid
				,1
					
			fetch next from @recremovedupes into @supplierid

		end
		close @recremovedupes
		deallocate @recremovedupes
	end

--		*/
--********************End Send Email Notification for Duplicate Records*******************	

	
return
GO
