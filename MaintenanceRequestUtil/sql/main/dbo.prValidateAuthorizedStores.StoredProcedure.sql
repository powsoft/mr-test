USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateAuthorizedStores]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateAuthorizedStores]
as


--select * from stores where chainid = 40393

insert into Util_UnAuthorizedStores
	(StoreID, DateTimeCreated, LastActiveDate)
	select storeid, DATEADD(day, -7, Activelastdate), Activelastdate 
	from stores
	where ActiveLastDate < DATEADD(day, 7, getdate())
	and StoreID not in
	(
		select storeid 
		from Util_UnAuthorizedStores
	)

--select * from Util_UnAuthorizedStores
update w set WorkingStatus = -8
--select *
from StoreTransactions_Working w
inner join Util_UnAuthorizedStores u
on w.StoreID=u.StoreID
--and WorkingSource in ('POS')
and WorkingStatus = 4
and (CAST(w.saledatetime as date) > cast(u.LastActiveDate as date) or GETDATE() > u.BlockDate)
and w.ChainID not in (44199)

if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Unauthorized Stores Found in POS'
		,'POS records have been found that are unauthorized.  These records have been set to a workingstatus value of -8 and will not be processed.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com'
	end
return
GO
