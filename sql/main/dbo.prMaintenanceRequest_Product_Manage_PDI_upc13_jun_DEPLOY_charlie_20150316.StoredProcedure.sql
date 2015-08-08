USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Product_Manage_PDI_upc13_jun_DEPLOY_charlie_20150316]    Script Date: 06/25/2015 18:26:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[prMaintenanceRequest_Product_Manage_PDI_upc13_jun_DEPLOY_charlie_20150316]
as

declare @rec cursor
declare @rec2 cursor
declare @rec3 cursor
declare @rec4 cursor
declare @upc nvarchar(50)
declare @productid int
declare @productdescription nvarchar(100)
declare @brandid int
declare @mrupc nvarchar(50)
declare @checkdigit char(1)
declare @lenofupc tinyint
declare @maintenancerequestid int
--declare @addnewproduct smallint=1
declare @itemdescription nvarchar(255)
declare @upc12 nvarchar(50)
declare @upc11 nvarchar(50)
declare @chainid int
declare @addnewproduct bit=1
declare @productfound bit
declare @approved bit
declare @recten cursor
declare @brandname nvarchar(50)
declare @supplierid int
declare @requesttypeid int
declare @requestsource nvarchar(50)


DECLARE @badrecidsP varchar(max)=''
DECLARE @SubjectP VARCHAR(MAX)=''
DECLARE @errMessageP varchar(max)=''
DECLARE @badrecordsP table (recordid int)

DECLARE @badrecidsP1 varchar(max)=''
DECLARE @SubjectP1 VARCHAR(MAX)=''
DECLARE @errMessageP1 varchar(max)=''
DECLARE @badrecordsP1 table (recordid int)
declare @myid int=0
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_find_productid') 
                  drop table  zztemp_find_productid  
                                    
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='temp_MaintenanceRequest_PDI_NO_Prodid') 
                  drop table temp_MaintenanceRequest_PDI_NO_Prodid
                  
/***********mapping between MR and SupplierPackages**************************
1 OwnerPackageIdentifier =PurchPackDescription	
2 OwnerPackageDescription  =VINDescription						   
3 OwnerPackageSizeDescription  =Size
4 OwnerPackageQty  = PurchPackQty     
5 ThisPackageUOMBasis=PurchPackDescription	
6 ThisPackageEACHBasisQty=PurchPackQty
7 AllowReorder=case when SellPkgVINAllowReorder = 'Y' then 1 else 0 end
8 AllowReclaim=case when SellPkgVINAllowReClaim = 'Y' then 1 else 0 end
9 Purchasable= case when SellPkgVINAllowReorder = 'Y' then 1 else 0 end	
10 OwnerTradeItemSizeUOM=PrimarySellablePkgIdentifier
11 OwnerTradeItemSizeQty=PrimarySellablePkgQty
*******************/
               
                  
 update s set s.VIN=m.vin  
  ,s.OwnerPackageIdentifier=case  when (isnull(m.PurchPackDescription,'') <>'') then m.PurchPackDescription --#1
  else s.OwnerPackageIdentifier end
  ,s.OwnerPackageDescription=case  when (isnull(m.VINDescription,'') <>'') then m.VINDescription             --#2
  else s.OwnerPackageDescription end
  ,OwnerPackageSizeDescription=case  when m.Size IS NOT null then m.Size                                     --#3
  else s.OwnerPackageSizeDescription end  
  ,s.OwnerPackageQty=case  when m.PurchPackQty IS NOT null then m.PurchPackQty                               --#4
  else s.OwnerPackageQty end
  ,s.ThisPackageUOMBasis=case  when m.PurchPackDescription IS NOT null then m.PurchPackDescription           --#5
  else s.ThisPackageUOMBasis end
  ,s.ThisPackageEACHBasisQty=case  when m.PurchPackQty IS NOT null then  m.PurchPackQty                      --#6
  else s.ThisPackageEACHBasisQty end
  ,s.OwnerTradeItemSizeUOM=case  when m.PrimarySellablePkgIdentifier IS NOT null                             --#10
   then m.PrimarySellablePkgIdentifier  else s.OwnerTradeItemSizeUOM end
  ,s.OwnerTradeItemSizeQty=case  when m.PrimarySellablePkgQty IS NOT null 
  then m.PrimarySellablePkgQty  else s.OwnerTradeItemSizeQty end                                             --#11
  ,AllowReorder=case when SellPkgVINAllowReorder = 'Y' then 1 when SellPkgVINAllowReorder is null then AllowReorder  else 0 end
  ,AllowReclaim=case when SellPkgVINAllowReClaim = 'Y' then 1 when SellPkgVINAllowReClaim is null then AllowReclaim else 0 end
  ,Purchasable= case when SellPkgVINAllowReorder = 'Y' then 1 when SellPkgVINAllowReorder is null then Purchasable else 0 end	
  
 ----select s.OwnerPackageDescription,m.PurchPackDescription,vindescription,s.OwnerPackageQty,m.PurchPackQty,requeststatus,oldvin,m.vin,s.vin,s.*
 from SupplierPackages s
 inner join MaintenanceRequests m
 on OldVIN=s.vin
 and OwnerEntityID=ChainID
 and s.SupplierID=m.SupplierID
 and PDIParticipant=1
 and requesttypeid=15
 and RequestStatus<>5
                  
                  

