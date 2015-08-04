USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_GetStoresToBill_B]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prBilling_GetStoresToBill_B]
@billingcontrolid int --,
--@billingcontrolchainid int

as
/*
select * from dbo.BillingGroups
select * from dbo.BillingGroupTypes
prBilling_GetStoresToBill 48, 40393
*/

declare @chainid int
declare @billinggrouptablecolumnname nvarchar(50)
declare @parametertablename nvarchar(50)
declare @parametercolumnname nvarchar(50)
declare @operator nvarchar(50)
declare @rec cursor
declare @strSQL nvarchar(4000)
declare @billnggrouprecordcount int

select CAST(null as int) as StoreID into #tempStoresToBill

truncate table #tempStoresToBill

set @rec = CURSOR local fast_forward FOR

select distinct g.chainid, p.BillingGroupTableColumnName, p.BillingGroupParameterTableName, p.BillingGroupParameterTableColumnName, p.BillingGroupParameterOperator
from dbo.BillingGroups g
inner join dbo.BillingGroupTypes t
on g.BillingGroupTypeID = t.BillingGroupTypeID
and t.GroupEntityTypeName = 'Store'
inner join dbo.BillingGroupParameters p
on t.BillingGroupTypeID = p.BillingGroupTypeID
where g.BillingControlID = @billingcontrolid

open @rec

fetch next from @rec into @chainID, @billinggrouptablecolumnname,@parametertablename,@parametercolumnname,@operator

if @@FETCH_STATUS = 0
	begin
		while @@FETCH_STATUS = 0
			begin
			
				--select @billnggrouprecordcount = COUNT(BillingControlID) 
				--from BillingGroups g inner join BillingGroupTypes t 
				--on g.BillingGroupTypeID = t.BillingGroupTypeID 
				--and t.GroupEntityTypeName = 'Store'
				--and g.BillingControlID = 48 @billingcontrolid
				
				set @strSQL = 'Insert into #tempStoresToBill Select StoreID from stores e inner join '
				--Stores where '
				set @strSQL = @strSQL + @parametertablename + ' t on e.StoreId = t.ownerentityid where ' + @parametercolumnname + ' ' + @operator
				set @strSQL = @strSQL + ' (select distinct ' + @billinggrouptablecolumnname + ' from BillingGroups where BillingControlID = ' + cast(@billingcontrolid as nvarchar) + ')'
				set @strSQL = @strSQL + ' and e.ChainID in (select distinct chainid from BillingGroups where BillingControlID = ' + cast(@billingcontrolid as nvarchar) + ')'
				print @strSQL
				
				execute(@strSQL)
				
				fetch next from @rec into @chainID, @billinggrouptablecolumnname,@parametertablename,@parametercolumnname,@operator
			end
	end
else
	begin
		Insert into #tempStoresToBill Select distinct StoreID from storetransactions --where stores e where e.ChainID = @billingcontrolchainid
	end		

		
	
close @rec
deallocate @rec

select StoreID from #tempStoresToBill








return
GO
