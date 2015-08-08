USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_GetProductsToBill]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prBilling_GetProductsToBill]
@billingcontrolid int

as
/*
select * from dbo.BillingGroups
select * from dbo.BillingGroupTypes
prBilling_GetProductsToBill 49
*/

declare @chainid int
declare @billinggrouptablecolumnname nvarchar(50)
declare @parametertablename nvarchar(50)
declare @parametercolumnname nvarchar(50)
declare @operator nvarchar(50)
declare @rec cursor
declare @strSQL nvarchar(4000)

select CAST(null as int) as ProductID into #tempProductsToBill

truncate table #tempProductsToBill

set @rec = CURSOR local fast_forward FOR

select distinct p.chainid, p.BillingGroupTableColumnName, p.BillingGroupParameterTableName, p.BillingGroupParameterTableColumnName, p.BillingGroupParameterOperator
from dbo.BillingGroups g
inner join dbo.BillingGroupTypes t
on g.BillingGroupTypeID = t.BillingGroupTypeID
and t.GroupEntityTypeName = 'Product'
inner join dbo.BillingGroupParameters p
on t.BillingGroupTypeID = p.BillingGroupTypeID
where g.BillingControlID = @billingcontrolid

open @rec

fetch next from @rec into @chainID, @billinggrouptablecolumnname,@parametertablename,@parametercolumnname,@operator

while @@FETCH_STATUS = 0
	begin
		set @strSQL = 'Insert into #tempProductsToBill Select ProductID from Products e inner join '
		--Products where '
		set @strSQL = @strSQL + @parametertablename + ' t on e.ProductId = t.ownerentityid and e.ChainID = ' + cast(@chainid as nvarchar) + ' where ' + @parametercolumnname + ' ' + @operator
		set @strSQL = @strSQL + ' (select ' + @billinggrouptablecolumnname + ' from BillingGroups where BillingControlID = ' + cast(@billingcontrolid as nvarchar) + ')'
		
		print @strSQL
		
		execute(@strSQL)
		
		fetch next from @rec into @chainID, @billinggrouptablecolumnname,@parametertablename,@parametercolumnname,@operator
	
	end
	
close @rec
deallocate @rec

select ProductID from #tempProductsToBill








return
GO
