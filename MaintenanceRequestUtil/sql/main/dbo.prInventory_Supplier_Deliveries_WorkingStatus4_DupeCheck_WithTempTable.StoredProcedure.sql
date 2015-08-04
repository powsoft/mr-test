USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Supplier_Deliveries_WorkingStatus4_DupeCheck_WithTempTable]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_Supplier_Deliveries_WorkingStatus4_DupeCheck_WithTempTable]
as


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
declare @ediname nvarchar(50)
declare @purposecode nvarchar(50)
declare @storenumber nvarchar(50)
declare @productidentifier nvarchar(50)
declare @date as date
declare @qty int
declare @supplierid int
declare @workingsource nvarchar(50)
declare @storeid int
declare @productid int
declare @supplierinvoicenumber nvarchar(50)
declare @IsDuplicateFound int=0
declare @suppliername nvarchar(100)
declare @body nvarchar(max)
declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
--/*

/*
select *
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4
and SaleDateTime > '11/30/2011'
--and TransactionTypeID is null
and workingsource in ('SUP-S','SUP-U')
*/

update i set TransactionTypeID = case when WorkingSource = 'SUP-S' then 5 else 8 end
--select *
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4
and SaleDateTime > '11/30/2011'
and TransactionTypeID is null
and workingsource in ('SUP-S','SUP-U')

select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, supplierinvoicenumber, qty, CAST(4 as int) as Workingstatus
into #tempsup
from DataTrue_Main.dbo.StoreTransactions_Working w
where charindex('SUP', WorkingSource) > 0
and WorkingStatus = 4