update r set  r.OwnerMarketID = z.OwnerMarketID
--select r.CostZoneID, z.CostZoneID, z.*
from MaintenanceRequests r
inner join costzones z
on r.chainid = z.ownerentityid
and r.supplierid = z.supplierid
and ltrim(rtrim(r.CostZoneID)) = ltrim(rtrim(z.CostZoneID))
and r.PDIParticipant = 1
and r.OwnerMarketID is null
and z.OwnerMarketID is not null
and r.CostZoneID is not null
and r.dtstorecontexttypeid=3

update m set 
	m.productid=p.productid
	from dbo.MaintenanceRequests  m
    inner join productidentifiers p
    on LTRIM(rtrim(identifiervalue))=LTRIM(rtrim(upc12))      
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.ProductId <> p.productid
	and ProductIdentifierTypeID = 2
    and  (m.Bipad is  null or m.Bipad ='')
    
    

update c set  c.PDIParticipant = p.PDIParticipant
--select *
from MaintenanceRequests c
inner join PDI_CHAIN_SUPPLIER_RELATIONS p
on c.supplierid = p.supplierid
and c.chainid=p.chainid
where RequestStatus  not in (5,999)
and c.PDIParticipant<> p.PDIParticipant
and (Bipad is  null or Bipad<>'')

update c set  PDIParticipant = PDITradingPartner
--select c.datetimecreated, RequestStatus,*
from MaintenanceRequests c
inner join chains  b
on c.chainid = b.chainid
and PDIParticipant <> PDITradingPartner
and RequestStatus not in (5)
and cast(c.datetimecreated as date) > '1/1/2015'
and Bipad is not null

update m set m.vin=c.vin
from MaintenanceRequests m
inner join DataTrue_EDI..costs c
on m.datatrue_edi_costs_recordid=recordid
where  m.PDIParticipant =1
and (m.Bipad is null or m.Bipad='')
and m.RequestStatus not in (5, 15, 6, 16, -8,-999)
and DATEADD(day, -30, getdate()) < m.SubmitDateTime
and c.VIN is not null and m.VIN is null


update m set m.vin=c.vin
from MaintenanceRequests m
inner join DataTrue_EDI..promotions c
on m.datatrue_edi_promotions_recordid=recordid
where  m.PDIParticipant =1
and (m.Bipad is null or m.Bipad='')
and m.RequestStatus not in (5, 15, 6, 16, -8,-999)
and DATEADD(day, -30, getdate()) < m.SubmitDateTime
and c.VIN is not null and m.VIN is null

update m set m.PurchPackDescription=c.PurchPackDescription
--select*
from MaintenanceRequests m
inner join DataTrue_EDI..costs c
on m.datatrue_edi_costs_recordid=recordid
where  m.PDIParticipant =1
and (m.Bipad is null or m.Bipad='')
and m.RequestStatus not in (5, 15, 6, 16, -8,-999)
and m.RequestTypeID=1
and DATEADD(day, -30, getdate()) < m.SubmitDateTime
and c.PurchPackDescription is not null and m.PurchPackDescription is null

update m set m.PurchPackDescription=c.ProductName
--select*
from MaintenanceRequests m
inner join DataTrue_EDI..costs c
on m.datatrue_edi_costs_recordid=recordid
where  m.PDIParticipant =1
and (m.Bipad is null or m.Bipad='')
and m.RequestStatus not in (5, 15, 6, 16, -8,-999)
and m.RequestTypeID=1
and DATEADD(day, -30, getdate()) < m.SubmitDateTime
and c.PurchPackDescription is  null and m.PurchPackDescription is null






select MaintenanceRequestID into temp_MaintenanceRequest_PDI_NO_Prodid
from dbo.MaintenanceRequests  m   
where  (m.ProductId is null or m.SupplierPackageID is null)
and PDIParticipant= 1 
and (Bipad is  null or Bipad ='')
and RequestStatus not in (5, 15, 6, 16, 999,-8,-311,18)


	
		
update m set upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc)))
--select*
	from dbo.MaintenanceRequests  m
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')
	and PDIParticipant= 1 
	and LEN(LTRIM(rtrim(upc)))>12
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc))) in (select distinct identifiervalue from ProductIdentifiers where ProductIdentifierTypeID = 2)
	or isnull(Approved, -1) <> 0	)
	
	
update m set upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))
 --select*
	from dbo.MaintenanceRequests  m
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
  and (Bipad is  null or Bipad ='')
	and PDIParticipant= 1 
	and isnull(Approved, -1) <> 0	
	and LEN(LTRIM(rtrim(rawproductidentifier)))>12	
	and LEN(LTRIM(rtrim(upc)))<1
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier))) in (select distinct identifiervalue from ProductIdentifiers where ProductIdentifierTypeID = 2)
	or isnull(Approved, -1) <> 0	)
	
	--and (datatrue_edi_costs_recordid in(select distinct Recordid from NOT_updated_Costs)
	--or datatrue_edi_promotions_recordid in (select distinct Recordid from NOT_updated_P  romotions))		
	
update m set upc12= datatrue_edi.dbo.fnParseUPC(upc)
	--select*
	from dbo.MaintenanceRequests  m	
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')
	--and isnull(Approved, -1) <> 0	
	and LEN(LTRIM(rtrim(upc)))<13
	and LEN(LTRIM(rtrim(upc)))>1
	and (datatrue_edi.dbo.fnParseUPC(upc) in (select distinct identifiervalue from ProductIdentifiers where ProductIdentifierTypeID = 2)
	or isnull(Approved, -1) <> 0	)
	
