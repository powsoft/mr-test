USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_PromoAllowance_Update]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Testing_PromoAllowance_Update]
as


select distinct suppliername from SuppliersSetupData



select *
from StoreTransactions
where Banner = 'ABS'
and SaleDateTime = '12/1/2011'

select *
from StoreTransactions
where Banner = 'SS'
and SaleDateTime = '12/1/2011'
and ReportedAllowance > 0
and PromoAllowance is null
and SetupCost is not null
order by ReportedAllowance desc

--update promoallowance with reported when setup is not null and > reported cost
select *
--update t set t.promotypeid = 8, t.promoallowance = t.reportedallowance
from StoreTransactions t
where Banner = 'SV'
and SaleDateTime = '12/1/2011'
and ReportedAllowance > 0
and SetupCost > ReportedCost
and PromoAllowance is null
and SetupCost is not null
order by ReportedAllowance desc

select *
--update t set PromoTypeID = 8, PromoAllowance = Allowance
from StoreTransactions t
inner join SuppliersSetupData s
on t.StoreID = s.StoreID and t.ProductID = s.ProductID and t.SupplierID = s.datatruesupplierid
where t.Banner = 'SS'
and t.SaleDateTime = '12/1/2011'
--and t.ReportedAllowance > 0
and t.PromoAllowance is null
and CAST(saledatetime as date) between StartDate and EndDate
and StartDate is not null and EndDate is not null
order by ReportedAllowance desc


select distinct banner from SuppliersSetupData 
select distinct banner from SuppliersSetupDataMore

/*
select *
--update t set PromoTypeID = 8, PromoAllowance = Allowance
from StoreTransactions t
inner join SuppliersSetupDatamore s
on t.StoreID = s.StoreID and t.ProductID = s.ProductID and t.SupplierID = s.datatruesupplierid
where t.Banner = 'SS'
and t.SaleDateTime = '12/1/2011'
and t.ReportedAllowance > 0
and t.PromoAllowance is null
order by ReportedAllowance desc
*/

select * from SuppliersSetupData 
where suppliername = 'bimbo'
and storeid = 41021 and productid = 18568 and datatruesupplierid = 40557

/*
41021	18568	40557
41151	18516	40557
41021	5911	40557
41174	18568	40557
41134	18558	40557
41136	18518	40557
41136	18569	40557
41023	18569	40557
41205	5909	40557
*/
GO
