USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundPOSTransactions_ForJEWELandSHAWS_Newspaper_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundPOSTransactions_ForJEWELandSHAWS_Newspaper_PRESYNC_20150415]
/*
RoleID 7415
*/
As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @continue bit=1
declare @ProcessID int
set @MyID = 7415 


declare @rec cursor
declare @date date
declare @SBTNO nvarchar(50)
declare @banner nvarchar(100)
declare @storeid int

--INSERT INTO DataTrue_Main.dbo.JobProcesses (JobRunningID) VALUES (14) --JobRunningID 3 = DailyRegulatedBilling
SELECT @ProcessID = LastProcessId from JobRunning where JobRunningID = 14
--select MAX(ProcessID) from DataTrue_Main.dbo.JobProcesses where JobRunningID in (14)
--UPDATE DataTrue_Main.dbo.JobRunning SET LastProcessID = @ProcessID WHERE JobRunningID = 14


--Take care of insertions-------------------------------------------------------------------------------
select RecordID 
into #tempInboundTransactions2
--select *  
--select distinct
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
--and CAST(saledate as date) in ('12/2/2014') --
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and charindex(case when len(cast(Month(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -2, getdate())) As nvarchar) else cast(Month(dateadd(day, -2, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -2, getdate())) As nvarchar) else cast(Day(dateadd(day, -2, getdate())) As nvarchar) end + cast(Year(dateadd(day, -2, getdate())) as nvarchar), FileName)>0
and recordtype = 2

if @@rowcount = 0
	begin

		--exec dbo.prSendEmailNotification_PassEmailAddresses 'Jewel Newspaper Isertions @@rowcount = 0'
		--,'Jewel Newspaper Isertions @@rowcount = 0. Processing of the Jewel records will be held for manual review.'
		--,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'

		set @continue = 0
	end


If @continue = 1
	begin
begin try


begin transaction

set @loadstatus = 1



INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           --,[ReportedUnitRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[SupplierIdentifier]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,RecordID_EDI_852
           ,Banner
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[RecordType]
           ,[workingstatus]
           ,[ProcessID])
     select
           ltrim(rtrim(ChainIdentifier))
           ,cast(cast(StoreIdentifier as int) as nvarchar)
           ,Qty
           ,SaleDate
           ,ltrim(rtrim(ProductIdentifier))
           ,ltrim(rtrim(ProductQualifier))
           ,ltrim(rtrim(ProductCategoryIdentifier))
           ,ltrim(rtrim(BrandIdentifier))
           ,ltrim(rtrim(InvoiceNo))
           ,Cost
           ,Retail
           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
           --,Retail
           ,'POS'
           ,0 --@MyID
           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
     ,DateTimeReceived
           ,ltrim(rtrim([SupplierIdentifier]))
           ,Allowance
           ,PromotionPrice
           ,s.RecordID
           ,isnull(Banner, '')
		  ,isnull([StoreName], '')
		  ,isnull([ProductQualifier] , '')     
		  ,isnull([RawProductIdentifier], '')
		  ,isnull([SupplierName], '')           
		  ,isnull([DivisionIdentifier], '')           
		   ,isnull([UnitMeasure], '')          
		  ,isnull([SalePrice], 0.0)         
		   ,isnull([InvoiceNo], '')          
		   ,isnull([PONo], '')          
		  ,isnull([CorporateName], '')
		  ,isnull([CorporateIdentifier], '')
		  ,[RecordType]
		  ,0
		  ,@ProcessID
		  --select *
		  --update s set s.recordstatus = 1
     from DataTrue_EDI..Inbound852Sales s
 --    where SaleDate = '2015-01-11 00:00:00.000'
	--and filename = 'opdssbtjewelshawsins.dat.01122015.111811'
	--and productidentifier <> 'X'
	--and RecordStatus = 0
	--and suppliername like '%icontrol%'
     inner join #tempInboundTransactions2 t
     on s.RecordID = t.RecordId
     order by s.RecordID
     
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID

	
end catch
	

update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound852Sales s
inner join #tempInboundTransactions2 t
on s.RecordID = t.RecordID

end
----------------------------------------------------------------------------------

if @continue = 1
	begin

--Take care of deletions
begin try
--select distinct filename delete from DataTrue_EDI..Inbound852Sales  where recordstatus = 0
select RecordID 
into #tempInboundTransactions3
--select *  
--select distinct
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
--and (charindex(case when len(cast(Month(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -2, getdate())) As nvarchar) else cast(Month(dateadd(day, -2, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -2, getdate())) As nvarchar) else cast(Day(dateadd(day, -2, getdate())) As nvarchar) end + cast(Year(dateadd(day, -2, getdate())) as nvarchar), FileName)>0 or charindex(case when len(cast(Month(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -3, getdate())) As nvarchar) else cast(Month(dateadd(day, -3, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -3, getdate())) As nvarchar) else cast(Day(dateadd(day, -3, getdate())) As nvarchar) end + cast(Year(dateadd(day, -3, getdate())) as nvarchar), FileName)>0)
--and filename = 'opdssbtjewelshawsins.dat.12032014.183857'
and charindex(case when len(cast(Month(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -3, getdate())) As nvarchar) else cast(Month(dateadd(day, -3, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -3, getdate())) As nvarchar) else cast(Day(dateadd(day, -3, getdate())) As nvarchar) end + cast(Year(dateadd(day, -3, getdate())) as nvarchar), FileName)>0
and recordtype = 2