update m set upc12= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))	
--select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))	
	from dbo.MaintenanceRequests  m
    where  RequestStatus not in (5, 15, 6, 16, 999)
    and m.upc12 is null	
	and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')
	and LEN(LTRIM(rtrim(rawproductidentifier)))<13
	and LEN(LTRIM(rtrim(rawproductidentifier)))>1
	and LEN(LTRIM(rtrim(upc)))<1
	and (datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier))) in 
	(select distinct identifiervalue from ProductIdentifiers where ProductIdentifierTypeID = 2)
	or isnull(Approved, -1) <> 0	)
	
	
	update m set m.productid = p.ProductID 
	from dbo.MaintenanceRequests  m
    inner join supplierpackages p 
	on LTRIM(rtrim(m.VIN)) = LTRIM(rtrim(p.VIN)) --where LTRIM(rtrim(identifiervalue)) = @upc12
	and m.SupplierID = p.SupplierID
	and OwnerEntityID = m.ChainID
	and m.ProductId is null
	and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')
	and RequestStatus not in (5, 15, 6, 16, 999)
	--and requesttypeid not in (1,15)
	inner join ProductIdentifiers i
	on ltrim(rtrim(m.upc12)) = LTRIM(rtrim(i.identifiervalue))
	and i.ProductIdentifierTypeID = 2
	and (m.RequestTypeID = 1 or len(ISNULL(UPC12, '')) > 5)

	update m set m.productid = i.ProductID 
	from dbo.MaintenanceRequests  m
	--and requesttypeid not in (1,15)
	inner join ProductIdentifiers i
	on ltrim(rtrim(m.upc12)) = LTRIM(rtrim(i.identifiervalue))
	and i.ProductIdentifierTypeID = 2
	and m.RequestTypeID in (9)
	and m.ProductId is null
	and PDIParticipant= 1 
	and (m.Bipad is  null or m.Bipad ='')
	and RequestStatus not in (5, 15, 6, 16, 999)
	
	update m set m.productid = i.ProductID 
	from dbo.MaintenanceRequests  m
	--and requesttypeid not in (1,15)
	inner join ProductIdentifiers i
	on ltrim(rtrim(m.upc12)) = LTRIM(rtrim(i.identifiervalue))
	and i.ProductIdentifierTypeID = 2
	and m.ProductId is null
	and PDIParticipant= 1 
	and (m.Bipad is  null or m.Bipad ='')
	and RequestStatus not in (5, 15, 6, 16, 999)
	and m.RequestTypeID not in (1,9)
	and len(ISNULL(UPC, '')) > 0	
		
	update m set m.productid = p.ProductID 
	from dbo.MaintenanceRequests  m
    inner join supplierpackages p 
	on LTRIM(rtrim(m.VIN)) = LTRIM(rtrim(p.VIN)) --where LTRIM(rtrim(identifiervalue)) = @upc12
	and m.SupplierID = p.SupplierID
	and OwnerEntityID = m.ChainID
	and m.ProductId is null
	and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')
	and RequestStatus not in (5, 15, 6, 16, 999)
	and m.RequestTypeID not in (1,9)
	and len(ISNULL(UPC, '')) < 1
	
	
	update m set m.SupplierPackageID = p.SupplierPackageID
	from dbo.MaintenanceRequests  m
    inner join supplierpackages p 
	on LTRIM(rtrim(m.VIN)) = LTRIM(rtrim(p.VIN)) --where LTRIM(rtrim(identifiervalue)) = @upc12
	and m.SupplierID = p.SupplierID
	and OwnerEntityID = m.ChainID
	and m.SupplierPackageID is null
	and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')
	and RequestStatus not in (5, 15, 6, 16, 999,-8)
	and m.productid=p.productid
	
	
--update m set 
--	m.productid=p.productid,
--	dtproductdescription =description	
--	--select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(upc))),m.productid,p.productid,	dtproductdescription ,description
--	from dbo.MaintenanceRequests  m
--    inner join productidentifiers p
--    on LTRIM(rtrim(identifiervalue))=LTRIM(rtrim(upc12))      
--    inner join Products r
--    on p.ProductId=r.productid
--    where  RequestStatus not in (5, 15, 6, 16, 999)
--    and m.ProductId is null	
--	and PDIParticipant= 1 
--	and (m.Bipad is  null or m.Bipad ='')
--	--and isnull(Approved, -1) <> 0	
--	and ProductIdentifierTypeID = 2
	
				
	
		
	update m set 	
	dtproductdescription =description
	--select*	
	from dbo.MaintenanceRequests  m 	        
    inner join Products r
    on m.ProductId=r.productid
    where   dtproductdescription is  null	
    and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')
	
	update m set upc12=IdentifierValue
	from dbo.MaintenanceRequests  m
    inner join productidentifiers p 
	on 	m.ProductId =p.ProductID
	and PDIParticipant= 1 
	and upc12 is null 
	and (m.Bipad is  null or m.Bipad ='') 
	and RequestStatus not in (5, 15, 6, 16, 999,-8)
	and ProductIdentifierTypeID = 2
	
	
	update m set upc= upc12	
--select requeststatus,upc,upc12
	from dbo.MaintenanceRequests  m
    where   upc12 is not null	
	and LEN(LTRIM(rtrim(upc12)))>1
	and LEN(LTRIM(rtrim(upc)))<1
	and PDIParticipant= 1 
	and (Bipad is  null or Bipad ='')



