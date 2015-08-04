USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Load]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPDI_PriceBook_Load]
as




--Supplier Inserts

/*
select * from datatrue_edi.dbo.Temp_PDI_Vendors
*/

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
declare @chainidentfier nvarchar(50)

set @entitytypeid = 5 --supplier
set @recsup = CURSOR local fast_forward FOR
SELECT [RecordID]
      ,ltrim(rtrim([VendorIDinPDIFile]))
      ,ltrim(rtrim([VendorDescription]))
      ,ltrim(rtrim([VendorName]))
      ,ltrim(rtrim(chainidentifier))
  FROM [DataTrue_EDI].[dbo].[Temp_PDI_Vendors]
Where recordstatus = 0


open @recsup

fetch next from @recsup into @recordid, @vendoridentifier, @vendordescription, @vendorname, @chainidentfier

While @@FETCH_STATUS = 0
	begin
	
				select @chainid = chainid from datatrue_main.dbo.chains
				where REPLACE(@chainidentfier, '_PDI', '') = ltrim(rtrim(chainidentifier))
				or REPLACE(@chainidentfier, 'PDI_', '') = ltrim(rtrim(chainidentifier))
				
				set @supplieralreadyexists = 0
				
				Select @supplieralreadyexists = count(*) 
				FROM [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] 
				where [VendorIDinPDIFile] = @VendorIDinPDIFile
				and recordstatus = 1
				
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
								   ,@VendorIDinPDIFile
								   ,@VendorDescription
								   ,@startdate
								   ,@enddate
								   ,@MyID)					

--set up translation
						

--Type 26  = PDI_SupplierIdentifierForOnePDIChaintoDataTrueSupplierID

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
							   
						--INSERT INTO [DataTrue_EDI].[dbo].[TranslationMaster]
						--	   ([TranslationTypeID]
						--	   ,[TranslationTradingPartnerIdentifier]
						--	   ,[TranslationChainID]
						--	   ,[TranslationSupplierID]
						--	   ,[TranslationClusterID]
						--	   ,[TranslationStoreID]
						--	   ,[TranslationProductID]
						--	   ,[TranslationTargetColumn]
						--	   ,[TranslationValueOutside]
						--	   ,[TranslationColumn1]
						--	   ,[TranslationCriteria1]
						--	   ,[ActiveStartDate]
						--	   ,[ActiveLastDate])
						-- VALUES
						--	   (26 --<TranslationTypeID, int,>
						--	   ,@chainidentfier --<TranslationTradingPartnerIdentifier, nvarchar(50),>
						--	   ,@chainid --<TranslationChainID, int,>
						--	   ,0 --<TranslationSupplierID, int,>
						--	   ,0 --<TranslationClusterID, int,>
						--	   ,0 --<TranslationStoreID, int,>
						--	   ,0 --<TranslationProductID, int,>
						--	   ,'ALL' --<TranslationTargetColumn, nvarchar(500),>
						--	   ,@vendorname --<TranslationValueOutside, nvarchar(500),>
						--	   ,'ALL' --<TranslationColumn1, nvarchar(50),>
						--	   ,CAST(@supplierid as nvarchar) --<TranslationCriteria1, nvarchar(50),>
						--	   ,'1/1/2010' --<ActiveStartDate, datetime,>
						--	   ,'12/31/2099') --<ActiveLastDate, datetime,>)

			
						update [DataTrue_EDI].[dbo].[Temp_PDI_Vendors] set recordstatus = 1 
						where recordid = @RecordID
					end 


--INSERT INTO [DataTrue_Main].[dbo].[CostZones]
--           ([CostZoneName]
--           ,[CostZoneDescription]
--           ,[SupplierId])
--     VALUES
--           (<CostZoneName, nvarchar(50),>
--           ,<CostZoneDescription, nvarchar(255),>
--           ,<SupplierId, int,>)
--GO

					
--SELECT [RecordID]
--      ,[VendorIDinPDIFile]
--      ,[CostZoneID]
--      ,[CostZoneDescription]
--      ,[VendorName]
--      ,[VendorIdentifier]
--      ,[FileName]
--      ,[DateTimeReceived]
--      ,[RecordStatus]
--  FROM [DataTrue_EDI].[dbo].[Temp_PDI_VendorCostZones]
--GO

					
					
					
			fetch next from @recsup into @recordid, @vendoridentifier, @vendordescription, @vendorname, @chainidentfier						
end

/*
--Product inserts
select * from datatrue_edi.dbo.Temp_PDI_UPC where pdiitemnumber = 10257
select * from datatrue_edi.dbo.Temp_PID_SitesUPCsVINs where pdiitemnumber = 10257               
*/

declare @recprd cursor
declare @upc nvarchar(50)
declare @vin nvarchar(50)
declare @productid int
declare @productname nvarchar(255)
declare @productdescription nvarchar(500)
declare @packagecode nvarchar(20)
declare @packageqty nvarchar(50)
declare @sellUOMUnits nvarchar(50)
declare @productalreadyexists smallint
declare @pdiitemno nvarchar(50)
declare @vendorname2 nvarchar(50)
declare @basecost money
declare @retail money
declare @costeffectivedate date

