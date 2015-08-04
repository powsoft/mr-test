USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_UPC_Cleanup]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_UPC_Cleanup]
as

select distinct ProductId from StoreTransactions where ChainID = 40393

drop table Import.dbo.UPCCleanUp_20111116

select distinct ProductIdentifier
from DataTrue_EDI.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
order by ProductIdentifier

select distinct cast(0 as int) as ProductID
,ltrim(rtrim(ProductIdentifier)) as UPC_Old
,CAST('' as nvarchar(50)) as UPC_Corrected
,CAST(0 as bit) as Applied
into Import.dbo.UPCCleanUp_20111116
from DataTrue_EDI.dbo.Inbound852Sales
where ChainIdentifier = 'SV'
and RecordStatus = 1
order by ltrim(rtrim(ProductIdentifier))

select * from Import.dbo.UPCCleanUp_20111116

select *
--update i set i.ProductID = p.ProductID
from Import.dbo.UPCCleanUp_20111116 i
inner join DataTrue_Main.dbo.ProductIdentifiers p
on ltrim(rtrim(i.UPC_Old)) = ltrim(rtrim(p.IdentifierValue))

declare @rec cursor
declare @upcold nvarchar(50)
declare @right11upcold nvarchar(50)
declare @upcnew nvarchar(50)
declare @checkdigit char(1)

set @rec = CURSOR local fast_forward FOR
	select UPC_OLD from Import.dbo.UPCCleanUp_20111116 where len(UPC_Corrected) = 0
	
open @rec

fetch next from @rec into @upcold

while @@FETCH_STATUS = 0
	begin
		set @checkdigit = ''
		set @right11upcold = right(@upcold, 11)
		exec prUtil_UPC_GetCheckDigit @right11upcold, @checkdigit output
		set @upcnew = right(@upcold, 11) + @checkdigit
		update Import.dbo.UPCCleanUp_20111116 set UPC_Corrected = @upcnew where UPC_Old = @upcold
		--print @upcold + '|' + @upcnew
		fetch next from @rec into @upcold	
	end
	
close @rec
deallocate @rec

select * from Import.dbo.UPCCleanUp_20111116

update Import.dbo.UPCCleanUp_20111116 set Extra = UPC_Corrected
update Import.dbo.UPCCleanUp_20111116 set UPC_Corrected = ''

select *
into Import.dbo.StoreTransactions_Working_20111116_BeforeUPCCleanup
from StoreTransactions_Working

select *
into Import.dbo.StoreTransactions_20111116_BeforeUPCCleanup
from StoreTransactions

select *
into Import.dbo.ProductIdentifiers_20111116_BeforeUPCCleanup
from ProductIdentifiers

select *
--update w set w.UPC = c.UPC_Corrected
from StoreTransactions_Working w
inner join Import.dbo.UPCCleanUp_20111116 c
on w.ProductID = c.ProductID

select *
--update w set w.UPC = c.UPC_Corrected
from StoreTransactions w
inner join Import.dbo.UPCCleanUp_20111116 c
on w.ProductID = c.ProductID

select *
--update w set w.identifiervalue = c.UPC_Corrected
from ProductIdentifiers w
inner join Import.dbo.UPCCleanUp_20111116 c
on w.ProductID = c.ProductID


truncate table DataTrue_Archive.dbo.InventoryPerpetual
truncate table DataTrue_Archive.dbo.StoreTransactions



select top 1000 * from datatrue_EDI.dbo.SV_ItemFile

select * from datatrue_EDI.dbo.SV_ItemFile

select distinct productcode from datatrue_EDI.dbo.SV_ItemFile

select distinct p.IdentifierValue
from datatrue_EDI.dbo.SV_ItemFile i
inner join ProductIdentifiers p
on ltrim(rtrim(i.ProductCode)) = ltrim(rtrim(p.IdentifierValue))

select * from stores where Custom3 = 'SV'


/*
declare @rec cursor
declare @upcold nvarchar(50)
declare @right11upcold nvarchar(50)
declare @upcnew nvarchar(50)
declare @checkdigit char(1)

set @rec = CURSOR local fast_forward FOR
	select ltrim(rtrim(productcode)) from datatrue_EDI.dbo.SV_ItemFile
	where len(productcode)<>13
open @rec

fetch next from @rec into @upcold

while @@FETCH_STATUS = 0
	begin
		set @checkdigit = ''
		set @right11upcold = right(@upcold, 11)
		exec prUtil_UPC_GetCheckDigit @right11upcold, @checkdigit output
		set @upcnew = right(@upcold, 11) + @checkdigit
		update datatrue_EDI.dbo.SV_ItemFile set [12digitUPC] = @upcnew where LTRIM(rtrim(ProductCode)) = @upcold
		--print @upcold + '|' + @upcnew
		fetch next from @rec into @upcold	
	end
	
close @rec
deallocate @rec
*/

return
GO
