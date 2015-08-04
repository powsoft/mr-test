USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_Product_Validation_RollBack_20150217]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPDI_PriceBook_Master_Automated_Product_Validation_RollBack_20150217]
@chainid int,
@supplierid int
as
--declare @chainid int= 75217 declare @supplierid int=79174
--declare @chainid int= 75407 declare @supplierid int=79282
--declare @chainid int= 75131 declare @supplierid int=75405
--declare @chainid int= 75217 declare @supplierid int=79172
--declare @chainid int= 75130 declare @supplierid int=75394
--[dbo].[prPDI_PriceBook_Master_Automated_Product_Validation] 75130, 75394
declare @chainidentifier nvarchar(50)
declare @chainname nvarchar(255)
declare @suppliername nvarchar(255)
declare @supplierIdentifier nvarchar(50)
declare @errormessage nvarchar(max)
declare @errormessage_extarnal nvarchar(max)
declare @records_count int  = 0
declare @email_subject nvarchar(400)
declare @testmode varchar(1000) = '' -- THIS IS A TEST - '
declare @filedate date
declare @notcalidrecords varchar(MAX)


select @chainidentifier = chainidentifier,   
	@chainname = ChainName
from chains 
where ChainID = @chainid

select 	@suppliername = SupplierName
from Suppliers
where supplierid = @supplierid


select @supplierIdentifier = LTRIM(rtrim(TranslationValueOutside)) 
from [DataTrue_EDI].[dbo].[TranslationMaster] 
where isnumeric(TranslationCriteria1) > 0 
and TranslationTypeID = 26 
and CAST(TranslationCriteria1 as int) = @supplierid
and TranslationChainID = @chainid


set @errormessage = ''
set @errormessage_extarnal = '' 
set @email_subject = @testmode + 'PDI PriceBook Import Issue/s Detected  for chain name  ' + @chainname + '('+@chainidentifier+') and supplier name ' + @suppliername+'('+@supplierIdentifier+')'


			
--Verify  Costzone 			
select t.RecordID
from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] t
		left join [DataTrue_Main].[dbo].[CostZones] cz
			on cz.OwnerEntityID = t.DataTrueChainID  
				and cz.SupplierId = t.DataTrueSupplierID 			
				and cz.OwnerMarketID= ltrim(rtrim(t.CostZoneID))
where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	and Datetimereceived  in 
			(select  MAX(Datetimereceived) 
			 from datatrue_edi.dbo.Temp_PDI_VendorCostZones 
			 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
			) 
	and cz.CostZoneID is Null
			
set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### CostZones were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'COST ZONE ID'+replicate(char(9),2)+'COST ZONE DESC'+char(13)+char(10) 
	
	select @notcalidrecords += rtrim(ltrim(t.CostZoneID))+replicate(char(9),3)
								 +rtrim(ltrim(t.CostZoneDescription))+char(13)+char(10)
	from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] t
			left join [DataTrue_Main].[dbo].[CostZones] cz
				on cz.OwnerEntityID = t.DataTrueChainID  
					and cz.SupplierId = t.DataTrueSupplierID 			
					and cz.OwnerMarketID= ltrim(rtrim(t.CostZoneID))
	where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
		and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.Temp_PDI_VendorCostZones 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				) 
		and cz.CostZoneID is Null
								 
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 


	set  @errormessage = @errormessage + '	### Not all CostZones were loaded. Please see query: 
	select t.*
	from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] t
			left join [DataTrue_Main].[dbo].[CostZones] cz
				on cz.OwnerEntityID = t.DataTrueChainID  
					and cz.SupplierId = t.DataTrueSupplierID 			
					and cz.OwnerMarketID= ltrim(rtrim(t.CostZoneID))
	where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.Temp_PDI_VendorCostZones 
				 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
				) 
		and cz.CostZoneID is Null
	====================================================================	
	
	'
end 

select t.* 
from  datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations t
		left  join DataTrue_Main.dbo.CostZoneRelations czr
			on czr.OwnerEntityID = t.DataTrueChainID  
				and czr.SupplierId = t.DataTrueSupplierID 			
				and czr.StoreID = t.DataTrueStoreID
		left join 	DataTrue_Main.dbo.CostZones cz
			on cz.OwnerEntityID = t.DataTrueChainID  
				and cz.SupplierId = t.DataTrueSupplierID 			
				and cz.OwnerMarketID= ltrim(rtrim(t.CostZoneID))
				and cz.CostZoneID = czr.CostZoneID
where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	 and Datetimereceived  in 
			(select  MAX(Datetimereceived) 
			 from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations 
			 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
			) 	
	and RecordStatus = 0
	and DataTrueStoreID is not null	
	and czr.CostZoneRelationID is Null
			
