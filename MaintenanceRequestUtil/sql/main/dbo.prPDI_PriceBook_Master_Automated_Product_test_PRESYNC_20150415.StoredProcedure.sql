USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_Product_test_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPDI_PriceBook_Master_Automated_Product_test_PRESYNC_20150415]
@chainid int,
@supplierid int,
@wipeandreload bit = 1

as

/*
declare @chainid int=65726
declare @supplierid int=73564
declare @chainidentifier nvarchar(50)='TIGER'
declare @supplierIdentifier nvarchar(50)='Hartman'
declare @wipeandreload bit = 0
declare @startdate date = '1/1/2014'
declare @enddate date = '12/31/2099'
76209	65726
74918
76231
76217	75130
--74918	74918
select * from datatrue_edi.dbo.Temp_PDI_VendorS
select * from chains where chainid = 75215
select * from suppliers where supplierid = 76850
and datatruechainid = 74918
and datatruesupplierid = 78648 75377	75130

declare @chainid int = 44285
declare @supplierid int = 77929

*/
-- declare @chainid int = 44285 declare @supplierid int = 77929 declare @wipeandreload bit = 1
--declare @chainid int = 75217 declare @supplierid int = 79174 declare @wipeandreload bit = 1	
--declare @chainid int = 75130 declare @supplierid int = 75394 declare @wipeandreload bit = 1	
--declare @chainid int = 75131 declare @supplierid int = 75405 declare @wipeandreload bit = 0
--declare @chainid int = 75407 declare @supplierid int = 79282 declare @wipeandreload bit = 0
--declare @chainid int = 75217 declare @supplierid int = 79172 declare @wipeandreload bit = 0	
--declare @chainid int = 75130 declare @supplierid int = 76949 declare @wipeandreload bit = 1	
--declare @chainid int = 75130 declare @supplierid int = 75394 declare @wipeandreload bit = 0
--declare @chainid int = 75217 declare @supplierid int = 79416 declare @wipeandreload bit = 1
	
declare @chainidentifier nvarchar(50)
declare @supplierIdentifier nvarchar(50)
declare @mostrecentfiledate date
declare @errormessage nvarchar(4000)
declare @FutureEndDate date = '12/31/2099'

begin try


 
select @chainidentifier = chainidentifier from chains where ChainID = @chainid



select @supplierIdentifier = LTRIM(rtrim(TranslationValueOutside)) 
from [DataTrue_EDI].[dbo].[TranslationMaster] 
where isnumeric(TranslationCriteria1) > 0 
and TranslationTypeID = 26 
and CAST(TranslationCriteria1 as int) = @supplierid
and TranslationChainID = @chainid


--*****************************set recordstatus = 1 for all previous*************************************

if @wipeandreload = 1
	begin

		select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.Temp_PDI_VendorCostZones where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.Temp_PDI_VendorCostZones set recordstatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) <> @mostrecentfiledate
		update datatrue_edi.dbo.Temp_PDI_VendorCostZones set recordstatus = 0 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) = @mostrecentfiledate

		select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations set recordstatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) <> @mostrecentfiledate
		update datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations set recordstatus = 0 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) = @mostrecentfiledate

		select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.Temp_PDI_Costs where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.Temp_PDI_Costs set RecordStatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) <> @mostrecentfiledate
		update datatrue_edi.dbo.Temp_PDI_Costs set RecordStatus = 0 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) = @mostrecentfiledate

		select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.Temp_PDI_ItemGrp where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.Temp_PDI_ItemGrp set recordstatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) <> @mostrecentfiledate
		update datatrue_edi.dbo.Temp_PDI_ItemGrp set recordstatus = 0 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) = @mostrecentfiledate

		select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.Temp_PDI_AltItemGrps where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.Temp_PDI_AltItemGrps set recordstatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) <> @mostrecentfiledate
		update datatrue_edi.dbo.Temp_PDI_AltItemGrps set recordstatus = 0 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) = @mostrecentfiledate

		select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.temp_PDI_ItemPKG where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.temp_PDI_ItemPKG set Recordstatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) <> @mostrecentfiledate
		update datatrue_edi.dbo.temp_PDI_ItemPKG set Recordstatus = 0 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) = @mostrecentfiledate

		select @mostrecentfiledate = MAX(DateTimeCreated) from datatrue_edi.dbo.temp_PDI_UPC where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.temp_PDI_UPC set RecordStatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeCreated as date) <> @mostrecentfiledate

		select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.temp_PDI_Retail where ChainIdentifier = @chainidentifier and CHARINDEX(@supplierIdentifier, FileName) > 0
		update datatrue_edi.dbo.temp_PDI_Retail set RecordStatus = 1 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) <> @mostrecentfiledate
		update datatrue_edi.dbo.temp_PDI_Retail set RecordStatus = 0 where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid and cast(DateTimeReceived as date) = @mostrecentfiledate

	end
	
--***********************************Clear Storesetup and ProductPrices and Supplierpackages*********************************

if @wipeandreload = 1
	begin

		delete
		from storesetup where chainid = @chainid and supplierid = @supplierid

		delete
		from productprices where chainid = @chainid and supplierid = @supplierid

		delete
		from SupplierPackages where ownerentityid = @chainid and supplierid = @supplierid
		
		delete
		from costzonerelations where OwnerEntityID = @chainid and SupplierID = @supplierid
				
		delete
		from costzones where OwnerEntityID = @chainid and SupplierID = @supplierid
	end

--**********************************update datatrue id columns*******************************************

update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].[dbo].[Temp_PDI_AltItemGrps] a                                           
inner join chains c
on LTRIM(rtrim(a.ChainIdentifier)) = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].dbo.Temp_PDI_Costs a                                           
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].dbo.Temp_PDI_ItemGrp a                                         
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].dbo.temp_PDI_ItemPKG a                                           
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].dbo.Temp_PDI_Retail a                                          
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruechainid = c.ChainID 
from  [DataTrue_EDI].dbo.Temp_PDI_UPC a                                        
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].dbo.Temp_PDI_VendorCostZones a                                           
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].dbo.Temp_PDI_Vendors a                                     
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null


update A set a.datatruechainid = c.ChainID
from  [DataTrue_EDI].dbo.Temp_PDI_VendorSiteAuthorizations a                                      
inner join chains c
on replace(LTRIM(rtrim(a.ChainIdentifier)), '_pdi','') = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruestoreid = s.storeid
from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a
inner join stores s
on cast(a.siteid as int) = CAST(s.storeidentifier as int)
and a.datatruechainid = s.chainid 
and a.datatruestoreid is null

update A set a.datatruestoreid = s.storeid
--select *
from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a
inner join stores s
on cast(right(a.siteid, 3) as int) = CAST(s.storeidentifier as int)
and a.datatruechainid = s.chainid 
and a.datatruestoreid is null



declare @RecordID int
declare @VendorName nvarchar(50)
declare @myid int=0



update A set a.datatruesupplierid = cast(TranslationCriteria1 as int)
from  [DataTrue_EDI].dbo.Temp_PDI_AltItemGrps a
inner join  [DataTrue_EDI].[dbo].[TranslationMaster] t
on ltrim(rtrim(a.VendorIdentifier)) = LTRIM(rtrim(TranslationValueOutside))
and t.TranslationChainID = @chainid
and TranslationTypeID = 26
and datatruesupplierid is null

update A set a.datatruesupplierid = cast(TranslationCriteria1 as int)
from  [DataTrue_EDI].dbo.Temp_PDI_Costs a
inner join  [DataTrue_EDI].[dbo].[TranslationMaster] t
on ltrim(rtrim(a.vendorname)) = LTRIM(rtrim(TranslationValueOutside))
and t.TranslationChainID = @chainid
and TranslationTypeID = 26
and datatruesupplierid is null

update A set a.datatruesupplierid = t.datatruesupplierid
from  [DataTrue_EDI].dbo.Temp_PDI_ItemGrp a --where datatruesupplierid is null
inner join  [DataTrue_EDI].dbo.Temp_PDI_Vendors t
on ltrim(rtrim(a.vendorname)) = LTRIM(rtrim(t.vendorname))
and a.datatruesupplierid is null

update p set p.VendorIdentifier = v.VendorIDinPDIFile
from  [DataTrue_EDI].dbo.temp_PDI_ItemPKG p
inner join [DataTrue_EDI].dbo.temp_PDI_Vendors v
on p.VendorName = v.vendorname
and p.chainidentifier = v.chainidentifier
and p.VendorIdentifier is null

update A set a.datatruesupplierid = cast(TranslationCriteria1 as int)
from  [DataTrue_EDI].dbo.temp_PDI_ItemPKG a --where datatruesupplierid is null
inner join  [DataTrue_EDI].[dbo].[TranslationMaster] t
on ltrim(rtrim(a.Vendoridentifier)) = LTRIM(rtrim(TranslationValueOutside))
and t.TranslationChainID = @chainid
and TranslationTypeID = 26
and datatruesupplierid is null

update A set a.datatruesupplierid = v.datatruesupplierid, a.VendorIdentifier = v.VendorIDinPDIFile
from datatrue_edi.dbo.Temp_PDI_Retail a
inner join [DataTrue_EDI].dbo.temp_PDI_Vendors v
on a.VendorName = v.vendorname
and a.chainidentifier = v.chainidentifier 
and a.datatruesupplierid is null
 
update A set a.datatruesupplierid = v.datatruesupplierid, a.VendorIdentifier = v.VendorIDinPDIFile
from datatrue_edi.dbo.Temp_PDI_UPC a
inner join [DataTrue_EDI].dbo.temp_PDI_Vendors v
on a.VendorName = v.vendorname
and a.chainidentifier = v.chainidentifier
and a.datatruesupplierid is null

