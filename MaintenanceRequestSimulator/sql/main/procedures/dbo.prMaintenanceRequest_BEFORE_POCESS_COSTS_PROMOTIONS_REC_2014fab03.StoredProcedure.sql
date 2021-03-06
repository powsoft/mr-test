USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_BEFORE_POCESS_COSTS_PROMOTIONS_REC_2014fab03]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Procedure inserts pre MR records from DataTrue_edi tables for furure reference>
-- =============================================
CREATE PROCEDURE [dbo].[prMaintenanceRequest_BEFORE_POCESS_COSTS_PROMOTIONS_REC_2014fab03]
	
AS
declare @rec cursor
declare @costtablerecordid int
declare @RecordID int
declare @mridreturned int
declare @RecordCount int
declare @RecordCountPromo int

DECLARE @badrecids varchar(max)=''
DECLARE @Subject VARCHAR(MAX)=''
DECLARE @errMessage varchar(max)=''
DECLARE @badrecords table (recordid int)

DECLARE @badrecidsP varchar(max)=''
DECLARE @SubjectP VARCHAR(MAX)=''
DECLARE @errMessageP varchar(max)=''
DECLARE @badrecordsP table (recordid int)

DECLARE @badrecids1 varchar(max)=''
DECLARE @Subject1 VARCHAR(MAX)=''
DECLARE @errMessage1 varchar(max)=''
DECLARE @badrecords1 table (recordid int)

DECLARE @badrecids2 varchar(max)=''
DECLARE @Subject2 VARCHAR(MAX)=''
DECLARE @errMessage2 varchar(max)=''
DECLARE @badrecords2 table (recordid int)

DECLARE @badrecidsP1 varchar(max)=''
DECLARE @SubjectP1 VARCHAR(MAX)=''
DECLARE @errMessageP1 varchar(max)=''
DECLARE @badrecordsP1 table (recordid int)

DECLARE @badrecidsT varchar(max)=''
DECLARE @SubjectT VARCHAR(MAX)=''
DECLARE @errMessageT varchar(max)=''
DECLARE @badrecordsT table (recordid int)

DECLARE @badMRidsMRt varchar(max)=''
DECLARE @SubjectMRt VARCHAR(MAX)=''
DECLARE @errMessageMRt varchar(max)=''
DECLARE @badrecordsMRt table (maintenancerequestid int)

IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztepm_costs_notin_Membership_0222') 
                  drop table zztepm_costs_notin_Membership_0222 
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztepm_promotions_notin_Membership_0222') 
                  drop table zztepm_promotions_notin_Membership_0222  

BEGIN
INSERT INTO NOT_updated_Costs(
      [RecordID]
      ,[PartnerIdentifier]
      ,[PartnerName]
      ,[PartnerDuns]
      ,[PartnerAddress]
      ,[PartnerCity]
      ,[PartnerState]
      ,[PartnerZip]
      ,[PriceChangeCode]
      ,[Banner]
      ,[StoreIdentifier]
      ,[StoreName]
      ,[StoreAddress]
      ,[StoreCity]
      ,[StoreState]
      ,[StoreZip]
      ,[PricingMarket]
      ,[AllStores]
      ,[Cost]
      ,[SuggRetail]
      ,[RawProductIdentifier]
      ,[ProductIdentifier]
      ,[ProductName]
      ,[ProcessDate]
      ,[ProcessTime]
      ,[EffectiveDate]
      ,[EndDate]
      ,[FirstOrderDate]
      ,[FirstShipDate]
      ,[FirstArrivalDate]
      ,[MarketAccount]
      ,[MarketAccountDescription]
      ,[PriceBracket]
      ,[UOM]
      ,[PrePriced]
      ,[Qty]
      ,[StoreNumber]
      ,[unitweight]
      ,[weightqualifier]
      ,[weightunitcode]
      ,[FileName]
      ,[DateCreated]
      ,[PriceListNumber]
      ,[RecordStatus]
      ,[dtchainid]
      ,[dtstoreid]
      ,[dtproductid]
      ,[dtbrandid]
      ,[dtsupplierid]
      ,[dtbanner]
      ,[dtstorecontexttypeid]
      ,[dtmaintenancerequestid]
      ,[Recordsource]
      ,[SentToRetailer]
      ,[DateSentToRetailer]
      ,[dtcostzoneid]
      ,[TempNeedToSend]
      ,[dtpromoallowance]
      ,[ProductNameReceived]
      ,[Deleted]
      ,[ApprovalDateTime]
      ,[Approved]
      ,[BrandIdentifier]
      ,[ChainLoginID]
      ,[CurrentSetupCost]
      ,[datetimecreated]
      ,[DealNumber]
      ,[DeleteDateTime]
      ,[DeleteLoginId]
      ,[DeleteReason]
      ,[DenialReason]
      ,[EmailGeneratedToSupplier]
      ,[EmailGeneratedToSupplierDateTime]
      ,[RequestStatus]
      ,[RequestTypeID]
      ,[Skip_879_889_Conversion_ProcessCompleted]
      ,[SkipPopulating879_889Records]
      ,[SubmitDateTime]
      ,[SupplierLoginID]
      ,[ProductCategory]
      ,[ActualEffectiveDateSent]
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
      ,[OldUPC]
      ,[InvoiceNo]
      ,[StoreDuns]
      ,[OldVIN]
      ,[OldVINDescription]
      ,[ReplaceUPC]
      ,[StoreGLN]
      ,[SupplierIdentifier]
      ,[ChainIdentifier]
      ,[ProductIdentifierType]
      ,[Bipad]
      ,[OwnerMarketID]
     ,[insertTimefromCOST] )
    select
     [RecordID]
      ,[PartnerIdentifier]
      ,SUBSTRING(PartnerName,1,30)
      ,[PartnerDuns]
      ,[PartnerAddress]
      ,[PartnerCity]
      ,[PartnerState]
      ,[PartnerZip]
      ,[PriceChangeCode]
      ,[Banner]
      ,[StoreIdentifier]
      ,[StoreName]
      ,[StoreAddress]
      ,[StoreCity]
      ,[StoreState]
      ,[StoreZip]
      ,[PricingMarket]
      ,[AllStores]
      ,[Cost]
      ,[SuggRetail]
      ,[RawProductIdentifier]
      ,[ProductIdentifier]
      ,[ProductName]
      ,[ProcessDate]
      ,[ProcessTime]
      ,[EffectiveDate]
      ,[EndDate]
      ,[FirstOrderDate]
      ,[FirstShipDate]
      ,[FirstArrivalDate]
      ,[MarketAccount]
      ,[MarketAccountDescription]
      ,[PriceBracket]
      ,[UOM]
      ,[PrePriced]
      ,[Qty]
      ,[StoreNumber]
      ,[unitweight]
      ,[weightqualifier]
      ,[weightunitcode]
      ,[FileName]
      ,[DateCreated]
      ,[PriceListNumber]
      ,[RecordStatus]
      ,[dtchainid]
      ,[dtstoreid]
      ,[dtproductid]
      ,[dtbrandid]
      ,[dtsupplierid]
      ,[dtbanner]
      ,[dtstorecontexttypeid]
      ,[dtmaintenancerequestid]
      ,[Recordsource]
      ,[SentToRetailer]
      ,[DateSentToRetailer]
      ,[dtcostzoneid]
      ,[TempNeedToSend]
      ,[dtpromoallowance]
      ,[ProductNameReceived]
      ,[Deleted]
      ,[ApprovalDateTime]
      ,[Approved]
      ,[BrandIdentifier]
      ,[ChainLoginID]
      ,[CurrentSetupCost]
      ,[datetimecreated]
      ,[DealNumber]
      ,[DeleteDateTime]
      ,[DeleteLoginId]
      ,[DeleteReason]
      ,[DenialReason]
      ,[EmailGeneratedToSupplier]
      ,[EmailGeneratedToSupplierDateTime]
      ,[RequestStatus]
      ,[RequestTypeID]
      ,[Skip_879_889_Conversion_ProcessCompleted]
      ,[SkipPopulating879_889Records]
      ,[SubmitDateTime]
      ,[SupplierLoginID]
      ,[ProductCategory]
      ,[ActualEffectiveDateSent]
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
      ,[OldUPC]
      ,[InvoiceNo]
      ,[StoreDuns]
      ,[OldVIN]
      ,[OldVINDescription]
      ,[ReplaceUPC]
      ,[StoreGLN]
      ,[SupplierIdentifier]
      ,[ChainIdentifier]
      ,[ProductIdentifierType]
      ,[Bipad]
      ,[OwnerMarketID]
      ,getdate()
     -- select*
  from DataTrue_edi.dbo.costs with (NOLOCK) where 
 recordstatus = 0 
 and RecordID not in (select distinct RecordID from not_updated_costs)

