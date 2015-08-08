USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateAuthorizedStores_INV]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateAuthorizedStores_INV]
as


update w set WorkingStatus = -8
--select *
from StoreTransactions_Working w
inner join Util_UnAuthorizedStores u
on w.StoreID=u.StoreID
and WorkingSource in ('INV')
and WorkingStatus = 4
and w.ChainID not in (44199)


if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Unauthorized Stores Found in Inventory Load'
		,'INV records have been found that are unauthorized.  These records have been set to a workingstatus value of -8 and will not be processed.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com'
	end
return
GO