select Distinct s.PDIItemNo, s.RawProductIdentifier, u.[RecordID]
      ,u.[UPCNumber]
      ,u.[LongDescription]
      ,u.[ShortDescription]
      ,u.[PackageCode]
      ,u.[PackageQuantity]
      ,u.[SellUOMUnits]
      ,u.chainidentifier
      ,s.vendorIdentifier
into #tempProds --drop table #tempProds select * from #tempProds
--select u.*, s.*
  FROM [DataTrue_EDI].[dbo].[Temp_PDI_UPC] u
  inner join [DataTrue_EDI].dbo.Temp_PDI_Costs s
  on u.PDIItemNumber = s.PDIItemNo
Where u.recordstatus = 0
and LEN(ltrim(rtrim(u.[UPCNumber]))) = 11

select * from #tempProds

set @recprd = CURSOR local fast_forward FOR
SELECT ltrim(rtrim(PDIItemNo)), ltrim(rtrim([RawProductIdentifier])), [RecordID]
      ,ltrim(rtrim([UPCNumber]))
      ,ltrim(rtrim([LongDescription]))
      ,ltrim(rtrim([ShortDescription]))
      ,ltrim(rtrim([PackageCode]))
      ,replace([PackageQuantity], '''', '')
      ,ltrim(rtrim([SellUOMUnits]))
      ,ltrim(rtrim(chainidentifier))
      ,ltrim(rtrim(vendoridentifier))
  FROM #tempProds

open @recprd

fetch next from @recprd into @pdiitemno, @vin, @recordid, @upc, @productdescription, @productname, @packagecode, @packageqty, @sellUOMUnits, @chainidentfier, @vendorname2

While @@FETCH_STATUS = 0
	begin
--select top 100 * from suppliers order by supplierid desc	
				select @supplierid = supplierid
				from datatrue_main.dbo.Suppliers
				where LTRIM(rtrim(suppliername)) = @vendorname2
				
				select @chainid from datatrue_main.dbo.ChainS
				where LTRIM(rtrim(chainidentifier)) = @chainidentfier
				
				set @chainid = 44285
				
				set @productalreadyexists = 0
			
				if len(@upc) = 10 
					begin
						set @upc = '00' + @upc
					end
				if len(@upc) = 11 
					begin
						set @upc = '0' + @upc
					end
					
				Select @productalreadyexists = count(*) 
				FROM [DataTrue_Main].[dbo].[ProductIdentifiers] 
				where identifiervalue = @upc
				and ProductIdentifierTypeID = 2
				and LEN(ltrim(rtrim(identifiervalue))) = 12
begin Transaction				
				if @productalreadyexists > 0 or LEN(@upc) <> 12
					begin
					
						update [DataTrue_EDI].[dbo].[Temp_PDI_UPC] set recordstatus = -1 
						where recordid = @RecordID
					
					end
				else
					begin
	
--select * from datatrue_edi.dbo.Temp_PDI_UPC
						INSERT INTO [DataTrue_Main].[dbo].[Products]
								   ([ProductName]
								   ,[Description]
								   ,[ActiveStartDate]
								   ,[ActiveLastDate]
								   ,[LastUpdateUserID]
								   ,[UOM]
								   ,[UOMQty])
						Values(@productname, @productdescription, '1/1/2013', '12/31/2025', 0, @packagecode, @packageqty)

						set @productid = SCOPE_IDENTITY()
						
						INSERT INTO [DataTrue_Main].[dbo].[ProductIdentifiers]
							   ([ProductID]
							   ,[ProductIdentifierTypeID]
							   ,[OwnerEntityId]
							   ,[IdentifierValue]
							   ,[LastUpdateUserID])
						 VALUES
							   (@productid
							   ,2 --<ProductIdentifierTypeID, int,>
							   ,0 --<OwnerEntityId, int,>
							   ,@upc --<IdentifierValue, nvarchar(20),>
							   ,0) --<LastUpdateUserID, nvarchar(20),>)

						INSERT INTO [DataTrue_Main].[dbo].[ProductIdentifiers]
							   ([ProductID]
							   ,[ProductIdentifierTypeID]
							   ,[OwnerEntityId]
							   ,[IdentifierValue]
							   ,[LastUpdateUserID])
						 VALUES
							   (@productid
							   ,3 --VIN <ProductIdentifierTypeID, int,>
							   ,0 --<OwnerEntityId, int,>
							   ,@vin --<IdentifierValue, nvarchar(20),>
							   ,0) --<LastUpdateUserID, nvarchar(20),>)
					
					INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]
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
						 select ChainID
							   ,StoreID
							   ,@productid
							   ,@supplierid --<SupplierID, int,>
							   ,0 --<BrandID, int,>
							   ,0 --<InventoryRuleID, int,>
							   ,'1/1/2013' --<ActiveStartDate, datetime,>
							   ,'12/31/2099' --<ActiveLastDate, datetime,>
							   ,0 --<LastUpdateUserID, nvarchar(50),>
							   ,1 --<PDIParticipant, bit,>)
						 from datatrue_main.dbo.stores
						 where ChainID = @chainid	
						 
						 
						 --update dbo.Temp_PDI_Costs set chainidentifier = 'CTM'
						  --update dbo.Temp_PDI_Retail set chainidentifier = 'CTM'
						 --select * from dbo.Temp_PDI_Costs
						 
						 --select * from dbo.Temp_PDI_Retail
						 
						 select @basecost = packagecost, @costeffectivedate = EffectiveDate
						 from datatrue_edi.dbo.Temp_PDI_Costs
						 where ltrim(rtrim(PDIItemNo)) = @pdiitemno
						 and ltrim(rtrim(ChainIdentifier)) = @chainidentfier
						 and PromotionEndDate is null		
						 
						 select @retail = GrossPrice
						 from datatrue_edi.dbo.Temp_PDI_Retail
						 where ltrim(rtrim(PDIItemNo)) = @pdiitemno
						 and ltrim(rtrim(ChainIdentifier)) = @chainidentfier				
					
						INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
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
						   ,[LastUpdateUserID])
					Select  3 --<ProductPriceTypeID, int,>
						   ,@productID
						   ,@chainid
						   ,StoreID
						   ,0 --<BrandID, int,>
						   ,@supplierid
						   ,@basecost
						   ,@retail
						   ,0 --<PricePriority, smallint,>
						   ,@costeffectivedate
						   ,'12/31/2099'
						   ,0 --<LastUpdateUserID, nvarchar(50),>
						 from datatrue_main.dbo.stores
						 where ChainID = @chainid	
					
						update [DataTrue_EDI].[dbo].[Temp_PDI_UPC] set recordstatus = 1 
						where recordid = @RecordID
commit transaction						
					end 

			fetch next from @recprd into @pdiitemno, @vin, @recordid, @upc, @productdescription, @productname, @packagecode, @packageqty, @sellUOMUnits, @chainidentfier, @vendorname2
			
end


--Item Groups



select cast(grouplevel as int) as grouplevel, cast(groupid as int) as groupid, vendorname, groupdescription as categoryidentifier, cast(ParentGroupID as int) as ParentGroupID,
CAST(null as nvarchar(255)) as parentcategoryidentifier
into #tempcategories --drop table #tempcategories
--select *
from datatrue_edi.dbo.Temp_PDI_ItemGrp
where recordstatus = 0
and vendorname = 'FritoLay'
--and GroupLevel = 1
order by cast(grouplevel as int), cast(groupid as int)
--and groupid = 4

--select * from #tempcategories order by cast(grouplevel as int), cast(groupid as int)

update t set t.parentcategoryidentifier = g.GroupDescription
--select *
from #tempcategories t
inner join datatrue_edi.dbo.Temp_PDI_ItemGrp g
on t.ParentGroupID = g.groupid
and g.vendorname = t.vendorname
and g.GroupLevel = 1
and t.grouplevel = 2


update t set t.parentcategoryidentifier = g.GroupDescription
--select *
from #tempcategories t
inner join datatrue_edi.dbo.Temp_PDI_ItemGrp g
on t.ParentGroupID = g.groupid
and g.vendorname = t.vendorname
and g.GroupLevel = 2
and t.grouplevel = 3

INSERT INTO [DataTrue_EDI].[dbo].[Load_ProductCategories]
           ([OwnerIdentifier]
           ,[OwnerEntityTypeID]
           ,[CategoryIdentifier]
           ,[CategoryParentIdentifier]
           ,[CategoryDescription]
           ,[LoadStatus]
           ,[Order]
           ,[GroupLevelID]
           ,[GroupID])
select vendorname, 5, categoryidentifier, parentcategoryidentifier, categoryidentifier, 0, grouplevel, grouplevel, groupid 
--select * 
from #tempcategories
order by cast(grouplevel as int), cast(groupid as int)






/*
select * from datatrue_main.dbo.chains where chainidentifier = 'CTM'

select * from datatrue_edi.dbo.Temp_PDI_Costs

select * from datatrue_edi.dbo.Temp_PDI_ItemGrp

select * from datatrue_edi.dbo.temp_PDI_ItemPKG

select * from datatrue_edi.dbo.Temp_PDI_Retail

select * from datatrue_edi.dbo.Temp_PDI_UPC --where len(UPCNumber) = 12

select p.*, u.*
--update p set p.Description = u.LongDescription, p.ProductName = u.ShortDescription
from datatrue_edi.dbo.Temp_PDI_UPC u
inner join ProductIdentifiers i
on LTRIM(rtrim(UPCNumber)) = right(identifiervalue, 11)
inner join Products p
on i.ProductID = p.ProductID

select *
from Products
order by productid desc

select *
from InvoicesRetailer
order by RetailerInvoiceID desc

select * from datatrue_edi.dbo.Temp_PDI_VendorCostZones


select * from datatrue_edi.dbo.Temp_PDI_Vendors

select * from Suppliers order by SupplierID desc

*/
GO