INSERT INTO NOT_updated_Promotions--[DataTrue_EDI].[dbo].[Promotions]
   (recordid
           ,[SupplierIdentifier]
           ,[DateStartPromotion]
           ,[DateEndPromotion]
           ,[PromotionStatus]
           ,[PromotionNumber]
           ,[MarketAreaCodeIdentifier]
           ,[MarketAreaCode]
           ,[UnitSize]
           ,[VendorName]
           ,[VendorDuns]
           ,[Note]
           ,[StoreName]
           ,[StoreDuns]
           ,[StoreNumber]
           ,[ProductName]
           ,[Allowance_ChargeCode]
           ,[Allowance_ChargeMethod]
           ,[Allowance_ChargeRate]
           ,[Allowance_ChargeMeasureCode]
           ,[RawProductIdentifier]
           ,[ProductIdentifier]
           ,[ExceptionNumber]
           ,[GroupNumber]
           ,[FileName]
           ,[DateTimeCreated]
           ,[Loadstatus]
           ,[chainid]
           ,[productid]
           ,[brandid]
           ,[supplierid]
           ,[storeid]
           ,[banner]
           ,[CorpIdentifier]
           ,[CorporateName]
           ,[SupplierName]
           ,[StoreIdentifier]
           ,[StoreSBTNumber]
           ,[dtstorecontexttypeid]
           ,[dtcostzoneid]
           ,[dtmaintenancerequestid]
           ,[Recordsource]
           ,[dtbanner]
           ,[SentToRetailer]
           ,[DateSentToRetailer]
           ,[ControlNumber]
           ,[TempNeedToSend]
           ,[Restored]
           ,[ProductNameReceived]
           ,[Approved]
           ,[ApprovalDateTime]
           ,[AllStores]
           ,[BrandIdentifier]
           ,[ChainLoginID]
           ,[Cost]
           ,[CurrentSetupCost]
           ,[DealNumber]
           ,[DeleteDateTime]
           ,[DeleteLoginId]
           ,[DeleteReason]
           ,[DenialReason]
           ,[EmailGeneratedToSupplier]
           ,[EmailGeneratedToSupplierDateTime]
           ,[MarkDeleted]
           ,[RequestStatus]
           ,[RequestTypeID]
           ,[Skip_879_889_Conversion_ProcessCompleted]
           ,[SkipPopulating879_889Records]
           ,[SubmitDateTime]
           ,[SuggestedRetail]
           ,[SupplierLoginID]
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
           ,[OwnerMarketID]
           ,[insertTimefromCOST] )
    select
           [recordid]
           ,[SupplierIdentifier]
           ,[DateStartPromotion]
           ,[DateEndPromotion]
           ,[PromotionStatus]
           ,[PromotionNumber]
           ,[MarketAreaCodeIdentifier]
           ,[MarketAreaCode]
           ,[UnitSize]
           ,[VendorName]
           ,[VendorDuns]
           ,[Note]
           ,[StoreName]
           ,[StoreDuns]
           ,[StoreNumber]
           ,[ProductName]
           ,[Allowance_ChargeCode]
           ,[Allowance_ChargeMethod]
           ,[Allowance_ChargeRate]
           ,[Allowance_ChargeMeasureCode]
           ,[RawProductIdentifier]
           ,[ProductIdentifier]
           ,[ExceptionNumber]
           ,[GroupNumber]
           ,[FileName]
           ,[DateTimeCreated]
           ,[Loadstatus]
           ,[chainid]
           ,[productid]
           ,[brandid]
           ,[supplierid]
           ,[storeid]
           ,[banner]
           ,[CorpIdentifier]
           ,[CorporateName]
           ,[SupplierName]
           ,[StoreIdentifier]
           ,[StoreSBTNumber]
           ,[dtstorecontexttypeid]
           ,[dtcostzoneid]
           ,[dtmaintenancerequestid]
           ,[Recordsource]
           ,[dtbanner]
           ,[SentToRetailer]
           ,[DateSentToRetailer]
           ,[ControlNumber]
           ,[TempNeedToSend]
           ,[Restored]
           ,[ProductNameReceived]
           ,[Approved]
           ,[ApprovalDateTime]
           ,[AllStores]
           ,[BrandIdentifier]
           ,[ChainLoginID]
           ,[Cost]
           ,[CurrentSetupCost]
           ,[DealNumber]
           ,[DeleteDateTime]
           ,[DeleteLoginId]
           ,[DeleteReason]
           ,[DenialReason]
           ,[EmailGeneratedToSupplier]
           ,[EmailGeneratedToSupplierDateTime]
           ,[MarkDeleted]
           ,[RequestStatus]
           ,[RequestTypeID]
           ,[Skip_879_889_Conversion_ProcessCompleted]
           ,[SkipPopulating879_889Records]
           ,[SubmitDateTime]
           ,[SuggestedRetail]
           ,[SupplierLoginID]
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
           ,[OwnerMarketID]
           ,getdate()
                 
  from DataTrue_edi.dbo.promotions with (NOLOCK) where 
 loadstatus = 0
 and RecordID not in (select distinct RecordID from not_updated_promotions)
 
 /****************************************find not DX chains/suppliers in comming sets***********************/
 


 
 /*********************** all costs updates***********************************/



 
  update c 
 set Approved = 1, ApprovaldateTime = getdate(), SkipPopulating879_889Records = 1
 --select SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Costs c
 where RecordStatus = 0 
 and PDIParticipant=1
 and RequestTypeID=11
 
 
 update c set filetype = 