set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### CostZoneRelations were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'COST ZONE ID'+replicate(char(9),2)+'SITE ID'+char(13)+char(10) 

	select @notcalidrecords += rtrim(ltrim(t.CostZoneID))+replicate(char(9),3)
								 +rtrim(ltrim(t.SiteID))+char(13)+char(10)
	from  datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations t
			left  join DataTrue_Main.dbo.CostZoneRelations czr
				on czr.OwnerEntityID = t.DataTrueChainID  
					and czr.SupplierId = t.DataTrueSupplierID 			
					and czr.StoreID = t.DataTrueStoreID
			left join 	DataTrue_Main.dbo.CostZones cz
				on cz.OwnerEntityID = t.DataTrueChainID  
					and cz.SupplierId = t.DataTrueSupplierID 			
					and cz.OwnerMarketID= ltrim(rtrim(t.CostZoneID))
					and cz.CostZoneID = czr.CostZoneID
	where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
		 and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				) 	
		and RecordStatus = 0
		and DataTrueStoreID is not null	
		and czr.CostZoneRelationID is Null
	
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 
	
	set  @errormessage = @errormessage + '### Not all CostZoneRelations were loaded. Please see query: 
	select t.* 
	from  datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations t
			left  join DataTrue_Main.dbo.CostZoneRelations czr
				on czr.OwnerEntityID = t.DataTrueChainID  
					and czr.SupplierId = t.DataTrueSupplierID 			
					and czr.StoreID = t.DataTrueStoreID
			left join 	DataTrue_Main.dbo.CostZones cz
				on cz.OwnerEntityID = t.DataTrueChainID  
					and cz.SupplierId = t.DataTrueSupplierID 			
					and cz.OwnerMarketID= ltrim(rtrim(t.CostZoneID))
					and cz.CostZoneID = czr.CostZoneID
	where DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		 and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations 
				 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
				) 	
		and RecordStatus = 0
		and DataTrueStoreID is not null	
		and czr.CostZoneRelationID is Null
	====================================================================	
	
	'
end 

--Verify UPC
select   *
from datatrue_edi.dbo.Temp_PDI_UPC
where  DataTrueChainID = @chainid
	and DataTrueSupplierID = @supplierid
    and DateTimeCreated  in 
			(select  MAX(DateTimeCreated) 
			 from datatrue_edi.dbo.Temp_PDI_UPC 
			 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
			)
	and DataTrueProductid is Null  
set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### UPCs were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'UPC'+char(13)+char(10) 

	select @notcalidrecords += rtrim(ltrim(UPCNumber))+char(13)+char(10)
	from datatrue_edi.dbo.Temp_PDI_UPC
	where  DataTrueChainID = @chainid
		and DataTrueSupplierID = @supplierid
		and DateTimeCreated  in 
				(select  MAX(DateTimeCreated) 
				 from datatrue_edi.dbo.Temp_PDI_UPC 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				)
		and DataTrueProductid is Null  
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 

	set  @errormessage = @errormessage + '### Not all UPCs were loaded. Please see query: 
	select   *
	from datatrue_edi.dbo.Temp_PDI_UPC
	where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
		and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		and DateTimeCreated  in 
				(select  MAX(DateTimeCreated) 
				 from datatrue_edi.dbo.Temp_PDI_UPC 
				 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
				)
		and DataTrueProductid is Null  
	====================================================================	
	
	'
end 

--Verify ItmePkg
select  t.*	
from datatrue_edi.dbo.temp_PDI_ItemPKG  t
		left  join  [DataTrue_Main].[dbo].SupplierPackages p
			on  p.ProductID = t.DataTrueProductID
			 and p.SupplierID = t.DataTrueSupplierID
			 and p.OwnerEntityID = t.DataTrueChainID
			 and p.OwnerPackageIdentifier = ltrim(rtrim(t.PackageCode_Scrubbed))
			 and p.OwnerPDIItemNo = ltrim(rtrim(t.PDIItemNumber))
where  DataTrueChainID = @chainid
	and DataTrueSupplierID = @supplierid
	and Datetimereceived  in 
			(select  MAX(Datetimereceived) 
			 from datatrue_edi.dbo.temp_PDI_ItemPKG 
			 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
			) 	
	and p.SupplierPackageID is Null		
