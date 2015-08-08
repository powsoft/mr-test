USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_SiteLevelCosts_Add_PendingDeployment_20150102_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPDI_PriceBook_Master_Automated_SiteLevelCosts_Add_PendingDeployment_20150102_PRESYNC_20150329]
@chainid int=null,
@supplierid int=null

as

--declare @chainid int = 65726 declare @supplierid int = 74767
--declare @chainid int = 75217 declare @supplierid int = 79416
declare @MyID int=0
declare @mostrecentfiledate date
declare @errormessage nvarchar(1000)

select @mostrecentfiledate = MAX(Datetimereceived) from datatrue_edi.dbo.temp_PDI_ItemPKG where DataTrueChainID = @chainid and DataTrueSupplierID = @supplierid

  
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



select ltrim(rtrim(t.PDIItemNo)) PDIItemNo
	  ,ltrim(rtrim(t.RawProductIdentifier)) VIN
	  ,t.RecordID
      --,ltrim(rtrim(t.vendorIdentifier)) vendorIdentifier
      ,t.PackageCode_Scrubbed
      --,replace(t.PackageQty, '''', '') PackageQty
      --,LTRIM(rtrim(t.costzoneid)) costzoneid
      ,t.PackageCost
      ,t.effectivedate
      ,LTRIM(rtrim(t.itemdescription)) itemdescription
      ,case when LTRIM(rtrim(t.Purchasable)) = 'Y' then 1 else 0 end Purchasable
      ,case when LTRIM(rtrim(t.Sellable)) = 'Y' then 1 else 0 end Sellable
      --,LTRIM(rtrim(t.sizedescription)) sizedescription
      ,t.DataTrueChainID
      ,t.DataTrueSupplierID
      ,t.DataTrueProductID
      --,case when LTRIM(rtrim(t.Reclaimable)) = 'Y' then 1 else 0 end Reclaimable
      --,case when LTRIM(rtrim(t.AllowPartialPack)) = 'Y' then 1 else 0 end AllowPartialPack
      --,case when LTRIM(rtrim(t.Orderable)) = 'Y' then 1 else 0 end Orderable
      --,t.PromoCostOnly
      --,t.PromotionEndDate
      --,t.StoreID StoreIdent
      ,st.Storeid 
      ,s.SupplierPackageID
      into  #TempSiteLevelCosts
from #tempProds_3 t
		inner join stores st
			on LTRIM(rtrim(st.custom2)) = t.StoreID
				and st.ChainID  = @chainid 
		inner join  SupplierPackages s
			on s.OwnerEntityID = @chainid
				and s.SupplierID = @supplierid
				and s.ProductID = t.DataTrueProductID
				and LTRIM(rtrim(IsNull(s.vin,''))) = ltrim(rtrim(IsNull(t.RawProductIdentifier,'')))
				--Was w/o this conditions 
				and s.OwnerPackageIdentifier = t.PackageCode_Scrubbed
			    and s.OwnerPDIItemNo = ltrim(rtrim(t.PDIItemNo))


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
		   ,[PriceReportedToRetailerDate]
		   ,[DateTimeCreated]
		   ,[LastUpdateUserID]
		   ,[DateTimeLastUpdate]
		   ,[BaseCost]
		   ,[Allowance]
		   ,[NewActiveStartDateNeeded]
		   ,[NewActiveLastDateNeeded]
		   ,[OldStartDate]
		   ,[OldEndDate]
		   ,[TradingPartnerPromotionIdentifier]
		   ,[SupplierPackageID]
		   ,[IncludeInAdjustments]
		   ,[CostPlusPercentOfRetail])
select 		   
			11 --[ProductPriceTypeID]
		   ,t.DataTrueProductID --[ProductID]
		   ,@chainid --[ChainID]
		   ,t.Storeid --[StoreID]
		   ,0 --[BrandID]
		   ,@supplierid --[SupplierID]
		   ,t.PackageCost --[UnitPrice]
		   ,0 --[UnitRetail]
		   ,0 --[PricePriority]
		   ,t.effectivedate --[ActiveStartDate]
		   ,'12/31/2099' --[ActiveLastDate]
		   ,null --[PriceReportedToRetailerDate]
		   ,getdate() --[DateTimeCreated]
		   ,@MyID --[LastUpdateUserID]
		   ,getdate() --[DateTimeLastUpdate]
		   ,t.PackageCost --[BaseCost]
		   ,null --[Allowance]
		   ,null --[NewActiveStartDateNeeded]
		   ,null --[NewActiveLastDateNeeded]
		   ,null --[OldStartDate]
		   ,null --[OldEndDate]
		   ,null --[TradingPartnerPromotionIdentifier]
		   ,t.SupplierPackageID --[SupplierPackageID]
		   ,0 --[IncludeInAdjustments]
		   ,null --[CostPlusPercentOfRetail])
from #TempSiteLevelCosts t
		left join [DataTrue_Main].[dbo].[ProductPrices] pp
			on   pp.ProductID = t.DataTrueProductID
			 and pp.SupplierID = t.DataTrueSupplierID
			 and pp.ProductPriceTypeID = 11
			 and pp.supplierpackageid = t.SupplierPackageID
			 --and cast(pp.ActiveStartDate as date)  = t.EffectiveDate
			and pp.StoreID  = t.StoreID	    
where t.Purchasable = 1		
	and pp.ProductPriceID is Null
	



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
		   ,[PriceReportedToRetailerDate]
		   ,[DateTimeCreated]
		   ,[LastUpdateUserID]
		   ,[DateTimeLastUpdate]
		   ,[BaseCost]
		   ,[Allowance]
		   ,[NewActiveStartDateNeeded]
		   ,[NewActiveLastDateNeeded]
		   ,[OldStartDate]
		   ,[OldEndDate]
		   ,[TradingPartnerPromotionIdentifier]
		   ,[SupplierPackageID]
		   ,[IncludeInAdjustments]
		   ,[CostPlusPercentOfRetail])
select 		   
			3 --[ProductPriceTypeID]
		   ,t.DataTrueProductID --[ProductID]
		   ,@chainid --[ChainID]
		   ,t.Storeid --[StoreID]
		   ,0 --[BrandID]
		   ,@supplierid --[SupplierID]
		   ,t.PackageCost --[UnitPrice]
		   ,0 --[UnitRetail]
		   ,0 --[PricePriority]
		   ,t.effectivedate --[ActiveStartDate]
		   ,'12/31/2099' --[ActiveLastDate]
		   ,null --[PriceReportedToRetailerDate]
		   ,getdate() --[DateTimeCreated]
		   ,@MyID --[LastUpdateUserID]
		   ,getdate() --[DateTimeLastUpdate]
		   ,t.PackageCost --[BaseCost]
		   ,null --[Allowance]
		   ,null --[NewActiveStartDateNeeded]
		   ,null --[NewActiveLastDateNeeded]
		   ,null --[OldStartDate]
		   ,null --[OldEndDate]
		   ,null --[TradingPartnerPromotionIdentifier]
		   ,t.SupplierPackageID --[SupplierPackageID]
		   ,0 --[IncludeInAdjustments]
		   ,null --[CostPlusPercentOfRetail])
from #TempSiteLevelCosts t
		left join [DataTrue_Main].[dbo].[ProductPrices] pp
			on   pp.ProductID = t.DataTrueProductID
			 and pp.SupplierID = t.DataTrueSupplierID
			 and pp.ProductPriceTypeID = 3
			 and pp.supplierpackageid = t.SupplierPackageID
			 --and cast(pp.ActiveStartDate as date)  = t.EffectiveDate
			and pp.StoreID  = t.StoreID	    
where t.Sellable = 1		
	and pp.ProductPriceID is Null


drop table #tempProds_3

drop table #TempSiteLevelCosts


--set @recprd = CURSOR local fast_forward FOR
--SELECT ltrim(rtrim(PDIItemNo)), ltrim(rtrim([RawProductIdentifier])), [RecordID]
--      ,ltrim(rtrim([vendorIdentifier]))
--      ,ltrim(rtrim([PackageCode_Scrubbed]))
--      ,replace([PackageQty], '''', '')
--      ,LTRIM(rtrim(costzoneid))
--      ,PackageCost
--      ,effectivedate
--      ,LTRIM(rtrim(itemdescription))
--      ,case when LTRIM(rtrim(Purchasable)) = 'Y' then 1 else 0 end
--      ,case when LTRIM(rtrim(Sellable)) = 'Y' then 1 else 0 end
--      ,LTRIM(rtrim(sizedescription))
--      ,DataTrueChainID
--      ,DataTrueSupplierID
--      ,DataTrueProductID
--      ,case when LTRIM(rtrim(Reclaimable)) = 'Y' then 1 else 0 end
--      ,case when LTRIM(rtrim(AllowPartialPack)) = 'Y' then 1 else 0 end
--      ,case when LTRIM(rtrim(Orderable)) = 'Y' then 1 else 0 end
--      ,PromoCostOnly
--      ,PromotionEndDate
--      ,StoreID
--  FROM #tempProds_3
--  where 1 = 1 --and ltrim(rtrim(CostZoneID)) = @costzonetouse
--  order by ltrim(rtrim([PDIItemNo])), PackageCode_Scrubbed, cast(effectivedate as date), PackageCost 
  
--  --select *   FROM #tempProds_3

--open @recprd


--fetch next from @recprd into @pdiitemno, @vin, @recordid, 
--@vendorname2, @packagecode, 
--@packageqty, @ownermarketid, @basecost, @costeffectivedate, @productdescription,
--@purchaseable, @sellable, @sizedescription, @chainid, @supplierid, @productid, @Reclaimable, @AllowPartialPack,@Orderable	
--,@PromoCostOnly, @CursorProductPriceEndDate, @siteid

--While @@FETCH_STATUS = 0
--	begin
	
--		print @vin
--		print @pdiitemno

--		set @supplierpackageid = null
		
--		select @supplierpackageid = supplierpackageid
--		from SupplierPackages
--		where OwnerEntityID = @chainid
--		and SupplierID = @supplierid
--		and ProductID = @productid
--		and LTRIM(rtrim(vin)) = @vin
	
--		set @storeid = null 
		
--		Select @storeid = storeid from stores where ChainID = @chainid and LTRIM(rtrim(custom2)) = @siteid
		
--		set @rowcount = 0
		

--		select @rowcount = COUNT(*)
--		from ProductPrices
--		where 1 = 1
--		and StoreID = @storeid
--		and ProductID = @productid
--		and UnitPrice = @basecost
--		and ProductPriceTypeID in (3,11) 
--		and SupplierPackageID = @supplierpackageid
		
		
--		If isnull(@rowcount, 0) < 1
--			begin
--				select *
--				from ProductPrices
--				where 1 = 1
--				and StoreID = @storeid
--				and ProductID = @productid
--				and ProductPriceTypeID in (3,11)
--				and SupplierPackageID = @supplierpackageid
				
--				if @@ROWCOUNT > 0
--				begin
--					print 'ISSUE'
					
--					set @rowcount = 1
					
--					set @errormessage = 'A Site-Only Cost for Chainid/SupplierID ' + CAST(@chainid as varchar) + '/' + CAST(@chainid as varchar) + ' has failed to load'
					
--					exec dbo.prSendEmailNotification_PassEmailAddresses 'PDI PriceBook Import Issue Detected - Site-Only Cost Not Loaded'
--						,@errormessage
--						,'DataTrue System', 0, 'charlie.clark@icucsolutions.com;ezaslonkin@sphereconsultinginc.com'						
					
--				end
--			end
		
		
--		If isnull(@rowcount, 0) < 1	and @supplierpackageid is not null and @storeid is not null and @productid is not null	
--			begin
			
--				INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
--						   ([ProductPriceTypeID]
--						   ,[ProductID]
--						   ,[ChainID]
--						   ,[StoreID]
--						   ,[BrandID]
--						   ,[SupplierID]
--						   ,[UnitPrice]
--						   ,[UnitRetail]
--						   ,[PricePriority]
--						   ,[ActiveStartDate]
--						   ,[ActiveLastDate]
--						   ,[PriceReportedToRetailerDate]
--						   ,[DateTimeCreated]
--						   ,[LastUpdateUserID]
--						   ,[DateTimeLastUpdate]
--						   ,[BaseCost]
--						   ,[Allowance]
--						   ,[NewActiveStartDateNeeded]
--						   ,[NewActiveLastDateNeeded]
--						   ,[OldStartDate]
--						   ,[OldEndDate]
--						   ,[TradingPartnerPromotionIdentifier]
--						   ,[SupplierPackageID]
--						   ,[IncludeInAdjustments]
--						   ,[CostPlusPercentOfRetail])
--						values(11 --[ProductPriceTypeID]
--						   ,@productid --[ProductID]
--						   ,@chainid --[ChainID]
--						   ,@storeid --[StoreID]
--						   ,0 --[BrandID]
--						   ,@supplierid --[SupplierID]
--						   ,@basecost --[UnitPrice]
--						   ,0 --[UnitRetail]
--						   ,0 --[PricePriority]
--						   ,@costeffectivedate --[ActiveStartDate]
--						   ,'12/31/2099' --[ActiveLastDate]
--						   ,null --[PriceReportedToRetailerDate]
--						   ,getdate() --[DateTimeCreated]
--						   ,@MyID --[LastUpdateUserID]
--						   ,getdate() --[DateTimeLastUpdate]
--						   ,@basecost --[BaseCost]
--						   ,null --[Allowance]
--						   ,null --[NewActiveStartDateNeeded]
--						   ,null --[NewActiveLastDateNeeded]
--						   ,null --[OldStartDate]
--						   ,null --[OldEndDate]
--						   ,null --[TradingPartnerPromotionIdentifier]
--						   ,@supplierpackageid --[SupplierPackageID]
--						   ,0 --[IncludeInAdjustments]
--						   ,null) --[CostPlusPercentOfRetail])
						   
