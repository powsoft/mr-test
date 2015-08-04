USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPOS_Dupe_Check]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPOS_Dupe_Check]
as


-- update t set workingstatus = -872
-- --select *
-- from storetransactions_working t
-- where StoreID = 41235
-- and SupplierID = 41440
--and WorkingStatus = 4
--and WorkingSource = 'POS'

update t set workingstatus = -871	 
--select *
from storetransactions_working t
inner join [DataTrue_EDI].[dbo].[NST_Items] i
on t.UPC = i.UPC
and StoreID = 40542
and i.Type = 'I'	 
and WorkingSource = 'POS'
and WorkingStatus = 4

declare @rec cursor
declare @storeid int
declare @productid int
declare @transid int
declare @rec2 cursor

set @rec = CURSOR local fast_forward FOR

 select storeid, productid
from StoreTransactions_Working w
where 1 = 1
and WorkingStatus = 4
and WorkingSource = 'POS'
and ChainID in (40393, 44125)
group by storeid, productid, storeidentifier, upc, cast(w.SaleDateTime as date), ltrim(rtrim(PONO))
having COUNT(w.storetransactionid) = 2
order by StoreID, ProductID

open @rec 

fetch next from @rec into @storeid, @productid

while @@FETCH_STATUS = 0
	begin
	
		print @storeid
		print @productid
		
		set @rec2 = CURSOR local fast_forward FOR
			select Storetransactionid
			from StoreTransactions_Working w
			where 1 = 1
			and WorkingStatus = 4
			and StoreID = @storeid
			and ProductID = @productid
			order by StoreTransactionID desc
			
		open @rec2
		
		fetch next from @rec2 into @transid
		
		while @@fetch_status  = 0
			begin
		
		update StoreTransactions_Working set WorkingStatus = -1112 where StoreTransactionID = @transid
		
		fetch next from @rec2 into @transid
		fetch next from @rec2 into @transid
		
		end
		
	close @rec2
	deallocate @rec2
		
fetch next from @rec into @storeid, @productid
	
	
	
	end
	
close @rec
deallocate @rec
GO
