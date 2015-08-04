USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateStoresInStoreTransactions_Working_INV_RULES_Manual_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prValidateStoresInStoreTransactions_Working_INV_RULES_Manual_PRESYNC_20150329]

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus int
declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @ruleid int
declare @supplierid int
declare @ediname nvarchar(50)
declare @MyID int
set @MyID = 7594

begin try

select distinct StoreTransactionID, ChainIdentifier, StoreIdentifier
into #tempStoreTransaction
--select *
--select count(*)
--update w set EDIName = 'PEP'
--update w set w.workingstatus = 0
from [dbo].[StoreTransactions_Working] w
where WorkingStatus = 0
--and StoreID is null
and WorkingSource in ('INV')
--and SupplierIdentifier = '6034243'

begin transaction

set @loadstatus = 1


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
--declare @errorsenderstring nvarchar(255)
		set @errormessage = 'Unknown Chain Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateStoresInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_INV'
		print @errormessage
		--exec dbo.prLogExceptionAndNotifySupport
		--2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
	end

update t set t.WorkingStatus = -1
from [dbo].[StoreTransactions_Working] t
inner join #tempStoreTransaction tmp
on t.StoreTransactionID = tmp.StoreTransactionID
where WorkingStatus = 0
--and StoreID is null
and ISNUMERIC(t.StoreIdentifier) < 1

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Store Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateStoresInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_INV'
		print @errormessage
		
		--exec dbo.prLogExceptionAndNotifySupport
		--2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
	end

--select * from datatrue_edi.[dbo].[translationmaster]
update t set t.StoreID = s.TranslationCriteria1
--select t.*
from [dbo].[StoreTransactions_Working] t
inner join datatrue_edi.[dbo].[translationmaster] s
on ltrim(rtrim(t.StoreIdentifier)) = LTRIM(rtrim(TranslationValueOutside))
and ltrim(rtrim(s.TranslationTradingPartnerIdentifier)) = ltrim(rtrim(t.EDIName))
where 1 = 1
and ChainIdentifier = 'DG'
and WorkingStatus = 0
and workingsource in ('INV')
and EDIName = 'ACK'
--and t.StoreID is null

update w set w.StoreID=s.StoreID,w.Workingstatus=1
from StoreTransactions_Working w join Stores s
on w.StoreIdentifier=s.StoreIdentifier and w.ChainID=s.ChainID
where EdiName='Valley'
and WorkingSource='INV'

update w set w.StoreID=s.StoreID
--select distinct StoreIdentifier
from StoreTransactions_Working w join Stores s
on w.StoreIdentifier=s.StoreIdentifier
and w.ChainID=s.ChainID
where w.WorkingStatus=0
and w.ChainID=42491
and WorkingSource in ('INV')

update w set w.ChainID=c.ChainID,w.StoreID=s.StoreID,w.WorkingStatus=1
from StoreTransactions_Working w join Stores s 
on w.StoreIdentifier=s.StoreIdentifier
join Chains c on c.ChainIdentifier=w.ChainIdentifier
and s.ChainID=c.ChainID
where WorkingStatus=0
and WorkingSource in ('INV')
and EdiName='FUNFACTORY'

update w set w.StoreID=s.StoreID,w.WorkingStatus=1
from StoreTransactions_Working w with (nolock)
join Stores s with (nolock) on w.StoreIdentifier=s.StoreIdentifier
and w.ChainID=s.ChainID
where WorkingStatus=0
and w.ChainID=60634
and WorkingSource in ('INV')

update w set w.StoreID=s.StoreID,w.WorkingStatus=1
from StoreTransactions_Working w join Stores s 
on w.StoreIdentifier=s.StoreIdentifier
and w.ChainID=s.ChainID 
where 1=1
and w.WorkingStatus=0
and w.ChainIdentifier='WLMRT'
and WorkingSource in ('INV')


update w set w.StoreID=s.StoreID,w.WorkingStatus=1
--select distinct ChainIdentifier
from StoreTransactions_Working w join Stores s 
on right(ltrim(rtrim(Banner)) ,4)=s.StoreIdentifier
and w.ChainID=s.ChainID 
where 1=1
and w.WorkingStatus=0
and w.ChainIdentifier='WLMRT'
and WorkingSource in ('INV')


update w set w.StoreID=s.StoreID,w.WorkingStatus=1
--select distinct ChainIdentifier
from StoreTransactions_Working w join Stores s 
on  Left(RIGHT(ltrim(rtrim(Banner)), LEN(ltrim(rtrim(Banner))) - CHARINDEX('#',ltrim(rtrim(Banner)))),4)=s.StoreIdentifier
and w.ChainID=s.ChainID 
where 1=1
and w.WorkingStatus=0
and w.ChainIdentifier='WLMRT'
and WorkingSource in ('INV')

