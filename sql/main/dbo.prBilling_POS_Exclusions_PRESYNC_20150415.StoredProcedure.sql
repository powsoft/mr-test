USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_POS_Exclusions_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_POS_Exclusions_PRESYNC_20150415]
as

Declare @ProcessID int
Select @ProcessID = LastProcessID From JobRunning Where JobRunningId = 14

update t set t.TransactionStatus = Case when Isnull(Recordtype,0) = 0 then 3 else 813 end, ProcessingErrorDesc = isnull(ProcessingErrorDesc, '') + '-This POS record excluded from billing by BillingExclusion table records.', DateTimeLastUpdate = GETDATE()
--select *
from StoreTransactions t with (index(98))
inner join BillingExclusions e
on t.StoreID = e.StoreID
and t.ProductID = e.ProductID
and e.Supplierid = 0
and e.BrandID = 0
and t.SaleDateTime between e.ActiveStartDate and e.ActiveLastDate
and e.InvoiceDetailTypeID = 1
and t.TransactionStatus not in (813, 3, 810, 811)
and t.ProcessID In (Select ProcessID From JobProcesses where JobRunningID in (9,13,14))
and t.SaleDateTime >= '2014-10-01'
and convert(date, t.DateTimeCreated) >= dateadd(day, -1, CONVERT(date, getdate()))
--option (querytraceon 8649)

update t set t.TransactionStatus = Case when Isnull(Recordtype,0) = 0 then 3 else 813 end, ProcessingErrorDesc = isnull(ProcessingErrorDesc, '') + '-This POS record excluded from billing by BillingExclusion table records.', DateTimeLastUpdate = GETDATE()
--select *
from StoreTransactions t with (index(98))
inner join BillingExclusions e
on t.chainid = e.chainid
and e.StoreID = 0
and e.ProductID = 0
and e.Supplierid = 0
and e.InvoiceDetailTypeID = 1
and t.TransactionStatus not in (813, 3, 810, 811)
and LTRIM(rtrim(t.upc)) = LTRIM(rtrim(e.upc))
and t.SaleDateTime between e.ActiveStartDate and e.ActiveLastDate
and t.ProcessID In (Select ProcessID From JobProcesses where JobRunningID in (9,13,14))
and t.SaleDateTime >= '2014-10-01'
and convert(date, t.DateTimeCreated) >= dateadd(day, -1, CONVERT(date, getdate()))

update t set t.TransactionStatus = Case when Isnull(Recordtype,0) = 0 then 3 else 813 end, ProcessingErrorDesc = isnull(ProcessingErrorDesc, '') + '-This POS record excluded from billing by BillingExclusion table records.', DateTimeLastUpdate = GETDATE()
--select *
from StoreTransactions t with (index(98))
inner join BillingExclusions e
on t.chainid = e.chainid
and e.StoreID = t.StoreID
and e.ProductID = 0
and e.Supplierid = t.SupplierID
and e.InvoiceDetailTypeID = 1
and t.TransactionStatus not in (813, 3, 810, 811)
--and LTRIM(rtrim(t.upc)) = LTRIM(rtrim(e.upc))
and t.SaleDateTime between e.ActiveStartDate and e.ActiveLastDate
and t.ProcessID In (Select ProcessID From JobProcesses where JobRunningID in (9,13,14))
and t.SaleDateTime >= '2014-10-01'
and convert(date, t.DateTimeCreated)>= dateadd(day, -1, CONVERT(date, getdate()))

update t set t.TransactionStatus = Case when Isnull(Recordtype,0) = 0 then 3 else 813 end, ProcessingErrorDesc = isnull(ProcessingErrorDesc, '') + '-This POS record excluded from billing by BillingExclusion table records.', DateTimeLastUpdate = GETDATE()
--select ProcessingErrorDesc, *
from StoreTransactions t with (index(98))
inner join BillingExclusions e
on t.chainid = e.chainid
and e.StoreID = 0
and e.ProductID = 0
and e.Supplierid = t.SupplierID
and e.InvoiceDetailTypeID = 1
and t.TransactionStatus not in (813, 3, 810, 811)
--and LTRIM(rtrim(t.upc)) = LTRIM(rtrim(e.upc))
and t.SaleDateTime between e.ActiveStartDate and e.ActiveLastDate
and t.ProcessID In (Select ProcessID From JobProcesses where JobRunningID in (9,13,14))
and t.SaleDateTime >= '2014-10-01'
and convert(date, t.DateTimeCreated) >= dateadd(day, -1, CONVERT(date, getdate()))


/*
select * from products where productid = 7974

select * from billingexclusions

select *
from productidentifiers
where 1 = 1
and productidentifiertypeid = 2
and identifiervalue = '042704001938'


"051321000057/37703" Or "070992352708/(Type2-3482430)" Or "075470082337(type2-7974)" or “042704001938"

select *
--update t set t.productid = i.productid
from dbo.zztemp_CFExclusions_20140310 t
inner join productidentifiers i
on ltrim(rtrim(t.bipad)) = ltrim(rtrim(i.bipad))
and i.productidentifiertypeid = 8

select *
--update t set t.storeid = i.storeid
from dbo.zztemp_CFExclusions_20140310 t
inner join stores i
on replace(ltrim(rtrim(t.store)), 'CF', '') = ltrim(rtrim(i.custom2))
and i.chainid = 60624

select *
--select distinct bipad
from dbo.zztemp_CFExclusions_20140310
where productid is null
order by productid

select *
from productidentifiers
where bipad like '%BIAGD%'
BIAGD
ND
NEWBD
UNHR
Z0342



INSERT INTO [DataTrue_Main].[dbo].[BillingExclusions]
           ([InvoiceDetailTypeID]
           ,[ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[Supplierid]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateDateTime]
           ,[DateTimeCreated]
           ,[LastUpdateUserID])
     select 0 --<InvoiceDetailTypeID, int,>
           ,60624 --<ChainID, int,>
           ,storeid --<StoreID, int,>
           ,productid --<ProductID, int,>
           ,0 --<BrandID, int,>
           ,0 --<Supplierid, int,>
           ,'1/1/2014' --<ActiveStartDate, datetime,>
           ,'12/31/2099' --<ActiveLastDate, datetime,>
           ,getdate() --<LastUpdateDateTime, datetime,>
           ,getdate() --<DateTimeCreated, datetime,>
           ,0 --<LastUpdateUserID, int,>)

--select *
from dbo.zztemp_CFExclusions_20140310
where storeid is not null
and productid is not null
*/




return
GO
