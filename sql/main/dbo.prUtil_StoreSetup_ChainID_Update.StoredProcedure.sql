USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_StoreSetup_ChainID_Update]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_StoreSetup_ChainID_Update]
as
select distinct supplierid from StoreTransactions where SaleDateTime between '12/1/2011' and '12/7/2011'
select distinct datatruesupplierid from datatrue_edi.dbo.EDI_SupplierCrossReference where datatruesupplierid IS not null

select * into import.dbo.storesetup_20111208_BeforeDupeSupplierChange from StoreSetup

select *
--update s set ChainID = 41532
from storesetup s
where chainid = 40393
and SupplierID not in
(
select distinct datatruesupplierid from datatrue_edi.dbo.EDI_SupplierCrossReference where datatruesupplierid IS not null
)


select * from Suppliers where SupplierID in
(
select distinct supplierid
--update s set ChainID = 41532
from storesetup s
where chainid = 40393
and SupplierID not in
(
select distinct datatruesupplierid from datatrue_edi.dbo.EDI_SupplierCrossReference where datatruesupplierid IS not null
)
)
and SupplierID <> 0

return
GO