case 
	when LTRIM(rtrim(filename)) like '%.888.%' then 888
	when LTRIM(rtrim(filename)) like '%.879.%' then 879
	when LTRIM(rtrim(filename)) like '%.832.%' then 832
else null
end
from datatrue_edi.dbo.costs c
 where RecordStatus = 0  





--update c set c.recordstatus = 20
--from datatrue_edi.dbo.Costs c
--where partneridentifier = 'BIM'
----and dtSupplierid = 40557
--and (charindex('Farm Fresh', Storename)>0 or charindex('Farm Fresh', dtbanner)>0)
--and ISNULL(requesttypeid, 0) <> 8
--and recordstatus = 0

update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p 
inner join chains s
on LTRIM(rtrim(p.ChainIdentifier)) = LTRIM(rtrim(s.ChainIdentifier))
where p.dtchainid is null
and recordstatus = 0



update p  set p.dtchainid = s.chainid
from [DataTrue_EDI].[dbo].[costs] p 
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.Banner)) = LTRIM(rtrim(s.banner))
where p.dtchainid is null
and RecordStatus = 0

update p  set p.ChainIdentifier = s.ChainIdentifier
from [DataTrue_EDI].[dbo].[costs] p 
inner join chains s
on p.dtchainid = s.chainid
where p.ChainIdentifier is null
and recordstatus = 0

update p  set p.dtchainid = s.chainid
--select count(*)
from [DataTrue_EDI].[dbo].[costs] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreIdentifier)) = LTRIM(rtrim(s.CorporateIdentifier))
and p.dtchainid is null
and recordstatus = 0
	

update c set 
 dtsupplierid = SupplierID  
 from datatrue_edi.dbo.Costs c 
 inner join Suppliers s 
 on LTRIM(rtrim(UniqueEDIName))=LTRIM(rtrim(PartnerIdentifier))
 and  dtsupplierid is null
and recordstatus = 0

update  c set dtsupplierid = supplierid
--select *
from datatrue_edi.dbo.Costs c 
inner join Suppliers s
on LTRIM(rtrim(c.supplieridentifier)) = LTRIM(rtrim(s.supplieridentifier))
where dtsupplierid is null
and recordstatus = 0
and StoreIdentifier is not null
                  
  select dtchainid,dtsupplierid into zztepm_costs_notin_Membership_0222
 from (
 select distinct dtchainid,dtsupplierid
 from datatrue_edi.dbo.Costs c
 where RecordStatus = 0 
 and dtchainid is not null
 and dtsupplierid is not null
 except
 select distinct OrganizationEntityID,MemberEntityID
 from datatrue_main..Memberships m
 where  m.MembershipTypeID  in (14)) a
 --Changed to above line by charlie and Gilad 3/2/2015 where  m.MembershipTypeID  in (14,15)) a
 
  update c set c.PDIParticipant = 

( Case  when lower(ltrim(rtrim(recordsource)))='tmp'  then '0'
        when lower(ltrim(rtrim(recordsource)))='tmppdi' then '1'
                            else null end)
 from datatrue_edi.dbo.Costs c
  where RecordStatus = 0 --and c.PDIParticipant is null

update c set  c.PDIParticipant = p.PDIParticipant
--select *
from datatrue_edi.dbo.Costs c 
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on dtsupplierid = supplierid
and dtchainid=p.chainid
where RecordStatus = 0
and (Bipad is  null or Bipad<>'')


update c set PDIParticipant = PDITradingPartner, Approved = 1, ApprovalDateTime = GETDATE()
--select recordsource, *
from datatrue_edi.dbo.Costs c
inner join datatrue_main.dbo.chains b
on c.dtchainid = b.chainid
where RecordStatus = 0
and bipad is not null


