USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Job_StoreLevel_PDI_jun_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Job_StoreLevel_PDI_jun_PRESYNC_20150329]
as


DECLARE @badrecidsP varchar(max)=''
DECLARE @SubjectP VARCHAR(MAX)=''
DECLARE @errMessageP varchar(max)=''
DECLARE @badrecordsP table (recordid int)
BEGIN                                                                     
update  c set dtstoreid = StoreId,  dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on cast(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and c.dtchainid = s.chainid
and ISNUMERIC(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), ''))=1
and c.dtstoreid is null
and recordstatus = 0
and c.StoreIdentifier is not null
and len(c.StoreIdentifier) > 0  
and PDIParticipant=1
and (Bipad is null or Bipad<>'')

update  c set dtstoreid = StoreId,  dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on cast(replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and c.dtchainid = s.chainid
and ISNUMERIC(replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), ''))=1
and c.dtstoreid is null
and recordstatus = 0
and c.storenumber is not null
and c.StoreNumber <>''
and PDIParticipant=1
and (Bipad is null or Bipad<>'')

update p set p.dtstoreid = s.storeid,
 p.dtstorecontexttypeid = 1
 --select* 
from datatrue_edi.dbo.costs p
inner join stores s
on cast(replace(LTRIM(rtrim(p.storenumber)), ltrim(rtrim(p.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
--on CAST(storenumber as int) = CAST(s.custom2 as int)
and LTRIM(rtrim(p.dtbanner)) = LTRIM(rtrim(custom1))
and ISNUMERIC(replace(LTRIM(rtrim(p.storenumber)), ltrim(rtrim(p.chainidentifier)), ''))=1
where recordstatus = 0
and p.StoreNumber is not null
and p.StoreNumber <>''
and PDIParticipant=1
and (Bipad is null or Bipad<>'')

  select *from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0 
and PDIParticipant =1
and (VIN is null and  RequestTypeID <> 9)
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=1
and (StoreNumber is null or StoreNumber='')


if @@ROWCOUNT>0
begin
insert @badrecordsP       
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0     
and PDIParticipant =1
and (VIN is null and  RequestTypeID <> 9)
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=1
and (StoreNumber is null or StoreNumber='')


set @errMessageP+='VIN is null.' +CHAR(13)+CHAR(10)
end

if @errMessageP <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsP)
				delete c where dupe>1
			set @SubjectP ='Promotion PDI records can not be move to MaintenanceRequest. VIN is null.' 
			select @badrecidsP += cast(recordid as varchar(13))+ ','
			from @badrecordsP
			set @errMessageP+=CHAR(13)+CHAR(10)+'Message sent from SP prUtil_MaintenanceRequest_EDICosts_Load_Job_StoreLevel_PDI_jun'+CHAR(13)+CHAR(10)+'Cost Record ID:'+CHAR(13)+CHAR(10)+@badrecidsP
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com',--;gilad.keren@icucsolutions.com',
				@subject=@SubjectP,@body=@errMessageP				
	
       end  
                                                                                                                 

declare @rec cursor
declare @costtablerecordid int
declare @storeid int
declare @mridreturned int
declare @errormessage nvarchar(255)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
begin try

begin transaction

set @rec = CURSOR local fast_forward FOR
select recordid, dtstoreid
--into #temp
--select *
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid=1
and dtchainid is not null
--and dtbanner is not null
and (VIN is NOT null or RequestTypeID = 9)
and dtsupplierid is not null
and PriceChangeCode in ('A','B','W','D')
and Recordsource is not null
and PDIParticipant = 1
and len(ltrim(rtrim(isnull(dtstoreid,''))))>0
and (Bipad is null or Bipad='')






open @rec

fetch next from @rec into @costtablerecordid, @storeid

while @@FETCH_STATUS = 0
	begin

		INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
				   ([datatrue_edi_costs_recordid]
				   ,[SubmitDateTime]
				   ,[RequestTypeID]
				   ,[ChainID]
				   ,[SupplierID]
				   ,[Banner]
				   ,[AllStores]
				   ,[UPC]
				   ,[ItemDescription]
				   ,[Cost]
				   ,[SuggestedRetail]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[SupplierLoginID]
				   ,[dtstorecontexttypeid]
				   ,[CostZoneID]
				   ,[RequestSource]
				   ,VIN
				   ,VINDescription
				   ,PurchPackDescription
				   )
		SELECT c.[RecordID]
			  ,cast([DateCreated] as date)
			   ,case when RequestTypeID in (1,11) then 1 else RequestTypeID end  
			  ,c.dtchainid
			  ,c.dtsupplierid
			  ,LTRIM(rtrim(dtbanner))
			  ,[AllStores] --case when dtstorecontexttypeid in (2,3) then 1 else 0 end --[AllStores] 
			  ,[ProductIdentifier]
			  ,isnull([ProductName], '')
			  ,isnull([Cost], 0.0)
			  ,isnull([SuggRetail], 0.0)
			  ,cast(isnull([EffectiveDate], '12/1/2011') as date)
			  ,cast(isnull([EndDate], '12/31/2099') as Date)
			  ,-1 --0
			  ,1
			  ,[dtcostzoneid]
			  ,Recordsource
			  ,vin
			   ,VINDescription
			  ,PurchPackDescription
			
			  --select *
		  FROM [DataTrue_EDI].[dbo].[Costs] c
		  where c.RecordID = @costtablerecordid
		    and PriceChangeCode in ('A','B','W','D')
		  and dtstorecontexttypeid =1
		  
  
  
			set @mridreturned = SCOPE_IDENTITY()
			
			insert into maintenancerequeststores
			(MaintenanceRequestID, StoreID, Included)
			values(@mridreturned, @storeid, 1)
			
			--select top 1000 * from maintenancerequeststores
  
			  update c set c.recordstatus = 1
			from [DataTrue_EDI].[dbo].[Costs] c
			inner join MaintenanceRequests m
            on m.datatrue_edi_costs_recordid=c.RecordID
			where c.RecordID = @costtablerecordid
			
			fetch next from @rec into @costtablerecordid, @storeid			
		end
commit transaction
end try
begin catch
rollback transaction
end catch
return
END
GO
