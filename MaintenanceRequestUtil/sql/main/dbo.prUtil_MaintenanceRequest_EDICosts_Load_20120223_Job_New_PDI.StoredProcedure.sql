USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20120223_Job_New_PDI]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20120223_Job_New_PDI]
as

/*
select * from suppliers where supplierid = 40560
select * from suppliers where ediname = 'JML'
select distinct PartnerIdentifier from  datatrue_edi.dbo.Costs where recordstatus = 0
select * from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and recordstatus = 0 order by storename
select * from  datatrue_edi.dbo.Costs where recordstatus = 0 order by storename
select * from  datatrue_edi.dbo.promotions where loadstatus = 0 
select * from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and cast(datecreated as date) = '5/31/2012'
select distinct storename from  datatrue_edi.dbo.Costs where partneridentifier = 'SOUR' and cast(datecreated as date) = '5/31/2012'

select distinct PartnerIdentifier from  datatrue_edi.dbo.Costs 
where StoreIdentifier is null

select * from  datatrue_edi.dbo.Costs  
order by recordid desc
where PartnerIdentifier ='PEP'

select *
--update c set recordstatus=0
 from  datatrue_edi.dbo.Costs  c
where recordId between  70254 and 70262


select * 

from datatrue_edi.dbo.Costs c
where 1 = 1
and recordstatus = 20 

select * 
--select distinct Storename
update c set c.recordstatus = 20
from datatrue_edi.dbo.Costs c
where 1 = 1
and (partneridentifier = 'BIM' or dtSupplierid = 40557)
and charindex('Farm Fresh', Storename)>0
and recordstatus = 0

select dtchainid, * 
--select distinct Storename
--update c set c.dtchainid = 59973
from datatrue_edi.dbo.Costs c
where 1 = 1
and recordstatus = 0
and dtchainid is null
and ltrim(rtrim(partnername)) = '59973'
*/


update datatrue_edi.dbo.Costs set recordsource = 
case when PartnerIdentifier IS null and dtsupplierid IS Not null then 'TMP' else 'EDI' end 
where RecordStatus = 0
and Recordsource is null

/*
select *
--update c set c.Banner = 'CTM', c.dtBanner = 'CT Markets LLC', 
c.pricechangecode = 'B', c.cost = c.currentsetupcost
from [DataTrue_EDI].[dbo].[costs] c
where recordstatus = 0
and partnerName = '44285'

select *
--update c set c.Banner = 'CST', c.dtBanner = 'CST Brands Inc', c.pricechangecode = 'B', c.cost = c.currentsetupcost
from [DataTrue_EDI].[dbo].[costs] c
where recordstatus = 0
and pdiparticipant = 1
and partnerName = '59973'
*/

update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p
inner join stores s
on LTRIM(rtrim(p.Banner)) = LTRIM(rtrim(s.Custom3))
where p.dtchainid is null

update p  set p.dtchainid = 
case when CHARINDEX('44285',filename)>0 then 44285
	when CHARINDEX('59973',filename)>0 then 59973
	else null
end
from [DataTrue_EDI].[dbo].[costs] p
where p.dtchainid is null


update datatrue_edi.dbo.Costs set dtsupplierid = 
--select * from [DataTrue_EDI].[dbo].[Costs]
case --when PartnerIdentifier = 'LWS' then 41464
	when  ltrim(rtrim(PartnerIdentifier)) = 'BIM' then 40557
	when ltrim(rtrim(PartnerIdentifier)) = 'GOP' then 40558
	when ltrim(rtrim(PartnerIdentifier)) = 'NST' then 40559
	when ltrim(rtrim(PartnerIdentifier)) = 'LWS' then 41464
	when ltrim(rtrim(PartnerIdentifier)) = 'SAR' then 41465
	when ltrim(rtrim(PartnerIdentifier)) = 'SOUR' then 41440
	when ltrim(rtrim(PartnerIdentifier)) = 'RUG' then 40560	
	when ltrim(rtrim(PartnerIdentifier)) = 'TTT' then 42148
	when ltrim(rtrim(PartnerIdentifier)) = 'MRV' then 40563	
	when ltrim(rtrim(PartnerIdentifier)) = 'BUR' then 40578
	when ltrim(rtrim(PartnerIdentifier)) = 'CHO' then 40569
	when ltrim(rtrim(PartnerIdentifier)) = 'SHM' then 40561
	when ltrim(rtrim(PartnerIdentifier)) = 'JML' then 44109
	when ltrim(rtrim(PartnerIdentifier)) = 'XON' then 44188
	when ltrim(rtrim(PartnerIdentifier)) = 'ARM' then 44246
	when ltrim(rtrim(PartnerIdentifier)) = 'PDIBEER' then 44269
	when ltrim(rtrim(PartnerIdentifier)) = 'SEagleWINE' then 62314
	else null
