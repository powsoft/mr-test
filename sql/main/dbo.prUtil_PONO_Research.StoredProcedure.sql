USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_PONO_Research]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_PONO_Research]
as

select * from InvoiceDetailS
where PONo = '105666'
and SaleDate in ('12/5/2011','12/6/2011')
order by RawProductIdentifier

select * from storetransactions
where cast(saledatetime as date) in ('12/5/2011','12/6/2011')
and PONo = '105666'

select * from storetransactions_working
where cast(saledatetime as date) in ('12/5/2011','12/6/2011')
and PONo = '105666'

select * from storetransactions_working
where cast(saledatetime as date) in ('12/5/2011','12/6/2011')
and PONo = '105668'

select w.SetupCost, t.SetupCost, w.ReportedCost, t.ReportedCost, w.Qty, t.Qty, *
from storetransactions_working w
inner join storetransactions t
on w.StoreID = t.StoreID
and w.ProductID = t.ProductID
and w.SupplierID = t.SupplierID
and CAST(w.saledatetime as date) = CAST(t.saledatetime as date)
and w.StoreTransactionID in
(
4703710,
4703711,
4698633
)

/*
StoreNo
 PONo
 UPC
 SupplierIdentifier
 
7937
 105666
 1410007160
 140589
 
7937
 105666
 1410009527
 140589
 
7937
 105668
 7192101669
 561983
 */
 
 return
GO
