USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Reporting_Audit]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_Reporting_Audit]
as

select t.*
from DataTrue_Report..StoreTransactions t
inner join Stores s
on t.storeid = s.StoreID
and s.StoreIdentifier = '1002'

select SUM(qty * ruleretail) as RetailSales
from StoreTransactions t
inner join Stores s
on t.storeid = s.StoreID
and s.StoreIdentifier = '1002'

update ProductPrices set ActiveStartDate = '1/1/2000'
update StoreSetup set ActiveStartDate = '1/1/2000'



return
GO
