USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Load_fab03]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPDI_PriceBook_Master_Load_fab03]
as



declare @recsup cursor
declare @RecordID int
declare @VendorIDinPDIFile nvarchar(50)
declare @VendorDescription nvarchar(500)
declare @VendorName nvarchar(50)
declare @VendorIdentifier nvarchar(50)
declare @myid int=0
declare @entitytypeid smallint
declare @supplierid int
declare @startdate date = '1/1/2013'
declare @enddate date = '12/31/2025'
declare @supplieralreadyexists smallint
declare @chainid int
declare @chainidentfier nvarchar(50)='VOLT'

set @entitytypeid = 5 --supplier
set @recsup = CURSOR local fast_forward FOR
SELECT [RecordID]
      ,ltrim(rtrim([VendorIDinPDIFile]))
      ,ltrim(rtrim([VendorDescription]))
      ,ltrim(rtrim([VendorDescription]))
      --,ltrim(rtrim([VendorName]))
      ,ltrim(rtrim(chainidentifier))
      --select *
  FROM [DataTrue_EDI].[dbo].[Temp_PDI_Vendors]
Where 1 = 1
--and RecordID = 10
and recordstatus = 0
and ltrim(rtrim(ChainIdentifier)) = @chainidentfier

/*

*/

open @recsup

fetch next from @recsup into @recordid, @vendoridentifier, @vendordescription, @vendorname, @chainidentfier

While @@FETCH_STATUS = 0
	begin
	
				select @chainid = chainid from datatrue_main.dbo.chains
				where REPLACE(@chainidentfier, '_PDI', '') = ltrim(rtrim(chainidentifier))
				or REPLACE(@chainidentfier, 'PDI_', '') = ltrim(rtrim(chainidentifier))
				
				set @supplieralreadyexists = 0
				
				--Select @supplieralreadyexists = count(*) 
				--FROM [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] 
				--where [VendorIDinPDIFile] = @VendorIDinPDIFile
				--and recordstatus = 1
				
				Select @supplieralreadyexists = @supplieralreadyexists + count(*) 
				FROM [DataTrue_Main].[dbo].[Suppliers] 
				where ltrim(rtrim(SupplierName)) = ltrim(rtrim(@VendorName))
				
				if @supplieralreadyexists > 0
					begin
					
						Select @supplierid = supplierid
						FROM [DataTrue_Main].[dbo].[Suppliers] 
						where ltrim(rtrim(SupplierName)) = ltrim(rtrim(@VendorName))
				
						update [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] set recordstatus = -1 
						where recordid = @RecordID
					
					end
				else
					begin
					
						INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
						   ([EntityTypeID]
						   ,[LastUpdateUserID])
						VALUES
						   (@entitytypeid
						   ,@MyID)
				           

						set @supplierid = Scope_Identity()
							
						INSERT INTO [DataTrue_Main].[dbo].[Suppliers]
								   ([SupplierID]
								   ,[SupplierName]
								   ,[SupplierIdentifier]
								   ,[SupplierDescription]
								   ,[ActiveStartDate]
								   ,[ActiveLastDate]
								   ,[LastUpdateUserID])
							 VALUES
								   (@supplierid
								   ,@VendorName
								   ,@vendoridentifier --@VendorIDinPDIFile
								   ,@VendorDescription
								   ,@startdate
								   ,@enddate
								   ,@MyID)					


			
						update [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] set recordstatus = 1 
						where recordid = @RecordID
					end 


						INSERT INTO [DataTrue_EDI].[dbo].[TranslationMaster]
							   ([TranslationTypeID]
							   ,[TranslationTradingPartnerIdentifier]
							   ,[TranslationChainID]
							   ,[TranslationSupplierID]
							   ,[TranslationClusterID]
							   ,[TranslationStoreID]
							   ,[TranslationProductID]
							   ,[TranslationTargetColumn]
							   ,[TranslationValueOutside]
							   ,[TranslationColumn1]
							   ,[TranslationCriteria1]
							   ,[ActiveStartDate]
							   ,[ActiveLastDate])
						 VALUES
							   (26 --<TranslationTypeID, int,>
							   ,@chainidentfier --<TranslationTradingPartnerIdentifier, nvarchar(50),>
							   ,@chainid --<TranslationChainID, int,>
							   ,0 --<TranslationSupplierID, int,>
							   ,0 --<TranslationClusterID, int,>
							   ,0 --<TranslationStoreID, int,>
							   ,0 --<TranslationProductID, int,>
							   ,'ALL' --<TranslationTargetColumn, nvarchar(500),>
							   ,@vendoridentifier --<TranslationValueOutside, nvarchar(500),>
							   ,'ALL' --<TranslationColumn1, nvarchar(50),>
							   ,CAST(@supplierid as nvarchar) --<TranslationCriteria1, nvarchar(50),>
							   ,'1/1/2010' --<ActiveStartDate, datetime,>
							   ,'12/31/2099') --<ActiveLastDate, datetime,>)
					
					
					
			fetch next from @recsup into @recordid, @vendoridentifier, @vendordescription, @vendorname, @chainidentfier						
end

close @recsup
deallocate @recsup



update A set a.datatruechainid = c.ChainID
--select a.chainidentifier, c.chainidentifier, * 
from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] a 
--order by datetimereceived
--where 1 = 1                                           
inner join chains c
on LTRIM(rtrim(a.ChainIdentifier)) = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null