begin transaction

set @loadstatus = 1



--INSERT INTO [dbo].[StoreTransactions_Working]
--           ([ChainIdentifier]
--           ,[StoreIdentifier]
--           ,[Qty]
--           ,[SaleDateTime]
--           ,[UPC]
--           ,[ProductIdentifierType]
--           ,[ProductCategoryIdentifier]
--           ,[BrandIdentifier]
--           ,[SupplierInvoiceNumber]
--           ,[ReportedCost]
--           ,[ReportedRetail]
--           --,[ReportedUnitRetail]
--           ,[WorkingSource]
--           ,[LastUpdateUserID]
--           ,[SourceIdentifier]
--           ,[DateTimeSourceReceived]
--           ,[SupplierIdentifier]
--           ,[ReportedAllowance]
--           ,[ReportedPromotionPrice]
--           ,RecordID_EDI_852
--           ,Banner
--           ,[StoreName]
--           ,[ProductQualifier]
--           ,[RawProductIdentifier]
--           ,[SupplierName]
--           ,[DivisionIdentifier]
--           ,[UOM]
--           ,[SalePrice]
--           ,[InvoiceNo]
--           ,[PONo]
--           ,[CorporateName]
--           ,[CorporateIdentifier]
--           ,[RecordType]
--           ,[workingstatus])
--     select
--           ltrim(rtrim(ChainIdentifier))
--           ,cast(cast(StoreIdentifier as int) as nvarchar)
--           ,Qty
--           ,SaleDate
--           ,ltrim(rtrim(ProductIdentifier))
--           ,ltrim(rtrim(ProductQualifier))
--           ,ltrim(rtrim(ProductCategoryIdentifier))
--           ,ltrim(rtrim(BrandIdentifier))
--           ,ltrim(rtrim(InvoiceNo))
--           ,Cost
--           ,Retail
--           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
--           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
--           --,Retail
--           ,'POS'
--           ,@MyID
--           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
--           ,DateTimeReceived
--           ,ltrim(rtrim([SupplierIdentifier]))
--           ,Allowance
--           ,PromotionPrice
--           ,s.RecordID
--           ,isnull(Banner, '')
--		  ,isnull([StoreName], '')
--		  ,isnull([ProductQualifier] , '')     
--		  ,isnull([RawProductIdentifier], '')
--		  ,isnull([SupplierName], '')           
--		  ,isnull([DivisionIdentifier], '')           
--		   ,isnull([UnitMeasure], '')          
--		  ,isnull([SalePrice], 0.0)         
--		   ,isnull([InvoiceNo], '')          
--		   ,isnull([PONo], '')          
--		  ,isnull([CorporateName], '')
--		  ,isnull([CorporateIdentifier], '')
--		  ,[RecordType]
--		  ,12
	 update s set s.RecordStatus = -1
     from DataTrue_EDI..Inbound852Sales s
     inner join #tempInboundTransactions3 t
     on s.RecordID = t.RecordId
     --order by s.RecordID
     
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID		
		
end catch
	

--update s set RecordStatus = @loadstatus
--from DataTrue_EDI..Inbound852Sales s
--inner join #tempInboundTransactions3 t
--on s.RecordID = t.RecordID