--				If @sellable = 1
--					begin
					
			
--						INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
--								   ([ProductPriceTypeID]
--								   ,[ProductID]
--								   ,[ChainID]
--								   ,[StoreID]
--								   ,[BrandID]
--								   ,[SupplierID]
--								   ,[UnitPrice]
--								   ,[UnitRetail]
--								   ,[PricePriority]
--								   ,[ActiveStartDate]
--								   ,[ActiveLastDate]
--								   ,[PriceReportedToRetailerDate]
--								   ,[DateTimeCreated]
--								   ,[LastUpdateUserID]
--								   ,[DateTimeLastUpdate]
--								   ,[BaseCost]
--								   ,[Allowance]
--								   ,[NewActiveStartDateNeeded]
--								   ,[NewActiveLastDateNeeded]
--								   ,[OldStartDate]
--								   ,[OldEndDate]
--								   ,[TradingPartnerPromotionIdentifier]
--								   ,[SupplierPackageID]
--								   ,[IncludeInAdjustments]
--								   ,[CostPlusPercentOfRetail])
--								values(3 --[ProductPriceTypeID]
--								   ,@productid --[ProductID]
--								   ,@chainid --[ChainID]
--								   ,@storeid --[StoreID]
--								   ,0 --[BrandID]
--								   ,@supplierid --[SupplierID]
--								   ,@basecost --[UnitPrice]
--								   ,0 --[UnitRetail]
--								   ,0 --[PricePriority]
--								   ,@costeffectivedate --[ActiveStartDate]
--								   ,'12/31/2099' --[ActiveLastDate]
--								   ,null --[PriceReportedToRetailerDate]
--								   ,getdate() --[DateTimeCreated]
--								   ,@MyID --[LastUpdateUserID]
--								   ,getdate() --[DateTimeLastUpdate]
--								   ,@basecost --[BaseCost]
--								   ,null --[Allowance]
--								   ,null --[NewActiveStartDateNeeded]
--								   ,null --[NewActiveLastDateNeeded]
--								   ,null --[OldStartDate]
--								   ,null --[OldEndDate]
--								   ,null --[TradingPartnerPromotionIdentifier]
--								   ,@supplierpackageid --[SupplierPackageID]
--								   ,0 --[IncludeInAdjustments]
--								   ,null) --[CostPlusPercentOfRetail])					
					

					
					
--					end
--			end
	
--		fetch next from @recprd into @pdiitemno, @vin, @recordid, 
--		@vendorname2, @packagecode, 
--		@packageqty, @ownermarketid, @basecost, @costeffectivedate, @productdescription,
--		@purchaseable, @sellable, @sizedescription, @chainid, @supplierid, @productid, @Reclaimable, @AllowPartialPack,@Orderable	
--		,@PromoCostOnly, @CursorProductPriceEndDate, @siteid
--	end
	
--close @recprd
--deallocate @recprd

--drop table #tempProds_3
GO