end
--select * from datatrue_edi.dbo.Costs
where dtsupplierid is null
and recordstatus = 0

--select * from suppliers where supplierid = 44431
update datatrue_edi.dbo.Costs set PartnerIdentifier = 
case --when PartnerIdentifier = 'LWS' then 41464
	when  ltrim(rtrim(dtsupplierid)) = 40562 then 'PEP'
	when ltrim(rtrim(dtsupplierid)) = 40558 then 'GOP'
	when ltrim(rtrim(dtsupplierid)) =  40559 then 'NST'
	when ltrim(rtrim(dtsupplierid)) =  41464 then 'LWS'
	when ltrim(rtrim(dtsupplierid)) =  41465 then 'SAR'
	when ltrim(rtrim(dtsupplierid)) =   41440 then 'SOUR'
	when ltrim(rtrim(dtsupplierid)) =   40570 then 'SONY'
	when ltrim(rtrim(dtsupplierid)) =   40557 then 'BIM'
	when ltrim(rtrim(dtsupplierid)) =   40567 then 'FLO'
	when ltrim(rtrim(dtsupplierid)) =   40560 then 'RUG'
	when ltrim(rtrim(dtsupplierid)) =   42148 then 'TTT'
	when ltrim(rtrim(dtsupplierid)) =   40563 then 'MRV'
	when ltrim(rtrim(dtsupplierid)) =   40578 then 'BUR'
	when ltrim(rtrim(dtsupplierid)) =   40569 then 'CHO'
	when ltrim(rtrim(dtsupplierid)) =   40561 then 'SHM'
	when ltrim(rtrim(dtsupplierid)) =   44109 then 'JML'
	when ltrim(rtrim(dtsupplierid)) =   44188 then 'XON'
	when ltrim(rtrim(dtsupplierid)) =   44246 then 'ARM'
	when ltrim(rtrim(dtsupplierid)) =   44253 then 'LDRG'
	when ltrim(rtrim(dtsupplierid)) =   44431 then 'PDIGEN'
	when ltrim(rtrim(dtsupplierid)) =   44269 then 'PDIBEER'
	when ltrim(rtrim(dtsupplierid)) =   62314 then 'SEagleWINE'
	when ltrim(rtrim(dtsupplierid)) =   63868 then 'HPHOOD'	
	
	else null
end
--select * from datatrue_edi.dbo.Costs
where PartnerIdentifier is null
and recordstatus = 0


update datatrue_edi.dbo.costs set dtstorecontexttypeid = 
case when PartnerIdentifier = 'LWS' then 3
	when  PartnerIdentifier = 'BIM' then 2
	when PartnerIdentifier = 'SAR' then 3
	when PartnerIdentifier = 'NST' then 2
	when PartnerIdentifier = 'GOP' then 3
	when PartnerIdentifier = 'PEP' then 2
	when PartnerIdentifier = 'SONY' then 2
	when PartnerIdentifier = 'SOUR' then 2
	when PartnerIdentifier = 'FLO' then 3
	when PartnerIdentifier = 'RUG' then 2
	when PartnerIdentifier = 'TTT' then 2
	when PartnerIdentifier = 'MRV' then 2
	when PartnerIdentifier = 'BUR' then 2
	when PartnerIdentifier = 'CHO' then 2
	when PartnerIdentifier = 'SHM' then 2
	when PartnerIdentifier = 'JML' then 2
	when PartnerIdentifier = 'XON' then 2
	when PartnerIdentifier = 'ARM' then 2
	when PartnerIdentifier = 'LDRG' then 2
	when PartnerIdentifier = 'PDIGEN' then 3
	when PartnerIdentifier = 'PDIBEER' then 3
	when PartnerIdentifier = 'SEagleWINE' then 3
	when PartnerIdentifier = 'HPHOOD' then 3
	else null
end
--select * from [DataTrue_EDI].[dbo].[Costs]
where dtstorecontexttypeid is null
and RecordStatus = 0

update datatrue_edi.dbo.Costs set dtbanner = 
case when  ltrim(rtrim(banner)) = 'Cub' then 'Cub Foods'                                
	else null
end
,dtstorecontexttypeid = 3
,dtcostzoneid = 875
where 1=1
and dtbanner is null
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
where recordstatus = 0
--and dtstorecontexttypeid is null
and partneridentifier in ('BIM', 'NST','PEP')
and dtbanner is null

--select * from stores where chainid = 63614

