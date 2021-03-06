USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Job_Rule_PDI_jun]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_MaintenanceRequest_EDICosts_Load_Job_Rule_PDI_jun]
as
DECLARE @badrecidsP varchar(max)=''
DECLARE @SubjectP VARCHAR(MAX)=''
DECLARE @errMessageP varchar(max)=''
DECLARE @badrecordsP table (recordid int)


update r set  r.dtcostzoneid = z.CostZoneID
--select recordid,r.dtCostZoneID,dtsupplierid,dtchainid , r.OwnerMarketID, z.*
from datatrue_edi.dbo.costs r
inner join costzones z
on r.dtchainid = z.ownerentityid
and r.dtsupplierid = z.supplierid
and ltrim(rtrim(r.OwnerMarketID)) = ltrim(rtrim(z.OwnerMarketID))
and PDIParticipant=1
and r.OwnerMarketID is not null
and r.dtcostzoneid is null
and RecordStatus=0
and (StoreNumber is null or StoreNumber='')

update r set  r.OwnerMarketID = z.OwnerMarketID
--select recordid,r.dtCostZoneID,dtsupplierid,dtchainid , r.OwnerMarketID, z.*
from datatrue_edi.dbo.costs r
inner join costzones z
on r.dtchainid = z.ownerentityid
and r.dtsupplierid = z.supplierid
and ltrim(rtrim(r.dtCostZoneID)) = ltrim(rtrim(z.costzoneid))
and PDIParticipant=1
and (r.OwnerMarketID is null or r.OwnerMarketID='')
and RecordStatus=0
and (StoreNumber is null or StoreNumber='')

update r set  r.OwnerMarketID = r.dtCostZoneID,r.dtcostzoneid = z.CostZoneID
--select recordid,r.dtCostZoneID,dtsupplierid,dtchainid , r.OwnerMarketID, z.*
from datatrue_edi.dbo.costs r
inner join costzones z
on r.dtchainid = z.ownerentityid
and r.dtsupplierid = z.supplierid
and ltrim(rtrim(r.dtCostZoneID)) = ltrim(rtrim(z.OwnerMarketID))
and PDIParticipant=1
and r.OwnerMarketID is null
and RecordStatus=0
and (StoreNumber is null or StoreNumber='')

select *from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and PDIParticipant =1
and (OwnerMarketID is null)
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=3
and (StoreNumber is null or StoreNumber='')
and isnull(filetype,'ND')<>'888'

if @@ROWCOUNT>0
begin
insert @badrecordsP       
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0     
and PDIParticipant =1
and (OwnerMarketID is null )
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=3
and (StoreNumber is null or StoreNumber='')
and isnull(filetype,'ND')<>'888'

set @errMessageP+='OwnerMarketID is null.' +CHAR(13)+CHAR(10)
end

 select *from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0 
and PDIParticipant =1
and (VIN is null and requesttypeid<>9)
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=3
and (StoreNumber is null or StoreNumber='')


if @@ROWCOUNT>0
begin
insert @badrecordsP       
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0     
and PDIParticipant =1
and (VIN is null and requesttypeid<>9)
and (Bipad is null or Bipad='')
and dtstorecontexttypeid=3
and (StoreNumber is null or StoreNumber='')


set @errMessageP+='VIN is null.' +CHAR(13)+CHAR(10)
end

if @errMessageP <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsP)
				delete c where dupe>1
			set @SubjectP ='Cost PDI records can not be move to MaintenanceRequest.OwnerMarketID or VIN is null.' 
			select @badrecidsP += cast(recordid as varchar(13))+ ','
			from @badrecordsP
			set @errMessageP+=CHAR(13)+CHAR(10)+'Message sent from SP prUtil_MaintenanceRequest_EDICosts_Load_Job_Rule_PDI_jun'+CHAR(13)+CHAR(10)+'Cost Record ID:'+CHAR(13)+CHAR(10)+@badrecidsP
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com;ben.shi@icucsolutions.com',--;gilad.keren@icucsolutions.com',
				@subject=@SubjectP,@body=@errMessageP				
	
       end  
       