--update c set PDIParticipant = PDITradingPartner
----select recordsource, *
--from datatrue_edi.dbo.Costs c
--inner join datatrue_main.dbo.chains b
--on c.dtchainid = b.chainid
--where RecordStatus = 0
--and PDIParticipant <> PDITradingPartner
--and lower(ltrim(rtrim(recordsource)))='edi'

 
 update c set recordsource = 

( Case  when lower(right(ltrim(rtrim(filename)),4))='xlsx' and Bipad is null and IsRegulated=0  and PDIParticipant=0 then 'XTMP'
        when lower(right(ltrim(rtrim(filename)),4))='xlsx' and Bipad is null and IsRegulated=0  and PDIParticipant=1 then 'XTMPPDI'
        when lower(right(ltrim(rtrim(filename)),4))='xlsx' and Bipad is null and IsRegulated=1 then 'XTMPREG'
        when lower(right(ltrim(rtrim(filename)),4))='xlsx' and Bipad is not null and IsRegulated=0 then 'XTmpnsp'
        when lower(right(ltrim(rtrim(filename)),4))<>'xlsx' and Bipad is null and IsRegulated=0 and PDIParticipant=0 then 'XEDI' 
        when lower(right(ltrim(rtrim(filename)),4))<>'xlsx' and Bipad is null and IsRegulated=0  and PDIParticipant=1 then 'XEDIPDI'
        when lower(right(ltrim(rtrim(filename)),4))<>'xlsx' and Bipad is not null and IsRegulated=0 then 'XEDInsp'
        when lower(right(ltrim(rtrim(filename)),4))<>'xlsx' and Bipad is  null and IsRegulated=1 then 'XEDIREG'           
                       else null end)
 from datatrue_edi.dbo.Costs c
 inner join Suppliers s
 on dtsupplierid=supplierid
 where RecordStatus = 0 and recordsource is null
 

 update  c set storenumber=replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), '')
--select storenumber,storeidentifier,replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), ''),chainidentifier ,*
from datatrue_edi.dbo.Costs c
where recordstatus = 0
and ISNUMERIC(LTRIM(rtrim(c.storenumber)))<>1
 
and c.storenumber is not null
and c.StoreNumber <>''

 update  c set storenumber=replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), '')
--select storenumber,storeidentifier,replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), ''),chainidentifier ,*
from datatrue_edi.dbo.Costs c
where recordstatus = 0
and ISNUMERIC(LTRIM(rtrim(c.storeidentifier)))<>1
and replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(c.chainidentifier)), '') in 
(select distinct storeidentifier from stores where chainid=dtchainid)
and c.storeidentifier is not null
and c.storeidentifier <>''
and (c.storenumber is  null or c.StoreNumber ='')
and recordsource like '%tmp%'

 update  c set storenumber=LTRIM(rtrim(c.storeidentifier))
--select storenumber,storeidentifier,replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(c.chainidentifier)), ''),chainidentifier ,*
from datatrue_edi.dbo.Costs c
where recordstatus = 0
and ISNUMERIC(LTRIM(rtrim(c.storeidentifier)))=1
and c.storeidentifier is not null
and c.StoreIdentifier in
(select distinct storeidentifier from stores where chainid=dtchainid)
and c.storeidentifier <>''
and (c.storenumber is  null or c.StoreNumber ='')
and recordsource like '%tmp%'


 



update p set dtstorecontexttypeid=-1
--select distinct dtbanner,dtchainid,dtSupplierID,storenumber 
from DataTrue_EDI..costs p 
where 
recordstatus=0 and storenumber is not null and StoreNumber<>'' 
and StoreNumber not in (select distinct s.StoreIdentifier from stores s where s.chainid=p.dtchainid )   


update c
    set PartnerIdentifier = UniqueEDIName
    from datatrue_edi.dbo.Costs c
    join Suppliers s on SupplierID=ltrim(rtrim(dtsupplierid))
    and PartnerIdentifier is null and recordstatus = 0
 update c
    set supplierIdentifier = UniqueEDIName
    from datatrue_edi.dbo.Costs c
    join Suppliers s on SupplierID=ltrim(rtrim(dtsupplierid))
    and c.supplierIdentifier is null and recordstatus = 0






update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreIdentifier))=LTRIM(rtrim(e.CorporateIdentifier))
and LTRIM(rtrim(e.EdiName))=LTRIM(rtrim(c.partneridentifier))
and c.dtbanner is null
and c.StoreIdentifier is not null
and c.StoreIdentifier<>''
and c.RecordStatus=0

update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreName))=LTRIM(rtrim(e.CorporateName))
and LTRIM(rtrim(e.EdiName))=LTRIM(rtrim(c.partneridentifier))
and c.dtbanner is null
and e.custom1 is not null
and c.StoreName is not null 
and c.StoreName<>''
and c.RecordStatus=0

update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.costs c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreName))=LTRIM(rtrim(e.CorporateName))
and DataTrueSupplierID=dtsupplierid
and c.dtbanner is null
and e.custom1 is not null
and c.StoreName is not null 
and c.StoreName<>''
and c.RecordStatus=0




 
 update c 
 set  approved = 1, approvaldatetime = getdate(), SkipPopulating879_889Records =1
 ----select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Costs c
 inner join zztepm_costs_notin_Membership_0222 z
 on c.dtsupplierid=z.dtsupplierid 
 and c.dtchainid=z.dtchainid
 inner join suppliers s
 on c.dtsupplierid=supplierid
 where 1 = 1
 and RecordStatus = 0 
 and IsRegulated=1
 
  update c 
 set  SkipPopulating879_889Records =1
 ----select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Costs c
 inner join zztepm_costs_notin_Membership_0222 z
 on c.dtsupplierid=z.dtsupplierid 
 and c.dtchainid=z.dtchainid
 inner join suppliers s
 on c.dtsupplierid=supplierid
 where 1 = 1
 and RecordStatus = 0 
 and IsRegulated=0
 and PDIParticipant=1



 update c 
 set Approved = null , SkipPopulating879_889Records =0
 --select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Costs c
 inner join suppliers s
 on dtsupplierid=supplierid 
