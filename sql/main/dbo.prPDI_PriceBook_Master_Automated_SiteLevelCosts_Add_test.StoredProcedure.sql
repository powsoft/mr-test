USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_SiteLevelCosts_Add_test]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPDI_PriceBook_Master_Automated_SiteLevelCosts_Add_test]
@chainid int=null,
@supplierid int=null

as

--declare @chainid int = 65726 declare @supplierid int = 74767
--declare @chainid int = 75217 declare @supplierid int = 79416
declare @MyID int=0
declare @mostrecentfiledate date
declare @errormessage nvarchar(1000)

select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.temp_PDI_ItemPKG where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid

declare @recprd cursor
declare @pdiitemno varchar(50)
declare @vin varchar(50)
declare @vendorname2 varchar(50)
declare @packagecode varchar(50)
declare @ownermarketid varchar(50)
declare @productdescription varchar(255)
declare @productid int
declare @basecost money
declare @retail money
declare @costeffectivedate date
declare @packageqty nvarchar(50)
declare @recordid int
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
--declare @costzonetouse nvarchar(10)
declare @siteid varchar(50)
declare @storeid int
declare @startdate date
declare @enddate date
declare @rowcount int


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
      ,ltrim(rtrim(storeID)) as StoreID
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
  and c.DiscontinueDate is null
  and c.PromotionEndDate is null
  and p.Purchasable = 'Y' 
  and LEN(ltrim(rtrim(c.storeid))) > 0
  and CAST(p.datetimereceived as date) = @mostrecentfiledate
  and CAST(c.datetimereceived as date) = @mostrecentfiledate
 and p.PDIItemNumber in ('16658')
  and c.RawProductIdentifier = '80201'
 
  
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
      ,ltrim(rtrim(storeID)) as StoreID
into #tempProds_3 --drop table #tempProds_3 select * from #tempProds
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
  and c.DiscontinueDate is null
  and c.PromotionEndDate is null
  and p.Purchasable = 'Y' 
  and LEN(ltrim(rtrim(c.storeid))) > 0
  and CAST(p.datetimereceived as date) = @mostrecentfiledate
  and CAST(c.datetimereceived as date) = @mostrecentfiledate
and p.PDIItemNumber in ('16658')
  and c.RawProductIdentifier = '80201'

