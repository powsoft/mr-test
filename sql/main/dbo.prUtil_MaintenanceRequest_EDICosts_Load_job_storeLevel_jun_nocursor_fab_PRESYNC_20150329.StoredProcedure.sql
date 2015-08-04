USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_storeLevel_jun_nocursor_fab_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create
 PROCEDURE [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_job_storeLevel_jun_nocursor_fab_PRESYNC_20150329]
AS
declare @rec cursor
declare @costtablerecordid int
declare @storeid int
declare @mridreturned int

DECLARE @Subject VARCHAR(MAX)
DECLARE @errMessage varchar(max)=''
DECLARE @badrecords table (recordid int)

DECLARE @badrecids varchar(max)=''
BEGIN




update  c set dtstoreid = StoreId,  dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on cast(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and ISNUMERIC(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), ''))=1
and c.dtchainid = s.chainid
and c.dtstoreid is null
and recordstatus = 0
and c.StoreIdentifier is not null



update p set p.dtstoreid = s.storeid,
 p.dtstorecontexttypeid = 1
--select  SupplierIdentifier,dtstoreid, s.storeid,p.banner,s.custom3,dtchainid,s.chainid
from datatrue_edi.dbo.costs p
inner join stores s
--on CAST(storenumber as int) = CAST(s.storeidentifier as int)
on cast(replace(LTRIM(rtrim(p.storenumber)), ltrim(rtrim(p.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and ISNUMERIC(replace(LTRIM(rtrim(p.storenumber)), ltrim(rtrim(p.chainidentifier)), ''))=1
and p.dtstoreid is null
and p.dtchainid=s.ChainID
and p.StoreNumber is not null 
and p.StoreNumber <>''
and PDIParticipant=0
and p.recordStatus=0

update p set p.dtstoreid = s.storeid,
 p.dtstorecontexttypeid = 1
from datatrue_edi.dbo.costs p
inner join stores s
on cast(replace(LTRIM(rtrim(p.storenumber)), ltrim(rtrim(p.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and ISNUMERIC(replace(LTRIM(rtrim(p.storenumber)), ltrim(rtrim(p.chainidentifier)), ''))=1
and LTRIM(rtrim(p.dtbanner)) = LTRIM(rtrim(custom1))
where recordstatus = 0
and p.StoreNumber is not null
and p.StoreNumber <>''
and p.dtstoreid is  null 

update p set p.dtcostzoneid=costzoneid
--select*
from datatrue_EDI..costs p
inner join CostZoneRelations c
on p.dtstoreid=storeid
and dtsupplierid=c.supplierid
and PDIParticipant=0
and p.recordStatus=0


                                                                                                                                

begin try
begin transaction



select recordid, dtstoreid into zztemp_toMR_0203
--select *
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid is not null
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and len(ltrim(rtrim(isnull(dtstoreid,''))))>0
and PriceChangeCode in ('A','B','W','D')
and Recordsource is not null
and PDIParticipant = 0
and ProductIdentifier is not null
and dtChainId=81541
and dtsupplierid in( 82017,82147)




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
				   ,bipad)
		SELECT c.[RecordID]
			  ,cast([DateCreated] as date)
			  ,case when [PriceChangeCode] in ('A','W') then 1 
			        when [PriceChangeCode] = 'D' then 9
			        else 2 end
			  ,c.dtchainid
			  ,c.dtsupplierid
			  ,LTRIM(rtrim(dtbanner))
			  ,0  --[AllStores] 
			  ,[ProductIdentifier]
			  ,isnull([ProductName], '')
			  ,isnull([Cost], 0.0)
			  ,isnull([SuggRetail], 0.0)
			  ,cast(isnull([EffectiveDate], '12/1/2011') as date)
			  ,cast(isnull([EndDate], '12/31/2099') as Date)
			  ,-1 
			  ,1
			  ,[dtcostzoneid]
			  ,Recordsource
			  ,bipad
		  FROM [DataTrue_EDI].[dbo].[Costs] c
		  inner join zztemp_toMR_0203 z
		  on c.RecordID = z.recordid		  
		
		  and dtstorecontexttypeid =1	  
  
			--set @mridreturned = SCOPE_IDENTITY()
			
			insert into maintenancerequeststores
			(MaintenanceRequestID, StoreID, Included)
			select
			MaintenanceRequestID, dtStoreID, 1
			from MaintenanceRequests m
			inner join zztemp_toMR_0203 z
			on RecordID=datatrue_edi_costs_recordid
			and MaintenanceRequestID not in 
			(select distinct MaintenanceRequestid from MaintenanceRequestStores where DateTimeCreated>GETDATE()-20)
		
			update c set c.recordstatus = 1
            from [DataTrue_EDI].[dbo].[Costs] c
            inner join zztemp_toMR_0203 t
            on c.RecordID = t. RecordID
             inner join MaintenanceRequests m
            on m.datatrue_edi_costs_recordid=c.RecordID
  
		
commit transaction
drop  table zztemp_toMR_0203
end try
begin catch
rollback transaction
end catch
return
END
GO