Declare @SizeDescription nvarchar(50)
Declare @SellPkgVINAllowReorder nvarchar(50)
Declare @SellPkgVINAllowReclaim  nvarchar(50)
Declare @PrimarySellablePkgIdentifier nvarchar(50)
Declare @VIN nvarchar(50)
Declare @VINDescription nvarchar(50)
Declare @PurchPackDescription nvarchar(50)
Declare @PurchPackQty nvarchar(50)
Declare @AltSellPackage1 nvarchar(50)
Declare @AltSellPackage1Qty nvarchar(50)
Declare @AltSellPackage1UPC nvarchar(50)
Declare @AltSellPackage1Retail nvarchar(50)
declare @count int
declare @productcategoryid int
DECLARE @ownergrouplevelid nvarchar(50)
declare @owneritemgroupid nvarchar(50)
declare @supplierpackageid int
declare @manfactid int
declare @manfactname nvarchar(255)
declare @PrimarySellablePkg nvarchar(50)
declare @PrimarySellablePkgQty nvarchar(50)
declare @CountOfBrandAssignments int
declare @CountOfCategoryAssignments int

set @rec2 = CURSOR local fast_forward FOR
	select maintenancerequestid, LTRIM(rtrim(upc12)), LTRIM(rtrim(ItemDescription)) , Chainid, approved--, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource, Size, SellPkgVINAllowReorder, SellPkgVINAllowReclaim, 
	PrimarySellablePkgIdentifier, ltrim(rtrim(VIN)), VINDescription, ltrim(rtrim(PurchPackDescription)), PurchPackQty, AltSellPackage1
	,AltSellPackage1Qty, AltSellPackage1UPC, AltSellPackage1Retail, ProductCategoryId
	,PrimaryGroupLevel, ItemGroup, ManufacturerIdentifier, PrimarySellablePkgIdentifier, PrimarySellablePkgQty
	--into import.dbo.tmpMaintenanceRequestRecordsThatGotWrongProductIDs_20111231
	--select *
	from dbo.MaintenanceRequests
	where RequestStatus  not in (5, 15, 6, 16, 999,-8)
	and ProductId is null	
	and (LEN(LTRIM(rtrim(upc12)))> = 12 and VIN is NOT null)
	and PDIParticipant=1
	and (Bipad is  null or Bipad ='')
	and Approved=1
	and RequestTypeID in (1,15)
	and datetimecreated >'11-01-2013'	
	order by requesttypeid


	
	
open @rec2

fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, 
@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
@AltSellPackage1UPC,@AltSellPackage1Retail,@productcategoryid
,@ownergrouplevelid, @owneritemgroupid, @manfactname, @PrimarySellablePkg, @PrimarySellablePkgQty

while @@FETCH_STATUS = 0
	begin
	        if LEN(LTRIM(rtrim(@itemdescription)))<1
			set @itemdescription=@upc12
			
			set @productid = null
			set @productfound = 0
			set @upc = @upc12
			
			--select @productid = productid from supplierpackages --select @productid = productid from ProductIdentifiers 
			--where LTRIM(rtrim(VIN)) = @VIN --where LTRIM(rtrim(identifiervalue)) = @upc12
			--and SupplierID = @supplierID --and ProductIdentifierTypeID = 2
			--and OwnerEntityID = @chainid
			
			
			--if @@ROWCOUNT <1
			
				
				begin
				select @productid = productid from ProductIdentifiers 
				where LTRIM(rtrim(identifiervalue)) = @upc12
				and ProductIdentifierTypeID = 2
				
					if @@ROWCOUNT < 1
					begin
					
										
								INSERT INTO [dbo].[Products]
								   ([ProductName]
								   ,[Description]
								   ,[ActiveStartDate]
								   ,[ActiveLastDate]
								   ,[LastUpdateUserID])
								VALUES
								   (@itemdescription
								   ,@itemdescription
								   ,GETDATE()
								   ,'12/31/2025'
								   ,2)

								set @productid = Scope_Identity()							
																	   
							end
							
					
							else
							begin
							select @itemdescription = description from products
							where productid=@productid
							
							end
					
					end
					
		update MaintenanceRequests set Productid = @productid, upc = @upc12, 
				 dtproductdescription = @itemdescription								
				where MaintenanceRequestID = @maintenancerequestid		
												
		fetch next from @rec2 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, 
			@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
			@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
			@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
			@AltSellPackage1UPC,@AltSellPackage1Retail,@productcategoryid
			,@ownergrouplevelid, @owneritemgroupid, @manfactname,@PrimarySellablePkg,@PrimarySellablePkgQty
	end
	
close @rec2
deallocate @rec2



set @rec3 = CURSOR local fast_forward FOR
	select m.maintenancerequestid, LTRIM(rtrim(upc12)), LTRIM(rtrim(ItemDescription)) , Chainid, approved, productid
	,RequestTypeID, ltrim(rtrim(BrandIdentifier)), SupplierID, requestsource, Size, SellPkgVINAllowReorder, SellPkgVINAllowReclaim, 
	PrimarySellablePkgIdentifier, ltrim(rtrim(VIN)), VINDescription, ltrim(rtrim(PurchPackDescription)), PurchPackQty, AltSellPackage1
	,AltSellPackage1Qty, AltSellPackage1UPC, AltSellPackage1Retail, ProductCategoryId
	,PrimaryGroupLevel, ItemGroup, ManufacturerIdentifier, PrimarySellablePkgIdentifier, PrimarySellablePkgQty
		--select *
	from dbo.MaintenanceRequests m
	inner join temp_MaintenanceRequest_PDI_NO_Prodid t
	on m.maintenancerequestid=t.MaintenanceRequestID	
	and m.Approved=1 
	and m.productid is not null
	and m.RequestTypeID in (1,15)
	order by requesttypeid


	
	