set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### ItemPkgs were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'ITEM NUMBER'+replicate(char(9),2)+'PACKAGE CODE'+replicate(char(9),2)+'REASON'+char(13)+char(10)

	select @notcalidrecords += ltrim(rtrim(t.PDIItemNumber))+replicate(char(9),3)
								 +t.PackageCode_Scrubbed+replicate(char(9),3)
								 +case when  c.RecordID is Null then 'Missing Cost Info' else 'Unknown' end
								 +char(13)+char(10)
	from datatrue_edi.dbo.temp_PDI_ItemPKG  t
			left  join  [DataTrue_Main].[dbo].SupplierPackages p
				on  p.ProductID = t.DataTrueProductID
				 and p.SupplierID = t.DataTrueSupplierID
				 and p.OwnerEntityID = t.DataTrueChainID
				 and p.OwnerPackageIdentifier = ltrim(rtrim(t.PackageCode_Scrubbed))
				 and p.OwnerPDIItemNo = ltrim(rtrim(t.PDIItemNumber))
			left join 
			 (
				select RecordID, PDIItemNo,PackageCode_Scrubbed,DiscontinueDate, PromotionEndDate
				from datatrue_edi.dbo.Temp_PDI_Costs
				where DataTrueChainID = @chainid
				and DataTrueSupplierID = @supplierid
				and Datetimereceived  in 
							(select  MAX(Datetimereceived) 
							 from datatrue_edi.dbo.Temp_PDI_Costs
							 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
							) 			 
			 ) c
				on rtrim(ltrim(c.PDIItemNo)) = rtrim(ltrim(t.PDIItemNumber)) 
					and c.PackageCode_Scrubbed = t.PackageCode_Scrubbed
					and t.Purchasable = 'Y'
	where  DataTrueChainID = @chainid
		and DataTrueSupplierID = @supplierid
		and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.temp_PDI_ItemPKG 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				) 	
		and p.SupplierPackageID is Null		


	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 

	set  @errormessage = @errormessage + '### Not all ItemPkgs were loaded. Please see query: 
	select  case when  c.RecordID is Null then ''Missing Cost Info'' else ''Unknown'' end Reason, t.*
	from datatrue_edi.dbo.temp_PDI_ItemPKG  t
			left join 
			 (
				select RecordID, PDIItemNo,PackageCode_Scrubbed,DiscontinueDate, PromotionEndDate
				from datatrue_edi.dbo.Temp_PDI_Costs
				where DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
				and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
				and Datetimereceived  in 
							(select  MAX(Datetimereceived) 
							 from datatrue_edi.dbo.Temp_PDI_Costs
							 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
							) 			 
			 ) c
				on rtrim(ltrim(c.PDIItemNo)) = rtrim(ltrim(t.PDIItemNumber)) 
					and c.PackageCode_Scrubbed = t.PackageCode_Scrubbed
					and t.Purchasable = ''Y''
			left  join  [DataTrue_Main].[dbo].SupplierPackages p
				on  p.ProductID = t.DataTrueProductID
				 and p.SupplierID = t.DataTrueSupplierID
				 and p.OwnerEntityID = t.DataTrueChainID
				 and p.OwnerPackageIdentifier = ltrim(rtrim(t.PackageCode_Scrubbed))
				 and p.OwnerPDIItemNo = ltrim(rtrim(t.PDIItemNumber))
	where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
		and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.temp_PDI_ItemPKG 
				 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
				) 	
		and p.SupplierPackageID is Null		
	====================================================================	
	'
end 



---Verify StoreSetup
select distinct p.RecordID, p.DataTrueProductID, p.DataTrueChainID, p.DataTrueSupplierID, ltrim(rtrim(c.CostZoneID)) CostZoneID,
		st.storeid,
		case when c.PromotionEndDate is Null then 'B'  else 'P' end fl 
into #temp_validation_storesetup 
from datatrue_edi.dbo.temp_PDI_ItemPKG p
  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
	  and ltrim(rtrim(c.PackageCode_Scrubbed)) = ltrim(rtrim(p.PackageCode_Scrubbed))
	  and p.DataTrueChainID = @chainid
	  and p.DataTrueSupplierID = @supplierid
	  and p.DataTrueChainID = c.DataTrueChainID
	  and p.DataTrueSupplierID = c.DataTrueSupplierID
	inner join  ( 
		 select r.storeid, LTRIM(rtrim(cz.OwnerMarketID)) OwnerMarketID
		 from [DataTrue_Main].[dbo].costzones cz
			 inner join datatrue_main.dbo.CostZoneRelations r
				on cz.CostZoneID = r.CostZoneID
					and cz.OwnerEntityID = @chainid
					and cz.SupplierId = @supplierid
				) st 
			on  st.OwnerMarketID = ltrim(rtrim(c.CostZoneID))
where p.DataTrueChainID is not null
  and p.DataTrueSupplierID is not null
  and p.DataTrueProductID is not null
  and c.DiscontinueDate is null
  --and c.PromotionEndDate is null
  and p.Purchasable = 'Y' 
  and p.Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.temp_PDI_ItemPKG 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				) 		
  and c.Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.temp_PDI_Costs 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				 )
				