If OBJECT_ID('[#livesuppliers]') Is Not Null Drop Table [#livesuppliers]
If OBJECT_ID('[#tempInboundTransactions]') Is Not Null Drop Table [#tempInboundTransactions]
If OBJECT_ID('[#tempInboundTransactions2]') Is Not Null Drop Table [#tempInboundTransactions2]
If OBJECT_ID('[#tempInboundTransactions3]') Is Not Null Drop Table [#tempInboundTransactions3]

--drop table #livesuppliers
--drop table #tempInboundTransactions
--drop table #tempInboundTransactions2
--drop table #tempInboundTransactions3
end



/*
Notes
	5/27 had third deletion with one store 1422 but no third insertion
	5/28 had third deletion with one store 1422 but no third insertion


select  filename, COUNT(recordid)
--into #tempFilecount
--select *
from DataTrue_EDI..Inbound852Sales [No Lock]
where 1 = 1
and CAST(saledate as date) = '12/2/2014'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --'3/28/2014'
and banner in ('SV_JWL')
and recordtype = 2
--and storeidentifier = '3098'
--and filename = 'opdssbtjewelshawsins.dat.07012014.183759'


--select  filename, COUNT(recordid)
--into #tempFilecount
--select *
from DataTrue_EDI..Inbound852Sales [No Lock]
where 1 = 1
and CAST(saledate as date) = '12/2/2014'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --'3/28/2014'
and banner in ('SV_JWL')
--and recordtype = 2
--and storeidentifier = '3368'
--and filename = 'opdssbtjewelshawsins.dat.07022014.183949'
group by filename
order by filename


6/30
insert
opdssbtjewelshawsins.dat.06302014.184358	245
opdssbtjewelshawsins.dat.07012014.183759	321
opdssbtjewelshawsins.dat.07022014.183949	2
delete
opdssbtjewelshawsdel.dat.06302014.184534	187
opdssbtjewelshawsdel.dat.07012014.183928	187
opdssbtjewelshawsdel.dat.07022014.184119	1

4/8
insert
opdssbtjewelshawsins.dat.04082014.183737	4170
opdssbtjewelshawsins.dat.04092014.183455	5432
opdssbtjewelshawsins.dat.04102014.183604	11 3368
del
opdssbtjewelshawsdel.dat.04082014.183902	182
opdssbtjewelshawsdel.dat.04092014.183616	182
opdssbtjewelshawsdel.dat.04102014.183728	1

11/27
insert
opdssbtjewelshawsins.dat.11272013.185031	4647
opdssbtjewelshawsins.dat.11282013.183534	6779
opdssbtjewelshawsins.dat.11292013.182623	34
delete
opdssbtjewelshawsdel.dat.11272013.185212	178
opdssbtjewelshawsdel.dat.11282013.183658	178
opdssbtjewelshawsdel.dat.11292013.182721	1


1/1/14
insert
opdssbtjewelshawsins.dat.01012014.184025	2701
opdssbtjewelshawsins.dat.01022014.184337	3180
delete
opdssbtjewelshawsdel.dat.01012014.184202	178
opdssbtjewelshawsdel.dat.01022014.184457	176
1422
1469

3/24
in
opdssbtjewelshawsins.dat.03242014.184102	3286
opdssbtjewelshawsins.dat.03252014.183723	5139
opdssbtjewelshawsins.dat.03262014.183347	32
del
opdssbtjewelshawsdel.dat.03242014.184232	182
opdssbtjewelshawsdel.dat.03252014.183846	182
opdssbtjewelshawsdel.dat.03262014.183506	1

select storeidentifier
from DataTrue_EDI..Inbound852Sales [No Lock]
where filename = 'opdssbtjewelshawsdel.dat.01012014.184202'
and CAST(saledate as date) = '1/1/2014'
and recordtype = 1
and storeidentifier not in
(
select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales [No Lock]
where filename = 'opdssbtjewelshawsdel.dat.01022014.184457'
and recordtype = 1
and CAST(saledate as date) = '1/1/2014'
)


6/30
insert
opdssbtjewelshawsins.dat.06302014.184358	245
opdssbtjewelshawsins.dat.07012014.183759	321
opdssbtjewelshawsins.dat.07022014.183949	2
delete
opdssbtjewelshawsdel.dat.06302014.184534	187
opdssbtjewelshawsdel.dat.07012014.183928	187
opdssbtjewelshawsdel.dat.07022014.184119	1

opdssbtjewelshawsdel.dat.06142013.222152	178
opdssbtjewelshawsdel.dat.06152013.190114	177

5/27 deletions
opdssbtjewelshawsdel.dat.05272013.195412	178
opdssbtjewelshawsdel.dat.05282013.204947	178
opdssbtjewelshawsdel.dat.05292013.200148	1
5/27 insertions
opdssbtjewelshawsins.dat.05272013.195229	4351
opdssbtjewelshawsins.dat.05282013.204813	5446

4/22 deletions
opdssbtjewelshawsdel.dat.04222013.194959	178
opdssbtjewelshawsdel.dat.04232013.185819	178
opdssbtjewelshawsdel.dat.04242013.185808	1
4/22 insertions
opdssbtjewelshawsins.dat.04222013.194822	3986
opdssbtjewelshawsins.dat.04232013.185655	5425
opdssbtjewelshawsins.dat.04242013.185647	31

--second deletion not complete

select *  
--select distinct filename
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
--and FileName = 'opdssbtjewelshawsdel.dat.04012013.190248'
--opdssbtjewelshawsdel.dat.04182013.190806
--opdssbtjewelshawsdel.dat.04192013.190205


opdssbtjewelshawsins.dat.04182013.190640
opdssbtjewelshawsins.dat.04192013.190039


opdssbtjewelshawsdel.dat.06142013.222152	178
opdssbtjewelshawsdel.dat.06152013.190114	177

select StoreIdentifier  
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
and FileName = 'opdssbtjewelshawsdel.dat.11282013.183658'
and StoreIdentifier not in
(
select StoreIdentifier  
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
and FileName = 'opdssbtjewelshawsdel.dat.11292013.182721'
)

11/28
insert
opdssbtjewelshawsins.dat.11282013.183534	3643
opdssbtjewelshawsins.dat.11292013.182623	3574
delete
opdssbtjewelshawsdel.dat.11282013.183658	178
opdssbtjewelshawsdel.dat.11292013.182721	170
3471
3282
1422
3236
1469
3043
3114
3454

1/1/14
insert
opdssbtjewelshawsins.dat.01012014.184025	2701
opdssbtjewelshawsins.dat.01022014.184337	3180
delete
opdssbtjewelshawsdel.dat.01012014.184202	178
opdssbtjewelshawsdel.dat.01022014.184457	176
1422
1469


3/24
in
opdssbtjewelshawsins.dat.03242014.184102	3286
opdssbtjewelshawsins.dat.03252014.183723	5139
opdssbtjewelshawsins.dat.03262014.183347	32 - 3122
del
opdssbtjewelshawsdel.dat.03242014.184232	182
opdssbtjewelshawsdel.dat.03252014.183846	182
opdssbtjewelshawsdel.dat.03262014.183506	1

select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
and FileName = 'opdssbtjewelshawsins.dat.03302014.184711'
and storeidentifier in
('1422',
'1469')

3/28
in
opdssbtjewelshawsins.dat.03282014.183733	4534
opdssbtjewelshawsins.dat.03292014.184121	6250
opdssbtjewelshawsins.dat.03302014.184711	26 --3518
del
opdssbtjewelshawsdel.dat.03282014.183855	182
opdssbtjewelshawsdel.dat.03292014.184257	182
opdssbtjewelshawsdel.dat.03302014.184858	1




select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
and FileName = 'opdssbtjewelshawsdel.dat.04242013.185808'
and storeidentifier in
(
'1469',
'3043',
'3114',
'3471',
'3282',
'1422',
'3176',
'3236')

3/13 deletions
opdssbtjewelshawsdel.dat.03132013.184718	179
opdssbtjewelshawsdel.dat.03142013.184648	178
opdssbtjewelshawsdel.dat.03152013.203740	2	3479, 3283
3/13 insertions
opdssbtjewelshawsins.dat.03132013.184558	3118
opdssbtjewelshawsins.dat.03142013.184521	4929
opdssbtjewelshawsins.dat.03152013.203603	82


4/22 deletions
opdssbtjewelshawsdel.dat.04222013.194959	178
opdssbtjewelshawsdel.dat.04232013.185819	178
opdssbtjewelshawsdel.dat.04242013.185808	1 --3720
4/22 insertions
opdssbtjewelshawsins.dat.04222013.194822	3986
opdssbtjewelshawsins.dat.04232013.185655	5425
opdssbtjewelshawsins.dat.04242013.185647	31

11/27
insert
opdssbtjewelshawsins.dat.11272013.185031	4647
opdssbtjewelshawsins.dat.11282013.183534	6779
opdssbtjewelshawsins.dat.11292013.182623	34
delete
opdssbtjewelshawsdel.dat.11272013.185212	178
opdssbtjewelshawsdel.dat.11282013.183658	178
opdssbtjewelshawsdel.dat.11292013.182721	1

12/18
Insert
opdssbtjewelshawsins.dat.12182013.184036	3710
opdssbtjewelshawsins.dat.12192013.185042	4856
opdssbtjewelshawsins.dat.12202013.184809	26
delete
opdssbtjewelshawsdel.dat.12182013.184200	178
opdssbtjewelshawsdel.dat.12192013.185211	178
opdssbtjewelshawsdel.dat.12202013.184946	1


3/24
in
opdssbtjewelshawsins.dat.03242014.184102	3286
opdssbtjewelshawsins.dat.03252014.183723	5139
opdssbtjewelshawsins.dat.03262014.183347	32 - 3122
del
opdssbtjewelshawsdel.dat.03242014.184232	182
opdssbtjewelshawsdel.dat.03252014.183846	182
opdssbtjewelshawsdel.dat.03262014.183506	1

select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and cast(saledate as date) = '3/24/2014'
and storeidentifier in ('3122')
and filename = 'opdssbtjewelshawsins.dat.03262014.183347'
order by ltrim(rtrim(productidentifier))

select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and cast(saledate as date) = '12/18/2013'
and storeidentifier in ('3260')
and filename = 'opdssbtjewelshawsins.dat.12192013.185042'
order by ltrim(rtrim(productidentifier))


select one.qty, two.qty, *
--update two set two.recordstatus = 1
--select *
--select two.recordid, two.*
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on ltrim(rtrim(one.storeidentifier)) = ltrim(rtrim(two.storeidentifier))
and ltrim(rtrim(one.productidentifier)) = ltrim(rtrim(two.productidentifier))
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '4/8/2014'
and ltrim(rtrim(one.storeidentifier)) = '3368'
and ltrim(rtrim(one.filename)) = 'opdssbtjewelshawsins.dat.04092014.183455'
and ltrim(rtrim(two.filename)) = 'opdssbtjewelshawsins.dat.04102014.183604'
and one.recordtype = 0
and two.recordtype = 0
and two.recordstatus = 0
and one.qty <> two.qty

4/8
insert
opdssbtjewelshawsins.dat.04082014.183737	4170
opdssbtjewelshawsins.dat.04092014.183455	5432
opdssbtjewelshawsins.dat.04102014.183604	11 3368
del
opdssbtjewelshawsdel.dat.04082014.183902	182
opdssbtjewelshawsdel.dat.04092014.183616	182
opdssbtjewelshawsdel.dat.04102014.183728	1

select *
--update s set s.recordstatus = 1
from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and recordid in 
(
157788858,
157789827
)

one
157788858
157789827
two
157871152
157868026

select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and CAST(saledate as date) = '1/29/2013'
and banner in ('SV_JWL')
and recordtype = 0
and filename = ''


select invoicebatchid as ibid, *
from storetransactions
where 1 = 1
and CAST(saledatetime as date) = '1/29/2013'
and banner in ('SV_JWL')
--and invoicebatchid is not null
order by invoicebatchid


dbo.Inbound852Sales_JWLSHW_Unmatched
dbo.Inbound852Sales_JWLSHW_Unmatched_2012



--check for more than two deletions
Currently there are 2 4's and 18 3's on 1/23/2013

drop table #tempFilecount
declare @filecount int

select CAST(saledate as date) as date, COUNT(distinct filename) as FileCount
into #tempFilecount
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and CAST(saledate as date) = '2/19/2013'
and banner in ('SV_JWL')
and recordtype = 1
group by CAST(saledate as date)
having COUNT(distinct filename) > 2
order by CAST(saledate as date)

select  sum(filecount) from #tempFilecount

select * from #tempFilecount

if @filecount > 62
	begin
	
	
	
	end

select CAST(saledate as date), COUNT(distinct filename)
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and CAST(saledate as date) > '11/15/2012'
and banner in ('SV_JWL')
and recordtype = 0
group by CAST(saledate as date)
having COUNT(distinct filename) > 2
order by CAST(saledate as date)

select StoreTransactionID into #tmpInboundPOS
from StoreTransactions_Working t
where t.WorkingStatus = 0
and WorkingSource = 'POS'

select max(saledatetime)
from storetransactions
where banner = 'SV_JWL'

--Retailer's reported cost is iControl's ReportedSalePrice

update t
set t.ReportedUnitPrice = Case when t.ReportedUnitPrice < 0.0001 then t.ReportedUnitCost else t.ReportedUnitPrice end
from #tmpInboundPOS tmp
inner join StoreTransactions_Working t
on tmp.StoreTransactionID = t.StoreTransactionID

select distinct recordstatus
from DataTrue_EDI..Inbound852Sales
order by recordstatus

select filename 
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
group by filename

select filename, count(recordid)
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 0
and CAST(saledate as date) = '1/21/2013'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
group by filename
order by filename


--1/21/2013
insertions
opdssbtjewelshawsins.dat.01212013.185913	2861
opdssbtjewelshawsins.dat.01222013.190322	3977
opdssbtjewelshawsins.dat.01252013.191352	21
deletions
opdssbtjewelshawsdel.dat.01212013.190052	181
opdssbtjewelshawsdel.dat.01222013.190446	181
opdssbtjewelshawsdel.dat.01252013.191519	1 (3264)

--12/1/2012
Insertions
Excel Sheet	459
opdssbtjewelshawsins.dat.12012012.184658	3982
opdssbtjewelshawsins.dat.12022012.185846	4892
opdssbtjewelshawsins.dat.12052012.193325	4916


Deletions
opdssbtjewelshawsdel.dat.12012012.184840	181
opdssbtjewelshawsdel.dat.12022012.190035	181
opdssbtjewelshawsdel.dat.12052012.193624	179

2/23 Deletions
opdssbtjewelshawsdel.dat.02232013.185123	180
opdssbtjewelshawsdel.dat.02242013.185730	180
opdssbtjewelshawsdel.dat.02262013.193310	47

2/23 Insertions
opdssbtjewelshawsins.dat.02232013.184942	5264
opdssbtjewelshawsins.dat.02242013.185543	6201
opdssbtjewelshawsins.dat.02262013.193127	1861


3/5 Deletions
opdssbtjewelshawsdel.dat.03052013.192850	180
opdssbtjewelshawsdel.dat.03062013.184756	179
3/5 Insertions
opdssbtjewelshawsins.dat.03052013.192715	2952
opdssbtjewelshawsins.dat.03062013.184635	3400


3/6 deletions
opdssbtjewelshawsdel.dat.03062013.184756	179
opdssbtjewelshawsdel.dat.03072013.191018	179
3/6 insertions
opdssbtjewelshawsins.dat.03062013.184635	3041
opdssbtjewelshawsins.dat.03072013.190849	4165

3/22 deletions
opdssbtjewelshawsdel.dat.03222013.190848	178
opdssbtjewelshawsdel.dat.03232013.185841	178
opdssbtjewelshawsdel.dat.03252013.191639	1
3/22 insertions
opdssbtjewelshawsins.dat.03222013.190717	5166
opdssbtjewelshawsins.dat.03232013.185657	6481
opdssbtjewelshawsins.dat.03252013.191458	37

3/14 deletions
opdssbtjewelshawsdel.dat.03142013.184648	178
opdssbtjewelshawsdel.dat.03152013.203740	178
opdssbtjewelshawsdel.dat.03252013.191639	1

3/14 insertions
opdssbtjewelshawsins.dat.03142013.184521	4417
opdssbtjewelshawsins.dat.03152013.203603	5800
opdssbtjewelshawsins.dat.03252013.191458	27
--find store not in second insertion


8/17 
deletions
opdssbtjewelshawsdel.dat.08172013.173404	178
opdssbtjewelshawsdel.dat.08182013.184807	178
opdssbtjewelshawsdel.dat.08192013.184449	1
insertions
opdssbtjewelshawsins.dat.08182013.184620	5878
opdssbtjewelshawsins.dat.08192013.184311	34 3074
opdssbtjewelshawsins.dat.08172013.173227	4587

11/15/2013
deletes
opdssbtjewelshawsdel.dat.11152013.184235	178
opdssbtjewelshawsdel.dat.11162013.183901	178
opdssbtjewelshawsdel.dat.11172013.184145	1
inserts
opdssbtjewelshawsins.dat.11152013.184112	4150
opdssbtjewelshawsins.dat.11162013.183723	5198
opdssbtjewelshawsins.dat.11172013.184003	20

select distinct ltrim(rtrim(storeidentifier)) --as number into #storesinfirst
--select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and recordtype = 1
and ltrim(rtrim(storeidentifier)) = '3518'
and cast(saledate as date) = '3/28/2014'
and filename = 'opdssbtjewelshawsdel.dat.03302014.184858'

select distinct ltrim(rtrim(storeidentifier)) as number into #storesinsecond
--select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and recordtype = 0
and ltrim(rtrim(storeidentifier)) = '3518'
and cast(saledate as date) = '3/28/2014'
and filename = 'opdssbtjewelshawsins.dat.03292014.184121'



select one.qty, two.qty, *
--update two set two.recordstatus = 1
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '11/15/2013'
and one.storeidentifier = '3445'
and one.filename = 'opdssbtjewelshawsins.dat.11162013.183723'
and two.filename = 'opdssbtjewelshawsins.dat.11172013.184003'
and one.recordtype = 0
and two.recordtype = 0
and two.recordstatus = 0
and one.qty <> two.qty


select *
from #storesinfirst
where ltrim(rtrim(number)) not in
(
select ltrim(rtrim(number)) from  #storesinsecond
)


3/7 Deletions
opdssbtjewelshawsdel.dat.03072013.191018	179
opdssbtjewelshawsdel.dat.03082013.190406	179
opdssbtjewelshawsdel.dat.03112013.190636	1
3/7 insertions
opdssbtjewelshawsins.dat.03072013.190849	4235
opdssbtjewelshawsins.dat.03082013.190234	5283
opdssbtjewelshawsins.dat.03112013.190455	22

store 3154
3/12 deletions
opdssbtjewelshawsdel.dat.03122013.185748	179
opdssbtjewelshawsdel.dat.03132013.184718	179
opdssbtjewelshawsdel.dat.03142013.184648	1
3/12 insertion
opdssbtjewelshawsins.dat.03122013.185621	3381
opdssbtjewelshawsins.dat.03132013.184558	4433
opdssbtjewelshawsins.dat.03142013.184521	46

select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and cast(saledate as date) = '3/12/2013'
and storeidentifier = '3154'
and filename = 'opdssbtjewelshawsdel.dat.03142013.184648'


select one.qty, two.qty, *
--update two set two.recordstatus = 1
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '3/12/2013'
and one.storeidentifier = '3154'
and one.filename = 'opdssbtjewelshawsins.dat.03132013.184558'
and two.filename = 'opdssbtjewelshawsins.dat.03142013.184521'
and one.recordtype = 0
and two.recordtype = 0
and two.recordstatus = 0
and one.qty <> two.qty

42995084
42991469
42991670

--this next query sets last insertion as one and original as two to find records missing from original
select one.qty, two.qty
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
left join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '2/23/2013'
and one.filename = 'opdssbtjewelshawsins.dat.02262013.193127'
and one.recordtype = 0
and two.filename = 'opdssbtjewelshawsins.dat.02242013.185543'
--and one.qty <> isnull(two.qty, 0)
where 
and two.recordtype = 0

order by two.qty

select * into #tempnew
from DataTrue_EDI.dbo.Inbound852Sales
where filename = 'opdssbtjewelshawsins.dat.02262013.193127'
and cast(saledate as date) = '2/23/2013'
and storeidentifier in
(
select distinct storeidentifier
from DataTrue_EDI.dbo.Inbound852Sales
where cast(saledate as date) = '2/23/2013'
and recordtype = 1
and filename = 'opdssbtjewelshawsdel.dat.02262013.193310'
)

select n.*, o.*
--update n set recordstatus = -3
from #temporiginal o
right join #tempnew n
on o.storeidentifier = n.storeidentifier
and o.productidentifier = n.productidentifier
where o.storeidentifier is null
order by o.storeidentifier

select *
--update s set s.recordstatus = -3
from DataTrue_EDI.dbo.Inbound852Sales s
inner join #tempnew n
on s.recordid = n.recordid
and n.recordstatus = -3

select distinct cast(datetimecreated as date)
from storetransactions
where cast(saledatetime as date) = '12/1/2012'
and banner = 'SV_JWL'
and transactiontypeid in (2, 6)
order by cast(datetimecreated as date)

2012-12-04
2012-12-12
2013-01-03

select *
from storetransactions
where cast(saledatetime as date) = '12/1/2012'
and cast(datetimecreated as date) = '1/3/2013'
and banner = 'SV_JWL'
and transactiontypeid in (2, 6)

select distinct cast(saledatetime as date), cast(datetimecreated as date)
from storetransactions
where banner = 'SV_JWL'
and cast(saledatetime as date) <> cast(dateadd(day, -3, datetimecreated) as date)
order by cast(saledatetime as date)

--select top 1000 * from DataTrue_EDI..Inbound852Sales

select *
--update s set recordstatus = 1
from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and filename = 'opdssbtjewelshawsins.dat.01252013.191352'
and cast(saledate as date) = '1/21/2013'
and recordstatus = 0
and storeidentifier = '3264'

select *
from DataTrue_EDI..Inbound852Sales one
inner join DataTrue_EDI..Inbound852Sales two
on cast(ltrim(rtrim(one.storeidentifier)) as int) = cast(ltrim(rtrim(two.storeidentifier)) as int)
and ltrim(rtrim(one.productidentifier)) = ltrim(rtrim(two.productidentifier))
and cast(one.saledate as date) = cast(two.saledate as date)
and one.filename = 'opdssbtjewelshawsins.dat.12312012.195717'
and two.filename = 'Excel Sheet 2 (Mark)'

select * --into import.dbo.Inbound852Sales_JWL_MissingUPCs_BeforeFilenameChange_20130103
--update s set s.filename = 'opdssbtjewelshawsins.dat.01012013.193904'
from DataTrue_EDI..Inbound852Sales s
where filename = 'Excel Sheet 2 (Mark)'
--and productidentifier = '009128461571'
and cast(saledate as date) = '12/31/2012'
order by  productidentifier


select *
from DataTrue_EDI..Inbound852Sales
where filename = 'opdssbtjewelshawsins.dat.01012013.193904'
--and productidentifier = '009128461571'
and cast(saledate as date) = '12/31/2012'
order by productidentifier

Excel Sheet 2 (Mark)
opdssbtjewelshawsins.dat.01012013.193904

select CAST(saledate as date), COUNT(distinct filename)
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and CAST(saledate as date) > '11/15/2012'
and banner in ('SV_JWL')
and recordtype = 1
group by CAST(saledate as date)
having COUNT(distinct filename) > 2
order by CAST(saledate as date)

select filename, COUNT(*)
--select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 1
and CAST(saledate as date) = '12/25/2012'
--and filename = 'opdssbtjewelshawsdel.dat.12142012.185351'
--and storeidentifier = '3425'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
group by filename
order by filename

select filename, COUNT(*)
--select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 1
and CAST(saledate as date) = '1/21/2013'
and filename = 'opdssbtjewelshawsdel.dat.01252013.191519'
--and storeidentifier = '3348'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
group by filename
order by filename

3348


select *
from DataTrue_EDI.dbo.Inbound852Sales one
where 1 = 1
and one.storeidentifier = '3741'
and one.filename = 'opdssbtjewelshawsins.dat.01222013.190322'
and one.recordtype = 0
and saledate = '2013-01-17 00:00:00.000'

--compare qty's in second and third insertion

select one.qty, two.qty
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and one.storeidentifier = '3741'
and one.filename = 'opdssbtjewelshawsins.dat.01182013.190259'
and two.filename = 'opdssbtjewelshawsins.dat.01222013.190322'
and one.recordtype = 0
and two.recordtype = 0
and one.qty <> two.qty

select distinct filename 
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0

1/17/2013
deletions
opdssbtjewelshawsdel.dat.01172013.185312	181
opdssbtjewelshawsdel.dat.01182013.190432	181
opdssbtjewelshawsdel.dat.01222013.190446	1 (3741)

insertions
opdssbtjewelshawsins.dat.01172013.185151	3434
opdssbtjewelshawsins.dat.01182013.190259	4813
opdssbtjewelshawsins.dat.01222013.190322	20


12/1/2012
deletions


insertions


--find stores to remove from second insertion

select distinct storeidentifier
--select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = '1/17/2013'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 1
and filename = 'opdssbtjewelshawsdel.dat.01222013.190446'

--find records in second insertion that will be pended
select *
--update s set recordstatus = 1107
from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.01182013.190259'
and storeidentifier in
(
select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 1
and filename = 'opdssbtjewelshawsdel.dat.12042012.190716'
)

--find records in third insertion
select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.12042012.190504'

--pull records in third insertion into working table

INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           --,[ReportedUnitRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[SupplierIdentifier]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,RecordID_EDI_852
           ,Banner
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[RecordType]
           ,[workingstatus])
     select
           ltrim(rtrim(ChainIdentifier))
           ,cast(cast(StoreIdentifier as int) as nvarchar)
           ,Qty
           ,SaleDate
           ,ltrim(rtrim(ProductIdentifier))
           ,ltrim(rtrim(ProductQualifier))
           ,ltrim(rtrim(ProductCategoryIdentifier))
           ,ltrim(rtrim(BrandIdentifier))
           ,ltrim(rtrim(InvoiceNo))
           ,Cost
           ,Retail
           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
           --,Retail
           ,'POS'
           ,0 --@MyID
           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
           ,DateTimeReceived
           ,ltrim(rtrim([SupplierIdentifier]))
           ,Allowance
           ,PromotionPrice
           ,s.RecordID
           ,isnull(Banner, '')
		  ,isnull([StoreName], '')
		  ,isnull([ProductQualifier] , '')     
		  ,isnull([RawProductIdentifier], '')
		  ,isnull([SupplierName], '')           
		  ,isnull([DivisionIdentifier], '')           
		   ,isnull([UnitMeasure], '')          
		  ,isnull([SalePrice], 0.0)         
		   ,isnull([InvoiceNo], '')          
		   ,isnull([PONo], '')          
		  ,isnull([CorporateName], '')
		  ,isnull([CorporateIdentifier], '')
		  ,[RecordType]
		  ,0
		  --select *
		  --update s set s.recordstatus = 1
     from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
and cast(saledate as date) = '3/28/2014'
and storeidentifier in ('3518')
and filename = 'opdssbtjewelshawsins.dat.03302014.184711'

3/28
in
opdssbtjewelshawsins.dat.03282014.183733	4534
opdssbtjewelshawsins.dat.03292014.184121	6250
opdssbtjewelshawsins.dat.03302014.184711	26 --3518
del
opdssbtjewelshawsdel.dat.03282014.183855	182
opdssbtjewelshawsdel.dat.03292014.184257	182
opdssbtjewelshawsdel.dat.03302014.184858	1


and (ProductIdentifier in (select upc from import.dbo.DSWandTTTUPCsGoingLiveAtJewel) or ProductIdentifier in (select upc from import.dbo.SourceUPCsGoingLiveAtJewel_20121011))

--update recordstatus in third insertion records already pulled.
update s set s.recordstatus = 1
--select *
 from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.03152013.203603'
and (ProductIdentifier in (select upc from import.dbo.DSWandTTTUPCsGoingLiveAtJewel) or ProductIdentifier in (select upc from import.dbo.SourceUPCsGoingLiveAtJewel_20121011))

--check second insertion file for correct recordstatus
select recordstatus as stat, *
from DataTrue_EDI..Inbound852Sales s
where 1 = 1
--and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.12032012.185234'
order by recordstatus desc

--check working table for correct records
select *
from storetransactions_working 
where workingsource = 'POS'
and workingstatus = 0




--362 deletions not received

select storeidentifier, count(*)  
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
group by storeidentifier
order by count(*)



select filename, COUNT(*)
--select *
--select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 1
and CAST(saledate as date) = '11/16/2012'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
--and filename = 'opdssbtjewelshawsins.dat.11162012.191802'
group by filename
order by filename

3156
3376
3302
3114
3471
3490
3288
3139


select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and CAST(saledate as date) = '11/16/2012'
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.11162012.191802'


*/
GO
