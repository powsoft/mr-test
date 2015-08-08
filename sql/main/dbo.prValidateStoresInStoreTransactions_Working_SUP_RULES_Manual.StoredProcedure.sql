USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_RULES_Manual]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_SUP_RULES_Manual]

as

declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @ruleid int
declare @supplierid int
declare @ediname nvarchar(50)
declare @MyID int
set @MyID = 7582

begin try

select distinct top 50000 StoreTransactionID, ChainIdentifier, StoreIdentifier
into #tempStoreTransaction
--select LEFT(Banner , CHARINDEX('#',Banner)-2), Banner as BNR, workingstatus as status, *
--select Banner as BNR, *
from [dbo].[StoreTransactions_Working]
where WorkingStatus = 0
and WorkingSource in ('SUP-S', 'SUP-U', 'SUP-X')
--and EDIName = 'NST'
--and CHARINDEX('#',Banner) = 0
--order by len(Banner)

begin transaction

set @loadstatus = 1

update t set t.WorkingStatus = -5
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and WorkingSource in ('SUP-X')

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Supplier Transactions Types Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

update t set t.ChainID = c.ChainID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[Chains] c
on t.ChainIdentifier = c.ChainIdentifier
where t.WorkingStatus = 0

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and ChainID is null



if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Chain Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

update t set t.SupplierID = (select SupplierID from Suppliers where UniqueEDIName=t.EDIName)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID

update t set t.StoreID = CAST(tr.TranslationCriteria1 as int)
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [DataTrue_EDI].[dbo].[TranslationMaster] tr
on t.SupplierID = tr.TranslationSupplierID
and tr.TranslationTypeID = 25
and ltrim(rtrim(t.StoreIdentifier)) = ltrim(rtrim(tr.TranslationValueOutside))


/*
drop table #tempStoreTransaction
select * from #tempStoreTransaction
select * from Stores where StoreIdentifier = '02804'
*/
	set @rec = CURSOR local fast_forward for
			select distinct ediname from
			StoreTransactions_Working
			where 1=1
			and WorkingStatus = 0
			and WorkingSource in ('SUP-S', 'SUP-U')
			and StoreId is null