update A set a.datatruesupplierid = v.datatruesupplierid, a.VendorIdentifier = v.VendorIDinPDIFile
from datatrue_edi.dbo.Temp_PDI_VendorCostZones a
inner join [DataTrue_EDI].dbo.temp_PDI_Vendors v
on a.VendorName = v.vendorname
and a.chainidentifier = v.chainidentifier
and a.datatruesupplierid is null

update A set a.datatruesupplierid = cast(TranslationCriteria1 as int), a.VendorIdentifier = LTRIM(rtrim(TranslationValueOutside))
from datatrue_edi.dbo.Temp_PDI_Vendors a
inner join  [DataTrue_EDI].[dbo].[TranslationMaster] t
on ltrim(rtrim(a.VendorIDinPDIFile)) = LTRIM(rtrim(TranslationValueOutside))
and t.TranslationChainID = @chainid
and TranslationTypeID = 26 
and a.VendorIdentifier is null
and datatruesupplierid is null

update A set a.datatruesupplierid = cast(TranslationCriteria1 as int)
from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a
inner join  [DataTrue_EDI].[dbo].[TranslationMaster] t
on ltrim(rtrim(a.vendorid)) = LTRIM(rtrim(TranslationValueOutside))
and t.TranslationChainID = @chainid
and TranslationTypeID = 26 
and datatruesupplierid is null


--**********************************update PackageCode_Scrubbed *******************************************
update datatrue_edi.dbo.Temp_PDI_ItemPKG
set PackageCode_Scrubbed = Replace(REPLACE(PackageCode,' ',''),'	','')
where 	--RecordStatus = 0 and 
DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
and PackageCode_Scrubbed  is NULL

update datatrue_edi.dbo.Temp_PDI_UPC
set PackageCode_Scrubbed = Replace(REPLACE(PackageCode,' ',''),'	','')
where 	--RecordStatus = 0 and 
DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
and PackageCode_Scrubbed  is NULL


update datatrue_edi.dbo.Temp_PDI_Costs
set PackageCode_Scrubbed = Replace(REPLACE(PackageCode,' ',''),'	','')
where 	--RecordStatus = 0 and 
DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
and PackageCode_Scrubbed  is NULL

update datatrue_edi.dbo.Temp_PDI_Retail
set PackageCode_Scrubbed = Replace(REPLACE(PackageCode,' ',''),'	','')
where 	--RecordStatus = 0 and 
DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
and PackageCode_Scrubbed  is NULL




declare @productid int
declare @productdescription nvarchar(50)
declare @upc nvarchar(50)
declare @pdiitemno nvarchar(50)
declare @ownermarketid nvarchar(50)

--=== Verify if all data exists
declare @count_VendorSiteAuthorizations  int = 0 

select @count_VendorSiteAuthorizations = COUNT(*)
from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations 
where DataTrueChainID = @chainid 
	and DataTrueSupplierID = @supplierid

if not exists 
	(
	select top 1 RecordID from datatrue_edi.dbo.Temp_PDI_VendorCostZones where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	union all select top 1 RecordID from datatrue_edi.dbo.Temp_PDI_Costs where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	union all select top 1 RecordID from datatrue_edi.dbo.Temp_PDI_ItemGrp where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	union all select top 1 RecordID from datatrue_edi.dbo.Temp_PDI_AltItemGrps where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	union all select top 1 RecordID from datatrue_edi.dbo.temp_PDI_ItemPKG where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	union all select top 1 RecordID from datatrue_edi.dbo.temp_PDI_UPC where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	union all select top 1 RecordID from datatrue_edi.dbo.temp_PDI_Retail where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	)
	and @count_VendorSiteAuthorizations > 0
begin
	--If only  datas in Temp_PDI_VendorSiteAuthorizations then  load dummy info  to store setup
	--+CostZone +CostZoneRelation
	
	insert into [DataTrue_Main].[dbo].[CostZones]
			   ([CostZoneName]
			   ,[CostZoneDescription]
			   ,[SupplierId]
			   ,[OwnerEntityID]
			   ,[OwnerMarketID])
	select distinct 
			   @chainidentifier+'/'+@supplierIdentifier --<CostZoneName, nvarchar(50),>
			   ,@chainidentifier+'/'+@supplierIdentifier--<CostZoneDescription, nvarchar(255),>
			   ,@supplierid
			   ,@chainid --<OwnerEntityID, int,>
			   ,ltrim(rtrim(t.CostZoneID)) --<OwnerMarketID, nvarchar(50),>)
	from  datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations t
			left join [DataTrue_Main].[dbo].CostZones  c
				on ltrim(rtrim(t.CostZoneID)) = c.OwnerMarketID
					and t.DataTrueSupplierID = c.SupplierId
					and t.DataTrueChainID = c.OwnerEntityID
	where t.DataTrueChainID = @chainid 
		and t.DataTrueSupplierID = @supplierid
		and c.CostZoneID is Null

	

	insert into [DataTrue_Main].[dbo].[CostZoneRelations]
		   ([StoreID]
		   ,[SupplierID]
		   ,[CostZoneID]
		   ,[OwnerEntityID])
		   
	select  
			t.DataTrueStoreID
		   ,t.DataTrueSupplierID
		   ,c.CostZoneID
		   ,t.DataTrueChainID
	from  datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations t
			inner  join  [DataTrue_Main].[dbo].[CostZones] c
				on ltrim(rtrim(t.CostZoneID)) = c.OwnerMarketID
					and t.DataTrueSupplierID = c.SupplierId
					and t.DataTrueChainID = c.OwnerEntityID		
			left join [DataTrue_Main].[dbo].[CostZoneRelations] cz_r
				on  cz_r.StoreID = t.DataTrueStoreID
					and cz_r.OwnerEntityID = t.DataTrueChainID
					and cz_r.SupplierID = t.DataTrueSupplierID
					and cz_r.CostZoneID = c.CostZoneID
	where t.DataTrueChainID = @chainid 
	and t.DataTrueSupplierID = @supplierid
	--and LTRIM(rtrim(t.costzoneid)) = @ownermarketid
	and t.RecordStatus = 0
	and t.DataTrueStoreID is not null
	and  cz_r.CostZoneRelationID is Null	
	
	---Add Store Setup with ProductID  = 0 for each store
	insert into [DataTrue_Main].[dbo].[StoreSetup]
	   ([ChainID]
	   ,[StoreID]
	   ,[ProductID]
	   ,[SupplierID]
	   ,[BrandID]
	   ,[InventoryRuleID]
	   ,[ActiveStartDate]
	   ,[ActiveLastDate]
	   ,[LastUpdateUserID]
	   ,[PDIParticipant])
	select  distinct 
		cz_r.OwnerEntityID
	   ,cz_r.StoreID
	   ,0--@productid
	   ,cz_r.SupplierID  --<SupplierID, int,>
	   ,0 --<BrandID, int,>
	   ,0 --<InventoryRuleID, int,>
	   ,'1/1/2013' --<ActiveStartDate, datetime,>
	   ,'12/31/2099' --<ActiveLastDate, datetime,>
	   ,0 --<LastUpdateUserID, nvarchar(50),>
	   ,1 --<PDIParticipant, bit,>)
	from CostZoneRelations cz_r
		left join 	[DataTrue_Main].[dbo].[StoreSetup] ss
			on 	cz_r.StoreID  = ss.StoreID
				and cz_r.SupplierID  = ss.SupplierID
				and cz_r.OwnerEntityID  = ss.ChainID
				and 0  = ss.ProductID
	where cz_r.OwnerEntityID =  @chainid 
		and cz_r.SupplierID = @supplierid 
		and ss.StoreSetupID is Null 		
	
	return
end

 

 --========load CostZone + CostZoneRelation
insert into [DataTrue_Main].[dbo].[CostZones]
		   ([CostZoneName]
		   ,[CostZoneDescription]
		   ,[SupplierId]
		   ,[OwnerEntityID]
		   ,[OwnerMarketID])
select
		   ltrim(rtrim(z.CostZoneDescription)) --<CostZoneName, nvarchar(50),>
		   ,ltrim(rtrim(z.CostZoneDescription))--<CostZoneDescription, nvarchar(255),>
		   ,z.DataTrueSupplierID
		   ,z.DataTrueChainID --<OwnerEntityID, int,>
		   ,ltrim(rtrim(z.CostZoneID))--<OwnerMarketID, nvarchar(50),>)
from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] z
	left join [DataTrue_Main].[dbo].CostZones  c
		on ltrim(rtrim(z.CostZoneID)) = c.OwnerMarketID
			and z.DataTrueSupplierID = c.SupplierId
			and z.DataTrueChainID = c.OwnerEntityID
where z.DataTrueChainID = @chainid 
and z.DataTrueSupplierID = @supplierid
and z.RecordStatus = 0 
and c.CostZoneID is Null


insert into [DataTrue_Main].[dbo].[CostZoneRelations]
	   ([StoreID]
	   ,[SupplierID]
	   ,[CostZoneID]
	   ,[OwnerEntityID])
	   
select  
		t.DataTrueStoreID
	   ,t.DataTrueSupplierID
	   ,c.CostZoneID
	   ,t.DataTrueChainID
from  datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations t
		inner  join  [DataTrue_Main].[dbo].[CostZones] c
			on ltrim(rtrim(t.CostZoneID)) = c.OwnerMarketID
				and t.DataTrueSupplierID = c.SupplierId
				and t.DataTrueChainID = c.OwnerEntityID		
		left join [DataTrue_Main].[dbo].[CostZoneRelations] cz_r
			on  cz_r.StoreID = t.DataTrueStoreID
				and cz_r.OwnerEntityID = t.DataTrueChainID
				and cz_r.SupplierID = t.DataTrueSupplierID
				and cz_r.CostZoneID = c.CostZoneID