open @rec3

fetch next from @rec3 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved,@productid, 
@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
@AltSellPackage1UPC,@AltSellPackage1Retail,@productcategoryid
,@ownergrouplevelid, @owneritemgroupid, @manfactname, @PrimarySellablePkg, @PrimarySellablePkgQty

while @@FETCH_STATUS = 0
	begin
	
		
								set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ChainProductFactors]
								where ChainID = @chainid
								and ProductID = @productid
								
								If @count < 1 and @productid is not null
									begin
								
										INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
										   ([ChainID]
										   ,[ProductID]
										   ,[BrandID]
										   ,[BaseUnitsCalculationPerNoOfweeks]
										   ,[CostFromRetailPercent]
										   ,[BillingRuleID]
										   ,[ActiveStartDate]
										   ,[ActiveEndDate]
										   ,[LastUpdateUserID])
										SELECT @chainid
											  ,@productid
											  ,0 --@brandid
											  ,[BaseUnitsCalculationPerNoOfweeks]
											  ,[CostFromRetailPercent]
											  ,[BillingRuleID]
											  ,[ActiveStartDate]
											  ,[ActiveEndDate]
											  ,2
										  FROM [DataTrue_Main].[dbo].[ChainProductFactors]
										  where 1 = 1
										  and ChainID = @chainid
										  and productid = 0
									end

								set @count = 0
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[ProductIdentifiers]
								where IdentifierValue = @upc12
								and ProductIdentifierTypeID = 2
								
								If @count < 1and @productid is not null
									begin
								  
										INSERT INTO [dbo].[ProductIdentifiers]
										   ([ProductID]
										   ,[ProductIdentifierTypeID]
										   ,[OwnerEntityId]
										   ,[IdentifierValue]
										   ,[LastUpdateUserID])
										VALUES
										   (@productid
										   ,2 --UPC is type 2
										   ,0 -- 0 is default entity
										   ,@UPC12
										   ,0)
									end


				

								set @count = 0
								set @supplierpackageid = null
								
								select @count= count(*)
								from [DataTrue_Main].[dbo].[SupplierPackages]
								where ltrim(rtrim(VIN)) = @VIN
								--Commented Out 20141204 since allowed duplicate ProductID/VIN supplierpackages records and OwnerPackageIdentifier = @PurchPackDescription
								and OwnerEntityId = @chainid
								and ProductID = @productid
								
								If @count < 1  and @PurchPackDescription is not null 
								and @VIN is not null
									begin	
																											   
										INSERT INTO [DataTrue_Main].[dbo].[SupplierPackages]
												   ([SupplierPackageTypeID]
												   ,[SupplierID]
												   ,[OwnerEntityID]
												   ,[OwnerPackageIdentifier]
												   ,[OwnerPackageDescription]
												   ,[OwnerPackageSizeDescription]
												   ,[OwnerPackageQty]
												   ,[VIN]
												   ,[ProductID]
												   ,[ThisPackageUOMBasis]
												   ,[ThisPackageUOMBasisQty]
												   ,[ThisPackageEACHBasisQty]
												   ,[AllowReorder]
												   ,[AllowReclaim]
												   ,[Purchasable]
												   ,[Sellable]
												   ,[OwnerTradeItemSizeUOM]
												   ,[OwnerTradeItemSizeQty])
										VALUES (1
											  ,@SupplierID
											  ,@chainid
											  ,@PurchPackDescription
											  ,@VINDescription
											  ,@SizeDescription
											  ,@PurchPackQty      
											  ,@VIN
											  ,@ProductID
											  ,@PurchPackDescription
											  ,1
											  ,@PurchPackQty
											  ,case when @SellPkgVINAllowReorder = 'Y' then 1 else 0 end
											  ,case when @SellPkgVINAllowReClaim = 'Y' then 1 else 0 end
											  ,case when @SellPkgVINAllowReorder = 'Y' then 1 else 0 end
											  ,case when @PurchPackDescription = @PrimarySellablePkg then 1 else 0 end
											  ,@PrimarySellablePkg
											  ,@PrimarySellablePkgQty)
											  
										set @supplierpackageid = SCOPE_IDENTITY()
								
										if @supplierpackageid is not null
											begin		
												update MaintenanceRequests set SupplierPackageID = @supplierpackageid
												where MaintenanceRequestID = @maintenancerequestid		
												--alter table MaintenanceRequests add SupplierPackageID INT  
											end
									
									end							  

								If @PurchPackDescription <> @PrimarySellablePkg AND @PrimarySellablePkg IS NOT NULL
									begin
										set @count = 0
										
										select @count= count(*)
										from [DataTrue_Main].[dbo].[SupplierPackages]
										where ltrim(rtrim(OwnerPackageIdentifier)) = @PrimarySellablePkg
										and OwnerEntityId = @chainid
										and ProductID = @productid
										
										If @count < 1  
											begin	
																													   
												INSERT INTO [DataTrue_Main].[dbo].[SupplierPackages]
														   ([SupplierPackageTypeID]
														   ,[SupplierID]
														   ,[OwnerEntityID]
														   ,[OwnerPackageIdentifier]
														   ,[OwnerPackageDescription]
														   ,[OwnerPackageSizeDescription]
														   ,[OwnerPackageQty]
														   ,[VIN]
														   ,[ProductID]
														   ,[ThisPackageUOMBasis]
														   ,[ThisPackageUOMBasisQty]
														   ,[ThisPackageEACHBasisQty]
														   ,[AllowReorder]
														   ,[AllowReclaim]
														   ,[Purchasable]
														   ,[Sellable]
														   ,[OwnerTradeItemSizeUOM]
														   ,[OwnerTradeItemSizeQty])
												VALUES (1
													  ,@SupplierID
													  ,@chainid
													  ,@PrimarySellablePkg --@PurchPackDescription
													  ,@ItemDescription --@VINDescription
													  ,@SizeDescription
													  ,@PrimarySellablePkgQty --@PurchPackQty      
													  ,@VIN
													  ,@ProductID
													  ,@PrimarySellablePkg --@PurchPackDescription
													  ,1
													  ,@PrimarySellablePkgQty --@PurchPackQty
													  ,0 --case when @SellPkgVINAllowReorder = 'Y' then 1 else 0 end
													  ,0 --case when @SellPkgVINAllowReClaim = 'Y' then 1 else 0 end
													  ,case when @PurchPackDescription = @PrimarySellablePkg then 1 else 0 end --case when @SellPkgVINAllowReorder = 'Y' then 1 else 0 end
													  ,1
													  ,@PrimarySellablePkg
													  ,@PrimarySellablePkgQty)
													  
											
											end							  
									end


								select @CountOfBrandAssignments = COUNT(*)
								--select top 100 *
								from ProductBrandAssignments
								where CustomOwnerEntityID = @chainid
								and ProductID = @ProductID
								   
						        --@brandname is not null 
						

										
								if @CountOfBrandAssignments < 1
								  begin
								  
								  If @manfactname is null
									begin
										set @manfactname = 'DEFAULT'
									end
									
									set @manfactid = null
									
									select @manfactid = ManufacturerID
									from Manufacturers
									where OwnerEntityID = @chainid
									and OwnerManufacturerIdentifier = @manfactname
				
									if @@ROWCOUNT < 1
										begin
										
											INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
												   ([EntityTypeID]
												   ,[DateTimeCreated]
												   ,[LastUpdateUserID]
												   ,[DateTimeLastUpdate])
											 VALUES
												   (11 --<EntityTypeID, int,>
												   ,GETDATE() --<DateTimeCreated, datetime,>
												   ,0 --<LastUpdateUserID, int,>
												   ,GETDATE()) --<DateTimeLastUpdate, datetime,>

											set @manfactid = SCOPE_IDENTITY()
									
									
									INSERT INTO [DataTrue_Main].[dbo].[Manufacturers]
										   ([ManufacturerID]
										   ,[ManufacturerName]
										   ,[ManufacturerIdentifier]
										   ,[ActiveStartDate]
										   ,[ActiveLastDate]
										   ,[Comments]
										   ,[DateTimeCreated]
										   ,[LastUpdateUserID]
										   ,[DateTimeLastUpdate]
										   ,[OwnerEntityID]
										   ,[OwnerManufacturerIdentifier])
									 VALUES
										   (@manfactid --<ManufacturerID, int,>
										   ,@manfactname --<ManufacturerName, nvarchar(100),>
										   ,@manfactname --<ManufacturerIdentifier, nvarchar(50),>
										   ,'1/1/2013' --<ActiveStartDate, smalldatetime,>
										   ,'12/31/2025' --<ActiveLastDate, smalldatetime,>
										   ,'' --<Comments, nvarchar(500),>
										   ,GETDATE() --<DateTimeCreated, datetime,>
										   ,0 --<LastUpdateUserID, nvarchar(50),>
										   ,GETDATE() --<DateTimeLastUpdate, datetime,>
										   ,@chainid --<OwnerEntityID, int,>
										   ,@manfactname) --<OwnerManufacturerIdentifier, nvarchar(50),>)


								
								end

									If @brandname is null
										begin
											set @brandname = 'DEFAULT'
										end
							
									set @brandid = null
									
									select @brandid = brandid
									--select *
									from Brands
									where LTRIM(rtrim(OwnerBrandIdentifier)) = @brandname
									and Ownerentityid = @chainid
									and ManufacturerID = @manfactid
									
									if @@ROWCOUNT < 1 and @brandname is not null and @manfactid is not null
										begin

											INSERT INTO [DataTrue_Main].[dbo].[Brands]
													   ([ManufacturerID]
													   ,[BrandName]
													   ,[BrandIdentifier]
													   ,[BrandDescription]
													   ,[OwnerEntityID]
													   ,[OwnerBrandIdentifier])
											Values (@manfactid, @brandname, @brandname, '', @chainid, @brandname)
											
											set @brandid = SCOPE_IDENTITY()
										end	
									

									
				           
							 set @count = 0
							
							select @count= count(*)
							from [DataTrue_Main].[dbo].[ProductBrandAssignments]
							where BrandID = @brandid
							and ProductId = @productid
							and CustomOwnerEntityID = @chainid
							
							If @count < 1 and @brandid is not null 
								begin	
								 
									 INSERT INTO [dbo].[ProductBrandAssignments]
											   ([BrandID]
											   ,[ProductID]
											   ,[CustomOwnerEntityID]
											   ,[LastUpdateUserID])
										 VALUES
											   (isnull(@brandid, 0)
											   ,@productid
											   ,@chainid
											   ,2)
								end	

								end  


	

										select @CountOfCategoryAssignments = COUNT(*)
										--select top 100 *
										from ProductCategoryAssignments
										where CustomOwnerEntityID = @chainid
										and ProductID = @ProductID
										
										if @CountOfCategoryAssignments < 1
										begin
											
											set @count=0
											
											If @productcategoryid is not null and @owneritemgroupid is not null
												begin
													select @count= count(*)
													--select *
													from [DataTrue_Main].[dbo].[ProductCategoryAssignments]
													where ProductCategoryID = @productcategoryid
													and ProductId = @productid
													and CustomOwnerEntityID = @chainid
												end
											Else
												begin
													set @ownergrouplevelid = '3'
													set @owneritemgroupid = 'DEFAULT'
													set @productcategoryid = null
													
													select @productcategoryid = ProductCategoryID
													from [ProductCategories] 
													where [OwnerEntityID] = @chainid
													and OwnerGroupLevelID = @ownergrouplevelid
													and OwnerGroupID = @owneritemgroupid
													
													select @count= count(*)
													--select *
													from [DataTrue_Main].[dbo].[ProductCategoryAssignments]
													where ProductCategoryID = @productcategoryid
													and ProductId = @productid
													and CustomOwnerEntityID = @chainid
												
												end

											
											If @count < 1 --and  @productcategoryid is not null
												begin	
												
													if @productcategoryid is null
														begin
														--select * from productcategories
															insert productcategories
															(ProductCategoryName, ProductCategoryDescription, ChainID, OwnerEntityID,
															DateTimeCreated, LastUpdateUserID, DateTimeLastUpdate, OwnerGroupLevelID,
															OwnerGroupID)
															values(@owneritemgroupid,@owneritemgroupid,@chainid,@chainid,
															getdate(), @myid, GETDATE(), @ownergrouplevelid, @owneritemgroupid)
															
															set @productcategoryid = SCOPE_IDENTITY()
														end
												
													--select @productcategoryid = ProductCategoryID
													--from [ProductCategories] 
													--where [OwnerEntityID] = @chainid
													--and OwnerGroupLevelID = @ownergrouplevelid
													--and OwnerGroupID = @owneritemgroupid
												
												--select * from [ProductCategories] where [OwnerEntityID] = 59973
												 --select * from [ProductCategoryAssignments] where [CustomOwnerEntityID] = 59973
													 INSERT INTO [dbo].[ProductCategoryAssignments]
															   ([ProductCategoryID]
															   ,[ProductID]
															   ,[CustomOwnerEntityID]
															   ,[LastUpdateUserID])
														 VALUES
															   (isnull(@productcategoryid, 0)
															   ,@productid
															   ,@chainid
															   ,2)
												end										
									end
							   update MaintenanceRequests set 
								PurchPackDescription = @PurchPackDescription, RequestStatus = 18
								where MaintenanceRequestID = @maintenancerequestid		
												
		fetch next from @rec3 into @maintenancerequestid, @upc12, @itemdescription, @chainid, @approved, @productid,
			@requesttypeid, @brandname, @supplierid, @requestsource, @SizeDescription,@SellPkgVINAllowReorder, 
			@SellPkgVINAllowReclaim,@PrimarySellablePkgIdentifier,@VIN,@VINDescription,
			@PurchPackDescription,@PurchPackQty,@AltSellPackage1,@AltSellPackage1Qty,
			@AltSellPackage1UPC,@AltSellPackage1Retail,@productcategoryid
			,@ownergrouplevelid, @owneritemgroupid, @manfactname,@PrimarySellablePkg,@PrimarySellablePkgQty
	end
