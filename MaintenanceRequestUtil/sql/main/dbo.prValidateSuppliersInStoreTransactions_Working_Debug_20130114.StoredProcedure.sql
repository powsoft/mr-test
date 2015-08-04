USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSuppliersInStoreTransactions_Working_Debug_20130114]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateSuppliersInStoreTransactions_Working_Debug_20130114]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7418


begin try

select distinct StoreTransactionID, StoreID, ProductID
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 13
and WorkingSource in ('POS')

begin transaction

set @loadstatus = 3

/*
--select * from datatrue_EDI.dbo.EDI_SupplierCrossReference
--declare @MyID int = 2
declare @recsup cursor
declare @supplieridentifiertoadd nvarchar(50)
declare @suppliernametoadd nvarchar(255)
declare @supplierentitytypeid int
declare @newsupplierid int

set @recsup = CURSOR local fast_forward FOR
	select distinct ltrim(rtrim(supplieridentifier)), ltrim(rtrim(suppliername))
	from datatrue_EDI.dbo.EDI_SupplierCrossReference
	where ltrim(rtrim(supplieridentifier))  not in
	(select ltrim(rtrim(supplieridentifier)) from Suppliers)
	
open @recsup

fetch next from @recsup into @supplieridentifiertoadd, @suppliernametoadd

if @@FETCH_STATUS = 0
	select @supplierentitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Supplier'
	
while @@FETCH_STATUS = 0
	begin
		INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
				   ([EntityTypeID]
				   ,[LastUpdateUserID])
			 VALUES
				   (@supplierentitytypeid
				   ,@MyID)
	
		set @newsupplierid = SCOPE_IDENTITY()
		
		INSERT INTO [DataTrue_Main].[dbo].[Suppliers]
				   ([SupplierID]
				   ,[SupplierName]
				   ,[SupplierIdentifier]
				   ,[SupplierDescription]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID])
			 VALUES
				   (@newsupplierid
				   ,@suppliernametoadd
				   ,@supplieridentifiertoadd
				   ,''
				   ,'1/1/2011'
				   ,'12/31/2025'
				   ,@MyID)		
		
		fetch next from @recsup into @supplieridentifiertoadd, @suppliernametoadd	
	end
	
close @recsup
deallocate @recsup
*/

/*ENABLE AFTER STORESETUP CLEANUP
--select t.StoreIdentifier, s.StoreIdentifier, s.StoreID, c.ChainID
update t set t.SupplierID = s.SupplierID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[StoreSetup] s
on t.StoreID = s.StoreID and t.ProductID = s.ProductID and t.BrandID = s.BrandID
where cast(t.SaleDateTime as DATE) between cast(s.ActiveStartDate AS DATE) and cast(s.ActiveLastDate as DATE)
and t.BrandID > 0

update t set t.SupplierID = s.SupplierID, t.BrandID = s.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[StoreSetup] s
on t.StoreID = s.StoreID and t.ProductID = s.ProductID
where cast(t.SaleDateTime as DATE) between cast(s.ActiveStartDate AS DATE) and cast(s.ActiveLastDate as DATE)
and t.BrandID = 0

update t set SupplierID = 0
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null
and (t.SupplierIdentifier is null or len(t.SupplierIdentifier) < 1)
ENABLE AFTER STORESETUP CLEANUP*/

update w set w.SupplierID = s.DataTrueSupplierID
from  #tempStoreTransaction tmp
inner join StoreTransactions_Working w
on tmp.StoreTransactionID = w.StoreTransactionID
inner join datatrue_edi.dbo.EDI_SupplierCrossReference s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where w.SupplierID is null or w.SupplierID = 0
--and w.ProductID <> 27704

--update t set t.SupplierID = s.SupplierID, t.BrandID = s.BrandID
----select t.*
--from #tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
--inner join [dbo].[StoreSetup] s
--on t.StoreID = s.StoreID and t.ProductID = s.ProductID
--where cast(t.SaleDateTime as DATE) between cast(s.ActiveStartDate AS DATE) and cast(s.ActiveLastDate as DATE)
--and t.BrandID = 0
--and t.SupplierID is null or t.SupplierID = 0
--and ltrim(rtrim(t.Banner)) <> 'SV_JWL'

--20120524 Added update just below for Jewel and Shaw C&M
update t set t.SupplierID = s.SupplierID, t.BrandID = s.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[StoreSetup] s
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and s.SupplierID <> 40558
where cast(t.SaleDateTime as DATE) between cast(s.ActiveStartDate AS DATE) and cast(s.ActiveLastDate as DATE)
and t.BrandID = 0
and t.SupplierID is null or t.SupplierID = 0
and ltrim(rtrim(t.Banner)) = 'SV_JWL'


update w set w.SupplierID = s.SupplierID
from  #tempStoreTransaction tmp
inner join StoreTransactions_Working w
on tmp.StoreTransactionID = w.StoreTransactionID
inner join Suppliers s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where w.SupplierID is null or w.SupplierID = 0
--and w.ProductID <> 27704

update t set t.WorkingStatus = -127
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null
and t.Banner = 'SV_JWL'

update t set t.WorkingStatus = -3
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null
and len(t.SupplierIdentifier) > 0

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Invalid Supplier Identifiers Found'
		set @errorlocation = 'prValidateSuppliersInStoreTransactions_Working'
		set @errorsenderstring = 'prValidateSuppliersInStoreTransactions_Working'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

		commit transaction
	
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
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID


return
GO