select  t.*
from (
		select  *
		from #temp_validation_storesetup a
		where fl = 'B'
		union  
		select  *
		from #temp_validation_storesetup b
		where fl = 'P'
			and b.RecordID not  in (select  RecordID from #temp_validation_storesetup a where fl = 'B')
		) t
	left  join  [DataTrue_Main].[dbo].StoreSetup st
		on st.ProductID =  t.DataTrueProductID
			and t.DataTrueChainID = st.ChainID
			and t.DataTrueSupplierID = st.SupplierID
			and t.StoreID = st.StoreID
where   st.StoreSetupID is Null

set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### Relation between UPC, CostZone and Store were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'UPC'+replicate(char(9),2)+'COST ZONE ID'+replicate(char(9),2)+'STORE ID'+char(13)+char(10)

	select @notcalidrecords += ltrim(rtrim(pri.IdentifierValue))+replicate(char(9),2)
									+ltrim(rtrim(t.CostZoneID))+replicate(char(9),2)
								 +cast(t.StoreId as varchar(20))+char(13)+char(10)
	from (
			select  *
			from #temp_validation_storesetup a
			where fl = 'B'
			union  
			select  *
			from #temp_validation_storesetup b
			where fl = 'P'
				and b.RecordID not  in (select  RecordID from #temp_validation_storesetup a where fl = 'B')
			) t
		inner  join ProductIdentifiers pri
			on pri.ProductID = t.DataTrueProductID 
				and pri.ProductIdentifierTypeID = 2
		left  join  [DataTrue_Main].[dbo].StoreSetup st
			on st.ProductID =  t.DataTrueProductID
				and t.DataTrueChainID = st.ChainID
				and t.DataTrueSupplierID = st.SupplierID
				and t.StoreID = st.StoreID
				--and st.StoreID is Null
	where   st.StoreSetupID is Null
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10)
	
	set  @errormessage = @errormessage + '### Not all data was loaded to the StoreSetup table. Please see query:
	IF OBJECT_ID(''tempdb..##temp_valid_storesetup_review_'+cast(@chainid as nvarchar(15))+'_'+cast(@supplierid as nvarchar(15))+''') IS NOT NULL
		drop table ##temp_valid_storesetup_review_'+cast(@chainid as nvarchar(15))+'_'+cast(@supplierid as nvarchar(15))+'


	select distinct p.RecordID, p.DataTrueProductID, p.DataTrueChainID, p.DataTrueSupplierID, ltrim(rtrim(c.CostZoneID)) CostZoneID,
			st.storeid,
			case when c.PromotionEndDate is Null then ''B''  else ''P'' end fl 
	into ##temp_valid_storesetup_review_'+cast(@chainid as nvarchar(15))+'_'+cast(@supplierid as nvarchar(15))+' 
	from datatrue_edi.dbo.temp_PDI_ItemPKG p
	  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs c
	  on ltrim(rtrim(c.PDIItemNo)) = ltrim(rtrim(p.PDIItemNumber))
		  and ltrim(rtrim(c.PackageCode_Scrubbed)) = ltrim(rtrim(p.PackageCode_Scrubbed))
		  and p.DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
		  and p.DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		  and p.DataTrueChainID = c.DataTrueChainID
		  and p.DataTrueSupplierID = c.DataTrueSupplierID
		inner join  ( 
			 select r.storeid, LTRIM(rtrim(cz.OwnerMarketID)) OwnerMarketID
			 from [DataTrue_Main].[dbo].costzones cz
				 inner join datatrue_main.dbo.CostZoneRelations r
					on cz.CostZoneID = r.CostZoneID
						and cz.OwnerEntityID = '+cast(@chainid as nvarchar(15)) +'
						and cz.SupplierId = '+cast(@supplierid as nvarchar(15)) +'
					) st 
				on  st.OwnerMarketID = ltrim(rtrim(c.CostZoneID))
	where p.DataTrueChainID is not null
	  and p.DataTrueSupplierID is not null
	  and p.DataTrueProductID is not null
	  and c.DiscontinueDate is null
	  --and c.PromotionEndDate is null
	  and p.Purchasable = ''Y'' 
	  and p.Datetimereceived  in 
					(select  MAX(Datetimereceived) 
					 from datatrue_edi.dbo.temp_PDI_ItemPKG 
					 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
					) 		
	  and c.Datetimereceived  in 
					(select  MAX(Datetimereceived) 
					 from datatrue_edi.dbo.temp_PDI_Costs 
					 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
					 )
					

	select  t.*
	from (
			select  *
			from ##temp_valid_storesetup_review_'+cast(@chainid as nvarchar(15))+'_'+cast(@supplierid as nvarchar(15))+' a
			where fl = ''B''
			union  
			select  *
			from ##temp_valid_storesetup_review_'+cast(@chainid as nvarchar(15))+'_'+cast(@supplierid as nvarchar(15))+' b
			where fl = ''P''
				and b.RecordID not  in (select  RecordID from ##temp_valid_storesetup_review_'+cast(@chainid as nvarchar(15))+'_'+cast(@supplierid as nvarchar(15))+' a where fl = ''B'')
			) t
		left  join  [DataTrue_Main].[dbo].StoreSetup st
			on st.ProductID =  t.DataTrueProductID
				and t.DataTrueChainID = st.ChainID
				and t.DataTrueSupplierID = st.SupplierID
				and t.StoreID = st.StoreID
	where   st.StoreSetupID is Null

	drop table ##temp_valid_storesetup_review_'+cast(@chainid as nvarchar(15))+'_'+cast(@supplierid as nvarchar(15))+'	
	====================================================================	
	
	'
end 
drop  table #temp_validation_storesetup


--Verify  Manufacturer
select distinct ltrim(rtrim(t.ManufacturerID))
from datatrue_edi.dbo.temp_PDI_ItemPKG t
		left  join  Manufacturers  m 
			on OwnerEntityID = t.DataTrueChainID
				and ltrim(rtrim(t.ManufacturerID)) = m.OwnerManufacturerIdentifier
where  t.DataTrueChainID = @chainid
	and t.DataTrueSupplierID = @supplierid
	and LEN(ltrim(rtrim(t.ManufacturerID))) > 0
	and ltrim(rtrim(t.BrandID)) <> 'Discontinued'
	and ltrim(rtrim(t.ManufacturerID)) <> 'BOTTLE DEPOSIT'
	and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.temp_PDI_ItemPKG 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				) 		
	and m.ManufacturerID is Null

set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### Manufacturers were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'MANUFACTURER ID'+char(13)+char(10)

	select   @notcalidrecords += ltrim(rtrim(ManufacturerID))+char(13)+char(10)
	from ( 
		select distinct ltrim(rtrim(t.ManufacturerID)) ManufacturerID
		from datatrue_edi.dbo.temp_PDI_ItemPKG t
				left  join  Manufacturers  m 
					on OwnerEntityID = t.DataTrueChainID
						and ltrim(rtrim(t.ManufacturerID)) = m.OwnerManufacturerIdentifier
		where  t.DataTrueChainID = @chainid
			and t.DataTrueSupplierID = @supplierid
			and LEN(ltrim(rtrim(t.ManufacturerID))) > 0
			and ltrim(rtrim(t.BrandID)) <> 'Discontinued'
			and ltrim(rtrim(t.ManufacturerID)) <> 'BOTTLE DEPOSIT'
			and Datetimereceived  in 
						(select  MAX(Datetimereceived) 
						 from datatrue_edi.dbo.temp_PDI_ItemPKG 
						 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
						) 		
			and m.ManufacturerID is Null
		) a
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 
	
	set  @errormessage = @errormessage + '### Not all Manufacturers were loaded. Please see query: 
	select distinct ltrim(rtrim(t.ManufacturerID))
	from datatrue_edi.dbo.temp_PDI_ItemPKG t
			left  join  Manufacturers  m 
				on OwnerEntityID = t.DataTrueChainID
					and ltrim(rtrim(t.ManufacturerID)) = m.OwnerManufacturerIdentifier
	where  t.DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
		and t.DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		and LEN(ltrim(rtrim(t.ManufacturerID))) > 0
		and ltrim(rtrim(t.BrandID)) <> ''Discontinued''
		and ltrim(rtrim(t.ManufacturerID)) <> ''BOTTLE DEPOSIT''
		and Datetimereceived  in 
					(select  MAX(Datetimereceived) 
					 from datatrue_edi.dbo.temp_PDI_ItemPKG 
					 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
					) 		
		and m.ManufacturerID is Null
	====================================================================	
	
	'
end 

--Verify  Brands
select distinct ltrim(rtrim(t.Brandid))
from datatrue_edi.dbo.temp_PDI_ItemPKG t
		left  join  Brands  m 
			on OwnerEntityID = t.DataTrueChainID
				and ltrim(rtrim(t.Brandid)) = m.OwnerBrandIdentifier
where  t.DataTrueChainID = @chainid
	and t.DataTrueSupplierID = @supplierid
	and LEN(ltrim(rtrim(t.ManufacturerID))) > 0
	and ltrim(rtrim(t.BrandID)) <> 'Discontinued'
	and LEN(ltrim(rtrim(t.BrandID))) > 0
	and ltrim(rtrim(t.ManufacturerID)) <> 'BOTTLE DEPOSIT'
	and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.temp_PDI_ItemPKG 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				) 		
	and m.brandid is Null

set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### Brands were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'BRAND ID'+char(13)+char(10)

	select   @notcalidrecords += ltrim(rtrim(Brandid))+char(13)+char(10)
	from ( 
		select distinct ltrim(rtrim(t.Brandid)) Brandid
		from datatrue_edi.dbo.temp_PDI_ItemPKG t
				left  join  Brands  m 
					on OwnerEntityID = t.DataTrueChainID
						and ltrim(rtrim(t.Brandid)) = m.OwnerBrandIdentifier
		where  t.DataTrueChainID = @chainid
			and t.DataTrueSupplierID = @supplierid
			and LEN(ltrim(rtrim(t.ManufacturerID))) > 0
			and ltrim(rtrim(t.BrandID)) <> 'Discontinued'
			and LEN(ltrim(rtrim(t.BrandID))) > 0
			and ltrim(rtrim(t.ManufacturerID)) <> 'BOTTLE DEPOSIT'
			and Datetimereceived  in 
						(select  MAX(Datetimereceived) 
						 from datatrue_edi.dbo.temp_PDI_ItemPKG 
						 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
						) 		
			and m.brandid is Null
		) a
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 
	
	set  @errormessage = @errormessage + '### Not all Brands were loaded. Please see query: 
	select distinct ltrim(rtrim(t.Brandid))
	from datatrue_edi.dbo.temp_PDI_ItemPKG t
			left  join  Brands  m 
				on OwnerEntityID = t.DataTrueChainID
					and ltrim(rtrim(t.Brandid)) = m.OwnerBrandIdentifier
	where  t.DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
		and t.DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		and LEN(ltrim(rtrim(t.ManufacturerID))) > 0
		and ltrim(rtrim(t.BrandID)) <> ''Discontinued''
		and LEN(ltrim(rtrim(t.BrandID))) > 0
		and ltrim(rtrim(t.ManufacturerID)) <> ''BOTTLE DEPOSIT''
		and Datetimereceived  in 
					(select  MAX(Datetimereceived) 
					 from datatrue_edi.dbo.temp_PDI_ItemPKG 
					 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
					) 		
		and m.brandid is Null
	====================================================================	
	
	'
end 

--Verify PromoCosts
select t.*
from datatrue_edi.dbo.temp_PDI_Costs t
		left  join  DataTrue_Main.dbo.SupplierPackages sp
			on   sp.SupplierID = t.DataTrueSupplierID
				 and sp.OwnerEntityID = t.DataTrueChainID
				 and ltrim(rtrim(sp.VIN)) = LTRIM(rtrim(t.RawProductIdentifier))
		left  join DataTrue_Main.dbo.ProductPrices pr
			on  pr.SupplierID = t.DataTrueSupplierID
				 and pr.ChainID = t.DataTrueChainID
				 and pr.ProductPriceTypeID = 8 
				 and pr.ActiveStartDate = t.effectivedate 
				 and pr.ActiveLastDate = t.PromotionEndDate
				 and sp.SupplierPackageID = pr.SupplierPackageID
where  t.DataTrueChainID = @chainid
	and t.DataTrueSupplierID = @supplierid
	and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.temp_PDI_Costs 
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				 )
	and t.Promotionenddate is not null
	and pr.ProductPriceID is Null

