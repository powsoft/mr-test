USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetUPC_From_Bipad_POS]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetUPC_From_Bipad_POS]
as

declare @daysbackcount smallint = 0
declare @limittolookbackindays smallint = 7
declare @nullupcremainingcount int

while @daysbackcount <= @limittolookbackindays
	begin
		update w set w.UPC = LTRIM(rtrim(t.UPC))
		--select *
		from StoreTransactions_Working w
		inner join StoreTransactions t
		on w.storeid = t.storeid
		and w.ProductID = t.productid
		and w.BrandID = t.BrandID
		and CAST(w.saledatetime as date) = CAST(dateadd(day, @daysbackcount,t.saledatetime) as date)
		and t.TransactionTypeID = 2
		and w.WorkingStatus between 2 and 4
		and t.UPC is null
		
		set @daysbackcount = @daysbackcount + 1
	end

update w set w.UPC = LTRIM(rtrim(t.IdentifierValue))
--select *
from StoreTransactions_Working w
inner join productidentifiers t
on w.ProductID = t.productid
and t.ProductIdentifierTypeID = 8
and w.WorkingStatus between 2 and 4
and w.UPC is null

select @nullupcremainingcount = count(StoreTransactionID)
from StoreTransactions_Working w
where 1 = 1
and w.WorkingStatus between 2 and 4
and w.UPC is null

if @nullupcremainingcount > 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'UPC NOT FOUND WITH BIPAD'
		,'UPC NOT FOUND WITH BIPAD'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'			
	end			

/*
select top 1000 *
from storetransactions
where transactiontypeid = 2
order by storetransactionid desc

*/

return
GO
