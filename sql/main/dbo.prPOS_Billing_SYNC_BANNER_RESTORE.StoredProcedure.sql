USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPOS_Billing_SYNC_BANNER_RESTORE]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPOS_Billing_SYNC_BANNER_RESTORE]
as

update w set banner = 'SYNC'
--select distinct supplierid, banner
from StoreTransactions_Working w
where 1 = 1
and Banner <> 'SYNC'
and WorkingStatus in (1, 2, 3, 4)
and ltrim(rtrim(SupplierIdentifier)) in ('5315075','7351304')
and SaleDateTime > '11/30/2011'

return
GO