select storetransactionid, chainid, storeid, ProductId, brandid, supplierid, transactiontypeid, saledatetime, supplierinvoicenumber, qty
into #tempsup2
from DataTrue_Main.dbo.StoreTransactions
where 1 = 1
and TransactionTypeID in (5, 8)
and CAST(SaleDateTime as date) in 
(select distinct CAST(SaleDateTime as date) from #tempsup)


update w set w.WorkingStatus = -10
--select *
--from DataTrue_Main.dbo.StoreTransactions_Working w
from #tempsup w
inner join #tempsup2 t --StoreTransactions t
on w.ChainID = t.ChainID
--and w.storetransactionid in (56965222,56986877)
and w.StoreID = t.StoreID
and w.ProductID = t.ProductID
and w.BrandID = t.BrandID
and w.SupplierID = t.SupplierID
and w.TransactionTypeID = t.TransactionTypeID
and w.TransactionTypeID in (5, 8)
and t.TransactionTypeID in (5,8)
and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
and isnull(w.SupplierInvoiceNumber, '') = isnull(t.SupplierInvoiceNumber, '')
and w.WorkingStatus = 4
and w.Qty = t.qty

update w set w.WorkingStatus = t.Workingstatus
from DataTrue_Main.dbo.StoreTransactions_Working w
inner join #tempsup t
on w.storetransactionid = t.storetransactionid
and t.Workingstatus = -10

--******************Begin Send Email Notification for Duplicate Records*******************	
--/*
if(@@ROWCOUNT>0)
	Begin
	set @recremovedupes = CURSOR local fast_forward FOR
	select distinct supplierid
		from StoreTransactions_Working where WorkingStatus = -10 and 
		CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and charindex('INV', WorkingSource) > 0 
		and datepart(hour,getdate())<12
		--from StoreTransactions_Working where WorkingStatus = -10 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and charindex('INV', WorkingSource) > 0 
		

	
	open @recremovedupes
	
	fetch next from @recremovedupes into @supplierid
	
	while @@FETCH_STATUS = 0
		Begin
			
			select @suppliername = SupplierName from Suppliers where SupplierID=@supplierid;
			
			Set @body ='While loading deliveries and pickup for supplier "'+ @suppliername +'" duplications were encountered for the Store/UPC/EffectiveDate combinations listed below.  Please inquire about these duplicates and provide instructions on how they should be managed.';
			set @body=@body+'<table style=" border-collapse: collapse;text-align:left; font-family: ''Lucida Sans Unicode'',''Lucida Grande'',Sans-Serif;font-size: 12px;">';
			set @body=@body + '<tr><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Store Number</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">UPC</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Quantity</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Sale Datetime</th></tr>'
			
			select 
				@body=@body + '<tr><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(StoreIdentifier as nvarchar(25)) +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ UPC +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(Qty as nvarchar(10))+'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ cast(SaleDateTime as nvarchar) +'</td></tr>'
			--from StoreTransactions_Working where WorkingStatus = -10 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and SupplierID= @supplierid and charindex('INV', WorkingSource) > 0
			from StoreTransactions_Working where WorkingStatus = -10 and CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and SupplierID= @supplierid and (charindex('SUP-S', WorkingSource) > 0 or charindex('SUP-U', WorkingSource) > 0)
			order by StoreID,ProductID
			
			set @body=@body+'</table>';
				
				set @errormessage = @body;
				set @errorlocation = 'Duplicate found during deliveries and pickup load'
				set @errorsenderstring = 'prInventory_Supplier_Deliveries_WorkingStatus4_DupeCheck'
				
				exec dbo.[prLogExceptionAndNotifySupport_HTML]
				2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,0
				,@supplierid
				,1 --1=Dupe check
					
			fetch next from @recremovedupes into @supplierid

		end
		close @recremovedupes
		deallocate @recremovedupes
	end

--		*/
--********************End Send Email Notification for Duplicate Records*******************	


select supplierid, workingsource, storeid, productid, cast(saledatetime as date) as saledate, qty, SupplierInvoiceNumber, count(storetransactionid) as dupecount 
into #tempdupes
from DataTrue_Main.dbo.StoreTransactions_Working i
WHERE 1 = 1
and WorkingStatus = 4
and SaleDateTime > '11/30/2011'
and Qty <> 0
--and SupplierID = 40557
and workingsource in ('SUP-S','SUP-U')
group by  supplierid, workingsource, storeid, productid, cast(saledatetime as date), qty, SupplierInvoiceNumber
having count(storetransactionid) > 1


set @recremovedupes = CURSOR local fast_forward FOR
select  supplierid, workingsource, storeid, productid, cast(saledate as date) as saledate, qty, supplierinvoicenumber, dupecount
from #tempdupes
	
	open @recremovedupes
	
	fetch next from @recremovedupes into
			@supplierid
			,@workingsource
			,@storeid
			,@productid
			,@date
			,@qty
			,@supplierinvoicenumber
			,@dupecount
										
	while @@FETCH_STATUS = 0
		begin

print @dupecount

-------------------Begins here to check the dupe check with 0 qty--------------------------
----------------Changes done to take care of dupe when one qty is 0 on 30052012 by Mandeep ----------------
			declare @StoreTransactionIDofZeroQty bigint=0;
			
			select StoreTransactionID,Qty into #tempDupeRec from StoreTransactions_Working
				where StoreID = @remstoreid
				and ProductID = @remproductid
				and BrandID = @rembrandid
				and SupplierID = @supplierid
				and CAST(saledatetime as DATE) =  @remsaledate
				and workingsource = @workingsource
				and WorkingStatus = 4
			
			if(@@ROWCOUNT>1)
				Begin
					select @StoreTransactionIDofZeroQty=storetransactionID 
					from #tempDupeRec where Qty=0 order by Qty desc;
					
					if(@StoreTransactionIDofZeroQty<>0)
						Begin
							update storetransactions_working set WorkingStatus = -6
							where StoreTransactionID=@StoreTransactionIDofZeroQty;
						End
					else	
					Begin
						update DataTrue_Main.dbo.StoreTransactions_Working set workingstatus = -6
						where supplierid = @supplierid
						and ltrim(rtrim(workingsource)) = @workingsource
						and StoreID  = @storeid
						and productid = @productid
						and CAST(saledatetime as date) = @date
						and Qty = @qty
						and isnull(supplierinvoicenumber, '') = isnull(@supplierinvoicenumber, '')
						--and StoreTransactionID not in
						--(
						--	select top 1 StoreTransactionID from DataTrue_Main.dbo.StoreTransactions_Working
						--	where supplierid = @supplierid
						--	and ltrim(rtrim(workingsource)) = @workingsource
						--	and StoreID  = @storeid
						--	and productid = @productid
						--	and CAST(saledatetime as date) = @date
						--	and Qty = @qty
						--	and isnull(supplierinvoicenumber, '') = isnull(@supplierinvoicenumber, '')
						--	order by StoreTransactionID
						-- )

					End
				End		
			drop table #tempDupeRec;
			
-------------------Finish here to check the dupe check with 0 qty--------------------------

			 							
			fetch next from @recremovedupes into
				@supplierid
				,@workingsource
				,@storeid
				,@productid
				,@date
				,@qty
				,@supplierinvoicenumber
				,@dupecount
		end
		
	close @recremovedupes
	deallocate @recremovedupes
	
	
--******************Begin Send Email Notification for Duplicate Records*******************	
--/*
if(@IsDuplicateFound=1)
	Begin
	set @recremovedupes = CURSOR local fast_forward FOR
	select distinct supplierid
		from StoreTransactions_Working where WorkingStatus = -6 and Qty<>0 
		and CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and charindex('INV', WorkingSource) > 0 
		and datepart(hour,getdate())<12
		--from StoreTransactions_Working where WorkingStatus = -6 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and charindex('INV', WorkingSource) > 0 
		
	
	
	open @recremovedupes
	
	fetch next from @recremovedupes into @supplierid
	
	while @@FETCH_STATUS = 0
		Begin
			
			select @suppliername = SupplierName from Suppliers where SupplierID=@supplierid;
			
			Set @body ='While loading deliveries and pick up for supplier "'+ @suppliername +'" duplications were encountered for the Store/UPC/EffectiveDate combinations listed below.  Please inquire about these duplicates and provide instructions on how they should be managed.';
			set @body=@body+'<table style=" border-collapse: collapse;text-align:left; font-family: ''Lucida Sans Unicode'',''Lucida Grande'',Sans-Serif;font-size: 12px;">';
			set @body=@body + '<tr><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Store Number</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">UPC</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Quantity</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Sale Datetime</th></tr>'
			
			select 
				@body=@body + '<tr><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(StoreIdentifier as nvarchar(25)) +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ UPC +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ CAST(Qty as nvarchar(10))+'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ cast(SaleDateTime as nvarchar) +'</td></tr>'
			--from StoreTransactions_Working where WorkingStatus = -6 and CAST(DateTimeCreated as date)=CAST('5/22/2012' as date)  and SupplierID= @supplierid and charindex('INV', WorkingSource) > 0
			from StoreTransactions_Working where WorkingStatus = -6 and CAST(DateTimeCreated as date)=CAST(GETDATE() as date) and SupplierID= @supplierid and (charindex('SUP-S', WorkingSource) > 0 or charindex('SUP-U', WorkingSource) > 0)
			order by StoreID,ProductID
			
			set @body=@body+'</table>';
				
				set @errormessage = @body;
				set @errorlocation = 'Duplicate found during deliveries and pick up load'
				set @errorsenderstring = 'prInventory_Supplier_Deliveries_WorkingStatus4_DupeCheck'
				
				exec dbo.[prLogExceptionAndNotifySupport_HTML]
				2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,0
				,@supplierid
				,1 --1=Dupe check
					
			fetch next from @recremovedupes into @supplierid

		end
		close @recremovedupes
		deallocate @recremovedupes
	end

--		*/
--********************End Send Email Notification for Duplicate Records*******************	

return
GO
