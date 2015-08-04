USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_20111213]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_EDIPromotions_Load_To_MaintenanceRequests_20111213]
as

/*
select * from datatrue_edi.dbo.Promotions where loadstatus = 0
Farm Fresh Duns = 1939636180000
*/

update datatrue_edi.dbo.Promotions set supplierid = 
case when SupplierIdentifier = 'LWS' then 41464
	when  SupplierIdentifier = 'BIM' then 40557
	when SupplierIdentifier = 'SAR' then 41465
end
where supplierid is null
and loadstatus = 0


update datatrue_edi.dbo.Promotions set dtcostzoneid = 
case when LTRIM(rtrim(PromotionNumber)) = 'SHOPNSAV11122601' then 874
	when  LTRIM(rtrim(PromotionNumber)) = 'SNSSPRI 11122602' then 876
else null
end
where loadstatus = 0



select distinct custom1 from stores

select * from stores where Custom1 = 'Farm Fresh Markets'

update datatrue_edi.dbo.Promotions set banner = 
case when LTRIM(rtrim(StoreDuns)) = '1939636180000' then 'Farm Fresh Markets'
else null
end
where loadstatus = 0

select * from datatrue_edi.dbo.Promotions where loadstatus = 0

update datatrue_edi.dbo.Promotions set banner = 
case when LTRIM(rtrim(StoreDuns)) = '1939636180000' then 'Farm Fresh Markets'
else null
end
where loadstatus = 0

update p set p.storeid = s.storeid
from datatrue_edi.dbo.Promotions p
inner join stores s
--on CAST(storenumber as int) = CAST(s.custom2 as int)
on CAST(storenumber as int) = CAST(s.storeidentifier as int)
and LTRIM(rtrim(p.banner)) = LTRIM(rtrim(custom1))

update datatrue_edi.dbo.Promotions set dtstorecontexttypeid = 
case when storeid is null and dtcostzoneid is not null then 3
	when storeid is null and dtcostzoneid IS null and banner IS Not null then 2
	when storeid Is Not null then 2
else null end
where loadstatus = 0


/*
update datatrue_edi.dbo.Promotions set banner = 
case when ltrim(rtrim(StoreName)) = 'SHOP N SAVE' then 'Shop N Save Warehouse Foods Inc'
else null
end
where banner is null
*/




--select distinct custom1 from stores SHOP N SAVE

declare @rec cursor
declare @upc nvarchar(50)
declare @storeid int
declare @startdate date
declare @enddate date
declare @productid int
declare @supplierid int
declare @brandid int=0
declare @allowance money
declare @mrupc nvarchar(50)
declare @checkdigit char(1)
declare @lenofupc tinyint
declare @maintenancerequestid int
declare @costzone nvarchar(50)

set @rec = CURSOR local fast_forward FOR
	select RecordID, RawProductidentifier
	from datatrue_edi.dbo.Promotions
	--where productid is null


open @rec

fetch next from @rec into @maintenancerequestid, @mrupc

while @@FETCH_STATUS = 0
	begin

		set @lenofupc = LEN(@mrupc)
		if @lenofupc = 12
			begin
				select @productid = ProductId
				from ProductIdentifiers
				where IdentifierValue = @mrupc
				and ProductIdentifierTypeID = 2
				if @@ROWCOUNT > 0
					begin
						update datatrue_edi.dbo.Promotions set Productid = @productid
						where RecordID = @maintenancerequestid
					end
			end
		if @lenofupc = 11
			begin
				select @productid = ProductId
				from ProductIdentifiers
				where IdentifierValue = '0' + @mrupc
				and ProductIdentifierTypeID = 2			
				if @@ROWCOUNT > 0
					begin
						update datatrue_edi.dbo.Promotions set Productid = @productid
						where RecordID = @maintenancerequestid
					end			
			end
		if @lenofupc = 11 and @productid is null
			begin
				set @CheckDigit = ''
				exec [dbo].[prUtil_UPC_GetCheckDigit]
					 @mrupc,
					 @CheckDigit OUT

				select @productid = productid
				from productidentifiers
				where identifiervalue = @mrupc + @CheckDigit
		
				if @@ROWCOUNT > 0
					begin
						update datatrue_edi.dbo.Promotions set Productid = @productid
						where RecordID = @maintenancerequestid
					end			
			end		
		
		
		fetch next from @rec into @maintenancerequestid, @mrupc

	end
	
close @rec
deallocate @rec

	
declare @rec2 cursor
/*
declare @brandid int=0
declare @maintenancerequestid int
declare @storeid int
declare @productid int
declare @supplierid int
declare @startdate date
declare @enddate date
declare @allowance money
*/
declare @newmaintenancerequestid int
declare @productname nvarchar(100)
declare @RawProductIdentifier nvarchar(50)
declare @marketareacode nvarchar(50)
declare @allstores bit=1

--Sara Lee store specific	
set @rec2 = CURSOR local fast_forward FOR
	select recordid, storeid, ProductId, supplierid, 
	DateStartPromotion, DateEndPromotion, Allowance_ChargeRate,
	ProductName, RawProductIdentifier, ltrim(rtrim(MarketAreaCode))
	from datatrue_edi.dbo.Promotions
	where Loadstatus = 0
	
	


open @rec2

fetch next from @rec2 into
	@maintenancerequestid
	,@storeid
	,@productid
	,@supplierid
	,@startdate
	,@enddate
	,@allowance
	,@productname
	,@RawProductIdentifier
	,@marketareacode

while @@FETCH_STATUS = 0
	begin


INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
           ([SubmitDateTime]
           ,[RequestTypeID]
           ,[ChainID]
           ,[SupplierID]
           ,[AllStores]
           ,[UPC]
           ,[ItemDescription]
           ,[Cost]
           ,[PromoTypeID]
           ,[PromoAllowance]
           ,[StartDateTime]
           ,[EndDateTime]
           ,[SupplierLoginID]
           ,[RequestStatus]
           ,[productid]
           ,[brandid]
           ,[CostZoneID])
     VALUES
           (getdate()
           ,3
           ,40393
           ,@supplierid
           ,@allstores
           ,@RawProductIdentifier
           ,@productname
           ,0.00
           ,1
           ,@allowance
           ,@startdate
           ,@enddate
           ,0
           ,0
           ,@productid
           ,0
           ,case when @marketareacode = 'SHOPNSAV' then 874 when @marketareacode = 'SNSSPRI' then 876 else null end)
           
           if @allstores = 0
			begin
				   set @newmaintenancerequestid = SCOPE_IDENTITY()
		           
				INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequestStores]
				   ([MaintenanceRequestID]
				   ,[StoreID]
				   ,[Included])
				VALUES
				   (@newmaintenancerequestid
				   ,@storeid
				   ,1)
			end

   update datatrue_edi.dbo.Promotions set loadstatus = 73 where recordid = @maintenancerequestid

		fetch next from @rec2 into
			@maintenancerequestid
			,@storeid
			,@productid
			,@supplierid
			,@startdate
			,@enddate
			,@allowance
			,@productname
			,@RawProductIdentifier
			,@marketareacode

	end
	
close @rec2
deallocate @rec2
	
	
return
GO
