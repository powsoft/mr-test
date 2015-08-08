USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_AAA_AM_Review]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_AAA_AM_Review]
as

SELECT *
  FROM [DataTrue_EDI].[dbo].[Costs]
where RecordStatus = 0



SELECT *
  FROM [DataTrue_EDI].[dbo].[Promotions]
  where Loadstatus = 0



SELECT     RequestStatus AS status, StartDateTime AS startdate, *
FROM         MaintenanceRequests
where RequestStatus = 0


 select banner, filename, saledate, COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales
where RecordStatus = 0
and Qty <> 0
group by banner, filename, saledate

 select storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO)), COUNT(recordid)
from datatrue_edi.dbo.Inbound852Sales
where 1 = 1
and RecordStatus = 0
--and banner = 'SS'
--and CAST(saledatetime as date) = '11/21/2011'
group by storeidentifier, ProductIdentifier, cast(SaleDate as date), ltrim(rtrim(PONO))
having COUNT(recordid) > 1

 select *
--update s set recordstatus = -5
from datatrue_edi.dbo.Inbound852Sales s
where RecordStatus = 0
and Banner = 'SYNC'
 
 
     select distinct ltrim(rtrim(UPC))
 from StoreTransactions_Working w
  where workingStatus = 1
  and ltrim(rtrim(UPC))
  not in 
(select ltrim(rtrim(identifiervalue)) from ProductIdentifiers)

return
GO
