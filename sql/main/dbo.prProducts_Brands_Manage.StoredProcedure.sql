USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProducts_Brands_Manage]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProducts_Brands_Manage]

as


update t set t.BrandID = a.BrandID
--select t.BrandID, a.BrandID, *
from datatrue_main.dbo.StoreTransactions t
inner join datatrue_Report.dbo.ProductBrandAssignments a
on t.ProductID = a.ProductID
and t.BrandID <> a.brandid
and t.SupplierID = 40561
and t.BrandID = 0
and a.BrandID <> 0

update t set t.BrandID = a.BrandID
--select t.BrandID, a.BrandID, *
from datatrue_report.dbo.StoreTransactions t
inner join datatrue_report.dbo.ProductBrandAssignments a
on t.ProductID = a.ProductID
and t.BrandID <> a.brandid
and t.SupplierID = 40561
and t.BrandID = 0
and a.BrandID <> 0


update t set t.BrandID = a.BrandID
--select t.BrandID, a.BrandID, *
from datatrue_report.dbo.StoreTransactions t
inner join datatrue_report.dbo.ProductBrandAssignments a
on t.ProductID = a.ProductID
and t.ChainID = a.CustomOwnerEntityID
and t.BrandID <> a.brandid
and ChainID in (select ChainID from chains where PDITradingPartner = 1)
--and ChainID in (44285, 59973)
and t.BrandID = 0
and a.BrandID <> 0

/*
select *
from datatrue_main.dbo.StoreTransactions t
where 1 = 1
and t.SupplierID = 40561
--and t.productid = 19612
and t.BrandID = 0

*/

return
GO