where t.DataTrueChainID = @chainid 
and t.DataTrueSupplierID = @supplierid
--and LTRIM(rtrim(t.costzoneid)) = @ownermarketid
and t.RecordStatus = 0
and t.DataTrueStoreID is not null
and  cz_r.CostZoneRelationID is Null


update z set z.recordstatus = 1
from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] z
	inner join [DataTrue_Main].[dbo].CostZones  c
		on ltrim(rtrim(z.CostZoneID)) = c.OwnerMarketID
			and z.DataTrueSupplierID = c.SupplierId
			and z.DataTrueChainID = c.OwnerEntityID
where z.DataTrueChainID = @chainid 
and z.DataTrueSupplierID = @supplierid
and z.RecordStatus = 0 

--======== end  load costzone 
 
--****************************************UPC Decompress************************************************
declare @rec cursor
declare @brandid int
declare @brandname nvarchar(50)


--*******************************End UPC Compress***********************************************


--*******************************Six or Less in Length*******************************************************

update p set p.UPC12 = case when len(ltrim(rtrim(upcnumber))) = 6 then '000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 5 then '0000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 4 then '00000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 3 then '000000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 2 then '0000000000' + ltrim(rtrim(upcnumber))
						else p.UPC12 end
from datatrue_edi.dbo.temp_PDI_UPC p
where 1 = 1
and datatruechainid = @chainid
and datatruesupplierid = @supplierid
and LEN(ltrim(rtrim(upcnumber))) between 2 and 6
--and (
--	UPC12 is null 
--	or 
--	LEN(ltrim(rtrim(UPC12))) between 2 and 6)
and datatrueproductid is null


update u set u.DataTrueProductID = i.ProductID
from datatrue_edi.dbo.temp_PDI_UPC u
		inner join datatrue_main.dbo.ProductIdentifiers i
			on UPC12 = LTRIM(rtrim(IdentifierValue)) and i.ProductIdentifierTypeID = 2
where 1 = 1
and datatruechainid = @chainid
and datatruesupplierid = @supplierid
and LEN(ltrim(rtrim(upcnumber))) between 2 and 6
and datatrueproductid is null