update datatrue_edi.dbo.costs set dtbanner = 
case when dtchainid = 63612 then 'Mile High Shoppes'
	when dtchainid = 62597 then 'VOLTA'
		when dtchainid = 63613 then 'Rocker Box Stores'
		when dtchainid = 63614 then 'Mountain Markets'
			when dtchainid = 59973 then 'CST Brands'
	--when dtchainid = 44285 then 'CT Markets'
else null
end
where dtbanner is null
and PDIParticipant = 1


update datatrue_edi.dbo.costs set dtbanner = 'Duchess Shoppe', Approved = 1
where LTRIM(rtrim(Banner)) = 'DCS'

update datatrue_edi.dbo.costs 
set dtstorecontexttypeid = 3
where RecordStatus = 0
and PDIParticipant = 1

--update datatrue_edi.dbo.costs 
--set dtbanner = 'CT Markets LLC', dtchainid = 44285
--where LTRIM(rtrim(PartnerName)) = 'CT Markets'
--and dtbanner is null

update datatrue_edi.dbo.costs 
set dtbanner = 'CST Brands'
where dtchainid = 59973
and dtbanner is null


--update datatrue_edi.dbo.costs set dtbanner = 
--case 
--	when dtchainid = 59973 then 'CST Brands'
--	when dtchainid = 44285 then 'CT Markets'
--else null
--end
--where recordstatus = 0
--and PDIParticipant = 1
--and dtbanner is null

update datatrue_edi.dbo.costs set dtstorecontexttypeid = 2
where recordstatus = 0
and dtstorecontexttypeid is null
and partneridentifier in ('BIM', 'NST','PEP')


update datatrue_edi.dbo.costs set dtbanner = 
case 
	when LTRIM(rtrim(StoreName)) = 'JEWEL OSCO' then 'JEWEL'
	when LTRIM(rtrim(StoreName)) = 'FARM FRESH' then 'Farm Fresh Markets'
	when LTRIM(rtrim(StoreName)) = 'ALBERTSONS SOCAL' then 'Albertsons - SCAL'
	--when LTRIM(rtrim(StoreName)) = '0069271833302' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreName)) = 'ACME FOODS' then 'Albertsons - ACME'
	--when LTRIM(rtrim(StoreName)) = '800881278000P' then 'Shop N Save Warehouse Foods Inc'
	when LTRIM(rtrim(StoreName)) = 'SHOPPERS FOOD' then 'Shoppers Food and Pharmacy'
	when LTRIM(rtrim(StoreName)) = 'Shoppers Food and Pharmacy' then 'Shoppers Food and Pharmacy'
	when LTRIM(rtrim(StoreName)) = 'Albertsons - SCAL' then 'Albertsons - SCAL'
	when LTRIM(rtrim(StoreName)) = 'Albertsons - ACME' then 'Albertsons - ACME'
	when LTRIM(rtrim(StoreName)) = 'Albertsons - IMW' then 'Albertsons - IMW'
	when LTRIM(rtrim(StoreName)) = 'JEWEL' then 'JEWEL'
	when LTRIM(rtrim(StoreName)) = 'Farm Fresh Markets' then 'Farm Fresh Markets'			                                     
else null
end
,dtstorecontexttypeid = 2
where recordstatus = 0
--and dtstorecontexttypeid is null
and dtbanner is null
and StoreName is not null
and partneridentifier in ('SOUR')

update datatrue_edi.dbo.costs set PriceChangeCode = 
case 
	when LTRIM(rtrim(RequestTypeID)) in (1,15) then 'A'
	when LTRIM(rtrim(RequestTypeID)) in (2,9,14) then 'B'
else null
end
where recordstatus = 0
and RequestTypeID is not null
and PriceChangeCode is null
                                                                  
                                                                                                       

begin try

begin transaction

