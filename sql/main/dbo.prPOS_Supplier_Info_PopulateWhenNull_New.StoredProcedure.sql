USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPOS_Supplier_Info_PopulateWhenNull_New]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPOS_Supplier_Info_PopulateWhenNull_New]
as

update w set w.SupplierIdentifier = e.SupplierIdentifier
--select *
from [dbo].[StoreTransactions_Working] w
inner join datatrue_edi.dbo.EDI_SupplierCrossReference_byCorp e
on w.SupplierID = e.DataTrueSupplierID
and ltrim(rtrim(w.Banner)) = ltrim(rtrim(e.Banner))
where WorkingStatus = 4
and WorkingSource in ('POS')
and (w.SupplierIdentifier is null or LEN(w.supplieridentifier) < 1)

update w set w.SupplierName = e.SupplierName
--select *
from [dbo].[StoreTransactions_Working] w
inner join datatrue_edi.dbo.EDI_SupplierCrossReference_byCorp e
on w.SupplierID = e.DataTrueSupplierID
and ltrim(rtrim(w.Banner)) = ltrim(rtrim(e.Banner))
where WorkingStatus = 4
and WorkingSource in ('POS')
and (w.SupplierName is null or LEN(w.suppliername) < 1)

Update I Set I.SupplierID = W.Supplierid 
--Select W.*
from DataTrue_EDI..Inbound852Sales I with(nolock)
inner Join StoreTransactions_Working W with(nolock)
On I.RecordID = W.RecordID_EDI_852
Where I.SupplierID is Null
and I.RecordStatus in (1)
and W.WorkingStatus in (4, 5)
and W.WorkingSource = 'POS'
and W.SupplierID is not null



/*
select *
from [dbo].[StoreTransactions_Working] w
where WorkingStatus = 3

select *
from datatrue_edi.dbo.EDI_SupplierCrossReference_byCorp
where datatruesupplierid = 41440

*/
return
GO