open @rec
fetch next from @rec into @ediname
while (@@FETCH_STATUS=0)
	Begin
		--Cursor to validate EDIBanner
		set @rec3=CURSOR local fast_forward for
					select r.RuleID,u.RuleUserEntityId from RuleUse u
					join Rules r on u.RuleId=r.ruleID
					and u.EdiName=@ediname
					and r.RuleTypeId=3
					order by RuleOrder
			open @rec3
			fetch next from @rec3 into @ruleid,@supplierid
			while(@@FETCH_STATUS=0)
				Begin
					if(@ruleid=10)
						Begin
								update t set t.EDIBanner=b.BannerValue
								--select distinct t.Banner,b.BannerValue
								from StoreTransactions_Working t join EdiBanners b
								on rtrim(ltrim(LEFT(Ltrim(Rtrim(Banner)),CHARINDEX(RIGHT(IsNull(Ltrim(Rtrim(Banner)),''),4),ltrim(rtrim(Banner)))-2)))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and WorkingSource in ('SUP-S', 'SUP-U')
								and t.EDIName=@ediname
						End
					else if(@ruleid=9)
						Begin
								update t set t.EDIBanner=b.BannerValue
								--select distinct t.Banner,b.BannerValue
								from StoreTransactions_Working t join EdiBanners b
								on Rtrim(LTRIM(LEFT(Banner , CHARINDEX('#',Banner)-2)))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and WorkingSource in ('SUP-S', 'SUP-U')
								and t.EDIName=@ediname
								and CHARINDEX('#',Banner)>0
						End
					else if(@ruleid=18)
						Begin
								update t set t.EDIBanner=b.BannerValue
								--select distinct t.Banner,b.BannerValue
								from StoreTransactions_Working t join EdiBanners b
								on Rtrim(LTRIM(LEFT(Banner , CHARINDEX(' ',Banner))))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and WorkingSource in ('SUP-S', 'SUP-U')
								and t.EDIName=@ediname
								and CHARINDEX(' ',Banner)>0
						End
					else if(@ruleid=8)
						Begin
								update t set t.EDIBanner=b.BannerValue
								--select distinct t.Banner,b.BannerValue
								from StoreTransactions_Working t join EdiBanners b
								on ltrim(rtrim(corporateidentifier))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and WorkingSource in ('SUP-S', 'SUP-U')
								and t.EDIName=@ediname
						End	
					else if(@ruleid=12)
						Begin
								update storetransactions_working 
								set EDIBanner ='SV'
								where 1 = 1
								and workingstatus = 0
								and WorkingSource in ('SUP-S', 'SUP-U')
								and EDIName = @ediname
						End	
					fetch next from @rec3 into @ruleid,@supplierid
				End
		close @rec3
		deallocate @rec3	
				
		--Cursor to validate Store
		set @rec2=CURSOR local fast_forward for
					select r.RuleID from RuleUse u
					join Rules r on u.RuleId=r.ruleID
					and u.EdiName=@ediname
					and r.RuleTypeId=2
					order by RuleOrder
			
			open @rec2
			fetch next from @rec2 into @ruleid
			while(@@FETCH_STATUS=0)
			Begin
				/*if(@ruleid=4)
					Begin
						--select distinct w.StoreIdentifier,w.StoreID
						update t set t.StoreID=s.StoreID 
						from Stores s 
						join StoreTransactions_Working t
						on CAST(s.Custom2 as int)=CAST(t.StoreIdentifier as int)
						and t.EDIName=@ediname and s.ChainID=40393
						and (t.StoreID is null or t.StoreID = 0)
						and WorkingStatus = 0
						and WorkingSource in ('INV') 
											--order by w.StoreIdentifier
					End
				else */if(@ruleid=5)
					Begin
						--select distinct w.StoreIdentifier,w.StoreID
						update t set t.StoreID=s.StoreID 
						from Stores s 
						join StoreTransactions_Working t
						on CAST(s.StoreIdentifier as int)=CAST(t.StoreIdentifier as int)
						and t.EDIName=@ediname and s.ChainID=t.ChainID
						and (t.StoreID is null or t.StoreID = 0)
						and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
						and WorkingStatus = 0
						and WorkingSource in ('SUP-S', 'SUP-U')
						--order by w.StoreIdentifier
					End
				else if(@ruleid=6)
					Begin
						--select *
						update t set t.StoreID = s.StoreID
						from [dbo].[StoreTransactions_Working] t
						inner join [dbo].[Stores] s
						on t.ChainID = s.ChainID 
						and cast('55' + right(ltrim(rtrim(t.StoreIdentifier)), 3) as int) = cast(ltrim(rtrim(s.custom2)) as int)
						and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
						where 1 = 1
						and WorkingStatus = 0
						and EDIName = @ediname
						and (t.StoreID is null or t.StoreID = 0)
						and WorkingSource in ('SUP-S', 'SUP-U')
					End
				else if(@ruleid=11)
					Begin
						--select distinct w.StoreIdentifier,w.StoreID
						update t set t.StoreID=s.StoreID 
						from Stores s 
						join StoreTransactions_Working t
						on CAST(s.Custom2 as int)=CAST(t.StoreIdentifier as int)
						and t.EDIName=@ediname and s.ChainID=t.ChainID
						and Rtrim(Ltrim(t.EDIBanner))=Ltrim(Rtrim(s.Custom3))
						and (t.StoreID is null or t.StoreID = 0)
						and WorkingStatus = 0
						and WorkingSource in ('SUP-S', 'SUP-U')
						--order by w.StoreIdentifier
					End
				else if(@ruleid = 20)
					 Begin 
				     
					 update t set t.StoreID=s.StoreID   
					 from Stores s   
					 join StoreTransactions_Working t  
					 on CAST(s.StoreIdentifier as int)=CAST(RIGHT(ltrim(rtrim(t.Banner)),4) as int)
					 and t.EDIName=@ediname and s.ChainID=t.ChainID
					 and Rtrim(Ltrim(t.EDIBanner))=Ltrim(Rtrim(s.Custom3))
					 and (t.StoreID is null or t.StoreID = 0)
					 and WorkingStatus = 0
					 and WorkingSource in ('SUP-S', 'SUP-U')
					 and ISNumeric(RIGHT(ltrim(rtrim(t.Banner)),4))>0

					End 	
				else if(@ruleid=19)
					Begin
						--select t.StoreID,s.StoreID,t.StoreIdentifier,CAST(t.DateTimeCreated as date)
						update t set t.StoreID = s.StoreID
						from [dbo].[StoreTransactions_Working] t
						inner join [dbo].[Stores] s
						on t.ChainID = s.ChainID 
						and cast(left(ltrim(rtrim(t.StoreIdentifier)), 4) as int) = cast(ltrim(rtrim(s.custom2)) as int)
						and ltrim(rtrim(s.Custom3)) = ltrim(rtrim(EDIBanner))
						where 1 = 1
						and WorkingStatus = 0
						and EDIName = @ediname
						and (t.StoreID is null or t.StoreID = 0)
						and WorkingSource in ('SUP-S', 'SUP-U')
					End
				else
					Begin
						--select *
						update t set t.StoreID = c.StoreID
						from [dbo].[StoreTransactions_Working] t
						inner join dbo.tUtil_SupplierStoreCrossReference c
						on ltrim(rtrim(t.StoreIdentifier)) = ltrim(rtrim(c.storeidentifier))
						and LTRIM(rtrim(t.EDIBanner)) = LTRIM(rtrim(c.edibanner))
						and LTRIM(rtrim(t.EdiName)) = LTRIM(rtrim(c.EdiName))
						where 1 = 1
						and WorkingStatus = 0
						and t.EDIName =@ediname
						and (t.StoreID is null or t.StoreID = 0)
						and WorkingSource in ('SUP-S', 'SUP-U')
					End
				fetch next from @rec2 into @ruleid
			End
			close @rec2
			deallocate @rec2
		fetch next from @rec into @ediname
	End
close @rec
deallocate @rec

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null
and ISNUMERIC(t.StoreIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Invalid Store Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
and StoreID is null

if @@ROWCOUNT > 0
	begin

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = 'Unknown Store Identifiers Found'
		set @errorlocation = 'prValidateStoresInStoreTransactions_Working_SUP'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_SUP'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
	end

commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9998
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailySUPLoadDeliveriesAndPickups_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Deliveries and Pickups Job Stopped at Store validate step'
				,'Deliveries and pickup loading has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
		
end catch
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.WorkingStatus = 0

return
GO