inner join Memberships m
 on s.SupplierID = m.MemberEntityID
 and c.dtchainid = m.OrganizationEntityID
 and m.MembershipTypeID = 14
 and RecordStatus = 0 
 and IsRegulated=1

 update c 
 set SkipPopulating879_889Records =0
 --select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Costs c
 inner join suppliers s
 on dtsupplierid=supplierid 
inner join Memberships m
 on s.SupplierID = m.MemberEntityID
 and c.dtchainid = m.OrganizationEntityID
 and m.MembershipTypeID = 14
 and SkipPopulating879_889Records is null
 
  update c 
 set SkipPopulating879_889Records =0
 --select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Costs c
 inner join suppliers s
 on dtsupplierid=supplierid 
inner join Memberships m
 on s.SupplierID = m.MemberEntityID
 and c.dtchainid = m.OrganizationEntityID
 and m.MembershipTypeID = 15
 and IsRegulated=0
  and SkipPopulating879_889Records is null
  
 update c 
 set dtstorecontexttypeid = 4
 --select SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Costs c
 inner join suppliers s
 on dtsupplierid=supplierid 
 where RecordStatus = 0 
 and IsRegulated=1
 and LTRIM(rtrim(RecordSource)) <>'Tmppdi'
 and StoreNumber is null
 
 
update c set dtstorecontexttypeid = 3
from datatrue_edi.dbo.costs c 
where PDIParticipant=1
and dtstorecontexttypeid is null and RecordStatus = 0
and (StoreNumber is null or StoreNumber ='')

update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	
                                 when 'COSTZONE' then 3
                                 when 'STORESETUP' then 4
                                 else null end)
from datatrue_edi.dbo.costs c inner join SupplierStoreProductContextMethod m
on  c.dtChainId=m.chainid
and c.dtsupplierid=supplierid
and Bipad is null
and ltrim(rtrim(m.Bannername)) =ltrim(rtrim(dtbanner))
and dtstorecontexttypeid is null and RecordStatus = 0
and (StoreNumber is null or StoreNumber ='')


update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	
                                 when 'COSTZONE' then 3
                                 when 'STORESETUP' then 4
                                 else null end)
from datatrue_edi.dbo.costs c inner join SupplierStoreProductContextMethod m
on  c.dtChainId=m.chainid
and c.dtsupplierid=supplierid
and Bipad is null
and Bannername is null
and dtstorecontexttypeid is null and RecordStatus = 0
and (StoreNumber is null or StoreNumber ='')




update datatrue_edi.dbo.costs set PriceChangeCode = 
case 
	when LTRIM(rtrim(RequestTypeID)) in (1,15) then 'A'	
	when LTRIM(rtrim(RequestTypeID)) = 2 then 'B'
	when LTRIM(rtrim(RequestTypeID)) = 20 then 'B'
	when LTRIM(rtrim(RequestTypeID)) = 9 then 'D'
	when LTRIM(rtrim(RequestTypeID)) = 14 then 'D'
else null
end
where recordstatus = 0
and RequestTypeID is not null
and PriceChangeCode is null


update datatrue_edi.dbo.costs set RequestTypeID = 
case 
	when LTRIM(rtrim(PriceChangeCode)) = 'A' then 1
	when LTRIM(rtrim(PriceChangeCode)) = 'B' then 2 
	when LTRIM(rtrim(PriceChangeCode)) = 'W' then 1
	when LTRIM(rtrim(PriceChangeCode)) = 'D' then 9
else null
end
where recordstatus = 0
and RequestTypeID is  null
and PriceChangeCode is not null


update datatrue_edi.dbo.costs set ProductIdentifier = ''
where recordstatus = 0
and ProductIdentifier is  null


update c set AllStores = case when AllStores = 'FALSE' then 0
							when AllStores = 'TRUE' then 1
							else AllStores end
--select *
from datatrue_edi.dbo.Costs c
where 1 = 1
and recordstatus = 0
and AllStores in ('FALSE','TRUE')


select *
from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and PDIParticipant not in (0,1)

if @@ROWCOUNT >0

insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and PDIParticipant not in (0,1)

if @@ROWCOUNT >0
set @errMessage+='Not identified PDIParticipant' +CHAR(13)+CHAR(10)

 select *
from [DataTrue_EDI].[dbo].[costs] p
inner join chains c
on c.ChainID=dtchainid
where recordstatus =0
and p.PDIParticipant <>c.PDITradingPartner
and Bipad is not null

if @@ROWCOUNT >0

insert @badrecords
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
inner join chains c
on c.ChainID=dtchainid
where recordstatus =0
and p.PDIParticipant <>c.PDITradingPartner
and Bipad is not null
	
if @@ROWCOUNT >0
set @errMessage+='Incorrect NEWSP PDIParticipant ' +CHAR(13)+CHAR(10)

if @errMessage <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecords)
				delete c where dupe>1
			set @Subject ='Incorrect NEWSP PDIParticipant ' 
			select @badrecids += cast(recordid as varchar(13))+ ','
			from @badrecords
			set @errMessage+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@Subject,@body=@errMessage				
	
       end       

select *
from datatrue_edi.dbo.costs c
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on c.dtsupplierid = p.supplierid
and c.dtchainid=p.chainid
and recordStatus = 0
and (c.PDIParticipant <>p.PDIParticipant or c.PDIParticipant is null)
and (Bipad is null or Bipad ='')

if @@ROWCOUNT >0

insert @badrecords2
select RecordID 
from datatrue_edi.dbo.costs c
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on c.dtsupplierid = p.supplierid
and c.dtchainid=p.chainid
and recordStatus = 0
and (c.PDIParticipant <>p.PDIParticipant or c.PDIParticipant is null)
and (Bipad is null or Bipad ='')

