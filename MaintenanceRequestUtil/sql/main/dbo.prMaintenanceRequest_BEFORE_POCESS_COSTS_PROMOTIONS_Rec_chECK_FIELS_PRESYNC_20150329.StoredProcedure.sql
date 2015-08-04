USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_BEFORE_POCESS_COSTS_PROMOTIONS_Rec_chECK_FIELS_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Procedure inserts pre MR records from DataTrue_edi tables for furure reference>
-- =============================================
CREATE PROCEDURE [dbo].[prMaintenanceRequest_BEFORE_POCESS_COSTS_PROMOTIONS_Rec_chECK_FIELS_PRESYNC_20150329]
	
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
 
 /*********************** all costs updates***********************************/
 
 
 update datatrue_edi.dbo.Costs set recordsource = 'TMP'
 --select * from datatrue_edi.dbo.Costs
 where RecordStatus = 0 --and recordsource is null
 and right(ltrim(rtrim(filename)),4)='xlsx'
 
 update datatrue_edi.dbo.Costs set recordsource =  'EDI'  
where RecordStatus = 0 and recordsource is null

update c set c.recordstatus = 20
from datatrue_edi.dbo.Costs c
where partneridentifier = 'BIM'
--and dtSupplierid = 40557
and (charindex('Farm Fresh', Storename)>0 or charindex('Farm Fresh', dtbanner)>0)
and ISNULL(requesttypeid, 0) <> 8
and recordstatus = 0

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

update c set  c.PDIParticipant = p.PDIParticipant
--select *
from datatrue_edi.dbo.Costs c 
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on dtsupplierid = supplierid
and dtchainid=p.chainid
where RecordStatus = 0
and (Bipad is  null or Bipad<>'')

update datatrue_edi.dbo.Costs set recordsource = 'PDITEMP'
where  RecordStatus = 0
and PDIParticipant=1 and bipad is  null and  right(ltrim(rtrim(filename)),4)='xlsx'

update datatrue_edi.dbo.Costs set recordsource = 'PDIEDI'
where  RecordStatus = 0
and PDIParticipant=1 and bipad is  null and  right(ltrim(rtrim(filename)),4)<>'xlsx'

update c set recordsource = 'TMP', PDIParticipant = PDITradingPartner, Approved = 1
--select recordsource, *
from datatrue_edi.dbo.Costs c
inner join datatrue_main.dbo.chains b
on c.dtchainid = b.chainid
where RecordStatus = 0
and bipad is not null

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




update c set dtstorecontexttypeid = 3
from datatrue_edi.dbo.costs c 
where PDIParticipant=1
and Bipad is null
and dtstorecontexttypeid is null and RecordStatus = 0

update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	when 'COSTZONE' then 3	else null end)
from datatrue_edi.dbo.costs c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=PartnerIdentifier
and c.dtChainId=m.chainid
and c.dtsupplierid=supplierid
and c.StoreIdentifier is null
and Bipad is null
and ltrim(rtrim(m.Bannername)) =ltrim(rtrim(dtbanner))
and dtstorecontexttypeid is null and RecordStatus = 0


update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	when 'COSTZONE' then 3	else null end)
from datatrue_edi.dbo.costs c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=PartnerIdentifier
and c.dtChainId=m.chainid
and c.dtsupplierid=supplierid
and Bipad is null
and c.StoreIdentifier is null
and Bannername is null
and dtstorecontexttypeid is null and RecordStatus = 0




update datatrue_edi.dbo.costs set PriceChangeCode = 
case 
	when LTRIM(rtrim(RequestTypeID)) in (1,15) then 'A'	
	when LTRIM(rtrim(RequestTypeID)) = 2 then 'B'
	when LTRIM(rtrim(RequestTypeID)) = 20 then 'B'
	when LTRIM(rtrim(RequestTypeID)) = 9 then 'D'
else null
end
where recordstatus = 0
and RequestTypeID is not null
and PriceChangeCode is null


update datatrue_edi.dbo.costs set RequestTypeID = 
case 
	when LTRIM(rtrim(PriceChangeCode)) = 'A' then 1
	when LTRIM(rtrim(PriceChangeCode)) = 'B' then 2 
	when LTRIM(rtrim(PriceChangeCode)) = 'B' then 20
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


 select *
from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and PDIParticipant =1
and ( VIN is null or PurchPackDescription is null)
and (Bipad is null or Bipad='')

if @@ROWCOUNT>0
begin
insert @badrecordsP
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and PDIParticipant =1
and ( VIN is null or PurchPackDescription is null)
and (Bipad is null or Bipad='')
set @errMessageP+='VIN or PurchPackDescription are null ' +CHAR(13)+CHAR(10)


