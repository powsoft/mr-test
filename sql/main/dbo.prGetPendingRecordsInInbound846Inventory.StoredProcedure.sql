USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetPendingRecordsInInbound846Inventory]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetPendingRecordsInInbound846Inventory]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)


select
	PurposeCode,RecordStatus,
	COUNT(RecordID) as "Count"
	into #tempTableCounts
	from
	 DataTrue_EDI.dbo.Inbound846Inventory
	where
	DATEDIFF(hour,TimeStamp,Getdate()) > 12 
	and
	DATEDIFF(hour,TimeStamp,Getdate()) < 48 
	and
	RecordStatus not in (0) 
	group
	by PurposeCode,RecordStatus



if @@ROWCOUNT > 0
	begin
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'Pending records in Inbound846Inventory table please review them'
		set @errorlocation = '[prGetPendingRecordsInInbound846Inventory]'
		set @errorsenderstring = '[prGetPendingRecordsInInbound846Inventory]'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,0
		
	end

	
return
GO