if @@ROWCOUNT >0
set @errMessage2+='Incorrect Cost PDIParticipant' +CHAR(13)+CHAR(10)

if @errMessage2 <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecords1)
				delete c where dupe>1
			set @Subject2 ='Incorrect Cost PDIParticipant ' 
			select @badrecids2 += cast(recordid as varchar(13))+ ','
			from @badrecords2
			set @errMessage2+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids2
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@Subject2,@body=@errMessage2				
	
       end      


--   

/******************************Promotions update for all ****************************************/





--update c set c.loadstatus = 20
--from datatrue_edi.dbo.Promotions c
--where  supplieridentifier = 'BIM'
----and Supplierid = 40557
--and (charindex('Farm Fresh', CorporateName)>0 or charindex('Farm Fresh', dtbanner)>0 or charindex('Farm Fresh', StoreName)>0)
--and loadstatus = 0


update p  set p.chainid = s.chainid
from [DataTrue_EDI].[dbo].[promotions] p
inner join [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp] s
on LTRIM(rtrim(p.StoreDuns)) = LTRIM(rtrim(s.CorporateIdentifier))
and p.chainid is null
and Loadstatus = 0

update p  set p.chainid = s.chainid
from [DataTrue_EDI].[dbo].[promotions] p
inner join stores s
on LTRIM(rtrim(p.StoreDuns)) = LTRIM(rtrim(s.DunsNumber))
where p.chainid is null
and Loadstatus = 0

update c set  c.supplierid = s.SupplierID  
 from datatrue_edi.dbo.Promotions c
 inner join Suppliers s 
 on s.UniqueEDIName=c.SupplierIdentifier
 and  c.supplierid is null
and loadstatus = 0


 select chainid,supplierid into zztepm_promotions_notin_Membership_0222
 from (
 select distinct chainid,supplierid
 from datatrue_edi.dbo.promotions c
 where LoadStatus = 0 
 and chainid is not null
 and supplierid is not null
 except
 select distinct OrganizationEntityID,MemberEntityID
 from datatrue_main..Memberships m
 where  m.MembershipTypeID  in (14)) a


 update c 
 set  approved = 1,approvaldatetime = getdate()--, SkipPopulating879_889Records =1
 ----select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Promotions c
 inner join zztepm_promotions_notin_Membership_0222 z
 on c.supplierid=z.supplierid 
 and c.chainid=z.chainid
 inner join suppliers s
 on c.supplierid=s.supplierid
 where 1 = 1
 and LoadStatus = 0 
 and IsRegulated=1
 
  update c 
 set  SkipPopulating879_889Records =1
 ----select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Promotions c
 --inner join zztepm_promotions_notin_Membership_0222 z
 --on c.supplierid=z.supplierid 
 --and c.chainid=z.chainid
 --inner join suppliers s
 --on c.supplierid=s.supplierid
 where 1 = 1
 and LoadStatus = 0 
 --and IsRegulated=0
 and PDIParticipant=1

 update c 
 set Approved = null , SkipPopulating879_889Records =0
 --select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Promotions c
 inner join suppliers s
 on c.supplierid=s.supplierid 
inner join Memberships m
 on s.SupplierID = m.MemberEntityID
 and c.chainid = m.OrganizationEntityID
 and m.MembershipTypeID = 14
 and LoadStatus = 0 
 and IsRegulated=1
 and isnull(PDIParticipant,0) <> 1

 update c 
 set SkipPopulating879_889Records =0
 --select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.Promotions c
 inner join suppliers s
 on c.supplierid=s.supplierid 
inner join Memberships m
 on s.SupplierID = m.MemberEntityID
 and c.chainid = m.OrganizationEntityID
 and m.MembershipTypeID = 14
 and SkipPopulating879_889Records is null
  and isnull(PDIParticipant,0) <> 1
 
 update c set recordsource = 

( Case  when lower(right(ltrim(rtrim(filename)),4))='xlsx'  and IsRegulated=0  and PDIParticipant=0 then 'TMP'
        when lower(right(ltrim(rtrim(filename)),4))='xlsx'  and IsRegulated=0  and PDIParticipant=1 then 'TMPPDI'
        when lower(right(ltrim(rtrim(filename)),4))='xlsx'  and IsRegulated=1 then 'TMPREG'
        when lower(right(ltrim(rtrim(filename)),4))<>'xlsx' and IsRegulated=0  and PDIParticipant=0 then  'EDI' 
        when lower(right(ltrim(rtrim(filename)),4))<>'xlsx' and IsRegulated=0  and PDIParticipant=1 then 'EDIPDI'
        when lower(right(ltrim(rtrim(filename)),4))<>'xlsx' and IsRegulated=1 then 'EDIREG'           
                       else null end)
 from datatrue_edi.dbo.promotions c 
 inner join Suppliers s
 on c.supplierid=s.supplierid
 where Loadstatus = 0 and recordsource is null

 update  c set storenumber=replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(chainidentifier)), '')
--select storenumber,storeidentifier,replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(chainidentifier)), ''),chainidentifier ,*
from datatrue_edi.dbo.Promotions c
inner join chains ch
on c.chainid=ch.chainid
where loadstatus = 0
and ISNUMERIC(LTRIM(rtrim(c.storenumber)))<>1 
and c.storenumber is not null
and c.StoreNumber <>''

 update  c set storenumber=replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(chainidentifier)), '')
--select storenumber,storeidentifier,replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(chainidentifier)), ''),chainidentifier ,*
from datatrue_edi.dbo.Promotions c
inner join chains ch
on c.chainid=ch.chainid
where loadstatus = 0
and ISNUMERIC(LTRIM(rtrim(c.storeidentifier)))<>1
and replace(LTRIM(rtrim(c.storeidentifier)), ltrim(rtrim(ch.chainidentifier)), '') in 
(select distinct storeidentifier from stores where chainid=c.chainid)
and c.storeidentifier is not null
and c.storeidentifier <>''
and (c.storenumber is  null or c.StoreNumber ='')
and recordsource like '%tmp%'

 update  c set storenumber=LTRIM(rtrim(c.storeidentifier))
