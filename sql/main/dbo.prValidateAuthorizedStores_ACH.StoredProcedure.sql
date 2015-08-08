USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateAuthorizedStores_ACH]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateAuthorizedStores_ACH]
as

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

update w set WorkingStatus = -8
--select *
from StoreTransactions_Working w
where 1 = 1
and WorkingSource in ('SUP-S', 'SUP-U')
and WorkingStatus = 3
and StoreID not in (select distinct StoreID from Storesetup as ss with (nolock) where ss.ChainID = w.ChainID and ss.SupplierID = w.SupplierID)
and ProcessID = @ProcessID

if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Unauthorized Stores Found in ACH'
		,'ACH records have been found that are unauthorized.  These records have been set to a workingstatus value of -8 and will not be processed.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
	end
return
GO