--*************************************Normal case for 12 length UPC***************************************
update u set UPC12 = datatrue_edi.dbo.fnParseUPC(ltrim(rtrim(upcnumber))), u.DataTrueProductID = i.ProductID
from [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
	left  join datatrue_main.dbo.ProductIdentifiers i
		on datatrue_edi.dbo.fnParseUPC(ltrim(rtrim(upcnumber))) = LTRIM(rtrim(IdentifierValue))
			and i.ProductIdentifierTypeID = 2
where 1 = 1 
and DataTrueChainID = @chainid
and DataTrueSupplierID = @supplierid		
--and LEN(ltrim(rtrim(upcnumber))) > 8	????
and (UPC12 is null 
	--or datatrueproductid is null
	and datatrueproductid is null
	)
	
		
--update u set UPC12 = datatrue_edi.dbo.fnParseUPC(ltrim(rtrim(upcnumber)))
--	FROM [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
--	where 1 = 1 	and DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
--	--and LEN(LTRIM(rtrim(upcnumber))) in (12,13)
--	and (UPC12 is null 
--		or LEN(datatrue_edi.dbo.fnParseUPC(ltrim(rtrim(upcnumber)))) between 12 and 14) -- or datatrueproductid is null)

update p set p.UPC12 = case when len(ltrim(rtrim(upcnumber))) = 8 then '0000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 7 then '00000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 6 then '000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 5 then '0000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 4 then '00000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 3 then '000000000' + ltrim(rtrim(upcnumber))
						when len(ltrim(rtrim(upcnumber))) = 2 then '0000000000' + ltrim(rtrim(upcnumber))
						else p.UPC12 end
from datatrue_edi.dbo.temp_PDI_UPC p
where 1 = 1
and datatruechainid = @chainid
and datatruesupplierid = @supplierid
and LEN(ltrim(rtrim(upcnumber))) between 2 and 8
and (UPC12 is null or LEN(ltrim(rtrim(UPC12))) between 2 and 8)
and datatrueproductid is null


---===UPC for existing products. Next statements load upcs for already  existing product that were loaded w/o UPC
/*
Needed Change Here

We need to try to match any remaining null DatatrueProductID's remaining after the last update
using join to the ItemPKG table as we do below updating ItemPKG table

Of course in this match the productidentifiers record was never created/inserted
so it will not be inserted by script below and will need to be done here
*/
print 'Logic for addint missing UPC for existing product'
--Try to get  prodid for the same chain/supplier updating U instead of P Table 
update u set u.datatrueproductid = p.datatrueproductid
from datatrue_edi.dbo.temp_PDI_ItemPKG p
	inner join datatrue_edi.dbo.Temp_PDI_UPC u
		on p.DataTrueChainID = u.DataTrueChainID
			and p.DataTrueSupplierID = u.DataTrueSupplierID
			and ltrim(rtrim(p.PDIItemNumber)) = ltrim(rtrim(u.PDIItemNumber))
			and ltrim(rtrim(p.PackageCode_Scrubbed)) = ltrim(rtrim(u.PackageCode_Scrubbed))
			and u.DataTrueProductID is  null
			and p.DataTrueProductID is not null
			--and u.DiscontinueDate is null ----???
			--and isnull(p.DataTrueProductID, 0) <> isnull(u.DataTrueProductID, 0) -- EZaslonkin: Not needed condition
			and u.DataTrueChainID = @chainid and u.DataTrueSupplierID = @supplierid
			and u.Recordstatus = 0 --
			and LEN(ltrim(rtrim(u.[UPC12]))) in (12, 13, 14)
	left  join [DataTrue_Main].[dbo].[ProductIdentifiers] pr_id 
				on pr_id.ProductID = p.datatrueproductid
				and pr_id.ProductIdentifierTypeID = 2
				and LEN(ltrim(rtrim(pr_id.identifiervalue))) between 12 and 14
where pr_id.ProductID is Null 


---Try to get  prodid for the same chain only  updating U instead of P Table 
update u set u.datatrueproductid = p.datatrueproductid
from  datatrue_edi.dbo.temp_PDI_ItemPKG p 
	inner join datatrue_edi.dbo.Temp_PDI_UPC u
		on p.DataTrueChainID = u.DataTrueChainID
			--and p.DataTrueSupplierID = u.DataTrueSupplierID
			and ltrim(rtrim(p.PDIItemNumber)) = ltrim(rtrim(u.PDIItemNumber))
			and ltrim(rtrim(p.PackageCode_Scrubbed)) = ltrim(rtrim(u.PackageCode_Scrubbed))
			and u.DataTrueProductID is  null
			and p.DataTrueProductID is not null
			--and u.DiscontinueDate is null
			--and isnull(p.DataTrueProductID, 0) <> isnull(u.DataTrueProductID, 0) -- EZaslonkin: Not needed condition
			and u.DataTrueChainID = @chainid and u.DataTrueSupplierID = @supplierid
			and u.Recordstatus = 0
			and LEN(ltrim(rtrim(u.[UPC12]))) in (12, 13, 14)
	left  join [DataTrue_Main].[dbo].[ProductIdentifiers] pr_id 
				on pr_id.ProductID = p.datatrueproductid
				and pr_id.ProductIdentifierTypeID = 2
				and LEN(ltrim(rtrim(pr_id.identifiervalue))) between 12 and 14
where pr_id.ProductID is Null 

print 'insert new id '
-- add ProductIdentifier data
insert into [DataTrue_Main].[dbo].[ProductIdentifiers]
	   ([ProductID]
	   ,[ProductIdentifierTypeID]
	   ,[OwnerEntityId]
	   ,[IdentifierValue]
	   ,[LastUpdateUserID]
	   ,[Comments])
select 
		u.datatrueproductid
	   ,2 --<ProductIdentifierTypeID, int,>
	   ,0 --<OwnerEntityId, int,>
	   ,ltrim(rtrim(u.[UPC12])) --<IdentifierValue, nvarchar(20),>
	   ,0
	   ,ltrim(rtrim(u.PDIItemNumber))
from datatrue_edi.dbo.Temp_PDI_UPC u
	left  join [DataTrue_Main].[dbo].[ProductIdentifiers] pr_id 
				on pr_id.ProductID = u.datatrueproductid
				and pr_id.ProductIdentifierTypeID = 2
				and LEN(ltrim(rtrim(pr_id.identifiervalue))) between 12 and 14
where  u.Recordstatus = 0
	and LEN(ltrim(rtrim(u.[UPC12]))) in (12, 13, 14)
	and pr_id.ProductID is Null
	and u.DataTrueChainID = @chainid 
	and u.DataTrueSupplierID = @supplierid
	and u.DataTrueProductID is not null 
	
	
---===End UPC for existing products

declare @recprd cursor
declare @vin nvarchar(50)
declare @productname nvarchar(255)
declare @PackageCode nvarchar(20)
declare @packageqty nvarchar(50)
declare @sellUOMUnits nvarchar(50)
declare @productalreadyexists smallint
declare @vendorname2 nvarchar(50)
declare @basecost money
declare @retail money
declare @costeffectivedate date
declare @count int
declare @packagecost money
declare @effectivedate date
declare @identifiertypetomatch tinyint


---===== Load New UPC
declare @Insertted_New_Product table( id int, Comments nvarchar(100)  );

select max(ltrim(rtrim(u.PDIItemNumber))) PDIItemNumber
	  ,min(u.[RecordID]) RecordID
      ,ltrim(rtrim(u.[UPC12])) UPC12
      ,max(ltrim(rtrim(u.[LongDescription]))) prod_desc
      ,max(ltrim(rtrim(u.[ShortDescription]))) prod_name
      ,max(u.[PackageCode_Scrubbed])  PackageCode_Scrubbed
      ,min(replace(u.[PackageQuantity], '''', '')) PackageQuantity
      --,u.[SellUOMUnits]
      --,u.chainidentifier
      --,u.vendorname as vendorIdentifier
      ,min(u.DataTrueChainID) DataTrueChainID
      ,max(u.DataTrueSupplierID) DataTrueSupplierID
	  ,cast(Null as int) ProductIdentifierTypeID
      ,cast(Null as int) ProductID
into #tempProds 
from [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
where 1 = 1
	and u.DataTrueProductID is null
	and ltrim(rtrim(isnull(u.[UPC12], ''))) <> ''
	and LEN(ltrim(rtrim(u.[UPC12]))) in (12, 13, 14)
	and u.DataTrueChainID = @chainid
	and u.DataTrueSupplierID = @supplierid
group  by  ltrim(rtrim(u.[UPC12]))


update u
set  ProductIdentifierTypeID = pr_id.ProductIdentifierTypeID,
	 ProductID  = pr_id.ProductID
from #tempProds u
	left join [DataTrue_Main].[dbo].[ProductIdentifiers] pr_id
		on pr_id.identifiervalue = ltrim(rtrim(u.[UPC12]))
			and pr_id.ProductIdentifierTypeID in (2,8)
			and LEN(ltrim(rtrim(pr_id.identifiervalue))) between 12 and 14

print 'Add New UPC'
begin Transaction
	--insert new product and id
	insert into [DataTrue_Main].[dbo].[Products]
			   ([ProductName]
			   ,[Description]
			   ,[ActiveStartDate]
			   ,[ActiveLastDate]
			   ,[LastUpdateUserID]
			   ,[UOM]
			   ,[UOMQty]
			   ,Comments
			   )
		output inserted.ProductID, inserted.Comments	into @Insertted_New_Product
	select  prod_name ProductName
		   ,prod_desc [Description]
		   ,'1/1/2013' ActiveStartDate
		   ,'12/31/2025' [ActiveLastDate]
		   ,@myid LastUpdateUserID
		   ,PackageCode_Scrubbed UOM
		   ,PackageQuantity UOMQty
		   ,RecordID Comments
	from #tempProds
	where ProductID is Null	   
	
	insert into [DataTrue_Main].[dbo].[ProductIdentifiers]
		   ([ProductID]
		   ,[ProductIdentifierTypeID]
		   ,[OwnerEntityId]
		   ,[IdentifierValue]
		   ,[LastUpdateUserID]
		   ,[Comments])
	select  
			pr.id
		   ,2 --[ProductIdentifierTypeID]
		   ,t.DataTrueChainID
		   ,t.UPC12
		   ,@myid
		   ,t.PDIItemNumber
	from  #tempProds t
			inner  join  @Insertted_New_Product  pr
				on pr.Comments =t.RecordID 
	where t.ProductID is Null	   

	update u set 
		u.ProductID = pr.id
	--select u.*
	from  #tempProds u
		inner  join  @Insertted_New_Product  pr
			on pr.Comments = u.RecordID 
	where ProductID is Null

	--insert only id
	insert into [DataTrue_Main].[dbo].[ProductIdentifiers]
		   ([ProductID]
		   ,[ProductIdentifierTypeID]
		   ,[OwnerEntityId]
		   ,[IdentifierValue]
		   ,[LastUpdateUserID]
		   ,[Comments])
	select  
			t.ProductID
		   ,2 --[ProductIdentifierTypeID]
		   ,t.DataTrueChainID
		   ,t.UPC12
		   ,@myid
		   ,t.PDIItemNumber
	from  #tempProds t
	where t.ProductID is not Null	   
		and t.ProductIdentifierTypeID = 8


	--update prodid and record status
	update u set 
		u.DataTrueProductID = pr.ProductID,
		u.RecordStatus = 1
	--select u.*
	from  [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
		inner  join  #tempProds  pr
			on pr.UPC12 = ltrim(rtrim(u.[UPC12])) 
	where u.DataTrueChainID = @chainid
		  and u.DataTrueSupplierID = @supplierid
		  and u.RecordStatus = 0	

commit transaction

drop table #tempProds
print 'END Add New UPC'

---===== End of load New UPC



---Try to get  prodid for the same chain/supplier 
update p set p.datatrueproductid = u.datatrueproductid
from datatrue_edi.dbo.temp_PDI_ItemPKG p
inner join datatrue_edi.dbo.Temp_PDI_UPC u
on p.DataTrueChainID = u.DataTrueChainID
and p.DataTrueSupplierID = u.DataTrueSupplierID
and ltrim(rtrim(p.PDIItemNumber)) = ltrim(rtrim(u.PDIItemNumber))
and ltrim(rtrim(p.PackageCode_Scrubbed)) = ltrim(rtrim(u.PackageCode_Scrubbed))
and p.DataTrueProductID is null
and u.DataTrueProductID is not null
and u.DiscontinueDate is null
--and isnull(p.DataTrueProductID, 0) <> isnull(u.DataTrueProductID, 0) -- EZaslonkin: Not needed condition
and p.DataTrueChainID = @chainid and p.DataTrueSupplierID = @supplierid

---Try to get  prodid for the same chain only 
update p set p.datatrueproductid = u.datatrueproductid
from  datatrue_edi.dbo.temp_PDI_ItemPKG p 
	inner join datatrue_edi.dbo.Temp_PDI_UPC u
	on p.DataTrueChainID = u.DataTrueChainID
--and p.DataTrueSupplierID = u.DataTrueSupplierID
and ltrim(rtrim(p.PDIItemNumber)) = ltrim(rtrim(u.PDIItemNumber))
and ltrim(rtrim(p.PackageCode_Scrubbed)) = ltrim(rtrim(u.PackageCode_Scrubbed))
and p.DataTrueProductID is null
and u.DataTrueProductID is not null
--and u.DiscontinueDate is null
--and isnull(p.DataTrueProductID, 0) <> isnull(u.DataTrueProductID, 0) -- EZaslonkin: Not needed condition
and p.DataTrueChainID = @chainid and p.DataTrueSupplierID = @supplierid
--and p.Recordstatus = 0


---Try to get  prodid for using Package Compare Logic with Package data as a source
exec [dbo].[prPDI_PriceBook_Master_Automated_Match_ProdId_By_Package_Logic] @chainid, @supplierid, 0

---Try to get  prodid for using Package Compare Logic with upc data as a source
exec [dbo].[prPDI_PriceBook_Master_Automated_Match_ProdId_By_Package_Logic] @chainid, @supplierid, 1



---Try to get  prodid from other chain/supplier 
update p set p.datatrueproductid = u.datatrueproductid
from  datatrue_edi.dbo.temp_PDI_ItemPKG p 
	inner join datatrue_edi.dbo.temp_PDI_ItemPKG u
	on --p.DataTrueChainID = u.DataTrueChainID
--and p.DataTrueSupplierID = u.DataTrueSupplierID
ltrim(rtrim(p.SizeDescription)) = ltrim(rtrim(u.SizeDescription))
and ltrim(rtrim(p.ItemDescription))= ltrim(rtrim(u.ItemDescription))
and ltrim(rtrim(p.PackageQuantity)) = ltrim(rtrim(u.PackageQuantity))
and ltrim(rtrim(p.PackageCode_Scrubbed)) = ltrim(rtrim(u.PackageCode_Scrubbed))
and p.DataTrueProductID is null
and u.DataTrueProductID is not null
--and u.DiscontinueDate is null !!!
---and u.Purchasable !!!!
--and isnull(p.DataTrueProductID, 0) <> isnull(u.DataTrueProductID, 0) -- EZaslonkin: Not needed condition
and p.DataTrueChainID = @chainid and p.DataTrueSupplierID = @supplierid


---Try to get  prodid for using Package Compare Logic again since we have populated addtional DataTrueProductIDs
exec [dbo].[prPDI_PriceBook_Master_Automated_Match_ProdId_By_Package_Logic] @chainid, @supplierid, 0

print 'Update ItemPKG using PDI# + Descriptions '
---Try to get  prodid for the same portion and the same chain/supplier but  only by PDI# + Descriptions
update p set p.datatrueproductid = u.datatrueproductid
from datatrue_edi.dbo.Temp_PDI_ItemPKG p
			inner  join datatrue_edi.dbo.Temp_PDI_ItemPKG u
				on p.DataTrueChainID = u.DataTrueChainID 
					and p.DataTrueSupplierID = u.DataTrueSupplierID
					and cast(p.Datetimereceived as date)  = cast(u.Datetimereceived as date)
					and ltrim(rtrim(p.PDIItemNumber))= ltrim(rtrim(u.PDIItemNumber))
					and ltrim(rtrim(p.ItemDescription))= ltrim(rtrim(u.ItemDescription))
					and ltrim(rtrim(p.SizeDescription)) = ltrim(rtrim(u.SizeDescription))
where p.DataTrueChainID = @chainid 
and p.DataTrueSupplierID = @supplierid
and p.DataTrueProductID is null
and u.DataTrueProductID is not null


--Create Product record w/o UPC
exec [dbo].[prPDI_PriceBook_Master_Automated_Add_MissingUPC] @chainid, @supplierid



--***********************Missing UPCs*********************************************

exec [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG] @chainid, @supplierid
--exec [dbo].[prPDI_PriceBook_Master_Automated_AddMissingItemPKG_PendingDeployment_20141219] @chainid, @supplierid


--************************Package File******************************************
declare @chainid2 int
declare @supplierid2 int
declare @purchaseable bit
declare @sellable bit
declare @sizedescription nvarchar(255)
declare @supplierpackageid int
declare @justsupplierpackages bit=0
declare @displaytables bit=0 
declare @Reclaimable bit
declare @AllowPartialPack bit
declare @Orderable bit
--EZAslonkin by  FogBugz #199919
declare @PromoCostOnly bit=0
declare @ProductPriceEndDate date 
declare @CursorProductPriceEndDate date 
declare @CursorProductPriceDiscontinueDate date
--declare @costzonetouse nvarchar(10)

select Distinct p.PDIItemNumber as PDIItemNo, RawProductIdentifier, p.[RecordID]
      ,p.VendorName as vendorIdentifier --U.vendorIdentifier
      ,p.PackageCode_Scrubbed
      ,p.PackageQuantity as PackageQty
      ,CostZoneID --cast(null as nvarchar(50)) as CostZoneID
      ,PackageCost --cast(null as money) as PackageCost
      ,effectivedate --cast(null as date) as effectivedate
      ,p.ItemDescription
      ,p.Purchasable
      ,p.Sellable
      ,p.sizedescription
      ,p.DataTrueChainID
      ,p.DataTrueSupplierID
      ,p.DataTrueProductID
      ,c.Reclaimable
      ,c.AllowPartialPack
      ,c.Orderable
      --Ezaslonkin by  FogBugz #19919 
      ,0 PromoCostOnly 
      ,cast (Null as date)  PromotionEndDate
      ,0 rnk
      ,c.DiscontinueDate  
into #tempProds2 --drop table #tempProds2 select * from #tempProds
--select *
  FROM datatrue_edi.dbo.temp_PDI_ItemPKG p
  --where 1 = 1
  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
  and ltrim(rtrim(c.PackageCode_Scrubbed)) = ltrim(rtrim(p.PackageCode_Scrubbed))
  and p.DataTrueChainID = @chainid
  and p.DataTrueSupplierID = @supplierid
  and p.DataTrueChainID = c.DataTrueChainID
  and p.DataTrueSupplierID = c.DataTrueSupplierID
  where p.DataTrueChainID is not null
  and p.DataTrueSupplierID is not null
  and p.DataTrueProductID is not null
  and p.Recordstatus = 0
  and c.RecordStatus = 0
--EZ: Added   cost with future DiscontinueDate
  --and c.DiscontinueDate is null
  and ISNull(c.DiscontinueDate, @FutureEndDate)  > cast(GETDATE() as date) 
  and c.PromotionEndDate is null
  and p.Purchasable = 'Y' 
  --and ltrim(rtrim(c.RawProductIdentifier)) = 'BLEACH'
  --order by p.PDIItemNumber, c.CostZoneID
  --and ltrim(rtrim(p.ChainIdentifier)) = @chainidentifier

--==EZaslonkin:	changes by  FogBugz #19919 
--add  item packages with promo price only 
insert into #tempProds2
select Distinct p.PDIItemNumber as PDIItemNo, c.RawProductIdentifier, p.[RecordID]
      ,p.VendorName as vendorIdentifier --U.vendorIdentifier
      ,p.PackageCode_Scrubbed
      ,p.PackageQuantity as PackageQty
      ,c.CostZoneID --cast(null as nvarchar(50)) as CostZoneID
      ,c.PackageCost --cast(null as money) as PackageCost
      ,c.effectivedate --cast(null as date) as effectivedate
      ,p.ItemDescription
      ,p.Purchasable
      ,p.Sellable
      ,p.sizedescription
      ,p.DataTrueChainID
      ,p.DataTrueSupplierID
      ,p.DataTrueProductID
      ,c.Reclaimable
      ,c.AllowPartialPack
      ,c.Orderable
      ,1 PromoCostOnly 
	  ,c.PromotionEndDate 
	  ,c.[RecordID] rnk
	  ,cast (Null as date)  DiscontinueDate  --c.DiscontinueDate 
from datatrue_edi.dbo.temp_PDI_ItemPKG p
  --where 1 = 1
  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
	  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
		  and ltrim(rtrim(c.PackageCode_Scrubbed)) = ltrim(rtrim(p.PackageCode_Scrubbed))
		  and p.DataTrueChainID = @chainid
		  and p.DataTrueSupplierID = @supplierid
		  and p.DataTrueChainID = c.DataTrueChainID
		  and p.DataTrueSupplierID = c.DataTrueSupplierID
	left  join  #tempProds2 tmp 
		on tmp.RecordID = p.RecordID
where tmp.RecordID is Null  
  and p.DataTrueChainID is not null
  and p.DataTrueSupplierID is not null
  and p.DataTrueProductID is not null
  and p.Recordstatus = 0
  and c.RecordStatus = 0
  and c.DiscontinueDate is null
  and c.PromotionEndDate is not null
  and p.Purchasable = 'Y' 



insert into #tempProds2
select Distinct p.PDIItemNumber as PDIItemNo, null as RawProductIdentifier, p.[RecordID]
      ,p.VendorName as vendorIdentifier --U.vendorIdentifier
      ,p.PackageCode_Scrubbed
      ,p.PackageQuantity as PackageQty
      ,cast(null as nvarchar(50)) as CostZoneID
      ,cast(null as money) as PackageCost
      ,cast(null as date) as effectivedate
      ,p.ItemDescription
      ,p.Purchasable
      ,p.Sellable
      ,p.sizedescription
      ,p.DataTrueChainID
      ,p.DataTrueSupplierID
      ,p.DataTrueProductID
      ,0
      ,0
      ,0
      --Ezaslonkin by  FogBugz #19919 
	  ,0 PromoCostOnly 
	  ,Null PromotionEndDate
	  ,0 rnk
	  ,cast (Null as date)  DiscontinueDate 
  --select *
  FROM datatrue_edi.dbo.temp_PDI_ItemPKG p
  where 1 = 1
  and p.DataTrueChainID = @chainid
  and p.DataTrueSupplierID = @supplierid
  and p.DataTrueChainID is not null
  and p.DataTrueSupplierID is not null
  and p.DataTrueProductID is not null
  and p.Sellable = 'Y'
  and p.Purchasable = 'N'
  and p.Recordstatus = 0 --select * from #tempProds2 --herenow
  


--===Ezaslonkin by  FogBugz #19919
--notification  about overlaping in promocosts
set @errormessage = 'One or more VINs with Promotion Costs only provided in the ' + @chainidentifier + '/' + @supplieridentifier + ' have overlaping  in dates range. This VINs have not been loaded '

select  a.RecordID RecordID_1, b.RecordID RecordID_2, 
		a.RawProductIdentifier  VIN_1,  b.RawProductIdentifier VIN_2
into  #temp_VINs_PromoCostOnly_deleted 
from  #tempProds2 a
		inner  join  #tempProds2 b 
			on  a.RecordID = b.RecordID and a.rnk <>  b.rnk
				and a.CostZoneID = b.CostZoneID 
where a.PromoCostOnly = 1 
	and b.PromoCostOnly = 1 
	and a.PromotionEndDate  between b.effectivedate and b.PromotionEndDate

select a.*	
from #tempProds2 a	
	left join  #temp_VINs_PromoCostOnly_deleted d1
		on  a.RecordID = d1.RecordID_1 --and a.RawProductIdentifier = d1.VIN_1
	left join  #temp_VINs_PromoCostOnly_deleted d2
		on  a.RecordID = d2.RecordID_2 --and a.RawProductIdentifier = d2.VIN_2
where  d1.RecordID_1 is not Null or d2.RecordID_1 is not Null 
	

if @@ROWCOUNT > 0
	begin
	
		exec dbo.prSendEmailNotification_PassEmailAddresses 'PDI PriceBook Import Issue Detected - Not loaded VINs'
			,@errormessage
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
	
	end

--- remove VINSs with overlaping 
delete a
from #tempProds2 a	
	left join  #temp_VINs_PromoCostOnly_deleted d1
		on  a.RecordID = d1.RecordID_1 and a.RawProductIdentifier = d1.VIN_1
	left join  #temp_VINs_PromoCostOnly_deleted d2
		on  a.RecordID = d2.RecordID_2 and a.RawProductIdentifier = d2.VIN_2
where  d1.RecordID_1 is not Null or d2.RecordID_1 is not Null 
	
drop table #temp_VINs_PromoCostOnly_deleted 
--=== 

--===Multiply costs Correct dates
select  RecordID, DataTrueProductID, LTRIM(rtrim(costzoneid)) costzoneid, rtrim(ltrim(RawProductIdentifier)) VIN, 
		PackageCode_Scrubbed,	rtrim(ltrim(PDIItemNo)) PDIItemNo, effectivedate,
		--PromotionEndDate,
		 DiscontinueDate, 

	DENSE_RANK() over( partition by  DataTrueProductID , LTRIM(rtrim(costzoneid)), rtrim(ltrim(RawProductIdentifier)),
									PackageCode_Scrubbed, rtrim(ltrim(PDIItemNo))
						order by effectivedate) dates_order 
into #tempProds2_ranked
from  #tempProds2 
where PromoCostOnly = 0 
	and  Purchasable = 'Y'
	
	
update a 
set a.DiscontinueDate = case 
							when  b.effectivedate is not Null
									and IsNull(a.DiscontinueDate,@FutureEndDate) >= b.effectivedate
								then dateadd(day,-1, b.effectivedate)
							else a.DiscontinueDate
							end
							
from #tempProds2_ranked a
	left  join #tempProds2_ranked b 
		on 	a.DataTrueProductID = b.DataTrueProductID 
			and a.costzoneid = b.costzoneid
			and a.VIN = b.VIN
			and a.PackageCode_Scrubbed = b.PackageCode_Scrubbed
			and a.PDIItemNo = b.PDIItemNo
			and  a.dates_order+1 = b.dates_order


update m
set m.DiscontinueDate = t.DiscontinueDate
--select m.RecordID,t.RecordID,m.DataTrueProductID, t.DataTrueProductID, m.RawProductIdentifier, t.VIN, m.EffectiveDate, m.DiscontinueDate, t.EffectiveDate, t.DiscontinueDate
from #tempProds2 m
		inner join #tempProds2_ranked t
			on m.RecordID = t.RecordID
			   and	ltrim(rtrim(m.CostZoneID)) = t.CostZoneID
			   and rtrim(ltrim(m.RawProductIdentifier))  = t.VIN
			   and m.EffectiveDate = t.EffectiveDate
where IsNull(m.DiscontinueDate,'1970-01-01') <>  IsNull(t.DiscontinueDate,'1970-01-01')


drop table #tempProds2_ranked	
--==== end Multiply costs Correct dates
  



-----!!!! ItemPckg  processing
select ltrim(rtrim(PDIItemNo))  PDIItemNo
	   ,ltrim(rtrim([RawProductIdentifier])) VIN
	  ,[RecordID]
      ,ltrim(rtrim([vendorIdentifier])) vendorIdentifier
      ,PackageCode_Scrubbed
      ,replace([PackageQty], '''', '') PackageQty
      ,LTRIM(rtrim(costzoneid)) costzoneid
      ,PackageCost
      ,effectivedate
      ,LTRIM(rtrim(itemdescription)) itemdescription
      ,case when LTRIM(rtrim(Purchasable)) = 'Y' then 1 else 0 end Purchasable
      ,case when LTRIM(rtrim(Sellable)) = 'Y' then 1 else 0 end Sellable
      ,LTRIM(rtrim(sizedescription)) sizedescription
      ,DataTrueChainID
      ,DataTrueSupplierID
      ,DataTrueProductID
      ,case when LTRIM(rtrim(Reclaimable)) = 'Y' then 1 else 0 end Reclaimable
      ,case when LTRIM(rtrim(AllowPartialPack)) = 'Y' then 1 else 0 end AllowPartialPack
      ,case when LTRIM(rtrim(Orderable)) = 'Y' then 1 else 0 end Orderable
      ,PromoCostOnly
      ,PromotionEndDate
      ,DiscontinueDate
      into #temp_ItmePckg
from #tempProds2

declare @Insertted_New_SupplierPackage table (SupplierPackageID int, SupplierID int, OwnerEntityID int,
		OwnerPackageIdentifier varchar(50), OwnerPDIItemNo varchar(50), VIN varchar(50), ProductID int, ReferenceIdentifier varchar(255))


begin transaction

--insert  data to  StoreSetup
	insert into [DataTrue_Main].[dbo].[StoreSetup]
			   ([ChainID]
			   ,[StoreID]
			   ,[ProductID]
			   ,[SupplierID]
			   ,[BrandID]
			   ,[InventoryRuleID]
			   ,[ActiveStartDate]
			   ,[ActiveLastDate]
			   ,[LastUpdateUserID]
			   ,[PDIParticipant])
	select 
		st.ChainID
	   ,st.StoreID
	   ,t.DataTrueProductID
	   ,c.SupplierId --<SupplierID, int,>
	   ,0 --<BrandID, int,>
	   ,0 --<InventoryRuleID, int,>
	   ,'1/1/2013' --<ActiveStartDate, datetime,>
	   ,'12/31/2099' --<ActiveLastDate, datetime,>
	   ,@myid --<LastUpdateUserID, nvarchar(50),>
	   ,1 --<PDIParticipant, bit,>)
	from 	
		(
		select distinct DataTrueProductID, costzoneid    
		 from #temp_ItmePckg
		) t 
		inner join [DataTrue_Main].[dbo].costzones c
			on  c.OwnerEntityID = @chainid
				and c.SupplierId = @supplierid
				and LTRIM(rtrim(c.OwnerMarketID)) = t.costzoneid
		inner join  datatrue_main.dbo.CostZoneRelations r 
			on c.CostZoneID = r.CostZoneID
		inner join datatrue_main.dbo.stores st
			on st.StoreID = r.storeid		
		left  join StoreSetup s
			on s.ChainID = 	st.ChainID
				and s.ProductID = t.DataTrueProductID
				and s.StoreID = st.StoreID
				and s.SupplierID = c.SupplierId 
	where  s.StoreSetupID is Null				


--add SupplierPackage
	insert into [DataTrue_Main].[dbo].[SupplierPackages]
		   ([SupplierPackageTypeID]
		   ,[SupplierID]
		   ,[OwnerEntityID]
		   ,[OwnerPDIItemNo]
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
		   ,[LastUpdateUserID]
		   ,[Purchasable]
		   ,[Sellable]
		   ,[AllowPartialPack]
		   ,ReferenceIdentifier
		   )
	output inserted.SupplierPackageID, inserted.SupplierID, inserted.OwnerEntityID,
			inserted.OwnerPackageIdentifier, inserted.OwnerPDIItemNo, inserted.VIN , 
			inserted.ProductID, inserted.ReferenceIdentifier	
			into @Insertted_New_SupplierPackage
	select distinct -- exclude multiply costs
		   1 --<SupplierPackageTypeID, smallint,>
		   ,t.DataTrueSupplierID--<SupplierID, int,>
		   ,t.DataTrueChainID --<OwnerEntityID, int,>
		   ,t.PDIItemNo --<OwnerPDIItemNo, nvarchar(50),>
		   ,t.PackageCode_Scrubbed --<OwnerPackageIdentifier, nvarchar(50),>
		   ,t.itemdescription --<OwnerPackageDescription, nvarchar(255),>
		   ,t.sizedescription --<OwnerPackageSizeDescription, nvarchar(50),>
		   ,t.Packageqty --<OwnerPackageQty, nvarchar(50),>
		   ,t.VIN --<VIN, nvarchar(50),>
		   ,t.DataTrueProductID --<ProductID, int,>
		   ,t.sizedescription --<ThisPackageUOMBasis, nvarchar(50),>
		   ,cast(replace(t.Packageqty, '.', '') as int) --cast(replace(replace(@packageqty, '0', ''), '.', '') as int) --<ThisPackageUOMBasisQty, nvarchar(50),>
		   ,t.Packageqty --<ThisPackageEACHBasisQty, nvarchar(50),>
		   ,t.Orderable --<AllowReorder, bit,>
		   ,t.Reclaimable --<AllowReclaim, bit,>
		   ,@myid --<LastUpdateUserID, nvarchar(50),>
		   ,t.Purchasable --<Purchasable, bit,>
		   ,t.Sellable
		   ,t.AllowPartialPack --<Sellable, bit,>
		   ,t.RecordID 
	from #temp_ItmePckg t
		left  join [DataTrue_Main].[dbo].SupplierPackages p 
			on p.ProductID = t.DataTrueProductID
			 and p.SupplierID = t.DataTrueSupplierID
			 and p.OwnerEntityID = t.DataTrueChainID
			 and p.OwnerPackageIdentifier = t.PackageCode_Scrubbed
			 and p.OwnerPDIItemNo = t.PDIItemNo
			 and LTRIM(rtrim(isnull(p.VIN,''))) = LTRIM(rtrim(isnull(t.VIN,'')))
	where p.SupplierPackageID is Null		 

--add Costs for Purchasebale packages
	insert into [DataTrue_Main].[dbo].[ProductPrices]
		   ([ProductPriceTypeID]
		   ,[ProductID]
		   ,[ChainID]
		   ,[StoreID]
		   ,[BrandID]
		   ,[SupplierID]
		   ,[UnitPrice]
		   ,[UnitRetail]
		   ,[PricePriority]
		   ,[ActiveStartDate]
		   ,[ActiveLastDate]
		   ,[LastUpdateUserID]
		   ,[SupplierPackageID])
	Select  11 --<ProductPriceTypeID, int,>
		   ,t.DataTrueProductID
		   ,t.DataTrueChainID
		   ,st.StoreID
		   ,0 --<BrandID, int,>
		   ,t.DataTrueSupplierID
		   ,t.PackageCost
		   ,ISNULL(rc.GrossPrice,0)
		   ,0 --<PricePriority, smallint,>
		   ,t.EffectiveDate
		   ,case 
			    when t.PromoCostOnly = 1
					then t.PromotionEndDate  --there is only  promo cost w/o base cost (load as base cost)
			    when t.Purchasable = 1 and t.DiscontinueDate is not Null 
					then t.DiscontinueDate -- there is base cost with DiscontinueDate
			   else  '12/31/2099' -- there is base cost w/o DiscontinueDate
			end 
		   ,@myid --<LastUpdateUserID, nvarchar(50),>
		   ,sp.SupplierPackageID
	from #temp_ItmePckg t 
		inner join @Insertted_New_SupplierPackage sp 
			on sp.OwnerPackageIdentifier = t.PackageCode_Scrubbed
				and sp.OwnerPDIItemNo = t.PDIItemNo
				and sp.VIN = t.VIN
				and sp.ProductID = t.DataTrueProductID
		inner join [DataTrue_Main].[dbo].costzones c
			on  c.OwnerEntityID = @chainid
				and c.SupplierId = @supplierid
				and LTRIM(rtrim(c.OwnerMarketID)) = t.costzoneid
		inner join  datatrue_main.dbo.CostZoneRelations r 
			on c.CostZoneID = r.CostZoneID
		inner join datatrue_main.dbo.stores st
			on st.StoreID = r.storeid		
		left join datatrue_edi.dbo.Temp_PDI_Retail rc
			on  rc.RecordStatus = 0 
				and rc.DataTrueChainID = @chainid
				and rc.DataTrueSupplierID = @supplierid
				and rc.DataTrueProductID = t.DataTrueProductID
				and rc.DataTrueStoreid = st.StoreID 
		left join [DataTrue_Main].[dbo].[ProductPrices] pp
			on   pp.ProductID = t.DataTrueProductID
			 and pp.SupplierID = t.DataTrueSupplierID
			 and pp.ProductPriceTypeID = 11
			 and pp.supplierpackageid = sp.SupplierPackageID
			 and cast(ActiveStartDate as date)  = t.EffectiveDate
			and pp.StoreID  = st.StoreID	    
	where t.Purchasable = 1		
		and t.PackageCost is not Null
		and pp.ProductPriceID is Null
		   

--add Costs for Sellable packages
	insert into [DataTrue_Main].[dbo].[ProductPrices]
		   ([ProductPriceTypeID]
		   ,[ProductID]
		   ,[ChainID]
		   ,[StoreID]
		   ,[BrandID]
		   ,[SupplierID]
		   ,[UnitPrice]
		   ,[UnitRetail]
		   ,[PricePriority]
		   ,[ActiveStartDate]
		   ,[ActiveLastDate]
		   ,[LastUpdateUserID]
		   ,[SupplierPackageID])
	Select  3 --<ProductPriceTypeID, int,>
		   ,t.DataTrueProductID
		   ,t.DataTrueChainID
		   ,st.StoreID
		   ,0 --<BrandID, int,>
		   ,t.DataTrueSupplierID
		   ,t.PackageCost
		   ,ISNULL(rc.GrossPrice,0)
		   ,0 --<PricePriority, smallint,>
		   ,t.EffectiveDate
		   ,case 
			    when t.PromoCostOnly = 1
					then t.PromotionEndDate  --there is only  promo cost w/o base cost (load as base cost)
			    when t.Purchasable = 1 and t.DiscontinueDate is not Null 
					then t.DiscontinueDate -- there is base cost with DiscontinueDate
			   else  '12/31/2099' -- there is base cost w/o DiscontinueDate
			end 
		   ,@myid --<LastUpdateUserID, nvarchar(50),>
		   ,sp.SupplierPackageID
	from #temp_ItmePckg t 
		inner join @Insertted_New_SupplierPackage sp 
			on sp.OwnerPackageIdentifier = t.PackageCode_Scrubbed
				and sp.OwnerPDIItemNo = t.PDIItemNo
				and sp.VIN = t.VIN
				and sp.ProductID = t.DataTrueProductID
		inner join [DataTrue_Main].[dbo].costzones c
			on  c.OwnerEntityID = @chainid
				and c.SupplierId = @supplierid
				and LTRIM(rtrim(c.OwnerMarketID)) = t.costzoneid
		inner join  datatrue_main.dbo.CostZoneRelations r 
			on c.CostZoneID = r.CostZoneID
		inner join datatrue_main.dbo.stores st
			on st.StoreID = r.storeid		
		left join datatrue_edi.dbo.Temp_PDI_Retail rc
			on  rc.RecordStatus = 0 
				and rc.DataTrueChainID = @chainid
				and rc.DataTrueSupplierID = @supplierid
				and rc.DataTrueProductID = t.DataTrueProductID
				and rc.DataTrueStoreid = st.StoreID 
		left join [DataTrue_Main].[dbo].[ProductPrices] pp
			on   pp.ProductID = t.DataTrueProductID
			 and pp.SupplierID = t.DataTrueSupplierID
			 and pp.ProductPriceTypeID = 3
			 and pp.supplierpackageid = sp.SupplierPackageID
			 and cast(ActiveStartDate as date)  = t.EffectiveDate
			and pp.StoreID  = st.StoreID	    
	where t.Sellable = 1		
		and t.PackageCost is not Null
		and pp.ProductPriceID is Null


	--Set status = 1
	update p
	set Recordstatus = 1 
	from [DataTrue_EDI].[dbo].[temp_PDI_ItemPKG] p
		inner join @Insertted_New_SupplierPackage t
			on t.ReferenceIdentifier = p.RecordID		
	
commit transaction		

drop  table #temp_ItmePckg





--***********************************Manufacturers and Brands******************************************

declare @recman cursor
declare @manname nvarchar(255)
declare @manfactid int


					


--=====Populating Manufacture and Brands
--temp set of Manufacturer
select  
		ManufacturerID,
		BrandID,
		cast(DataTrueChainID as varchar(20))+case when ManufacturerID = ''  then 'DEFAULT' else ManufacturerID end ReferenceIdentifier, 
		DataTrueChainID
		into #temp_Manufacturers_Brands
from (
	select distinct ltrim(rtrim(IsNull(ManufacturerID,''))) ManufacturerID, ltrim(rtrim(IsNull(BrandID,''))) BrandID,  DataTrueChainID
	from datatrue_edi.dbo.temp_PDI_ItemPKG
	where 1 = 1
		and DataTrueChainID = @chainid
		and DataTrueSupplierID = @supplierid
		and LEN(ltrim(rtrim(ManufacturerID))) > 0
		and DataTrueBrandID is null
		--TO do filter  for last porsion of data
		and ltrim(rtrim(BrandID)) <> 'Discontinued'
		and ltrim(rtrim(ManufacturerID)) <> 'BOTTLE DEPOSIT'
	) a


declare @Insertted_New_Manufacturer table (EntID int, ReferenceIdentifier varchar(255))

--Add system entity
insert into [DataTrue_Main].[dbo].[SystemEntities]
	   ([EntityTypeID]
	   ,[DateTimeCreated]
	   ,[LastUpdateUserID]
	   ,[DateTimeLastUpdate]
	   ,ReferenceIdentifier
	   )
   output inserted.EntityId, inserted.ReferenceIdentifier	into @Insertted_New_Manufacturer
select  distinct --only  unique Manufacturer  
		11 --<EntityTypeID, int,>
	   ,GETDATE() --<DateTimeCreated, datetime,>
	   ,@myid --<LastUpdateUserID, int,>
	   ,GETDATE() --<DateTimeLastUpdate, datetime,>
	   ,t.ReferenceIdentifier --ReferenceIdentifier
from 	#temp_Manufacturers_Brands t
		left  join Manufacturers m   
			on m.OwnerEntityID = t.DataTrueChainID
				and ltrim(rtrim(m.OwnerManufacturerIdentifier)) = t.ManufacturerID
where m.ManufacturerID is Null				

		
--Add Manufacturers
insert into [DataTrue_Main].[dbo].[Manufacturers]
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
	   
select distinct --only  unique Manufacturer  
		t_id.EntID --<ManufacturerID, int,>
	   ,t.ManufacturerID --<ManufacturerName, nvarchar(100),>
	   ,t.ManufacturerID --<ManufacturerIdentifier, nvarchar(50),>
	   ,'1/1/2013' --<ActiveStartDate, smalldatetime,>
	   ,'12/31/2025' --<ActiveLastDate, smalldatetime,>
	   ,'' --<Comments, nvarchar(500),>
	   ,GETDATE() --<DateTimeCreated, datetime,>
	   ,@myid --<LastUpdateUserID, nvarchar(50),>
	   ,GETDATE() --<DateTimeLastUpdate, datetime,>
	   ,t.DataTrueChainID --<OwnerEntityID, int,>
	   ,t.ManufacturerID --<OwnerManufacturerIdentifier, nvarchar(50),>)
from @Insertted_New_Manufacturer t_id
		inner join #temp_Manufacturers_Brands t
			on  t_id.ReferenceIdentifier = t.ReferenceIdentifier


--Add Brand
insert into [DataTrue_Main].[dbo].[Brands]
		   ([ManufacturerID]
		   ,[BrandName]
		   ,[BrandIdentifier]
		   ,[BrandDescription]
		   ,[OwnerEntityID]
		   ,[OwnerBrandIdentifier])
		   
select 		m.ManufacturerID --[ManufacturerID]
		   ,t.BrandID --[BrandName]
		   ,t.BrandID--[BrandIdentifier]
		   ,'' --[BrandDescription]
		   ,t.DataTrueChainID --[OwnerEntityID]
		   ,t.BrandID [OwnerBrandIdentifier]		   
from 	#temp_Manufacturers_Brands t
		inner join Manufacturers m
			on m.OwnerEntityID = t.DataTrueChainID
				and ltrim(rtrim(m.OwnerManufacturerIdentifier)) = t.ManufacturerID
		left  join Brands b   
			on b.OwnerEntityID = t.DataTrueChainID
				and LTRIM(rtrim(b.OwnerBrandIdentifier)) = t.BrandID
				and b.ManufacturerID = m.ManufacturerID
where  b.BrandID is Null			
			

update P set p.datatruebrandid = b.BrandID
from datatrue_edi.dbo.temp_PDI_ItemPKG p
		inner join Manufacturers m
			on m.OwnerEntityID = p.DataTrueChainID
				and ltrim(rtrim(m.OwnerManufacturerIdentifier)) = ltrim(rtrim(p.ManufacturerID))
		inner  join Brands b   
			on b.OwnerEntityID = p.DataTrueChainID
				and LTRIM(rtrim(b.OwnerBrandIdentifier)) = ltrim(rtrim(p.BrandID)) 
				and b.ManufacturerID = m.ManufacturerID
where 1 = 1
and DataTrueChainID = @chainid
and DataTrueSupplierID = @supplierid
and p.datatruebrandid is null


drop  table #temp_Manufacturers_Brands
--====end of populating Manufacture 


update datatrue_edi.dbo.temp_PDI_ItemPKG 
set DataTrueManufacturerID = 0 
where datatruechainid = @chainid 
and datatruesupplierid = @supplierid
and DataTrueManufacturerID is null

update datatrue_edi.dbo.temp_PDI_ItemPKG 
set DataTrueBrandID = 0 
where datatruechainid = @chainid 
and datatruesupplierid = @supplierid
and DataTrueBrandID is null

--drop table #productsalreadyassigned

select ProductId into #productsalreadyassigned
--select *
from [DataTrue_Main].[dbo].[ProductBrandAssignments]
where CustomOwnerEntityID = @chainid

INSERT INTO [DataTrue_Main].[dbo].[ProductBrandAssignments]
           ([BrandID]
           ,[ProductID]
           ,[CustomOwnerEntityID]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate])