--****************************************************************************************************	
close @rec3
deallocate @rec3
drop table temp_MaintenanceRequest_PDI_NO_Prodid



select *
from MaintenanceRequests p
where  PDIParticipant =1
and (( VIN is null and requesttypeid<>9) 
or (PurchPackDescription is null and RequestTypeID=1))
and (Bipad is null or Bipad='')
and RequestStatus not in (5, 15, 6, 16, -8,999,-999,-30,-31)
and DATEADD(day, -30, getdate()) < SubmitDateTime
	

if @@ROWCOUNT >0
begin
set @errMessageP+='VIN or PurchPackDescription are null.' +CHAR(13)+CHAR(10)

insert @badrecordsP
select MaintenanceRequestID from MaintenanceRequests p
where  PDIParticipant =1
and ( ( VIN is null and requesttypeid<>9) 
or (PurchPackDescription is null and RequestTypeID=1))
and (Bipad is null or Bipad='')
and RequestStatus not in (5, 15, 6, 16, -8,999,-999,-30,-31)
and DATEADD(day, -30, getdate()) < SubmitDateTime

end



if @errMessageP <>''
		begin;
			with c as (select ROW_NUMBER() over (partition by recordid order by recordid)dupe from @badrecordsP)
				delete c where dupe>1
			set @SubjectP =' VIN or PurchPackDescription are null ' 
			select @badrecidsP += cast(recordid as varchar(13))+ ','
			from @badrecordsP
			set @errMessageP+=CHAR(13)+CHAR(10)+'Error came from prMaintenanceRequest_Product_Manage_PDI_upc13_jun. '+CHAR(13)+CHAR(10)+'Record ID:'+CHAR(13)+CHAR(10)+@badrecidsP
			exec msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients='irina.trush@icucsolutions.com'--;gilad.keren@icucsolutions.com;charlie.clark@icucsolutions.com'
			,
				@subject=@SubjectP,@body=@errMessageP				
	
       end  
       
       
       update m set m.upc= LTRIM(rtrim(isnull(m.rawproductidentifier,'')))	