if @errMessageP <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsP)
				delete c where dupe>1
			set @SubjectP ='Cost VIN or PurchPackDescription are null for PDI record ' 
			select @badrecidsP += cast(recordid as varchar(13))+ ','
			from @badrecordsP
			set @errMessageP+=CHAR(13)+CHAR(10)+'Message sent from SP prMaintenanceRequest_BEFORE_POCESS_COSTS_PROMOTIONS_REC_2014fab03'+CHAR(13)+CHAR(10)+'Cost Record ID:'+CHAR(13)+CHAR(10)+@badrecidsP
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@SubjectP,@body=@errMessageP				
	
       end  
       
       end 
       /*************************************    TOPS   *************************************************/    

select *
from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and Banner ='TOP'
if @@ROWCOUNT >0

insert @badrecordsT
	select RecordID from [DataTrue_EDI].[dbo].[costs] p
where recordstatus =0
and Banner ='TOP'
if @@ROWCOUNT >0
set @errMessageT+='TOPS records loaded' +CHAR(13)+CHAR(10)

 

if @errMessageT <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsT)
				delete c where dupe>1
			set @SubjectT ='TOPS records loaded ' 
			select @badrecidsT += cast(recordid as varchar(13))+ ','
			from @badrecordsT
			set @errMessageT+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecidsT
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com;Charlie.Clark@icucsolutions.com;Tatiana.Alperovitch@icucsolutions.com',
				@subject=@SubjectT,@body=@errMessageT				
	   end  


/******************************Promotions update for all ****************************************/
update datatrue_edi.dbo.Promotions set recordsource = 'TMP'
 --select * from datatrue_edi.dbo.Costs
 where Loadstatus = 0 --and recordsource is null
 and right(ltrim(rtrim(filename)),4)='xlsx'
 

update datatrue_edi.dbo.Promotions set recordsource = 'EDI'
where recordsource is null and Loadstatus = 0


update c set c.loadstatus = 20
from datatrue_edi.dbo.Promotions c
where  supplieridentifier = 'BIM'
--and Supplierid = 40557
and (charindex('Farm Fresh', CorporateName)>0 or charindex('Farm Fresh', dtbanner)>0 or charindex('Farm Fresh', StoreName)>0)
and loadstatus = 0


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

update datatrue_edi.dbo.Promotions set recordsource = 'PDITEMP'
where recordsource ='EDI'and Loadstatus = 0
and PDIParticipant=1  and right(ltrim(rtrim(filename)),4)='xlsx'

update datatrue_edi.dbo.Promotions set recordsource = 'PDIEDI'
where recordsource ='EDI'and Loadstatus = 0
and PDIParticipant=1  and right(ltrim(rtrim(filename)),4)<>'xlsx'




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

update c set dtstorecontexttypeid = 3
from datatrue_edi.dbo.Promotions c 
where PDIParticipant=1
 and loadStatus = 0

update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	when 'COSTZONE' then 3	else null end)
from datatrue_edi.dbo.Promotions c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=SupplierIdentifier
and c.ChainId=m.chainid
and bannername =dtbanner
and c.supplierid=m.supplierid
and c.StoreIdentifier is null
and bannername is not null
and dtstorecontexttypeid is null and loadStatus = 0


update c set dtstorecontexttypeid = 
( Case StoreProductContextMethod when 'BANNER' then 2	when 'COSTZONE' then 3	else null end)
--select c.StoreIdentifier 
from datatrue_edi.dbo.Promotions c inner join SupplierStoreProductContextMethod m
on UniqueEDIName=SupplierIdentifier
and c.ChainId=m.chainid
and c.supplierid=m.supplierid
and c.StoreIdentifier is null
and bannername is null
and dtstorecontexttypeid is null and loadStatus = 0


   
  
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

select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and (OwnerMarketID is null )
and dtstorecontexttypeid=3
if @@ROWCOUNT >0
begin
insert @badrecordsP1
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and (OwnerMarketID is null)
and dtstorecontexttypeid=3

set @errMessageP1+='Promotion OwnerMarketID is null ;' +CHAR(13)+CHAR(10)
end

select *
from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and ( VIN is null or PurchPackDescription is null)


if @@ROWCOUNT >0
begin
insert @badrecordsP1
	select RecordID from [DataTrue_EDI].[dbo].[promotions] p
where loadstatus =0
and PDIParticipant =1
and ( VIN is null or PurchPackDescription is null)

set @errMessageP1+=' VIN or PurchPackDescription are null for PDIParticipant' +CHAR(13)+CHAR(10)
end
 

if @errMessageP1 <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsP1)
				delete c where dupe>1
			set @SubjectP1 ='Promotion OwnerMarketID, VIN or PurchPackDescription are null for PDIParticipant' 
			select @badrecidsP1 += cast(recordid as varchar(13))+ ','
			from @badrecordsP1
			set @errMessageP1+=CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecidsP1
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com',--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com',
				@subject=@SubjectP1,@body=@errMessageP1				
	
       end       


	
END
GO
