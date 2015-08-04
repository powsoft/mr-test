USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInventory_Counts_Multiple_ApplyToInventory_And_Invoice_Manually]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInventory_Counts_Multiple_ApplyToInventory_And_Invoice_Manually]
as

--**************************LOAD ALL COUNTS**************************
declare @reccount cursor
declare @countdate date
declare @cntsupplierid int--=40561
declare @initialcountdate as date='12/1/2011'

set @reccount = CURSOR local fast_forward FOR
	select distinct Supplierid, CAST(saledatetime as date)
	--select *
	from StoreTransactions t
	where 1 = 1
	--and SupplierID = 40562
	and t.TransactionTypeID = 11
	and t.TransactionStatus = 0
	and CAST(t.saledatetime as date) = '2013-02-21'
	and t.RuleCost is not null
	order by Supplierid, CAST(saledatetime as date)
	
open @reccount

fetch next from @reccount into  @cntsupplierid, @countdate

	begin
		exec prApplyINVStoreTransactionsToInventory_PassDateAndSupplier_NOCURSOR @countdate, @cntsupplierid 
		--exec prProcessShrink_PassDateAndSupplierId @countdate, @cntsupplierid
		--exec [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Shrink]
		--exec dbo.prInvoiceDetail_Retailer_Shrink_Create	
		fetch next from @reccount into  @cntsupplierid, @countdate	
	end
	
close @reccount
deallocate @reccount

return


/*
select * from inventoryperpetual
where shrinkrevision <> 0

select *
from storetransactions
where supplierid = 40562
and transactiontypeid in (5,8)
order by saledatetime desc

select *
from invoicedetails
where supplierid = 40562
and invoicedetailtypeid in (3)
order by saledate desc

*/
GO