update A set a.datatruesupplierid = cast(TranslationCriteria1 as int)
--select *
--select distinct chainidentifier, a.vendoridinpdifile,  cast(TranslationCriteria1 as int)
from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] a
inner join  [DataTrue_EDI].[dbo].[TranslationMaster] t
on ltrim(rtrim(a.vendoridinpdifile)) = LTRIM(rtrim(TranslationValueOutside))
and datatruesupplierid is null
--and ChainIdentifier in ('MILE','MTN','ROCK', 'VOLT')

update A set a.datatruechainid = c.ChainID
--select a.chainidentifier, c.chainidentifier, * 
from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a 
--order by datetimereceived
--where 1 = 1                                           
inner join chains c
on LTRIM(rtrim(a.ChainIdentifier)) = LTRIM(rtrim(c.ChainIdentifier))
and a.DatatrueChainid is null

update A set a.datatruestoreid = s.storeid
--select * 
from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a
inner join stores s
on cast(a.siteid as int) = CAST(s.storeidentifier as int)
and a.datatruechainid = s.chainid 
and a.datatruestoreid is null

update A set a.datatruesupplierid = cast(TranslationCriteria1 as int)
--select *
--select distinct chainidentifier, VendorID,  cast(TranslationCriteria1 as int)
from datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations a
inner join  [DataTrue_EDI].[dbo].[TranslationMaster] t
on ltrim(rtrim(a.vendorid)) = LTRIM(rtrim(TranslationValueOutside))
and datatruesupplierid is null
--and ChainIdentifier in ('MILE','MTN','ROCK', 'VOLT')
 
 

 declare @reccostzones cursor
 declare @ownermarketid nvarchar(50)
 declare @costzoneid int
 declare @costzonedesc nvarchar(255)
 --declare @supplierid int --= 62314
 --declare @chainid int --= 44285
 --declare @recordid int
 
 set @reccostzones = CURSOR local fast_forward FOR
	select RecordID, datatruechainid, datatruesupplierid, ltrim(rtrim(CostZoneID)), ltrim(rtrim(CostZoneDescription))
	--select *
	from  [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones]
	where 1 = 1
	and costzoneid <> '0'
	and RecordStatus = 0
	and isnumeric(CostZoneID)>0
	--and ChainIdentifier in ('MILE','MTN','ROCK', 'VOLT')
	order by datatruechainid, datatruesupplierid, cast(ltrim(rtrim(CostZoneID)) as int)
	
 open @reccostzones
 
 fetch next from @reccostzones into @recordid, @chainid, @supplierid, @ownermarketid,  @costzonedesc
 
 while @@FETCH_STATUS = 0
	begin


--select * from costzones	
		select @costzoneid = costzoneid
		from [DataTrue_Main].[dbo].CostZones
		where OwnerEntityID = @chainid
		and OwnerMarketID = @ownermarketid
		and SupplierId = @supplierid
		
		if @@ROWCOUNT < 1
			begin
	
				INSERT INTO [DataTrue_Main].[dbo].[CostZones]
						   ([CostZoneName]
						   ,[CostZoneDescription]
						   ,[SupplierId]
						   ,[OwnerEntityID]
						   ,[OwnerMarketID])
					 VALUES
						   (@costzonedesc --<CostZoneName, nvarchar(50),>
						   ,@costzonedesc --<CostZoneDescription, nvarchar(255),>
						   ,@supplierid
						   ,@chainid --<OwnerEntityID, int,>
						   ,@ownermarketid) --<OwnerMarketID, nvarchar(50),>)
						   
				set @costzoneid = SCOPE_IDENTITY()
				

				INSERT INTO [DataTrue_Main].[dbo].[CostZoneRelations]
						   ([StoreID]
						   ,[SupplierID]
						   ,[CostZoneID]
						   ,[OwnerEntityID])
					select datatruestoreid, datatrueSupplierid, @costzoneid, datatruechainid
					from  datatrue_edi.dbo.Temp_PDI_VendorSiteAuthorizations
					where 1 = 1
					and datatruechainid = @chainid
					and DataTrueSupplierID = @supplierid
					and LTRIM(rtrim(costzoneid)) = @ownermarketid
			end

			update z set z.recordstatus = 1
			from [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones] z
			where z.recordid = @recordid

--select * from [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones]
--select * from suppliers order by supplierid desc	
--select * from [DataTrue_EDI].dbo.Temp_PDI_VendorSiteAuthorizations	
		fetch next from @reccostzones into @recordid, @chainid, @supplierid, @ownermarketid,  @costzonedesc	
	end
	
close @reccostzones
deallocate @reccostzones
 


select *
from ProductIdentifiers
where 1 = 1
	and CHARINDEX('64480200001', identifiervalue) > 0

	select *
	--update u set datatrueproductid = i.productid
	FROM [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
	inner join productidentifiers i
	on ltrim(rtrim(upc12)) = ltrim(rtrim(i.identifiervalue))
	and ProductIdentifierTypeID = 8
	and LEN(LTRIM(rtrim(upc12))) = 12
	and ChainIdentifier in ('VOLT')

	select *
	--update u set datatrueproductid = i.productid
	FROM [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
	inner join productidentifiers i
	on ltrim(rtrim(upc12)) = ltrim(rtrim(i.identifiervalue))
	and ProductIdentifierTypeID = 2
	and LEN(LTRIM(rtrim(upc12))) = 12
	and ChainIdentifier in ('VOLT')
	and datatrueproductid is null

	select * 
--update u set u.datatruesupplierid = v.datatruesupplierid
from datatrue_edi.dbo.Temp_PDI_Vendors v
inner join [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
on v.ChainIdentifier = u.ChainIdentifier
and v.VendorName = u.VendorName


return
GO
