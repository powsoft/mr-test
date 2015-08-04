USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReviewStoreTransactionsForProcessErrors]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prReviewStoreTransactionsForProcessErrors]

as

declare @rec cursor
declare @transactionid bigint
declare @systemsupportemail nvarchar(100)
declare @errormessage nvarchar(2000)
declare @body nvarchar(4000)
declare @MyID int

set @MyID = 24119

select @systemsupportemail = v.AttributeValue
from AttributeDefinitions d
inner join AttributeValues v
on d.AttributeID = v.AttributeID
where d.AttributeName = 'DataTrueSystemSupportEmail'
and v.OwnerEntityID = 0

set @rec = CURSOR local fast_forward FOR
	select StoreTransactionID, ProcessingErrorDesc 
	from StoreTransactions
	where len(ProcessingErrorDesc) > 0
	
open @rec

fetch next from @rec into @transactionid, @errormessage

While @@FETCH_STATUS = 0
	begin
		
--declare @errorsenderstring nvarchar(255)
		set @body = 'StoreTransactions record ' + LTRIM(rtrim(cast(@transactionid as nvarchar(50)))) + ' has the following ProcessingErrorDesc: ' + @errormessage
		
		exec [dbo].[prSendEmailNotification_PassEmailAddresses]
			'StoreTransactions Process Error'
			,@body
			,prReviewStoreTransactionsForProcessErrors
			,@MyID
			,@systemsupportemail
			,''
			,''
		fetch next from @rec into @transactionid, @errormessage

	end
	
close @rec
deallocate @rec
GO