update w set w.StoreID=s.StoreID,w.WorkingStatus=1
from StoreTransactions_Working w join Stores s
on w.ChainID=s.ChainID
and w.StoreIdentifier=s.StoreIdentifier
where WorkingStatus=0
and w.ChainID=60620
and WorkingSource in ('INV')


update w set w.StoreID=s.StoreID,w.WorkingStatus=1
from StoreTransactions_Working w join Stores s
on w.ChainID=s.ChainID
and Cast(w.StoreIdentifier as int)=CAST(s.StoreIdentifier as int)
where WorkingStatus=0
and w.ChainID=60620
and WorkingSource in ('INV')

update w set w.StoreID=s.StoreID,w.WorkingStatus=1
from StoreTransactions_Working w join Stores s
on w.StoreIdentifier=s.StoreIdentifier and w.ChainID=s.ChainID
where WorkingStatus=0
and EDIName='Propane'
and WorkingSource in ('INV')

set @rec = CURSOR local fast_forward for
			select distinct ediname from
			StoreTransactions_Working
			where 1=1
			and WorkingStatus = 0
			and WorkingSource in ('INV')
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
								from StoreTransactions_Working t 
								join #tempStoreTransaction tmp
								on t.StoreTransactionID= tmp.StoreTransactionID
								join EdiBanners b
								on rtrim(ltrim(LEFT(Ltrim(Rtrim(Banner)),CHARINDEX(RIGHT(IsNull(Ltrim(Rtrim(Banner)),''),4),ltrim(rtrim(Banner)))-2)))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and t.WorkingSource in ('INV')
								and t.EDIName=@ediname
						End
					else if(@ruleid=9)
						Begin
								update t set t.EDIBanner=b.BannerValue
								--select distinct t.Banner,b.BannerValue
								from StoreTransactions_Working t 
								join #tempStoreTransaction tmp
								on t.StoreTransactionID=tmp.StoreTransactionID
								join EdiBanners b
								on Rtrim(LTRIM(LEFT(Banner , CHARINDEX('#',Banner)-2)))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and t.WorkingSource in ('INV')
								and t.EDIName=@ediname
								and CHARINDEX('#',Banner)>0
						End
					else if(@ruleid=18)
						Begin
								update t set t.EDIBanner=b.BannerValue
								--select distinct t.Banner,b.BannerValue
								from StoreTransactions_Working t 
								join #tempStoreTransaction tmp
								on t.StoreTransactionID=tmp.StoreTransactionID
								join EdiBanners b
								on Rtrim(LTRIM(LEFT(Banner , CHARINDEX(' ',Banner))))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and t.WorkingSource in ('INV')
								and t.EDIName=@ediname
								and CHARINDEX(' ',Banner)>0
						End
					else if(@ruleid=8)
						Begin
								update t set t.EDIBanner=b.BannerValue
								--select distinct t.Banner,b.BannerValue
								from StoreTransactions_Working t 
								join #tempStoreTransaction tmp
								on t.StoreTransactionID=tmp.StoreTransactionID
								join EdiBanners b
								on ltrim(rtrim(corporateidentifier))=b.BannerKey
								and b.SupplierID=@supplierid
								and t.WorkingStatus = 0
								and t.WorkingSource in ('INV')
								and t.EDIName=@ediname
						End	
					else if(@ruleid=12)
						Begin
								update storetransactions_working 
								set EDIBanner ='SV'
								where 1 = 1
								and workingstatus = 0
								and workingsource in ('INV')
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
						and WorkingSource in ('INV')
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
						and WorkingSource in ('INV')
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
						and WorkingSource in ('INV')
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
					 and WorkingSource in ('INV')

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
						and WorkingSource in ('INV')
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

if @@ROWCOUNT > 0
	begin

		set @errormessage = 'Unknown Store Identifiers Found.  Records in the StoreTransactions_Working have been pended to a status of -1.'
		set @errorlocation = 'Invalid EDI data found during execution of prValidateStoresInStoreTransactions_Working_INV'
		set @errorsenderstring = 'prValidateStoresInStoreTransactions_Working_INV'
		print @errormessage
		--exec dbo.prLogExceptionAndNotifySupport
		--2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
	end
	


commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9997

		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		print @errormessage
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
		--exec [msdb].[dbo].[sp_stop_job] 
		--@job_name = 'LoadInventoryCount'

		--exec dbo.prSendEmailNotification_PassEmailAddresses 'Load Inventory Job Stopped at Store validate step'
		--		,'Inventory count load has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
		--		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com;mandeep@amebasoftwares.com'	
end catch
	
--print 'got here'
--print @loadstatus
	
update t set WorkingStatus = @loadstatus, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.WorkingStatus = 0

/*
update t set WorkingStatus = -2, LastUpdateUserID = @MyID
from #tempStoreTransaction tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
where t.StoreID is null

if @@ROWCOUNT > 0
	begin
		--Call db-email here
		set @MyID = 7582
	end
*/

	
return
GO