set @recprd = CURSOR local fast_forward FOR
SELECT ltrim(rtrim(PDIItemNo)), ltrim(rtrim([RawProductIdentifier])), [RecordID]
      ,ltrim(rtrim([vendorIdentifier]))
      ,ltrim(rtrim([PackageCode_Scrubbed]))
      ,replace([PackageQty], '''', '')
      ,LTRIM(rtrim(costzoneid))
      ,PackageCost
      ,effectivedate
      ,LTRIM(rtrim(itemdescription))
      ,case when LTRIM(rtrim(Purchasable)) = 'Y' then 1 else 0 end
      ,case when LTRIM(rtrim(Sellable)) = 'Y' then 1 else 0 end
      ,LTRIM(rtrim(sizedescription))
      ,DataTrueChainID
      ,DataTrueSupplierID
      ,DataTrueProductID
      ,case when LTRIM(rtrim(Reclaimable)) = 'Y' then 1 else 0 end
      ,case when LTRIM(rtrim(AllowPartialPack)) = 'Y' then 1 else 0 end
      ,case when LTRIM(rtrim(Orderable)) = 'Y' then 1 else 0 end
      ,PromoCostOnly
      ,PromotionEndDate
      ,StoreID
  FROM #tempProds_3
  where 1 = 1 --and ltrim(rtrim(CostZoneID)) = @costzonetouse
  order by ltrim(rtrim([PDIItemNo])), PackageCode_Scrubbed, cast(effectivedate as date), PackageCost 
  
  --select *   FROM #tempProds_3

open @recprd


fetch next from @recprd into @pdiitemno, @vin, @recordid, 
@vendorname2, @packagecode, 
@packageqty, @ownermarketid, @basecost, @costeffectivedate, @productdescription,
@purchaseable, @sellable, @sizedescription, @chainid, @supplierid, @productid, @Reclaimable, @AllowPartialPack,@Orderable	
,@PromoCostOnly, @CursorProductPriceEndDate, @siteid

While @@FETCH_STATUS = 0
	begin
	
		print 'VIN = ' + @vin
		print 'ItemNo = ' +  @pdiitemno
		print 'ProdiD = ' +  cast(@productid as varchar(50))

		set @supplierpackageid = null
		
		select @supplierpackageid = supplierpackageid
		from SupplierPackages
		where OwnerEntityID = @chainid
		and SupplierID = @supplierid
		and ProductID = @productid
		and LTRIM(rtrim(vin)) = @vin
		
		print 'SupplierPack = ' +  cast(@supplierpackageid as varchar(50)) 

	
		set @storeid = null 
		
		Select @storeid = storeid from stores where ChainID = @chainid and LTRIM(rtrim(custom2)) = @siteid
		
		set @rowcount = 0
		

		select @rowcount = COUNT(*)
		from ProductPrices
		where 1 = 1
		and StoreID = @storeid
		and ProductID = @productid
		and UnitPrice = @basecost
		and ProductPriceTypeID in (3,11) 
		and SupplierPackageID = @supplierpackageid
		
		print 'rowcount' + cast(@rowcount as varchar(50)) 
		
		--select *
		--from ProductPrices
		--where 1 = 1
		--and StoreID = @storeid
		--and ProductID = @productid
		--and ProductPriceTypeID in (3,11) 
		--and SupplierPackageID = @supplierpackageid
		
		If isnull(@rowcount, 0) < 1
			begin
				select *
				from ProductPrices
				where 1 = 1
				and StoreID = @storeid
				and ProductID = @productid
				and ProductPriceTypeID in (3,11)
				
				
				if @@ROWCOUNT > 0
				begin
					print 'ISSUE'
					
					set @rowcount = 1
					
					set @errormessage = 'A Site-Only Cost for Chainid/SupplierID ' + CAST(@chainid as varchar) + '/' + CAST(@chainid as varchar) + ' has failed to load'
					
				--	exec dbo.prSendEmailNotification_PassEmailAddresses 'PDI PriceBook Import Issue Detected - Site-Only Cost Not Loaded'
				--		,@errormessage
				--		,'DataTrue System', 0, 'ezaslonkin@sphereconsultinginc.com'						
					
				end
			end
		
		print 'OK'
		If isnull(@rowcount, 0) < 1	and @supplierpackageid is not null and @storeid is not null and @productid is not null	
			begin
			Print 'IF insert'
			
				--INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
				--		   ([ProductPriceTypeID]
				--		   ,[ProductID]
				--		   ,[ChainID]
				--		   ,[StoreID]
				--		   ,[BrandID]
				--		   ,[SupplierID]
				--		   ,[UnitPrice]
				--		   ,[UnitRetail]
				--		   ,[PricePriority]
				--		   ,[ActiveStartDate]
				--		   ,[ActiveLastDate]
				--		   ,[PriceReportedToRetailerDate]
				--		   ,[DateTimeCreated]
				--		   ,[LastUpdateUserID]
				--		   ,[DateTimeLastUpdate]
				--		   ,[BaseCost]
				--		   ,[Allowance]
				--		   ,[NewActiveStartDateNeeded]
				--		   ,[NewActiveLastDateNeeded]
				--		   ,[OldStartDate]
				--		   ,[OldEndDate]
				--		   ,[TradingPartnerPromotionIdentifier]
				--		   ,[SupplierPackageID]
				--		   ,[IncludeInAdjustments]
				--		   ,[CostPlusPercentOfRetail])
				--		values(
					select	11 --[ProductPriceTypeID]
						   ,@productid --[ProductID]
						   ,@chainid --[ChainID]
						   ,@storeid --[StoreID]
						   ,0 --[BrandID]
						   ,@supplierid --[SupplierID]
						   ,@basecost --[UnitPrice]
						   ,0 --[UnitRetail]
						   ,0 --[PricePriority]
						   ,@costeffectivedate --[ActiveStartDate]
						   ,'12/31/2099' --[ActiveLastDate]
						   ,null --[PriceReportedToRetailerDate]
						   ,getdate() --[DateTimeCreated]
						   ,@MyID --[LastUpdateUserID]
						   ,getdate() --[DateTimeLastUpdate]
						   ,@basecost --[BaseCost]
						   ,null --[Allowance]
						   ,null --[NewActiveStartDateNeeded]
						   ,null --[NewActiveLastDateNeeded]
						   ,null --[OldStartDate]
						   ,null --[OldEndDate]
						   ,null --[TradingPartnerPromotionIdentifier]
						   ,@supplierpackageid --[SupplierPackageID_New]
						   ,0 --[IncludeInAdjustments]
						   ,null
					--) --[CostPlusPercentOfRetail])
					
					
					
			print 'After SupplierPack = ' +  cast(@supplierpackageid as varchar(50)) 
						   
						   
				If @sellable = 1
					begin
					
			
						--INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
						--		   ([ProductPriceTypeID]
						--		   ,[ProductID]
						--		   ,[ChainID]
						--		   ,[StoreID]
						--		   ,[BrandID]
						--		   ,[SupplierID]
						--		   ,[UnitPrice]
						--		   ,[UnitRetail]
						--		   ,[PricePriority]
						--		   ,[ActiveStartDate]
						--		   ,[ActiveLastDate]
						--		   ,[PriceReportedToRetailerDate]
						--		   ,[DateTimeCreated]
						--		   ,[LastUpdateUserID]
						--		   ,[DateTimeLastUpdate]
						--		   ,[BaseCost]
						--		   ,[Allowance]
						--		   ,[NewActiveStartDateNeeded]
						--		   ,[NewActiveLastDateNeeded]
						--		   ,[OldStartDate]
						--		   ,[OldEndDate]
						--		   ,[TradingPartnerPromotionIdentifier]
						--		   ,[SupplierPackageID]
						--		   ,[IncludeInAdjustments]
						--		   ,[CostPlusPercentOfRetail])
						--		values(
						select		3 --[ProductPriceTypeID]
								   ,@productid --[ProductID]
								   ,@chainid --[ChainID]
								   ,@storeid --[StoreID]
								   ,0 --[BrandID]
								   ,@supplierid --[SupplierID]
								   ,@basecost --[UnitPrice]
								   ,0 --[UnitRetail]
								   ,0 --[PricePriority]
								   ,@costeffectivedate --[ActiveStartDate]
								   ,'12/31/2099' --[ActiveLastDate]
								   ,null --[PriceReportedToRetailerDate]
								   ,getdate() --[DateTimeCreated]
								   ,@MyID --[LastUpdateUserID]
								   ,getdate() --[DateTimeLastUpdate]
								   ,@basecost --[BaseCost]
								   ,null --[Allowance]
								   ,null --[NewActiveStartDateNeeded]
								   ,null --[NewActiveLastDateNeeded]
								   ,null --[OldStartDate]
								   ,null --[OldEndDate]
								   ,null --[TradingPartnerPromotionIdentifier]
								   ,@supplierpackageid --[SupplierPackageID]
								   ,0 --[IncludeInAdjustments]
								   ,null
								   --) --[CostPlusPercentOfRetail])					
					

					
					
					end
							--select *
							--from ProductPrices
							--where 1 = 1
							--and StoreID = @storeid
							--and ProductID = @productid
							--and ProductPriceTypeID in (3,11) and SupplierPackageID = @supplierpackageid			
			end
	
		fetch next from @recprd into @pdiitemno, @vin, @recordid, 
		@vendorname2, @packagecode, 
		@packageqty, @ownermarketid, @basecost, @costeffectivedate, @productdescription,
		@purchaseable, @sellable, @sizedescription, @chainid, @supplierid, @productid, @Reclaimable, @AllowPartialPack,@Orderable	
		,@PromoCostOnly, @CursorProductPriceEndDate, @siteid
	end
	
close @recprd
deallocate @recprd

drop table #tempProds_3
GO
