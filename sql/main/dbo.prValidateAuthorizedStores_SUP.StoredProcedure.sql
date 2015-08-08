USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateAuthorizedStores_SUP]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateAuthorizedStores_SUP]
as


update w set WorkingStatus = -8
--select *
from StoreTransactions_Working w
inner join Util_UnAuthorizedStores u
on w.StoreID=u.StoreID
and WorkingSource in ('SUP-S','SUP-U')
and WorkingStatus = 4
and w.ChainID in (40393)


if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Unauthorized Stores Found in Deliveries and Pickup'
		,'Deleiveries & pickup records have been found that are unauthorized.  These records have been set to a workingstatus value of -8 and will not be processed.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com'
	end
return
GO