--select storenumber,storeidentifier,replace(LTRIM(rtrim(c.storenumber)), ltrim(rtrim(chainidentifier)), ''),chainidentifier ,*
from datatrue_edi.dbo.Promotions c
inner join chains ch
on c.chainid=ch.chainid
where loadstatus = 0
and ISNUMERIC(LTRIM(rtrim(c.storeidentifier)))=1
and c.storeidentifier in 
(select distinct storeidentifier from stores where chainid=c.chainid)
and c.storeidentifier is not null
and c.storeidentifier <>''
and (c.storenumber is  null or c.StoreNumber ='')
and recordsource like '%tmp%'





update p set dtstorecontexttypeid=-1      
--- select distinct banner,chainid,SupplierID,storenumber 
from DataTrue_EDI..promotions p 
where 
Loadstatus=0 and storenumber is not null and StoreNumber<>'' 
and StoreNumber not in (select distinct s.StoreIdentifier from stores s where s.chainid=p.chainid )




update datatrue_edi.dbo.Promotions set SupplierIdentifier = 
(select UniqueEDIName from Suppliers where SupplierID=ltrim(rtrim(datatrue_edi.dbo.Promotions.SupplierId)))
where SupplierIdentifier is null
and loadstatus = 0

update c set  c.PDIParticipant = p.PDIParticipant
from datatrue_edi.dbo.Promotions c
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on c.supplierid = p.supplierid
and c.chainid=p.chainid
where loadStatus = 0





update p set p.dtbanner= e.custom1
from datatrue_edi.dbo.promotions p
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(p.StoreDuns))=LTRIM(rtrim(e.CorporateIdentifier))
and e.EdiName=p.SupplierIdentifier
and p.dtbanner is null
and p.StoreDuns is not null
and p.StoreDuns<>''
where loadStatus = 0


update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.promotions c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreName))=LTRIM(rtrim(e.CorporateName))
and e.EdiName=c.SupplierIdentifier
and c.dtbanner is null
and c.StoreName is not null
and c.StoreName<>''
and (c.StoreDuns is  null or c.StoreDuns='')
--and c.datetimecreated>='10-01-2013'
and c.loadStatus=0

update c set c.dtbanner= e.custom1
from datatrue_edi.dbo.promotions c 
join  [DataTrue_EDI].[dbo].[EDI_SupplierCrossReference_byCorp]e
on LTRIM(rtrim(c.StoreName))=LTRIM(rtrim(e.CorporateName))
and DataTrueSupplierID=supplierid
and c.dtbanner is null
and e.custom1 is not null
and c.StoreName is not null 
and c.StoreName<>''
and c.loadStatus=0

 update c 
 set dtstorecontexttypeid = 4
 --select SkipPopulating879_889Records,*
 from datatrue_edi.dbo.promotions c
 inner join suppliers s
 on c.supplierid=s.supplierid 
 where Loadstatus = 0 
 and IsRegulated=1
 and LTRIM(rtrim(RecordSource)) <>'Tmppdi'
 and StoreNumber is null

update c set dtstorecontexttypeid = 3
from datatrue_edi.dbo.Promotions c 
where PDIParticipant=1
 and loadStatus = 0
 and dtstorecontexttypeid is null
 

update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	
                                 when 'COSTZONE' then 3
                                 when 'STORESETUP' then 4
                                 else null end)
from datatrue_edi.dbo.Promotions c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=SupplierIdentifier
and c.ChainId=m.chainid
and bannername =dtbanner
and c.supplierid=m.supplierid
and bannername is not null
and dtstorecontexttypeid is null and loadStatus = 0
and (StoreNumber is null or StoreNumber ='')

update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	
                                 when 'COSTZONE' then 3
                                 when 'STORESETUP' then 4
                                 else null end)
--select c.StoreIdentifier 
from datatrue_edi.dbo.Promotions c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=SupplierIdentifier
and c.ChainId=m.chainid
and c.supplierid=m.supplierid
and bannername is null
and dtstorecontexttypeid is null and loadStatus = 0
and (StoreNumber is null or StoreNumber ='')

   
  
 update datatrue_edi.dbo.promotions set ProductIdentifier = ''
where loadstatus = 0
and ProductIdentifier is  null

select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant not in (0,1)

if @@ROWCOUNT >0

insert @badrecords1
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant not in (0,1)

if @@ROWCOUNT >0
set @errMessage1+='Not identified PDIParticipant' +CHAR(13)+CHAR(10)

 select *
from datatrue_edi.dbo.Promotions c
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on c.supplierid = p.supplierid
and c.chainid=p.chainid
and loadStatus = 0
and (c.PDIParticipant <>p.PDIParticipant or c.PDIParticipant is null)

if @@ROWCOUNT >0

insert @badrecords1
select RecordID 
from datatrue_edi.dbo.Promotions c
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on c.supplierid = p.supplierid
and c.chainid=p.chainid
and loadStatus = 0
and (c.PDIParticipant <>p.PDIParticipant or c.PDIParticipant is null)

if @@ROWCOUNT >0
set @errMessage1+='Incorrect Promotion PDIParticipant' +CHAR(13)+CHAR(10)

if @errMessage1 <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecords1)
				delete c where dupe>1
			set @Subject1 ='Incorrect Incorrect Promotion PDIParticipant ' 
			select @badrecids1 += cast(recordid as varchar(13))+ ','
			from @badrecords1
			set @errMessage1+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecids1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@Subject1,@body=@errMessage1				
	
       end  
       


DECLARE @badrecidsCSt varchar(max)=''
DECLARE @SubjectCSt VARCHAR(MAX)=''
DECLARE @errMessageCSt varchar(max)=''
DECLARE @badrecordsCSt table (recordid int)

DECLARE @badrecidsPSt varchar(max)=''
DECLARE @SubjectPSt VARCHAR(MAX)=''
DECLARE @errMessagePSt varchar(max)=''
DECLARE @badrecordsPSt table (recordid int)