--select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier))),upc,submitdatetime	
	from dbo.MaintenanceRequests  m
	where  RequestStatus not in (5, 15, 6, 16)
    and LEN(LTRIM(rtrim(rawproductidentifier)))>1 
    and rawproductidentifier is not null
	and LEN(LTRIM(rtrim(upc)))<1
	
	update m set m.rawproductidentifier= datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(m.upc)))	
--select datatrue_edi.dbo.fnParseUPC(LTRIM(rtrim(rawproductidentifier)))	
	from dbo.MaintenanceRequests  m
	where  RequestStatus not in (5, 15, 6, 16)
    and(LEN(LTRIM(rtrim(rawproductidentifier)))<1 or rawproductidentifier is null)
	and LEN(LTRIM(rtrim(upc)))>1
	and SubmitDateTime>GETDATE()-15
	
	update m set RequestStatus=-31,Approved=0,DenialReason='Record can not be processed.UPC is not provided.'
	--select distinct banner,supplierid,upc,	RawProductIdentifier,requeststatus,DenialReason,approved,Bipad
	from dbo.MaintenanceRequests  m
	where   LEN(LTRIM(rtrim(upc)))<2
	and  (RawProductIdentifier is null or RawProductIdentifier ='')
	and (RequestTypeID in (1,9)or PDIParticipant=0)
	and RequestStatus<>-31
	
	--update m set RequestStatus=-31,Approved=-0,DenialReason='Record can not be processed.UPC is not provided.'
	select distinct banner,m.supplierid,upc12,s.productid,m.productid,chainid,m.vin,requeststatus,DenialReason,approved--,Bipad
	--update m set m.productid=s.ProductID,upc12=IdentifierValue,upc=IdentifierValue
	from dbo.MaintenanceRequests  m
	inner join SupplierPackages s
	on rtrim(ltrim(m.VIN))=rtrim(ltrim(s.vin))
	and m.ChainID=s.OwnerEntityID
	and m.SupplierID=s.supplierid	
	inner join ProductIdentifiers p
	on s.productid=p.productid
	and p.ProductIdentifierTypeID=2
	where   LEN(LTRIM(rtrim(isnull(upc12,''))))<2
	and (RequestTypeID not in (1,9) and  PDIParticipant=1 )
	and m.VIN is not null 
	and (m.Bipad is null or m.Bipad='')
	
	order by m.vin
	
	
	
	select MAX(s.productid) productid ,s.vin,chainid,m.supplierid  into zztemp_find_productid
	--,upc12,s.productid,m.productid,chainid,m.vin,requeststatus,DenialReason,approved--,Bipad
	--update m set m.productid=s.ProductID,upc12=IdentifierValue,upc=IdentifierValue
	from dbo.MaintenanceRequests  m
	inner join SupplierPackages s
	on rtrim(ltrim(m.VIN))=rtrim(ltrim(s.vin))
	and m.ChainID=s.OwnerEntityID
	and m.SupplierID=s.supplierid	
	inner join ProductIdentifiers p
	on s.productid=p.productid
	and p.ProductIdentifierTypeID=2
	where   LEN(LTRIM(rtrim(isnull(upc12,''))))<2
	and (RequestTypeID not in (1,9) and  PDIParticipant=1 )
	and m.VIN is not null 
	and (m.Bipad is null or m.Bipad='')	
	group by s.vin,chainid,m.supplierid 
	
	
	update m set m.productid=s.ProductID,upc12=IdentifierValue,upc=IdentifierValue
	from dbo.MaintenanceRequests  m
	inner join  zztemp_find_productid s
	on rtrim(ltrim(m.VIN))=rtrim(ltrim(s.vin))
	and m.ChainID=s.ChainID
	and m.SupplierID=s.supplierid	
	inner join ProductIdentifiers p
	on s.productid=p.productid
	and p.ProductIdentifierTypeID=2
	where   LEN(LTRIM(rtrim(isnull(upc12,''))))<2
	and (RequestTypeID not in (1,9) and  PDIParticipant=1 )
	and m.VIN is not null 
	and (m.Bipad is null or m.Bipad='')
	
	
	update c set RequestStatus=888
--select filetype,*
from 
MaintenanceRequests c
where 1=1
and isnull(Filetype ,'N') like '%888%'
and productid is not null
and (Bipad is null or bipad ='')
and RequestStatus<>888
and datetimecreated>GETDATE()-45


	
	 
 
update c set RequestStatus=0
--select*
from 
MaintenanceRequests c
where 1=1
and PDIParticipant=1
and RequestTypeID=1
and RequestStatus=18
and productid is not null
and VIN is not null
and (Bipad is null or bipad ='')
and SupplierPackageID is not null

update c set RequestStatus=18
--select*
from 
MaintenanceRequests c
where 1=1
and PDIParticipant=1
and ((RequestTypeID =2 and RequestStatus=0)
 or 
(RequestTypeID =3 and RequestStatus =17))
and productid is not null
and VIN is not null
and (Bipad is null or bipad ='')
--and SupplierPackageID is not null

	
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='zztemp_find_productid') 
                  drop table  zztemp_find_productid  
                                    
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='temp_MaintenanceRequest_PDI_NO_Prodid') 
                  drop table temp_MaintenanceRequest_PDI_NO_Prodid
	
return
GO
