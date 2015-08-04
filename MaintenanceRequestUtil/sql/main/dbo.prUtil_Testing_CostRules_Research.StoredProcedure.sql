USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_CostRules_Research]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Testing_CostRules_Research]
as

select *
from datatrue_edi.dbo.Inbound852Sales
where RawProductIdentifier = '007294576145'
and Saledate = '11/26/2011'
order by storeidentifier

select * from StoreTransactions_Working
where UPC = '072945761452'
and cast(SaleDateTime as date) = '11/26/2011'
and ltrim(rtrim(StoreIdentifier)) = '0006017'

select *
from StoreTransactions
where WorkingTransactionID in
(
select StoreTransactionID from StoreTransactions_Working
where UPC = '072945761452'
and cast(SaleDateTime as date) = '11/26/2011'
and ltrim(rtrim(StoreIdentifier)) = '0006017'
)

return
GO
