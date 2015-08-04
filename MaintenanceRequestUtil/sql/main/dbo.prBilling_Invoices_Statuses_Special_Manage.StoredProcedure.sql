USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Invoices_Statuses_Special_Manage]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Invoices_Statuses_Special_Manage]
as


--Pantry does not get a billing file sent to update the details so they will be skipped
update i set RecordStatus = 1
--select *
from datatrue_edi.dbo.InvoiceDetails i
where 1 = 1
and RecordStatus = 0
and ChainID in (74628,79380)

--update i set RecordStatus = 1
----select *
--from datatrue_edi.dbo.InvoiceDetails i
--where 1 = 1
--and RecordStatus = 0
--and ChainID in (42491)
--and SupplierID not in (65116)

update i set RecordStatus = 1
--select *
from datatrue_edi.dbo.InvoiceDetails i
where 1 = 1
and RecordStatus = 0
and ChainID in (40393)
and i.RecordType = 2
and i.Banner in ('ABS', 'SV')

update i set RecordStatus = 2
--select *
from datatrue_edi.dbo.InvoiceDetails i
where 1 = 1
and RecordStatus = 0
and ChainID in (40393)
--and i.RecordType = 2
and i.Banner in ('SS')

update i set RecordStatus = 1
--select *
from datatrue_edi.dbo.InvoiceDetails i
where 1 = 1
and RecordStatus = 0
and ChainID in (60627)
and RecordType = 2




return
GO
