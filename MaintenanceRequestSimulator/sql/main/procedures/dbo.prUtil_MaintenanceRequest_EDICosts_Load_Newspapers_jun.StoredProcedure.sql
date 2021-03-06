USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Newspapers_jun]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Newspapers_jun]
as


declare @rec cursor
declare @costtablerecordid int
declare @storeid int
declare @mridreturned int




update p  set p.ChainIdentifier = s.ChainIdentifier
from [DataTrue_EDI].[dbo].[costs] p
inner join chains s
on p.dtchainid = s.chainid
where p.ChainIdentifier is null
and recordstatus = 0
and bipad is not null

update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p
inner join chains s
on p.ChainIdentifier = s.ChainIdentifier
where p.ChainIdentifier is null
and recordstatus = 0
and bipad is not null


update c set dtstorecontexttypeid=-2
--select *
from datatrue_edi.dbo.Costs c
where  recordstatus = 0
and c.dtchainid =40393 
and dtbanner is null
and Bipad is  not null and  Bipad<>''

update  c set dtstoreid = StoreId, dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on cast(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and c.dtchainid = s.chainid 
and LTRIM(rtrim(dtbanner)) = LTRIM(rtrim(Custom1))
and c.dtstoreid is null 
and ISNUMERIC(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), ''))=1
and recordstatus = 0
and c.StoreIdentifier is not null
and c.dtchainid =40393 
and Bipad is  not null and  Bipad<>''


update  c set dtstoreid = StoreId, dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on cast(replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and c.dtchainid = s.chainid 
and LTRIM(rtrim(dtbanner)) = LTRIM(rtrim(Custom1))
and c.dtstoreid is null 
and ISNUMERIC(replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), ''))=1
and recordstatus = 0
and (c.storenumber is not null and c.storenumber <>'')


update  c set dtstoreid = StoreId, dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
--on LTRIM(rtrim(c.storenumber)) = LTRIM(rtrim(s.LegacySystemStoreIdentifier))
on LTRIM(rtrim(c.storenumber)) = LTRIM(rtrim(s.storeidentifier))
and c.dtchainid = s.chainid 
and LTRIM(rtrim(dtbanner)) = LTRIM(rtrim(Custom1))
and ISNUMERIC(LTRIM(rtrim(c.storenumber)))=1
and c.dtstoreid is null 
and recordstatus = 0
and (c.storenumber is not null and c.storenumber <>'')
and c.dtchainid =40393 
and Bipad is  not null and  Bipad<>''




update  c set dtstoreid = StoreId, dtbanner = Custom1, dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on cast(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and c.dtchainid = s.chainid
and (c.dtstoreid is null or dtbanner is null or dtstorecontexttypeid is null)
and ISNUMERIC(replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), ''))=1
and recordstatus = 0
and c.StoreIdentifier is not null
and c.dtchainid <>40393 
and Bipad is  not null and  Bipad<>''

update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreName))=LTRIM(rtrim(e.CorporateName))
and e.EdiName=c.partneridentifier
and c.dtchainid <>40393 
and c.dtbanner is null
and e.custom1 is not null
and c.StoreName is not null 
and c.StoreName<>''
and c.RecordStatus=0
and Bipad is  not null and  Bipad<>''

select * from [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e where ChainID=40393 

update  c set dtstoreid = StoreId,  dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on cast(replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), '') as bigint) = cast(LTRIM(rtrim(s.custom2))as bigint)
and c.dtchainid = s.chainid
and c.dtstoreid is null
and recordstatus = 0
and ISNUMERIC(LTRIM(rtrim(c.storenumber)))=1
and c.StoreIdentifier is not null
and Bipad is  not null and  Bipad<>''
and c.dtchainid <>40393 





update  c set dtproductid = ProductId
--select *
from datatrue_edi.dbo.Costs c
inner join ProductIdentifiers s
on LTRIM(rtrim(c.ProductIdentifier)) = LTRIM(rtrim(s.IdentifierValue))
and s.ProductIdentifierTypeID = 8
and c.dtproductid is null  
and recordstatus = 0  
and c.Bipad is  not null and  c.Bipad<>'' 


update  c set PriceChangeCode = 
case when RequestTypeID = 1 then 'A'
	when requesttypeid = 2 then 'B'
	when requesttypeid = 9 then 'D'
else null
end
--select *
from datatrue_edi.dbo.Costs c
where 1 = 1
and c.PriceChangeCode is null  
and recordstatus = 0  
and bipad is not null                                                                                                                                 

begin try

begin transaction

--select * from datatrue_edi.dbo.costs where recordstatus = 0
set @rec = CURSOR local fast_forward FOR
select recordid, dtstoreid
--into #temp
--select *
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid =1
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and dtstoreid is not null
and PriceChangeCode in ('A','B','W','D')
and Recordsource is not null
and dtstoreid is not null
and Bipad is  not null and  Bipad<>''
----and StoreIdentifier is not null


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
				   ,[RequestStatus]
				    ,[ProductID]
				   ,[Bipad]
				   ,[PDIParticipant])
		SELECT c.[RecordID]
			  ,cast([DateCreated] as date)
			  ,case when [PriceChangeCode] in ('A','W') then 1 
			        when [PriceChangeCode] = 'D' then 9
			        else 2 end
			  ,c.dtchainid
			  ,c.dtsupplierid
			  ,LTRIM(rtrim(dtbanner))
			  ,case when dtstorecontexttypeid in (2,3) then 1 else 0 end --[AllStores] 
			  ,[ProductIdentifier]
			  ,isnull([ProductName], '')
			  ,isnull([Cost], 0.0)
			  ,isnull([SuggRetail], 0.0)
			  ,cast(isnull([EffectiveDate], '12/1/2011') as date)
			  --,cast(isnull([EffectiveDate], '12/19/2011') as date)
			  ,cast(isnull([EndDate], '12/31/2099') as Date)
			  ,-1 --0
			  ,1
			  ,[dtcostzoneid]
			  ,Recordsource
			  ,11
			  ,dtproductid
			  ,bipad
			  ,isnull(PDIParticipant, 0)
			  --select *
		  FROM [DataTrue_EDI].[dbo].[Costs] c
		  where c.RecordID = @costtablerecordid
		  --where 1 = 1
		  --and RecordStatus = 0
		--  and PriceChangeCode in ('W')
		  and PriceChangeCode in ('A','B','W','D')
		  and dtstorecontexttypeid is not null
		  --and ISDATE([EndDate]) > 0
		  --and dtsupplierid <> 41440
  
  
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
GO
