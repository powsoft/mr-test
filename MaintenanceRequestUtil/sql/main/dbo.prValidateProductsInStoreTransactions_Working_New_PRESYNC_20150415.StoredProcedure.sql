USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateProductsInStoreTransactions_Working_New_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/25/2014
-- Description:	Validates the Products in Store Transactions Working
-- =============================================
CREATE PROCEDURE [dbo].[prValidateProductsInStoreTransactions_Working_New_PRESYNC_20150415]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7417

begin try

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14


update w set w.WorkingStatus = 1, ProcessID = @ProcessID
--select *
from StoreTransactions_Working w
inner join ProductIdentifiers i
on ltrim(rtrim(w.UPC)) = ltrim(rtrim(i.IdentifierValue))
and w.WorkingSource = 'POS'
and w.WorkingStatus = -2
and i.ProductIdentifierTypeID = 2
and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13,14))
and RecordType = 0

update w set w.WorkingStatus = 1, ProcessID = @ProcessID
--select *
from StoreTransactions_Working w
inner join ProductIdentifiers i
on ltrim(rtrim(w.UPC)) = ltrim(rtrim(i.IdentifierValue))
and w.WorkingSource = 'POS'
and w.WorkingStatus = -2
and i.ProductIdentifierTypeID = 8
and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13,14))
and RecordType = 2

update t set t.WorkingStatus = 1, ProcessID = @ProcessID
--Select *
from [dbo].[StoreTransactions_Working] t
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.ItemSKUReported)) = ltrim(rtrim(p.Bipad))
where t.workingstatus = -2
and p.ProductIdentifierTypeID in (8) --UPC is type 2 bipad UPC is type 8
and t.ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13,14))
and t.RecordType = 2

Update t Set t.UPC = m.TranslationCriteria1
--Select *
from StoreTransactions_Working t
Inner Join DataTrue_EDI..TranslationMaster m
on m.TranslationChainID = t.ChainID
and m.TranslationValueOutside = t.UPC
Where m.TranslationTypeID = 28
and t.WorkingSource = 'pos'
and t.WorkingStatus = 1
and t.ProcessID = @ProcessID

select distinct StoreTransactionID, UPC, 
ProductCategoryIdentifier, BrandIdentifier, t.ChainID, StoreID, SupplierIdentifier,
c.AllowProductAddFromPOS, ItemSKUReported
into #tempStoreTransaction
--Select *
from [dbo].[StoreTransactions_Working] t join Chains c
on t.ChainID=c.ChainID
where WorkingStatus = 1
and WorkingSource in ('POS')
and t.ProcessID = @ProcessID


begin transaction

set @loadstatus = 2

update t set t.ProductID = p.ProductID
from [dbo].[StoreTransactions_Working] t with (index(104))
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where t.workingstatus = 1
and p.ProductIdentifierTypeID in (8)
and t.RecordType = 2
and t.ProcessID = @ProcessID
option (querytraceon  8649)

update t set t.ProductID = p.ProductID
from [dbo].[StoreTransactions_Working] t with (index(104))
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.ItemSKUReported)) = ltrim(rtrim(p.Bipad))
where t.workingstatus = 1
and p.ProductIdentifierTypeID in (8) --UPC is type 2 bipad UPC is type 8
and t.ProductID is null
and t.ProcessID = @ProcessID
and t.RecordType = 2
option (querytraceon  8649)

update t set t.ProductID = p.ProductID
from [dbo].[StoreTransactions_Working] t with (index(104))
inner join [dbo].[ProductIdentifiers] p
on ltrim(rtrim(t.UPC)) = ltrim(rtrim(p.IdentifierValue))
where t.workingstatus = 1
and p.ProductIdentifierTypeID in (2)
and t.RecordType = 0
and t.ProcessID = @ProcessID
option (querytraceon  8649)

update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.ProductID is null

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Product Identifiers/UPCs Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

--20110930
update t set t.BrandID = p.BrandID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Brands] p
on ltrim(rtrim(t.BrandIdentifier)) = ltrim(rtrim(p.BrandIdentifier))
where t.BrandIdentifier is not null

update t set t.BrandID = 0
from [dbo].[StoreTransactions_Working] t with (index(104))
where t.workingstatus = 1
and t.workingsource = 'POS'
and t.BrandID is null
and (len(t.BrandIdentifier) < 1 or t.BrandIdentifier is null)
and t.ProcessID = @ProcessID


update t set t.WorkingStatus = -2
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.BrandID is null
and LEN(t.BrandIdentifier) > 0

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Brand Identifiers Found'
		set @errorlocation = 'prValidateProductsInStoreTransactions_Working'
		set @errorsenderstring = 'prValidateProductsInStoreTransactions_Working'
		
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
where t.ProductID is not null
and t.WorkingStatus = 1
and t.WorkingSource = 'POS'


END
GO
