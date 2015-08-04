USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20111219]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20111219]
as

begin try

begin transaction

select recordid
into #temp
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid is not null

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

*/


/*
update datatrue_edi.dbo.Costs set dtsupplierid = 
case --when PartnerIdentifier = 'LWS' then 41464
	when  ltrim(rtrim(PartnerIdentifier)) = 'BIM' then 40557
	when ltrim(rtrim(PartnerIdentifier)) = 'GOP' then 40558
	when ltrim(rtrim(PartnerIdentifier)) = 'NST' then 40559
	else null
end
where dtsupplierid is null
and recordstatus = 0

update datatrue_edi.dbo.Costs set dtbanner = 
case when  ltrim(rtrim(storeidentifier)) = 'XXXXXXXX' then 'Cub Foods'
when  ltrim(rtrim(storeidentifier)) = '0069271833301' then 'Albertsons - IMW'                                   
	else null
end
,dtstorecontexttypeid = 2
where dtbanner is null
and recordstatus = 0

update datatrue_edi.dbo.Costs set dtchainid = 40393
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
           ,[dtstorecontexttypeid])
SELECT c.[RecordID]
      ,cast([DateCreated] as date)
      ,case when [PriceChangeCode] = 'A' then 1 else 2 end
      ,c.dtchainid
      ,c.dtsupplierid
      ,LTRIM(rtrim(dtbanner))
      ,case when dtstorecontexttypeid in (2,3) then 1 else 0 end --[AllStores] 
      ,[ProductIdentifier]
      ,isnull([ProductName], '')
      ,isnull([Cost], 0.0)
      ,isnull([SuggRetail], 0.0)
      ,cast(isnull([EffectiveDate], '12/21/2011') as date)
      --,cast(isnull([EffectiveDate], '12/19/2011') as date)
      ,cast(isnull([EndDate], '12/31/2025') as Date)
      ,0
      ,[dtstorecontexttypeid]
  FROM [DataTrue_EDI].[dbo].[Costs] c
  inner join #temp t
  on c.RecordID = t. RecordID
  where RecordStatus = 0
  and dtstorecontexttypeid is not null

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
