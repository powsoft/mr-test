USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateSuppliersInStoreTransactions_Working_New_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/25/2014
-- Description:	Validates the Supplier in Store Transactions Working for both newspaper and non-newspaper products
-- =============================================
CREATE PROCEDURE [dbo].[prValidateSuppliersInStoreTransactions_Working_New_PRESYNC_20150329] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7418
DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14


begin try

Update w Set WorkingStatus = 2, ProcessID = @Processid
--Select *
From StoreTransactions_Working w
inner join datatrue_edi.dbo.EDI_SupplierCrossReference s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where Isnull(w.SupplierID, 0) <> s.DataTrueSupplierID
and s.DataTrueSupplierID <> 50726
and w.WorkingStatus = -3
and w.ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13,14))

Update t Set WorkingStatus = 2, ProcessID = @Processid
--Select *
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[StoreSetup] s
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and s.SupplierID Not in (40558, 50726, 28781)
where cast(t.SaleDateTime as DATE) between cast(s.ActiveStartDate AS DATE) and cast(s.ActiveLastDate as DATE)
and WorkingStatus = -3
and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13,14))
and t.SupplierID is null

select distinct StoreTransactionID, StoreID, ProductID
into #tempStoreTransaction
--select *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 2
and WorkingSource in ('POS')
--and ChainID in (Select EntityIDtoInclude from ProcessStepEntities where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')
and ProcessID = @PRocessID
begin transaction

set @loadstatus = 4


update w set w.SupplierID = s.DataTrueSupplierID
from  #tempStoreTransaction tmp
inner join StoreTransactions_Working w
on tmp.StoreTransactionID = w.StoreTransactionID
inner join datatrue_edi.dbo.EDI_SupplierCrossReference s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where Isnull(w.SupplierID, 0) <> s.DataTrueSupplierID
and s.DataTrueSupplierID <> 50726

update t set t.SupplierID = s.SupplierID, t.BrandID = s.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[StoreSetup] s
on t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and s.SupplierID Not in (40558, 50726, 28781)
where cast(t.SaleDateTime as DATE) between cast(s.ActiveStartDate AS DATE) and cast(s.ActiveLastDate as DATE)
and t.BrandID = 0
and Isnull(t.SupplierID, 0) <> S.SupplierID 


update w set w.SupplierID = s.SupplierID
from  #tempStoreTransaction tmp
inner join StoreTransactions_Working w
on tmp.StoreTransactionID = w.StoreTransactionID
inner join Suppliers s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where Isnull(w.SupplierID,0) <> s.SupplierID
and s.SupplierID <> 50276

update w set w.SupplierID = 0
from  #tempStoreTransaction tmp
inner join StoreTransactions_Working w
on tmp.StoreTransactionID = w.StoreTransactionID
where w.SupplierID is null
and RecordType = 2

--update t set t.WorkingStatus = -127
--from #tempStoreTransaction tmp
--inner join [dbo].[StoreTransactions_Working] t
--on tmp.StoreTransactionID = t.StoreTransactionID
--where SupplierID is null
--and t.Banner = 'SV_JWL'

update t set t.WorkingStatus = -3
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where SupplierID is null

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
			@job_name = 'DailyPOSBilling_New'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Record Processing Has Stopped'
				,'Record processing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'		

		
end catch
	


update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID, DateTimeLastUpdate = GETDATE()
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
Where SupplierID is not null

END
GO
