USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProductPrice_Manage_20131213]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProductPrice_Manage_20131213]
@chainid int=0
,@storeid int=0
,@productid int=0
,@brandid int=0
,@supplierid int=0
,@productpricetypeid int=0
,@productprice money=0.00
,@pricestartdate datetime='1/1/2000'
,@priceenddate datetime='12/31/2025'
,@productretail money=0.00
,@requestingMyID int=0
,@deletethispromo smallint=0
,@promotionidentifier nvarchar(50)=''
,@includeinadjustments tinyint

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 7610
declare @recprices cursor
declare @priceid int
declare @startdate date
declare @enddate date

begin try

begin transaction

if @deletethispromo = 1
	begin
	delete
	--update p set p.UnitPrice = 0, p.Allowance = p.UnitPrice
	from productprices
	where StoreID = @storeid
	and ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid
	and ProductPriceTypeID = @productpricetypeid
	and ProductPriceTypeID = 8
	and cast(ActiveStartDate as date) = cast(@pricestartdate as date)
	and cast(ActiveLastDate as date) = cast(@priceenddate as date)
	and UnitPrice = @productprice
	
	end
else
	begin
	
set @recprices = CURSOR local fast_forward FOR
	select productpriceid, activestartdate, activelastdate 
	from productprices
	where StoreID = @storeid
	and ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid
	and ProductPriceTypeID = @productpricetypeid
	and (( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @pricestartdate) or ( ActiveStartDate <= @priceenddate and ActiveLastDate >= @priceenddate) or ( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @priceenddate) or ( ActiveStartDate >= @pricestartdate and ActiveLastDate <= @priceenddate))
	--and (ActiveLastDate >= @pricestartdate or ActiveStartDate <= @priceenddate)
	order by ActiveStartDate
	
	open @recprices
--select top 10 * from productprices	
	fetch next from @recprices into @priceid, @startdate, @enddate
	
	--if @@FETCH_STATUS = 0
	--	begin
	
			while @@FETCH_STATUS = 0
				begin
					--case where existing record falls entirely within new date range 
					--ACTION = delete record
					if @startdate >= @pricestartdate and @enddate <= @priceenddate
						begin
						
						
							INSERT INTO [DataTrue_Main].[dbo].[ProductPricesDeleted]
									   ([ProductPriceID]
									   ,[ProductPriceTypeID]
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
									   ,[TradingPartnerPromotionIdentifier])

							SELECT [ProductPriceID]
								  ,[ProductPriceTypeID]
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
							  FROM [DataTrue_Main].[dbo].[ProductPrices]
							where ProductPriceID = @priceid
														
														
							delete from ProductPrices where ProductPriceID = @priceid
						end
					--case where existing record starts within new date range and goes beyond newenddate
					--ACTION = update existing startdate to one day later than newenddate
					if @startdate >= @pricestartdate and @enddate > @priceenddate
						begin
							update ProductPrices 
							set OldStartDate = ActiveStartDate, ActiveStartDate = DATEADD(day, 1, @priceenddate)
							where ProductPriceID = @priceid
						end
					--case where existing startdate < newstartdate and existingenddate <= newenddate
					--ACTION = set existing enddate one day earlier than newstartdate
					if @startdate < @pricestartdate and @enddate <= @priceenddate
						begin
							update ProductPrices 
							set OldEndDate = ActiveLastDate, ActiveLastDate = DATEADD(day, -1, @pricestartdate)
							where ProductPriceID = @priceid
						end
					--case when new date range falls entirely within an existing range
					--ACTION = 2)make existing enddate one day earlier than newstartdate 
					--1)insert new record for existing price starting one day after newenddate using existing end date
					if @startdate < @pricestartdate and @enddate > @priceenddate
						begin
						
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
									   ,[PriceReportedToRetailerDate]
									   ,[DateTimeCreated]
									   ,[LastUpdateUserID]
									   ,[BaseCost]
									   ,[Allowance]
									   ,[NewActiveStartDateNeeded]
									   ,[NewActiveLastDateNeeded]
									   ,[OldStartDate]
									   ,[OldEndDate])
							SELECT [ProductPriceTypeID]
								  ,[ProductID]
								  ,[ChainID]
								  ,[StoreID]
								  ,[BrandID]
								  ,[SupplierID]
								  ,[UnitPrice]
								  ,[UnitRetail]
								  ,[PricePriority]
								  ,DATEADD(day, 1, @priceenddate)
								  ,[ActiveLastDate]
								  ,[PriceReportedToRetailerDate]
								  ,GETDATE()
								  ,@MyID
								  ,[BaseCost]
								  ,[Allowance]
								  ,[NewActiveStartDateNeeded]
								  ,[NewActiveLastDateNeeded]
								  ,ActiveStartDate
								  ,ActiveLastDate
							  FROM [DataTrue_Main].[dbo].[ProductPrices]
							where ProductPriceID = @priceid						
						
							update ProductPrices 
							set OldEndDate = ActiveLastDate, ActiveLastDate = DATEADD(day, -1, @pricestartdate)
							where ProductPriceID = @priceid				
						
						end
					fetch next from @recprices into @priceid, @startdate, @enddate				
				end
	--	end
	--else
	--	begin
		
		
		
	--	end
		
	close @recprices
	deallocate @recprices
	
--If @productpricetypeid = 0 or @productpricetypeid = 3 --DEFAULTPRICE
--	begin
		
		INSERT INTO [dbo].[ProductPrices]
				   ([ProductPriceTypeID]
				   ,[ProductID]
				   ,[ChainID]
				   ,[BrandID]
				   ,[UnitPrice]
				   ,[UnitRetail]
				   ,[PricePriority]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID]
				   ,[StoreID]
				   ,[SupplierID]
				   ,[TradingPartnerPromotionIdentifier]
				   ,[IncludeInAdjustments])
			 VALUES
				   (@productpricetypeid
				   ,@productid
				   ,@chainid
				   ,@brandid
				   ,@productprice
				   ,@productretail
				   ,0 --<PricePriority, smallint,>
				   ,@pricestartdate
				   ,@priceenddate
				   ,@requestingMyID
				   ,@storeid
				   ,@supplierid
				   ,@promotionidentifier
				   ,@includeinadjustments)	
	
	end --else branch end for if @deletethispromo = 1


commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch

return
GO