select distinct datatrueBrandId, datatrueProductID, datatruechainid, getdate(), 0, getdate()
--select *
			from datatrue_edi.dbo.temp_PDI_ItemPKG p
			where 1 = 1
			and DataTrueChainID = @chainid
			and datatrueProductID is not null
			and datatrueBrandId is not null 
			and datatrueProductID not in
			(select ProductId from #productsalreadyassigned)


--***************************Categories****************************************
exec [dbo].[prPDI_PriceBook_Master_Automated_ProductCategories] @chainid

update p set p.datatrueproductcategoryid = c.ProductcategoryId
from ProductCategories c
inner join datatrue_edi.dbo.temp_PDI_ItemPKG p
on c.OwnerEntityID = p.DataTrueChainID
and ltrim(rtrim(c.OwnerGroupLevelID)) = '3'
and ltrim(rtrim(c.OwnerGroupID)) = ltrim(rtrim(p.PrimaryLevel3GroupID))
and p.datatrueproductcategoryid is null
and DataTrueChainID = @chainid

	
select ProductId into #tempProdCatsAlreadyAssigned
from [DataTrue_Main].[dbo].[ProductCategoryAssignments]
where CustomOwnerEntityID = @chainid
		
INSERT INTO [DataTrue_Main].[dbo].[ProductCategoryAssignments]
		   ([ProductCategoryID]
		   ,[ProductID]
		   ,[CustomOwnerEntityID])
	 select distinct datatrueproductcategoryid, datatrueProductid, datatruechainid
	from datatrue_edi.dbo.temp_PDI_ItemPKG
	where 1 = 1
	and DataTrueChainID = @chainid
	and datatrueproductcategoryid is not null
	and datatrueProductid is not null
	and DataTrueProductID not in 
	(select ProductId from #tempProdCatsAlreadyAssigned)


--*************************************Promotions****************************************************
declare @startdate date
declare @enddate date
declare @netcost money
declare @promotionamt money
declare @unitprice money
declare @showtables bit=0
declare @costzone nvarchar(50)


--!!!Added record status 
--!!!Only  for Promo with base cost -- 
--!!!New date logic 
select LTRIM(rtrim(c.rawproductidentifier)) VIN, 
			case   when  c.effectivedate >= bc.effectivedate then c.effectivedate
				else bc.effectivedate end effectivedate,
			case   when  c.PromotionEndDate <= IsNull(bc.DiscontinueDate,'12/31/2099') then c.PromotionEndDate
				else IsNull(bc.DiscontinueDate,'12/31/2099') end PromotionEndDate,
			c.PackageCost, c.CostZoneID,
			sp.supplierpackageid, sp.productid, bc.PackageCost - c.PackageCost Promotionamt
into #temp_Promo_Cost
from datatrue_edi.dbo.temp_PDI_Costs c
		inner join Supplierpackages sp
			on sp.supplierid = @supplierid
				and sp.ownerentityid = @chainid
				and ltrim(rtrim(sp.vin)) = LTRIM(rtrim(c.rawproductidentifier))
		inner join 	datatrue_edi.dbo.temp_PDI_Costs  bc
			on 	bc.datatruechainid = @chainid
				and bc.DataTrueSupplierID =    @supplierid
				and bc.Promotionenddate is  null
				and LTRIM(rtrim(bc.rawproductidentifier)) = LTRIM(rtrim(c.rawproductidentifier))
				and c.effectivedate <=  IsNull(bc.DiscontinueDate,'12/31/2099')
				and c.Promotionenddate  >= bc.effectivedate 
				and LTRIM(rtrim(c.CostZoneID)) = LTRIM(rtrim(bc.CostZoneID))
				and bc.RecordStatus = 0
where 1 = 1
and c.datatruechainid = @chainid
and c.DataTrueSupplierID =    @supplierid
and c.Promotionenddate is not null
and c.RecordStatus = 0


insert into productprices
(ProductPriceTypeID, ProductID, ChainID, StoreID, BrandID, 
	SupplierID, UnitPrice, UnitRetail, ActiveStartDate, ActiveLastDate, SupplierPackageID, LastUpdateUserID)
select 8, c.productid, @chainID, st.StoreID, 0, @supplierid, c.Promotionamt, 0,
c.effectivedate, c.PromotionEndDate, c.SupplierPackageID, @myid
from #temp_Promo_Cost c
		inner join [DataTrue_Main].[dbo].costzones cz
			on  cz.OwnerEntityID = @chainid
				and cz.SupplierId = @supplierid
				and LTRIM(rtrim(cz.OwnerMarketID)) = LTRIM(rtrim(c.costzoneid))
		inner join  datatrue_main.dbo.CostZoneRelations r 
			on cz.CostZoneID = r.CostZoneID
		inner join datatrue_main.dbo.stores st
			on st.StoreID = r.storeid		
		left join [DataTrue_Main].[dbo].[ProductPrices] pp
			on   pp.ProductID = c.productid
				and pp.SupplierID = @supplierid
				and pp.ChainID = @chainid
				and pp.ProductPriceTypeID = 8
				and pp.supplierpackageid = c.SupplierPackageID
				and cast(ActiveStartDate as date)  = c.effectivedate
				and pp.StoreID  = st.StoreID	    
where  pp.ProductPriceID is Null

drop table #temp_Promo_Cost


-------------------Site Level Costs Override--------------------------------

select distinct p.datatruechainid, p.datatrueproductid, ltrim(rtrim(StoreID)) as SiteID, PackageCost, cast(null as int) as StoreID
into #tempSiteCosts
from datatrue_edi.dbo.temp_PDI_ItemPKG p
inner join datatrue_edi.dbo.temp_PDI_Costs c
on p.pdiitemnumber = c.pdiitemno
and p.PackageCode_Scrubbed = c.PackageCode_Scrubbed
and p.datatruechainid = c.datatruechainid
and p.datatruesupplierid = c.datatruesupplierid
and p.datatruechainid = @chainid
and p.datatruesupplierid = @supplierid
and c.recordstatus = 0
and len(isnull(storeid, '')) > 0

--select * from #tempSiteCosts

update t set t.StoreID = s.StoreID
from #tempSiteCosts t
inner join Stores s
on t.datatruechainid = s.chainid
and ltrim(rtrim(t.SiteID)) = ltrim(rtrim(s.Custom2))

--select * from #tempSiteCosts

update p set p.UnitPrice = t.packagecost
--select t.PackageCost, p.UnitPrice, *
from #tempSiteCosts t
inner join productprices p
on t.storeid = p.storeid
and t.datatrueproductid = p.productid
and p.productpricetypeid in (3,11)

drop table #tempSiteCosts

exec [dbo].[prPDI_PriceBook_Master_Automated_SiteLevelCosts_Add_PendingDeployment_20150102] @chainid, @supplierid


--add SiteLevel data (for stores w/o Costzone) to StoreSetup
insert into [DataTrue_Main].[dbo].[StoreSetup]
			   ([ChainID]
			   ,[StoreID]
			   ,[ProductID]
			   ,[SupplierID]
			   ,[BrandID]
			   ,[InventoryRuleID]
			   ,[ActiveStartDate]
			   ,[ActiveLastDate]
			   ,[LastUpdateUserID]
			   ,[PDIParticipant])
select  distinct 
	a.ChainID
   ,a.StoreID
   ,a.ProductID
   ,a.SupplierId --<SupplierID, int,>
   ,0 --<BrandID, int,>
   ,0 --<InventoryRuleID, int,>
   ,'1/1/2013' --<ActiveStartDate, datetime,>
   ,'12/31/2099' --<ActiveLastDate, datetime,>
   ,0 --<LastUpdateUserID, nvarchar(50),>
   ,1 --<PDIParticipant, bit,>)
  from ProductPrices a
		left join [StoreSetup] b 
			on  a.ChainID = b.ChainID
				and a.SupplierID = b.SupplierID
				and a.StoreID = b.StoreID
				and a.ProductID = b.ProductID
where  a.ChainID = @chainid
	and a.SupplierID = @supplierid
	and a.ProductPriceTypeID in  (11,3, 8)
	and b.StoreSetupID is Null

--========Run validation 
--Added by  EZaslonkin
exec dbo.prPDI_PriceBook_Master_Automated_Product_Validation_TEST @chainid, @supplierid
--exec dbo.prPDI_PriceBook_Master_Automated_Product_Validation @chainid, @supplierid

exec dbo.prPDI_PriceBook_Master_Automated_Product_Validation_Duplicates @chainid, @supplierid

end try

begin catch
   if (XACT_STATE()) = -1
    begin
       rollback transaction;
       --print 'Y'
    end

   if (XACT_STATE()) = 1
    begin
        commit transaction;
       --print 'Y'
    end


	--exec prGetErrorInfo_SendEmailNotification @chainid,@supplierid
	exec prGetErrorInfo_SendEmailNotification_Test @chainid,@supplierid
	

end catch

/*

select * from storesetup where supplierid = 75375
select * from productprices where supplierid = 75375
select * from supplierpackages where supplierid = 75375

75130
75375

select *
	FROM [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
	where 1 = 1 	and DataTrueChainID = 75130 and DataTrueSupplierID = 75375
	--and LEN(LTRIM(rtrim(upcnumber))) in (12,13)
	and (UPC12 is null or datatrueproductid is null)


*/		
return
GO
