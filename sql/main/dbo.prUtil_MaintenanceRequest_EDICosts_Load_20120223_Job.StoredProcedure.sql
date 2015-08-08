USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20120223_Job]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20120223_Job]
as

/*
select * from  datatrue_edi.dbo.Costs where recordstatus = 0
select distinct PartnerIdentifier from  datatrue_edi.dbo.Costs where recordstatus = 0
select * from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and recordstatus = 0 order by storename
select * from  datatrue_edi.dbo.Costs where charindex('acme',filename)>0 and recordstatus = 1 and partneridentifier = 'SOUR' order by storename
select recordstatus, * from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' order by recordid desc
select * from  datatrue_edi.dbo.promotions where loadstatus = 0 
select * from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and cast(datecreated as date) = '5/31/2012'
select distinct storename from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and cast(datecreated as date) = '5/31/2012'
select * from maintenancerequests where 
select top 1000 * from maintenancerequests where datatrue_edi_costs_recordid = 28674
select top 1000 * from maintenancerequests where recordstatus = 1
select top 1000 * from maintenancerequests where datatrue_edi_costs_recordid in (select recordid from  datatrue_edi.dbo.Costs where charindex('acme',filename)>0 and recordstatus = 10 and partneridentifier = 'SOUR')

select top * from maintenancerequests where datatrue_edi_costs_recordid in (select recordid from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR')

select top 1000 * from maintenancerequests where supplierid = 41440 and banner = 'Albertsons - ACME'
*/

update  [DataTrue_EDI].[dbo].[Costs] set dtchainid = 40393 where recordstatus = 0

update datatrue_edi.dbo.Costs set dtsupplierid = 
case --when PartnerIdentifier = 'LWS' then 41464
	when  ltrim(rtrim(PartnerIdentifier)) = 'BIM' then 40557
	when ltrim(rtrim(PartnerIdentifier)) = 'GOP' then 40558
	when ltrim(rtrim(PartnerIdentifier)) = 'NST' then 40559
	when ltrim(rtrim(PartnerIdentifier)) = 'LWS' then 41464
	when ltrim(rtrim(PartnerIdentifier)) = 'SAR' then 41465
	when ltrim(rtrim(PartnerIdentifier)) = 'SOUR' then 41440
	else null
end
where dtsupplierid is null
and recordstatus = 0

update datatrue_edi.dbo.Costs set dtbanner = 
case when  ltrim(rtrim(banner)) = 'Cub' then 'Cub Foods'                                
	else null
end
,dtstorecontexttypeid = 3
,dtcostzoneid = 875
where dtbanner is null
and recordstatus = 0
and dtsupplierid =  40558

update datatrue_edi.dbo.costs set dtbanner = 
case 
	when LTRIM(rtrim(StoreIdentifier)) = '1939636180001' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreIdentifier)) = '1939636180000' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreIdentifier)) = '193963618' then 'Farm Fresh Markets'	                                         
	when LTRIM(rtrim(StoreIdentifier)) = '0069271863600' then 'Albertsons - SCAL'
	when LTRIM(rtrim(StoreIdentifier)) = '0069271833301' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreIdentifier)) = '0069271833302' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreIdentifier)) = '0069271877700' then 'Albertsons - ACME'
	when LTRIM(rtrim(StoreIdentifier)) = '0032326880002' then 'Cub Foods'
	when LTRIM(rtrim(StoreIdentifier)) = '8008812780000' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreIdentifier)) = '800881278000P' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreIdentifier)) = '4233100000000' then 'Shoppers Food and Pharmacy'	                                     
else null
end
,dtstorecontexttypeid = 2
where recordstatus = 0
--and dtstorecontexttypeid is null
and partneridentifier in ('BIM', 'NST')

update datatrue_edi.dbo.costs set dtbanner = 
case 
	when LTRIM(rtrim(StoreName)) = 'JEWEL OSCO' then 'JEWEL'
	when LTRIM(rtrim(StoreName)) = 'FARM FRESH' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreName)) = 'ALBERTSONS SOCAL' then 'Albertsons - SCAL'
	--when LTRIM(rtrim(StoreName)) = '0069271833302' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreName)) = 'ACME FOODS' then 'Albertsons - ACME'
	--when LTRIM(rtrim(StoreName)) = '800881278000P' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreName)) = 'SHOPPERS FOOD' then 'Shoppers Food and Pharmacy'	                                     
else null
end
,dtstorecontexttypeid = 2
where recordstatus = 0
--and dtstorecontexttypeid is null
and partneridentifier in ('SOUR')

update c set c.productidentifier = c.RawProductIdentifier
from [DataTrue_EDI].[dbo].[Costs] c
where LEN(rawproductidentifier) = 12
and ISNUMERIC(rawproductidentifier) > 0
and (len(productidentifier) < 1 or productidentifier is null)
and PriceChangeCode in ('W','A')
and RecordStatus = 0
                                                                     
select *
FROM [DataTrue_EDI].[dbo].[Costs] mr
where (len(productidentifier) < 1 or productidentifier is null)
and cast(datecreated as date) > '7/25/2012'

if @@rowcount > 0
	begin

exec dbo.prSendEmailNotification_PassEmailAddresses 'Empty ProductIdentifier Found in Costs Table'
,'Empty ProductIdentifier Found in Costs Table'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'

	end                                                                 
                                                                                                                                        

begin try

begin transaction

select recordid
into #temp
--select *
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid is not null
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and (StoreNumber is null or LEN(storenumber)<1)
and PriceChangeCode in ('A','B','W')

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

*/

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
           ,[CostZoneID])
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
      ,[dtstorecontexttypeid]
      ,[dtcostzoneid]
      --select *
  FROM [DataTrue_EDI].[dbo].[Costs] c
  inner join #temp t
  on c.RecordID = t. RecordID
  where 1 = 1
  --and RecordStatus = 0
--  and PriceChangeCode in ('W')
  and PriceChangeCode in ('A','B','W')
  and dtstorecontexttypeid is not null
  --and ISDATE([EndDate]) > 0
  --and dtsupplierid <> 41440

update c set c.recordstatus = 1
from [DataTrue_EDI].[dbo].[Costs] c
inner join #temp t
on c.RecordID = t. RecordID

commit transaction
end try

begin catch

rollback transaction


end catch




return
GO