select *
from [DataTrue_EDI].[dbo].[Costs] p
where recordstatus =0
and dtstorecontexttypeid=-1


if @@ROWCOUNT >0
begin
insert @badrecordsPSt
	select RecordID 
	from [DataTrue_EDI].[dbo].[Costs] p
where recordstatus =0
and dtstorecontexttypeid=-1

set @errMessageCST+='Invalid Store(s) in Cost Table.' +CHAR(13)+CHAR(10)
end

if @errMessageCST <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsCST)
				delete c where dupe>1
			set @SubjectCST ='Costs Records can not be moved to MR.Invalid Store(s) in Promotion Table.' 
			select @badrecidsCST += cast(recordid as varchar(13))+ ','
			from @badrecordsCST
			set @errMessageCST+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecidsCST
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
			@subject=@SubjectCST,@body=@errMessagePSt				
	
       end       


select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and dtstorecontexttypeid=-1


if @@ROWCOUNT >0
begin
insert @badrecordsPSt
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and dtstorecontexttypeid=-1

set @errMessagePSt+='Invalid Store(s) in Promotion Table.' +CHAR(13)+CHAR(10)
end
 

if @errMessagePSt <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsPST)
				delete c where dupe>1
			set @SubjectPSt ='Promotion Records can not be moved to MR.Invalid Store(s) in Promotion Table.' 
			select @badrecidsPSt += cast(recordid as varchar(13))+ ','
			from @badrecordsPSt
			set @errMessagePSt+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecidsPST
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@SubjectPSt,@body=@errMessagePSt				
	
       end 
   

 
 
 update c 
 set  Approved = 1, approvaldatetime = getdate(), SkipPopulating879_889Records =1
 ----select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.promotions c
 --inner join zztepm_promotions_notin_Membership_0222 z
 --on c.supplierid=z.supplierid 
 --and c.chainid=z.chainid
 inner join suppliers s
 on c.supplierid=s.supplierid
 and IsRegulated=1
 --commented out by charlie 3/2/2015 and (PDIParticipant=1 or IsRegulated=1)
 and loadStatus = 0 



 

 --commented in by charlie and Gilad on 3/2/2015
 update c 
 set Approved = null , SkipPopulating879_889Records =0
 --select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.promotions c
 inner join suppliers s
 on c.supplierid=s.supplierid 
 inner join Memberships m
 on s.SupplierID = m.MemberEntityID
 and c.chainid = m.OrganizationEntityID
 and m.MembershipTypeID = 14
 and Loadstatus = 0 
 and IsRegulated=1
 --and m.OrganizationEntityID is null
 
  update c 
 set  SkipPopulating879_889Records =1
 --select  SkipPopulating879_889Records,*
 from datatrue_edi.dbo.promotions c
 where PDIParticipant = 1
 and Loadstatus = 0 


  update cs 
 set  SyncToRetailer  = 1
 --select SkipPopulating879_889Records,*
 from datatrue_edi.dbo.promotions cs
 inner join Memberships m
 ON m.OrganizationEntityID = cs.chainid
 AND m.MemberEntityID = cs.supplierid
 AND m.MembershipTypeID  in (14)
 --Commented out by charlie and Gilad on 3/2/2015 AND m.MembershipTypeID  in (14,15)
 where LOadStatus = 0 
 

------------************************charlie added below 3/2/2015************************************--

select MaintenanceRequestID
--select requeststatus stat, *
into #tempBadUPCs
from MaintenanceRequests r with (nolock)
where RequestTypeID not in (1,9)
and ltrim(rtrim(isnull(upc12,''))) not in 
(select distinct ltrim(rtrim(identifiervalue)) from ProductIdentifiers where ProductIdentifierTypeID = 2)
and PDIParticipant = 1
and (LEN(bipad) < 1 or Bipad is null)
and LEN(ltrim(rtrim(isnull(upc12,'')))) >= 12
and RequestStatus not in (5, 15, 6, 16, -8, 999,-999,-30,-31)
and CAST(datetimecreated as date) >= '2/1/2015'
--order by stat


--DECLARE @badMRidsMRt varchar(max)=''
--DECLARE @SubjectMRt VARCHAR(MAX)=''
--DECLARE @errMessageMRt varchar(max)=''
--DECLARE @badrecordsMRt table (maintenancerequestid int)

if @@ROWCOUNT >0
	begin
		insert @badrecordsMRt
		select maintenancerequestid from #tempBadUPCs

		set @errMessageMRT+='MaintenanceRequests exist that have UPC values that do not exist for requests not of Type 1.  These requests will be set to a requeststatus of -30 and will need manual review and intervention.' +CHAR(13)+CHAR(10)
	end

if @errMessageMRT <>''
		begin
			with c as (select ROW_NUMBER() over (partition by maintenancerequestid order by maintenancerequestid)dupe from @badrecordsMRt)
				delete c where dupe>1
			set @SubjectMRT ='Invalid UPCs Received' 
			select @badMRidsMRT += cast(maintenancerequestid as varchar(13))+ ','
			from @badrecordsMRT
			set @errMessageMRT+=CHAR(13)+CHAR(10)+'MaintenanceRequestID:'+CHAR(13)+CHAR(10)+@badMRidsMRT
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;charlie.clark@icucsolutions.com',--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
			--exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='charlie.clark@icucsolutions.com',--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
			@subject=@SubjectMRT,@body=@errMessageMRt				

			update r set r.requeststatus = -30
			from MaintenanceRequests r 
			inner join #tempBadUPCs t
			on r.MaintenanceRequestID = t.MaintenanceRequestID

	
       end       

	drop table #tempBadUPCs
------------************************charlie added above 3/2/2015************************************--


IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztepm_costs_notin_Membership_0222') 
                  drop table zztepm_costs_notin_Membership_0222 
                  
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztepm_promotions_notin_Membership_0222') 
                  drop table zztepm_promotions_notin_Membership_0222  

	
END
GO
