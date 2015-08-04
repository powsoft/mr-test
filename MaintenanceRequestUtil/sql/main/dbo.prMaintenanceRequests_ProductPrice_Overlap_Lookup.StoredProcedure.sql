USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequests_ProductPrice_Overlap_Lookup]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequests_ProductPrice_Overlap_Lookup]
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
,@OnlyExactMatchFound bit output

as

/*
declare @dummy bit
exec prMaintenanceRequests_ProductPrice_Overlap_Lookup 1, null, 5287, 0, 40559, 8, '1/27/2000',  '12/31/2025', 2 ,null, 'Shop N Save Warehouse Foods Inc', @dummy output
print @dummy
*/
/*
declare @overlapfound bit`
declare @OnlyExactMatchFound bit
declare @storeid int
declare @maintenancerequestid int
declare @productid int=5251
declare @brandid int=0
declare @supplierid int=40559
declare @productpricetypeid int=8
declare @pricestartdate datetime='2012-01-01 00:00:00.000'
declare @priceenddate datetime='2099-12-31 00:00:00.000'
declare @storecontexttypeid smallint=2
declare @costzoneid int
declare @banner nvarchar(50)='Albertsons - SCAL'
*/

declare @batchid int
declare @strSQL nvarchar(1000)
declare @storecount int
declare @pricecount int

set @overlapfound = 0
set @OnlyExactMatchFound = 0

truncate table tmpStoreContextListSingleUse

if @storecontexttypeid = 1
	begin
		set @strSQL = 'insert tmpStoreContextListSingleUse select ' + cast(@storeid as nvarchar) + ' as storeid'
	end
if @storecontexttypeid = 2
	begin
		set @strSQL = 'insert tmpStoreContextListSingleUse select storeid from stores where Custom1 = ''' + @banner + ''''
	end
if @storecontexttypeid = 3
	begin
		set @strSQL = 'insert tmpStoreContextListSingleUse select storeid from CostZoneRelations where costzoneid = ' + cast(@costzoneid as nvarchar)
	end
if @storecontexttypeid = 5
	begin
		set @strSQL = 'insert tmpStoreContextListSingleUse select distinct storeid from StoreTransactions where supplierid = ' + cast(@supplierid as nvarchar) + ' and TransactionTypeID = 2'
	end
	
exec(@strSQL)

set @storecount = @@rowcount

set  @pricecount = 0

--select productid, brandid, unitprice, activestartdate, activelastdate, TradingPartnerPromotionIdentifier , CAST(datetimecreated as date) 
select @pricecount = COUNT(ProductID)
from productprices
where 1 = 1
and StoreID in (select StoreID from tmpStoreContextListSingleUse)
and ProductID = @productid
and BrandID = @brandid
and SupplierID = @supplierid
and ProductPriceTypeID = @productpricetypeid
and CAST(ActiveStartDate as date) = CAST(@pricestartdate as date)
and CAST(ActiveLastDate as date) = CAST(@priceenddate as date)

--set @pricecount = @@ROWCOUNT

if @storecount = @pricecount
	begin
		set @OnlyExactMatchFound = 1
	end
if @OnlyExactMatchFound = 0
	begin

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
	end			
return
GO
