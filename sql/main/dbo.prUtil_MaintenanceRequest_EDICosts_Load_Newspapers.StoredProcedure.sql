USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Newspapers]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Newspapers]
as

/*
select * from  datatrue_edi.dbo.Costs where recordstatus = 0
select distinct PartnerIdentifier from  datatrue_edi.dbo.Costs where recordstatus = 0
select * from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and recordstatus = 0 order by storename
select * from  datatrue_edi.dbo.Costs where charindex('acme',filename)>0 and recordstatus = 1 and partneridentifier = 'SOUR' order by storename
select recordstatus, * from  datatrue_edi.dbo.Costs where partneridentifier = 'SAR' order by recordid desc
select * from  datatrue_edi.dbo.promotions where loadstatus = 0 
select * from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and cast(datecreated as date) = '5/31/2012'
select distinct storename from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and cast(datecreated as date) = '5/31/2012'
select * from maintenancerequests where 
select top 1000 * from maintenancerequests where datatrue_edi_costs_recordid = 28674
select top 1000 * from maintenancerequests where recordstatus = 1
select top 100 * from maintenancerequests order by maintenancerequestid desc
select top 1000 * from maintenancerequests where datatrue_edi_costs_recordid in (select recordid from  datatrue_edi.dbo.Costs where charindex('acme',filename)>0 and recordstatus = 10 and partneridentifier = 'SOUR')
select * from suppliers where supplierid = 40560
select top * from maintenancerequests where datatrue_edi_costs_recordid in (select recordid from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR')

select top 1000 * from maintenancerequests where supplierid = 41440 and banner = 'Albertsons - ACME'
*/

declare @rec cursor
declare @costtablerecordid int
declare @storeid int
declare @mridreturned int

--update  [DataTrue_EDI].[dbo].[Costs] set dtchainid = 40393 where recordstatus = 3

update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p
inner join chains s
on LTRIM(rtrim(p.ChainIdentifier)) = LTRIM(rtrim(s.ChainIdentifier))
where p.dtchainid is null
and recordstatus = 0

update c set recordsource = 'TMP'
--select *
from datatrue_edi.dbo.Costs c
where RecordStatus = 0
and bipad is not null
and StoreIdentifier is not null
and recordsource is null

update  c set dtsupplierid = supplierid
--select *
from datatrue_edi.dbo.Costs c
inner join Suppliers s
on LTRIM(rtrim(c.supplieridentifier)) = LTRIM(rtrim(s.supplieridentifier))
where dtsupplierid is null
and recordstatus = 0
and StoreIdentifier is not null

update  c set dtstoreid = StoreId, dtbanner = Custom1, dtstorecontexttypeid = 1
--select *
from datatrue_edi.dbo.Costs c
inner join stores s
on replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), '') = LTRIM(rtrim(s.custom2))
and c.dtchainid = s.chainid
and c.dtstoreid is null
and recordstatus = 0


update  c set dtproductid = ProductId
--select *
from datatrue_edi.dbo.Costs c
inner join ProductIdentifiers s
on LTRIM(rtrim(c.ProductIdentifier)) = LTRIM(rtrim(s.IdentifierValue))
and s.ProductIdentifierTypeID = 8
and c.dtproductid is null  
and recordstatus = 0                                                                                                                                    

begin try

begin transaction

--select * from datatrue_edi.dbo.costs where recordstatus = 0
set @rec = CURSOR local fast_forward FOR
select recordid, dtstoreid
--into #temp
--select *
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid is not null
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and dtstoreid is not null
and PriceChangeCode in ('A','B','W')
and Recordsource is not null
and PDIParticipant = 0

/*
select * from AttributeValues where AttributeID = 9
select * from Logins where OwnerEntityId = 41476
update  [DataTrue_EDI].[dbo].[Costs] set effectivedate = '12/14/2011', enddate = '12/1/2013', recordstatus = 0
update  [DataTrue_EDI].[dbo].[Costs] set recordstatus = 1 where recordid < 375
select * from [DataTrue_EDI].[dbo].[Costs] where recordstatus = 0
select * from [DataTrue_EDI].[dbo].[promotions] where loadstatus = 0

select * from maintenancerequests
--delete from maintenancerequests
where datatrue_edi_costs_recordid in (select recordid from [DataTrue_EDI].[dbo].[Costs] where recordid < 188)
update maintenancerequests set chainloginid = 13 where supplierloginid = 98 and chainloginid is null
select * from [DataTrue_EDI].[dbo].[Costs] where recordid in (2, 189)
select * from [DataTrue_EDI].[dbo].[Costs] where recordstatus = 0
select distinct custom1 from stores
select distinct dunsnumber from stores
select * from stores where ltrim(rtrim(DunsNumber)) = '0069271863600'
select * from stores where ltrim(rtrim(custom1)) = 'Albertsons - IMW' order by dunsnumber desc
update stores set dunsnumber = '0069271863600' where ltrim(rtrim(custom1)) = 'Albertsons - SCAL' and dunsnumber is null
select * from import.dbo.SVStores 
edi_suppliercrossreference_corp
select * from datatrue_edi.dbo.Costs where ltrim(rtrim(SuggRetail)) = ''''
update datatrue_edi.dbo.Costs set SuggRetail = '0.00' where ltrim(rtrim(SuggRetail)) = ''''

*/


/*
select distinct PartnerIdentifier from [DataTrue_EDI].[dbo].[Costs] 

select * from [DataTrue_EDI].[dbo].[Costs] 
where 1 = 1
--and recordstatus = 0
and ltrim(rtrim(PartnerIdentifier)) = 'SONY'


select distinct PartnerIdentifier from  datatrue_edi.dbo.Costs where recordstatus = 0








update datatrue_edi.dbo.Costs set dtbanner = 
case when  ltrim(rtrim(storeidentifier)) = '0069271833301' then 'Albertsons - IMW' 
when  ltrim(rtrim(storeidentifier)) = '0069271863600' then 'Albertsons - SCAL'                                  
	else null
end
,dtstorecontexttypeid = 2
where dtbanner is null
and recordstatus = 0

update datatrue_edi.dbo.Costs set dtchainid = 40393, Recordsource = 'EDI'
where recordstatus = 0

select * from [DataTrue_EDI].[dbo].[Costs] where recordstatus = 1 and dtchainid is null and cast(datecreated as date) = '1/24/2012'

update datatrue_edi.dbo.Costs set effectivedate = '12/21/2011', enddate = '12/31/2025'
where recordstatus = 0
 

select * from [DataTrue_Main].[dbo].[MaintenanceRequests] where supplierid = 41465
*/


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
				   ,[ProductID])
		SELECT c.[RecordID]
			  ,cast([DateCreated] as date)
			  ,case when [PriceChangeCode] in ('A','W') then 1 else 2 end
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
			  --select *
		  FROM [DataTrue_EDI].[dbo].[Costs] c
		  where c.RecordID = @costtablerecordid
		  --where 1 = 1
		  --and RecordStatus = 0
		--  and PriceChangeCode in ('W')
		  and PriceChangeCode in ('A','B','W')
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
