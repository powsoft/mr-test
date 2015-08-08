USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateAuthorizedItems_Debug]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateAuthorizedItems_Debug]
as


delete
--select *
from Util_UnAuthorizedProducts
where cast(getdate() as date) = '7/1/2012'
and SupplierID = 40559
and ProductID in
(18954,
19071,
27015,
27014,
27188,
27189,
14381,
19072)

update w set WorkingStatus = -7
--select *
from StoreTransactions_Working w
inner join Util_UnAuthorizedProducts u
on w.ProductID = u.productid
and w.SupplierID = u.supplierid
and u.Banner is null
and WorkingSource in ('POS')
and WorkingStatus = 4


if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Unauthorized Products Found in POS'
		,'POS records have been found that are unauthorized.  These records have been set to a workingstatus value of -7 and will not be processed.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;mandeep@amebasoftwares.com'
	end


update w set WorkingStatus = -7
--select *
from StoreTransactions_Working w
inner join Util_UnAuthorizedProducts u
on w.ProductID = u.productid
and w.SupplierID = u.supplierid
and u.Banner is not null
and WorkingSource in ('POS')
and WorkingStatus = 4
and storeid in (select storeid from stores where LTRIM(rtrim(custom1)) = LTRIM(rtrim(u.Banner)))
--select distinct custom1 from stores



if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Unauthorized Products Found in POS'
		,'POS records have been found that are unauthorized.  These records have been set to a workingstatus value of -7 and will not be processed.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
	end

update w set w.workingstatus = 4
--select w.* into import.dbo.StoreTransactions_Working_20130325
from StoreTransactions_Working w
inner join storesetup s
on w.StoreID = s.StoreID
and w.ProductID = s.ProductID
and w.SupplierID = s.SupplierID
--and CAST(w.SaleDateTime as date) = '7/7/2012'
and w.WorkingSource = 'POS'
and w.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate
and w.WorkingStatus = -7

update w set w.SourceOrDestinationID = 1
from StoreTransactions_Working w
inner join storesetup s
on w.StoreID = s.StoreID
and w.ProductID = s.ProductID
and w.SupplierID = s.SupplierID
--and CAST(w.SaleDateTime as date) = '7/7/2012'
and w.WorkingSource = 'POS'
and w.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate
and w.WorkingStatus = 4


select *
from StoreTransactions_Working w
where w.WorkingSource = 'POS'
and w.WorkingStatus = 4
and isnull(w.SourceOrDestinationID, 0) <> 1


if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Products Found in POS Failing StoreSetup Match'
		,'POS records have been found that fail the storesetup match.  These records have been allowed to flow through to billing but need validation.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
	end
	
update w set w.WorkingStatus = -7
from StoreTransactions_Working w
--inner join storesetup s
--on w.StoreID = s.StoreID
--and w.ProductID = s.ProductID
--and w.SupplierID = s.SupplierID
--and CAST(w.SaleDateTime as date) = '7/7/2012'
where w.WorkingSource = 'POS'
--and w.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate
and w.WorkingStatus = 4
and isnull(w.SourceOrDestinationID, 0) <> 1
	
--update t set t.WorkingStatus = -2
----select *
--from storetransactions_working t
--where ProductID = 5462
--and ChainID <> 40393
--and WorkingStatus <> 5

--if @@ROWCOUNT > 0
--	begin
--		exec dbo.prSendEmailNotification_PassEmailAddresses 'Products Found in POS For Guns and Ammo at Pantry'
--		,'POS records have been found for productid 5462 For Guns and Ammo at Pantry.  These records have been set to a workingstatus of -2 and need review and validation.  Contact Esther for directions.'
--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
--	end
--------select StoreTransactionID, StoreID, ProductID, BrandID, SupplierID, CAST(saledatetime as date) as Saledate
--------,CAST(0 as int) as PastQtyReceived, Cast(0 as bit) as DeAuthorizeMRFound, CAST(0 as bit) as PendAsUnAuthorized
--------into #tempPendCheck 
--------from StoreTransactions_Working w
--------where w.WorkingSource = 'POS'
----------and CAST(w.SaleDateTime as date) = '7/7/2012'
--------and SourceOrDestinationID is null
--------and w.WorkingStatus = 4

--------update t set PastQtyReceived = s.PastQty
----------select *
--------from #tempPendCheck t
--------inner join
--------(
--------select storeid, ProductId, brandid, supplierid, SUM(Qty) as PastQty
--------from StoreTransactions_Working
--------where WorkingSource = 'POS'
--------and WorkingStatus = 5
--------and SaleDateTime < DATEADD(day, -14, getdate())
--------group by storeid, ProductId, brandid, supplierid
--------) s
--------on t.StoreID = s.StoreID
--------and t.ProductID = s.ProductID
--------and t.BrandID = s.BrandID
--------and t.SupplierID = s.SupplierID

--------select storeid, ProductId, brandid, supplierid, r.EndDateTime
--------into #tempMRwithStores
--------from MaintenanceRequests r
--------inner join MaintenanceRequestStores s
--------on r.MaintenanceRequestID = s.MaintenanceRequestID
--------and r.RequestTypeID in (1,2,9)
--------and ISNULL(r.approved, 0) = 1
--------and r.datetimecreated > '9/1/2012'

--------update t 
--------set t.DeAuthorizeMRFound = 1, PendAsUnAuthorized = 1
--------from #tempPendCheck t
--------inner join #tempMRwithStores s
--------on t.StoreID = s.StoreID
--------and t.ProductID = s.productid
--------and t.BrandID = s.brandid
--------and t.SupplierID = s.SupplierID
--------and s.EndDateTime < GETDATE()

--------update t 
--------set t.DeAuthorizeMRFound = 0, PendAsUnAuthorized = 0
--------from #tempPendCheck t
--------inner join #tempMRwithStores s
--------on t.StoreID = s.StoreID
--------and t.ProductID = s.productid
--------and t.BrandID = s.brandid
--------and t.SupplierID = s.SupplierID
--------and s.EndDateTime > GETDATE()

--update W set w.workingstatus = -7
--from StoreTransactions_Working w
--inner join #tempPendCheck t
--on w.StoreTransactionID = t.StoreTransactionID
--and ISNULL(t.DeAuthorizeMRFound, 0) = 1

--if @@ROWCOUNT > 0
--	begin
--		exec dbo.prSendEmailNotification_PassEmailAddresses 'Products Found in POS Failing StoreSetup Match'
--		,'POS records have been found that fail the storesetup match.  These records have been allowed to flow through to billing but need validation.'
--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
--	end

--update W set w.workingstatus = -7
--from StoreTransactions_Working w
--inner join #tempPendCheck t
--on w.StoreTransactionID = t.StoreTransactionID
--and ISNULL(t.DeAuthorizeMRFound, 0) = 0
--and t.PastQtyReceived = 0

--if @@ROWCOUNT > 0
--	begin
--		exec dbo.prSendEmailNotification_PassEmailAddresses 'Products Found in POS Failing StoreSetup Match'
--		,'POS records have been found that fail the storesetup match.  These records have been allowed to flow through to billing but need validation.'
--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
--	end

select distinct [DATE]
from import.dbo.SourceAcmeRollout
where CAST([Date] as date) = CAST(getdate() as date)

if @@ROWCOUNT > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'Store Rollout Today'
		,'POS records from a store going active today are expected.  Please check for this new POS.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
	end
	
return
GO
