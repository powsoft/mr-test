USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequests_ProductPrice_Overlap_Lookup_Rollback_20120217]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prMaintenanceRequests_ProductPrice_Overlap_Lookup_Rollback_20120217]
@maintenancerequestid int
,@storeid int
,@productid int
,@brandid int
,@supplierid int
,@productpricetypeid int
,@pricestartdate datetime
,@priceenddate datetime
,@storecontexttypeid smallint
,@costzoneid int
,@banner nvarchar(50)
,@overlapfound bit output

as

/*
declare @dummy bit
exec prMaintenanceRequests_ProductPrice_Overlap_Lookup 1, null, 5287, 0, 40559, 8, '1/27/2000',  '12/31/2025', 2 ,null, 'Shop N Save Warehouse Foods Inc', @dummy output
print @dummy

declare @maintenancerequestid int
declare @productid int=5287
declare @brandid int=0
declare @supplierid int=40559
declare @productpricetypeid int=8
declare @pricestartdate datetime='1/27/2000'
declare @priceenddate datetime='12/31/2025'
declare @storecontexttypeid smallint
declare @costzoneid int
declare @banner nvarchar(50)='Shop N Save Warehouse Foods Inc'
*/
declare @batchid int

set @overlapfound = 0


if @storecontexttypeid = 1
	begin
		INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequestExceptions]
				   ([MaintenanceRequestID]
				   ,[productid]
				   ,[brandid]
				   ,[UnitValue]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[TradingPartnerPromotionIdentifier]
				   ,[datedealadded])
			select distinct @maintenancerequestid, productid, brandid, unitprice, activestartdate, activelastdate, TradingPartnerPromotionIdentifier , CAST(datetimecreated as date) 
			from productprices
			where 1 = 1
			and StoreID in (@storeid)
			and ProductID = @productid
			and BrandID = @brandid
			and SupplierID = @supplierid
			and ProductPriceTypeID = @productpricetypeid
			and (( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @pricestartdate) 
				or ( ActiveStartDate <= @priceenddate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate >= @pricestartdate and ActiveLastDate <= @priceenddate))
			order by ActiveStartDate
			
		if @@ROWCOUNT > 0
			set @overlapfound = 1
	end
	
	
if @storecontexttypeid = 2
	begin
		INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequestExceptions]
				   ([MaintenanceRequestID]
				   ,[productid]
				   ,[brandid]
				   ,[UnitValue]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[TradingPartnerPromotionIdentifier]
				   ,[datedealadded])
			select distinct @maintenancerequestid, productid, brandid, unitprice, activestartdate, activelastdate, isnull(TradingPartnerPromotionIdentifier, ''), CAST(datetimecreated as date)  
			from productprices
			where 1 = 1
			and StoreID in (select storeid from stores where Custom1 = @banner)
			and ProductID = @productid
			and BrandID = @brandid
			and SupplierID = @supplierid
			and ProductPriceTypeID = @productpricetypeid
			and (
				( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @pricestartdate) 
				or ( ActiveStartDate <= @priceenddate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate >= @pricestartdate and ActiveLastDate <= @priceenddate)
				)
			order by ActiveStartDate
			
		if @@ROWCOUNT > 0
			set @overlapfound = 1
	end
	

if @storecontexttypeid = 3
	begin
		INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequestExceptions]
				   ([MaintenanceRequestID]
				   ,[productid]
				   ,[brandid]
				   ,[UnitValue]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[TradingPartnerPromotionIdentifier]
				   ,[datedealadded])
			select distinct @maintenancerequestid, productid, brandid, unitprice, activestartdate, activelastdate, TradingPartnerPromotionIdentifier, CAST(datetimecreated as date)  
			from productprices
			where 1 = 1
			and StoreID in (select storeid from CostZoneRelations where costzoneid = @costzoneid)
			and ProductID = @productid
			and BrandID = @brandid
			and SupplierID = @supplierid
			and ProductPriceTypeID = @productpricetypeid
			and (( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @pricestartdate) 
				or ( ActiveStartDate <= @priceenddate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate >= @pricestartdate and ActiveLastDate <= @priceenddate))
			order by ActiveStartDate
			
		if @@ROWCOUNT > 0
			set @overlapfound = 1
	end	
	
if @storecontexttypeid = 5
	begin
		INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequestExceptions]
				   ([MaintenanceRequestID]
				   ,[productid]
				   ,[brandid]
				   ,[UnitValue]
				   ,[StartDateTime]
				   ,[EndDateTime]
				   ,[TradingPartnerPromotionIdentifier]
				   ,[datedealadded])
			select distinct @maintenancerequestid, productid, brandid, unitprice, activestartdate, activelastdate, TradingPartnerPromotionIdentifier, CAST(datetimecreated as date) 
			from productprices
			where 1 = 1
			and StoreID in (select distinct storeid from StoreTransactions where supplierid = @supplierid and TransactionTypeID = 2)
			and ProductID = @productid
			and BrandID = @brandid
			and SupplierID = @supplierid
			and ProductPriceTypeID = @productpricetypeid
			and (( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @pricestartdate) 
				or ( ActiveStartDate <= @priceenddate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @priceenddate) 
				or ( ActiveStartDate >= @pricestartdate and ActiveLastDate <= @priceenddate))
			order by ActiveStartDate
			
		if @@ROWCOUNT > 0
			set @overlapfound = 1
	end	
		
		
if @overlapfound = 1
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(0)
	
		set @batchid = SCOPE_IDENTITY()

		update mr set mr.batchid = @batchid 
		from MaintenanceRequestExceptions mr
		where MaintenanceRequestID = @maintenancerequestid
		and mr.BatchID is null
	end	
	
return
GO