update datatrue_edi.dbo.costs set PriceChangeCode = 
case 
	when LTRIM(rtrim(RequestTypeID)) IN(1,15,11) then 'A'
	
	when LTRIM(rtrim(RequestTypeID)) in(2,20) then 'B'
	
	when LTRIM(rtrim(RequestTypeID)) = 9 then 'D'
else null
end
where recordstatus = 0
and RequestTypeID is not null

                                                                                                       

begin try

begin transaction

select recordid
into temp_costPDI
--select *
FROM [DataTrue_EDI].[dbo].[Costs]
where recordstatus = 0
and dtstorecontexttypeid in (3,4)
and dtchainid is not null
and dtbanner is not null
and (VIN is not null or ISNULL(requesttypeid, 0) in (9))
and dtsupplierid is not null
and (PriceChangeCode in ('A','B','W','D') or ISNULL(requesttypeid, 0) in (8, 20,14))
and Recordsource is not null
and PDIParticipant = 1
and (Bipad is null or Bipad='')
and (OwnerMarketID is not null or isnull(filetype,'ND')='888' or dtstorecontexttypeid =4)
and (StoreNumber is null or StoreNumber='')



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
           ,OwnerMarketID
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
           ,[AltSellPackage2]
           ,[AltSellPackage2Qty]
           ,[AltSellPackage2UPC]
           ,[AltSellPackage2Retail]
           ,[AltSellPackage3]
           ,[AltSellPackage3Qty]
           ,[AltSellPackage3UPC]
           ,[AltSellPackage3Retail]
           ,filetype
           ,bipad
           ,ReplaceUPC
           ,OldUPC
           ,OldVIN
           ,OldVINDescription
           ,PDIParticipant
           ,PrimarySellablePkgQty
			
)
SELECT c.[RecordID]
      ,cast([DateCreated] as date)
      ,case when RequestTypeID in (1,11) then 1 else RequestTypeID end  
      ,c.dtchainid
      ,c.dtsupplierid
      ,LTRIM(rtrim(dtbanner))
      ,case when dtstorecontexttypeid in (2,3) then 1 else 0 end --[AllStores] 
      ,isnull(ProductIdentifier,'')
      ,isnull([ProductName], '')
      ,isnull([Cost], 0.0)
      ,isnull([SuggRetail], 0.0)
      ,cast(isnull([EffectiveDate], '12/1/2011') as date)
      --,cast(isnull([EffectiveDate], '12/19/2011') as date)
      ,cast(isnull([EndDate], '12/31/2099') as Date)
      ,isnull([SupplierLoginID], 0.0)
      ,[dtstorecontexttypeid]
      ,dtcostzoneid
      ,OwnerMarketID
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
	,case when dtsupplierid = 40559 then 17 else isnull(RequestStatus, 0) end
	,Skip_879_889_Conversion_ProcessCompleted 
	,SkipPopulating879_889Records 
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
           ,[AltSellPackage2]
           ,[AltSellPackage2Qty]
           ,[AltSellPackage2UPC]
           ,[AltSellPackage2Retail]
           ,[AltSellPackage3]
           ,[AltSellPackage3Qty]
           ,[AltSellPackage3UPC]
           ,[AltSellPackage3Retail]
            ,filetype
           ,bipad
           ,isnull(ReplaceUPC,'')
           ,OldUPC
           ,OldVIN
           ,OldVINDescription
           ,PDIParticipant
           ,SellablePackageQty
           			
	--select *
  FROM [DataTrue_EDI].[dbo].[Costs] c
  inner join temp_costPDI t
  on c.RecordID = t.RecordID
  where 1 = 1
 and RecordStatus = 0
 
  
  

update c set c.recordstatus = 1
from [DataTrue_EDI].[dbo].[Costs] c
inner join temp_costPDI t
on c.RecordID = t.RecordID
inner join MaintenanceRequests m
on m.datatrue_edi_costs_recordid=c.RecordID


update MaintenanceRequestS
set RequestStatus = 17 
where RequestTypeID = 20
and RequestStatus = 0

drop table temp_costPDI
if @@rowcount > 0
	begin
	
		exec dbo.prSendEmailNotification_PassEmailAddresses 'NEW TYPE 20 LOADED'
		,'NEW TYPE 20 LOADED IN MR TABLE'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
	
	
	end
	

commit transaction
end try

begin catch

rollback transaction


end catch




return
GO