set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### Promotion Costs were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'VIN'+replicate(char(9),2)+'ITEM NUMBER'+replicate(char(9),2)+'PACKAGE CODE'
									+replicate(char(9),2)+'EFFECTIVE DATE'+char(13)+char(10)
	select @notcalidrecords += ltrim(rtrim(RawProductIdentifier))+replicate(char(9),2)
									+ltrim(rtrim(PDIItemNo))+replicate(char(9),3)
								 +PackageCode_Scrubbed+replicate(char(9),3)
								 +cast(EffectiveDate as varchar(14))+char(13)+char(10)
	from (							 
	select  distinct t.RawProductIdentifier, t.PDIItemNo, 	t.PackageCode_Scrubbed,	t.EffectiveDate					 
	from datatrue_edi.dbo.temp_PDI_Costs t
			left  join  DataTrue_Main.dbo.SupplierPackages sp
				on   sp.SupplierID = t.DataTrueSupplierID
					 and sp.OwnerEntityID = t.DataTrueChainID
					 and ltrim(rtrim(sp.VIN)) =LTRIM(rtrim(t.RawProductIdentifier))
			left  join DataTrue_Main.dbo.ProductPrices pr
				on  pr.SupplierID = t.DataTrueSupplierID
					 and pr.ChainID = t.DataTrueChainID
					 and pr.ProductPriceTypeID = 8 
					 and pr.ActiveStartDate = t.effectivedate 
					 and pr.ActiveLastDate = t.PromotionEndDate
					 and sp.SupplierPackageID = pr.SupplierPackageID
	where  t.DataTrueChainID = @chainid
		and t.DataTrueSupplierID = @supplierid
		and Datetimereceived  in 
					(select  MAX(Datetimereceived) 
					 from datatrue_edi.dbo.temp_PDI_Costs 
					 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
					 )
		and t.Promotionenddate is not null
		and pr.ProductPriceID is Null
	 )a
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 
	
	set  @errormessage = @errormessage + '### Not all Promotion Costs  were loaded. Please see query: 
	select t.*
	from datatrue_edi.dbo.temp_PDI_Costs t
			left  join  DataTrue_Main.dbo.SupplierPackages sp
				on   sp.SupplierID = t.DataTrueSupplierID
					 and sp.OwnerEntityID = t.DataTrueChainID
					 and ltrim(rtrim(sp.VIN)) = LTRIM(rtrim(t.RawProductIdentifier))
			left  join DataTrue_Main.dbo.ProductPrices pr
				on  pr.SupplierID = t.DataTrueSupplierID
					 and pr.ChainID = t.DataTrueChainID
					 and pr.ProductPriceTypeID = 8 
					 and pr.ActiveStartDate = t.effectivedate 
					 and pr.ActiveLastDate = t.PromotionEndDate
					 and sp.SupplierPackageID = pr.SupplierPackageID
	where  t.DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
		and t.DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
		and Datetimereceived  in 
					(select  MAX(Datetimereceived) 
					 from datatrue_edi.dbo.temp_PDI_Costs 
					 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
					 )
		and t.Promotionenddate is not null
		and pr.ProductPriceID is Null
	====================================================================	
	
	'
