USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20120223_Job_New_Rule]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_20120223_Job_New_Rule]
as

--Temporary Block of Bimbo Farm Fresh EDI
update c set c.recordstatus = 20
--select *
from datatrue_edi.dbo.Costs c
where 1 = 1
and partneridentifier = 'BIM'
--and dtSupplierid = 40557
and (charindex('Farm Fresh', Storename)>0 or charindex('Farm Fresh', dtbanner)>0)
and recordstatus = 0


--update  [DataTrue_EDI].[dbo].[Costs] set dtchainid = 
--case when (Banner = 'KNG' or dtBanner = 'The Pantry' or dtBanner = 'Pantry') then 42491
--else 40393
--end 
----select * from [DataTrue_EDI].[dbo].[Costs]
--where recordstatus = 0 
----and RecordID in (76151, 76152)

update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p
inner join stores s
on LTRIM(rtrim(p.Banner)) = LTRIM(rtrim(s.Custom3))
where p.dtchainid is null

update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p
inner join stores s
on LTRIM(rtrim(p.StoreIdentifier)) = LTRIM(rtrim(s.DunsNumber))
where p.dtchainid is null

update  c set c.dtbanner = 'Pantry'
--select *
from [DataTrue_EDI].[dbo].[Costs] c
where 1 = 1
and Banner = 'KNG'
and recordstatus = 0 

update datatrue_edi.dbo.Costs set 
dtsupplierid = (select SupplierID from Suppliers where UniqueEDIName=PartnerIdentifier)
--select * from datatrue_edi.dbo.Costs
where dtsupplierid is null
and recordstatus = 0


update datatrue_edi.dbo.Costs 
set PartnerIdentifier = (select UniqueEDIName from Suppliers where SupplierID=ltrim(rtrim(dtsupplierid)))
--select * from datatrue_edi.dbo.Costs
where PartnerIdentifier is null
and recordstatus = 0

update datatrue_edi.dbo.costs set dtstorecontexttypeid = 
(select Case StoreProductContextMethod
			when 'BANNER' then 2
			when 'COSTZONE' then 3
			else null
		end
from Suppliers where UniqueEDIName=PartnerIdentifier)
--when PartnerIdentifier = 'LWS' then 3
--	when  PartnerIdentifier = 'BIM' then 2
--	when PartnerIdentifier = 'SAR' then 3
--	when PartnerIdentifier = 'NST' then 2
--	when PartnerIdentifier = 'GOP' then 3
--	when PartnerIdentifier = 'PEP' then 2
--	when PartnerIdentifier = 'SONY' then 2
--	else null
--end
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

/*
select distinct Custom1 from Stores where DunsNumber='1939636180000'
select distinct Custom1 from Stores where DunsNumber='0069271863600'
select distinct Custom1 from Stores where DunsNumber='0069271877700'
select distinct Custom1 from Stores where DunsNumber='0032326880002'
select distinct Custom1 from Stores where DunsNumber='8008812780000'
select distinct Custom1 from Stores where DunsNumber='4233100000000'

select distinct Custom1 from Stores where DunsNumber='800881278000P'
select distinct Custom1 from Stores where DunsNumber='0069271833301'
select distinct Custom1 from Stores where DunsNumber='0069271833302'
select distinct Custom1 from Stores where DunsNumber='193963618'

select * from DataTrue_EDI.dbo.EDI_StoreCrossReference
where StoreIdentifier='1939636180001'

*/

update c set c.dtbanner=
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
--select *
from RuleUse u join Rules r
on u.RuleId=r.RuleId
and r.RuleTypeId=6
join datatrue_edi.dbo.costs c on
u.EdiName=c.partneridentifier
and r.RuleId=17
and c.RecordStatus=0
and c.dtbanner is null

/*
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
--and partneridentifier in ('BIM', 'NST','PEP')
and dtbanner is null
*/


update c set c.dtbanner=
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
--select *
from RuleUse u join Rules r
on u.RuleId=r.RuleId
and r.RuleTypeId=6
join datatrue_edi.dbo.costs c on
u.EdiName=c.partneridentifier
and r.RuleId=16
and c.RecordStatus=0
and c.dtbanner is null

/*
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
*/

update datatrue_edi.dbo.costs set PriceChangeCode = 
case 
	when LTRIM(rtrim(RequestTypeID)) = 1 then 'A'
	when LTRIM(rtrim(RequestTypeID)) = 2 then 'B'
else null
end
where recordstatus = 0
and RequestTypeID is not null
                                                                  
                                                                                                       

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
and PriceChangeCode in ('A','B','W')


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
			
)
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
	,isnull(RequestStatus, 0)
	,Skip_879_889_Conversion_ProcessCompleted 
	,SkipPopulating879_889Records  
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