select recordid
into #temp
--select *
--select PDIParticipant,dtstorecontexttypeid,dtchainid,dtbanner,dtsupplierid,PriceChangeCode,requesttypeid,Recordsource,*
--update c set c.dtchainid = 59973
FROM [DataTrue_EDI].[dbo].[Costs] c
where recordstatus = 0
and PDIParticipant = 1
--and RequestTypeID in (9,14,15)
and dtstorecontexttypeid is not null
and dtchainid is not null
and dtbanner is not null
and dtsupplierid is not null
and (PriceChangeCode in ('A','B','W') or ISNULL(requesttypeid, 0) in (8, 20))
and Recordsource is not null
and RequestTypeID is not null


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
           ,[CostZoneID]
           ,ApprovalDateTime 
			,Approved 
			,BrandIdentifier 
			,ChainLoginID 
			,CurrentSetupCost
			,DealNumber
			,DeleteDateTime
			,DeleteLoginId
			,DeleteReason
			,DenialReason 
			,EmailGeneratedToSupplier 
			,EmailGeneratedToSupplierDateTime
			,RequestStatus 
			,Skip_879_889_Conversion_ProcessCompleted 
			,SkipPopulating879_889Records  
			,Requestsource
			,Rawproductidentifier
			           ,[PrimaryGroupLevel]
           ,[AlternateGroupLevel]
           ,[ItemGroup]
           ,[AlternateItemGroup]
           ,[Size]
           ,[ManufacturerIdentifier]
           ,[SellPkgVINAllowReorder]
           ,[SellPkgVINAllowReClaim]
           ,[PrimarySellablePkgIdentifier]
           ,[VIN]
           ,[VINDescription]
           ,[PurchPackDescription]
           ,[PurchPackQty]
           ,[AltSellPackage1]
           ,[AltSellPackage1Qty]
           ,[AltSellPackage1UPC]
           ,[AltSellPackage1Retail]
		   ,[PDIParticipant]
		   --,[requeststatus]
)
SELECT c.[RecordID]
      ,cast([DateCreated] as date)
      ,RequestTypeID
      ,c.dtchainid
      ,c.dtsupplierid
      ,LTRIM(rtrim(dtbanner))
      ,case when [AllStores] = 'true' then 1
			when [AllStores] = '1' then 1
			when [AllStores] = 'false' then 0
			when [AllStores] = '0' then 0
		else 1
       end
      ,[ProductIdentifier]
      ,isnull([ProductName], '')
      ,isnull([Cost], 0.0)
      ,isnull([SuggRetail], 0.0)
      ,cast(isnull([EffectiveDate], '12/1/2011') as date)
      --,cast(isnull([EffectiveDate], '12/19/2011') as date)
      ,cast(isnull([EndDate], '12/31/2099') as Date)
      ,isnull([SupplierLoginID], 0.0)
      ,[dtstorecontexttypeid]
      ,[dtcostzoneid]
      ,ApprovalDateTime 
	,Approved 
	,BrandIdentifier 
	,ChainLoginID 
	,isnull(CurrentSetupCost, 0.0)
	,DealNumber
	,DeleteDateTime
	,DeleteLoginId
	,DeleteReason
	,DenialReason 
	,EmailGeneratedToSupplier 
	,EmailGeneratedToSupplierDateTime
	,case when requesttypeid in (1, 15) then 0 else 17 end--isnull(RequestStatus, 17)
	,null --Skip_879_889_Conversion_ProcessCompleted 
	,1 --SkipPopulating879_889Records 
	,Recordsource 
	,RawProductIdentifier
	           ,[PrimaryGroupLevel]
           ,[AlternateGroupLevel]
           ,[ItemGroup]
           ,[AlternateItemGroup]
           ,[Size]
           ,[ManufacturerIdentifier]
           ,[SellPkgVINAllowReorder]
           ,[SellPkgVINAllowReClaim]
           ,[PrimarySellablePkgIdentifier]
           ,[VIN]
           ,[VINDescription]
           ,[PurchPackDescription]
           ,[PurchPackQty]
           ,[AltSellPackage1]
           ,[AltSellPackage1Qty]
           ,[AltSellPackage1UPC]
           ,[AltSellPackage1Retail]
           ,[PDIParticipant]
           --,17
	--select *
  FROM [DataTrue_EDI].[dbo].[Costs] c
  inner join #temp t
  on c.RecordID = t. RecordID
  where 1 = 1
  --and RecordStatus = 0
--  and PriceChangeCode in ('W')
  --and (PriceChangeCode in ('A','B','W') or isnull(RequestTypeID, 0) in (8))
  --and dtstorecontexttypeid is not null
  --and ISDATE([EndDate]) > 0
  --and dtsupplierid <> 41440
  

update c set c.recordstatus = 1
from [DataTrue_EDI].[dbo].[Costs] c
inner join #temp t
on c.RecordID = t. RecordID


update MaintenanceRequestS
set RequestStatus = 17 
where RequestTypeID = 20
and RequestStatus = 0

commit transaction
end try

begin catch

rollback transaction

declare @str nvarchar(255)

		set @str  = error_message()
		set @str  = ERROR_PROCEDURE()				


end catch

/*
select p.productname, *
--update r set ItemDescription = p.productname, r.purchpackdescription = p.packidentifier
--update r set ItemDescription = p.productname, r.purchpackdescription = p.UOM
from maintenancerequests r
inner join productidentifiers i
on ltrim(rtrim(r.UPC)) = ltrim(rtrim(i.identifiervalue))
and i.productidentifiertypeid = 2
inner join products p
on i.Productid = p.productid
where 1 = 1 
and PDIParticipant = 1
and len(r.ItemDescription) < 1
and requesttypeid in (2,9,14,15)
and r.requeststatus in (0,1,2)
and r.chainid = 44285 --59973

*/
return
GO