end 

--Verify Vins
select * 
from datatrue_edi.dbo.Temp_PDI_Costs 
where DataTrueChainID = @chainid
and DataTrueSupplierID = @supplierid
and LTRIM(rtrim(rawproductidentifier)) not in 
(select LTRIM(rtrim(isnull(VIN,''))) from SupplierPackages where OwnerEntityID = @chainid and SupplierID = @supplierid)
	and Datetimereceived  in 
			(select  MAX(Datetimereceived) 
			 from datatrue_edi.dbo.Temp_PDI_Costs
			 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
			) 
set @records_count = @@ROWCOUNT


if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'VINs were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'VIN'+char(13)+char(10)

	select @notcalidrecords += ltrim(rtrim(RawProductIdentifier))+char(13)+char(10)
	from (
	select distinct RawProductIdentifier
	from datatrue_edi.dbo.Temp_PDI_Costs 
	where DataTrueChainID = @chainid
	and DataTrueSupplierID = @supplierid
	and LTRIM(rtrim(rawproductidentifier)) not in 
	(select LTRIM(rtrim(isnull(VIN,''))) from SupplierPackages where OwnerEntityID = @chainid and SupplierID = @supplierid)
		and Datetimereceived  in 
				(select  MAX(Datetimereceived) 
				 from datatrue_edi.dbo.Temp_PDI_Costs
				 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
				) 
	) a
	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 
	
	set  @errormessage = @errormessage + '### Not all VINs were loaded. Please see query: 
	select * 
	from datatrue_edi.dbo.Temp_PDI_Costs 
	where DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
	and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
	and LTRIM(rtrim(rawproductidentifier)) not in 
	(select LTRIM(rtrim(isnull(VIN,''''))) from SupplierPackages where OwnerEntityID = '+cast(@chainid as nvarchar(15)) +' and SupplierID = '+cast(@supplierid as nvarchar(15)) +')
		and Datetimereceived  in 
					(select  MAX(Datetimereceived) 
					 from datatrue_edi.dbo.temp_PDI_Costs 
					 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
					 )

	====================================================================	
	'
end 

--Verify  ItemPkg by  PDIItemNumber
select *
--select  @records_count = COUNT(RecordID)
from datatrue_edi.dbo.Temp_PDI_ItemPkg
where recordstatus = 0
and DataTrueChainID = @chainid
and DataTrueSupplierID = @supplierid
and Datetimereceived  in 
		(select  MAX(Datetimereceived) 
		 from datatrue_edi.dbo.temp_PDI_ItemPKG 
		 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
		) 	

and PDIItemNumber in
(
select PDIItemNumber 
from datatrue_edi.dbo.Temp_PDI_UPC
where DataTrueChainID = @chainid
and DataTrueSupplierID = @supplierid
and DataTrueProductID is not null
)
set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
--remove this validarion  from  external email

	--set @errormessage_extarnal = @errormessage_extarnal +'### ItemPkgs records  remains at recordstatus zero indicating it was not loaded:'+char(13)+char(10)
	--set @notcalidrecords = 'ITEM NUMBER'+replicate(char(9),2)+'PACKAGE CODE'+replicate(char(9),2)+'REASON'+char(13)+char(10)

	--select @notcalidrecords += ltrim(rtrim(t.PDIItemNumber))+replicate(char(9),3)
	--							 +t.PackageCode_Scrubbed+replicate(char(9),3)
	--							 +case when  c.RecordID is Null then 'Missing Cost Info' else 'Unknown' end
	--							 +char(13)+char(10)
	--from datatrue_edi.dbo.Temp_PDI_ItemPkg t
	--		left join 
	--		 (
	--			select RecordID, PDIItemNo,PackageCode_Scrubbed,DiscontinueDate, PromotionEndDate
	--			from datatrue_edi.dbo.Temp_PDI_Costs
	--			where DataTrueChainID = @chainid
	--			and DataTrueSupplierID = @supplierid
	--			and Datetimereceived  in 
	--						(select  MAX(Datetimereceived) 
	--						 from datatrue_edi.dbo.Temp_PDI_Costs
	--						 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	--						) 			 
	--		 ) c
	--			on rtrim(ltrim(c.PDIItemNo)) = rtrim(ltrim(t.PDIItemNumber)) 
	--				and c.PackageCode_Scrubbed = t.PackageCode_Scrubbed
	--				and t.Purchasable = 'Y'
			
			
	--where recordstatus = 0
	--and DataTrueChainID = @chainid
	--and DataTrueSupplierID = @supplierid
	--and Datetimereceived  in 
	--		(select  MAX(Datetimereceived) 
	--		 from datatrue_edi.dbo.temp_PDI_ItemPKG 
	--		 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
	--		) 	

	--and PDIItemNumber in
	--(
	--select PDIItemNumber 
	--from datatrue_edi.dbo.Temp_PDI_UPC
	--where DataTrueChainID = @chainid
	--and DataTrueSupplierID = @supplierid
	--and DataTrueProductID is not null
	--)
	--set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 
	
	set  @errormessage = @errormessage + '### One or more ItemPkgs records  remains at recordstatus zero indicating it was not loaded. Please see query: 
	select case when  c.RecordID is Null then ''Missing Cost Info'' else ''Unknown'' end Reason, t.*
	from datatrue_edi.dbo.Temp_PDI_ItemPkg t 
			left join 
			 (
				select RecordID, PDIItemNo,PackageCode_Scrubbed,DiscontinueDate, PromotionEndDate
				from datatrue_edi.dbo.Temp_PDI_Costs
				where DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
				and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
				and Datetimereceived  in 
							(select  MAX(Datetimereceived) 
							 from datatrue_edi.dbo.Temp_PDI_Costs
							 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
							) 			 
			 ) c
				on rtrim(ltrim(c.PDIItemNo)) = rtrim(ltrim(t.PDIItemNumber)) 
					and c.PackageCode_Scrubbed = t.PackageCode_Scrubbed
					and t.Purchasable = ''Y''
	
	where recordstatus = 0
	and DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
	and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
	and Datetimereceived  in 
			(select  MAX(Datetimereceived) 
			 from datatrue_edi.dbo.temp_PDI_ItemPKG 
			 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
			) 	
	and PDIItemNumber in
	(
	select PDIItemNumber 
	from datatrue_edi.dbo.Temp_PDI_UPC
	where DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
	and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
	and DataTrueProductID is not null
	)
	====================================================================	
	'
end 
-- -- AKotkin : changes by  FogBugz #20785
-- Validation of costs rejected data
select *
from datatrue_edi.dbo.Temp_PDI_Costs
where 1 = 1
and recordstatus < 0
and DataTrueChainID = @chainid
and DataTrueSupplierID = @supplierid
and Datetimereceived  in 
		(select  MAX(Datetimereceived) 
		 from datatrue_edi.dbo.Temp_PDI_Costs 
		 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
		) 	
		
set @records_count = @@ROWCOUNT

if @records_count > 0 
begin
	set @errormessage_extarnal = @errormessage_extarnal +'### Costs were not loaded:'+char(13)+char(10)
	set @notcalidrecords = 'ITEM NUMBER'+replicate(char(9),2)+'PACKAGE CODE'+replicate(char(9),2)+
		'EFFECTIVE DATE'+replicate(char(9),2) + 'DISCONTINUE DATE'+replicate(char(9),2) + 
		'PACKAGE COST'+replicate(char(9),2) + 'REASON'+char(13)+char(10)
		
	select @notcalidrecords += ltrim(rtrim(PDIItemNo))+replicate(char(9),3)
								 +PackageCode_Scrubbed+replicate(char(9),3)
								 +ISNULL(CONVERT(VARCHAR(20), EffectiveDate, 101), 'NULL')+replicate(char(9),3)
								 +ISNULL(CONVERT(VARCHAR(20), DiscontinueDate, 101), 'NULL')+replicate(char(9),3)
								 +ISNULL(CAST(PackageCost AS VARCHAR(20)), 'NULL')+replicate(char(9),3) 
								 +case 
									when  EffectiveDate > DiscontinueDate  then 'EffectiveDate > DiscontinueDate' 
									when PackageCost = 0.0  then 'EffectiveDate > DiscontinueDate'	
									else 'Unknown' end
								 +char(13)+char(10)
	from datatrue_edi.dbo.Temp_PDI_Costs
	where 1 = 1
	and recordstatus < 0
	and DataTrueChainID = @chainid
	and DataTrueSupplierID = @supplierid
	and Datetimereceived  in 
			(select  MAX(Datetimereceived) 
			 from datatrue_edi.dbo.Temp_PDI_Costs 
			 where  DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid
			) 	
			

	set @errormessage_extarnal += @notcalidrecords +char(13)+char(10) 

	set  @errormessage = @errormessage + '### Not all Costs were loaded. Please see query: 
	select  case 
			when  EffectiveDate > DiscontinueDate  then ''EffectiveDate > DiscontinueDate'' 
			when PackageCost = 0.0  then ''EffectiveDate > DiscontinueDate''	
			else ''Unknown'' end, *
	from datatrue_edi.dbo.Temp_PDI_Costs
	where 1 = 1
	and recordstatus < 0
	and DataTrueChainID = '+cast(@chainid as nvarchar(15)) +'
	and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
	and Datetimereceived  in 
			(select  MAX(Datetimereceived) 
			 from datatrue_edi.dbo.Temp_PDI_Costs 
			 where  DataTrueChainID = '+cast(@chainid as nvarchar(15)) +' and DataTrueSupplierID = '+cast(@supplierid as nvarchar(15)) +'
			) 		
	====================================================================	
	'
	
end

SET @errormessage = @testmode + @errormessage

if @errormessage <> ''
begin 
	--print @email_subject
	--print len(@errormessage)
	--print @errormessage
	exec dbo.prSendEmailNotification_PassEmailAddresses @email_subject
		,@errormessage
		--,'DataTrue System', 0, 'ezaslonkin@sphereconsultinginc.com;charlie.clark@icucsolutions.com'
		,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'		
		

		--,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'		
		--,'DataTrue System', 0, 'Eugene.zaslonkin@icucsolutions.com'
	
	--exec dbo.prSendEmailNotification_PassEmailAddresses @email_subject
	--	,@errormessage_extarnal
	--,'DataTrue System', 0,  'datatrueit@icucsolutions.com;edi@icucsolutions.com;dataexchange@profdata.com'
	----,'DataTrue System', 0, 'Eugene.zaslonkin@icucsolutions.com;charlie.clark@icucsolutions.com'
	
	exec dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] @email_subject
		  ,@errormessage_extarnal
		 ,'DataTrue System', 0, 'datatrueit@icucsolutions.com;edi@icucsolutions.com;dataexchange@profdata.com'
		--,'DataTrue System', 0, 'ezaslonkin@sphereconsultinginc.com;charlie.clark@icucsolutions.com'
	
	
end 

return
GO
