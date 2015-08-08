USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPOS_Supplier_Info_PopulateWhenNull]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPOS_Supplier_Info_PopulateWhenNull]
as

update w set w.SupplierIdentifier = e.SupplierIdentifier
--select *
from [dbo].[StoreTransactions_Working] w
inner join datatrue_edi.dbo.EDI_SupplierCrossReference_byCorp e
on w.SupplierID = e.DataTrueSupplierID
and ltrim(rtrim(w.Banner)) = ltrim(rtrim(e.Banner))
where WorkingStatus = 3
and WorkingSource in ('POS')
and (w.SupplierIdentifier is null or LEN(w.supplieridentifier) < 1)

update w set w.SupplierName = e.SupplierName
--select *
from [dbo].[StoreTransactions_Working] w
inner join datatrue_edi.dbo.EDI_SupplierCrossReference_byCorp e
on w.SupplierID = e.DataTrueSupplierID
and ltrim(rtrim(w.Banner)) = ltrim(rtrim(e.Banner))
where WorkingStatus = 3
and WorkingSource in ('POS')
and (w.SupplierName is null or LEN(w.suppliername) < 1)



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
