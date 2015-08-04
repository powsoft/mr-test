USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_Purchase_Data_Check]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Delivery Date - Lead time =  PO generation Date
-- exec [usp_Generate_Purchase_Data_Check] '44246','44199', '13193', '-1', '077013163077', '2013-05-10'
CREATE procedure [dbo].[usp_Generate_Purchase_Data_Check]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50),
@Banner varchar(50),
@UPC varchar(50), 
@PODate varchar(20)
as 
Begin
set nocount on
	begin try
		Drop table [@tmpVMIData]
		Drop table #tmpPOSDates
	end try
	begin catch
	end catch
	
	Declare @InventoryTakenBeforeDeliveries int, @InventoryTakenBeginOfDay int

	select  @InventoryTakenBeginOfDay=InventoryTakenBeginOfDay,
			@InventoryTakenBeforeDeliveries=InventoryTakenBeforeDeliveries 
	from dbo.InventoryRulesTimesBySupplierID where SupplierId=@SupplierId and ChainId=@ChainId

	set @InventoryTakenBeforeDeliveries = isnull(@InventoryTakenBeforeDeliveries, 1)
	set @InventoryTakenBeginOfDay = isnull(@InventoryTakenBeginOfDay, 1)
	
	Declare @strSQL varchar(2000)
	
	set @strSQL= 'select distinct SS.StoreSetupId, SS.SupplierID, SS.StoreID, SS.ProductID, POC.PlanogramCapacityMax, POC.PlanogramCapacityMin, POC.DateRange, POC.FillRate, POC.LeadTime, 
		(dateadd(d, LeadTime, ''' + @PODate + ''')) as DeliveryDate, rtrim(POD.DeliveryTime) as DeliveryTime,  POD.DaysToNextDelivery, 
		dateadd(d, LeadTime + isnull(POD.DaysToNextDelivery,1),''' + @PODate + ''' ) as NextDeliveryDate
		into [@tmpVMIData]
		from PO_Criteria POC 
		inner join PO_DeliveryDates POD on POD.StoreSetupId=POC.StoreSetupID
		inner join StoreSetup SS on SS.StoreSetupID = POC.StoreSetupID
		inner join Stores S on S.StoreID = SS.StoreID
		Inner join SupplierBanners SB on SB.SupplierId = SS.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
		inner join ProductIdentifiers P on P.ProductId= SS.ProductId
		where (POC.ReplenishmentType=''Daily'' 
		or (POC.ReplenishmentType=''Weekly'' and LEN(POD.DeliveryDayOrDate)< 3  and datePart(weekday,dateadd(d, LeadTime, ''' + @PODate + '''))=POD.DeliveryDayOrDate)
		or (POC.ReplenishmentType=''Monthly'' and LEN(POD.DeliveryDayOrDate)< 3 and datename(dd,dateadd(d, LeadTime, ''' + @PODate + '''))=POD.DeliveryDayOrDate)
		)'
						
	if(@SupplierId<>'-1')
			set @strSQL = @strSQL +  ' and SS.SupplierID=' + @SupplierId 
			
	if(@ChainId<>'-1')				
			set @strSQL = @strSQL +  ' and SS.ChainId=' + @ChainId 
			
	if(@StoreNumber<>'')				
			set @strSQL = @strSQL +  ' and S.StoreIdentifier like ''%' + @StoreNumber + '%'''
			
	if(@Banner<>'-1')				
			set @strSQL = @strSQL +  ' and S.Custom1=''' + @Banner + ''''
			
	if(@UPC<>'')				
			set @strSQL = @strSQL +  ' and P.IdentifierValue like ''%' + @UPC + '%'''

	set @strSQL = @strSQL +  ' order by StoreSetupId, DeliveryDate '
	
	
	exec (@strSQL)
	Select * from [@tmpVMIData]
	
	Declare @StoreSetupId varchar(10), @Supplier varchar(10), @StoreId varchar(10), @ProductId varchar(10), @PlanogramCapacityMax int, @PlanogramCapacityMin int, @DateRange int, @PAD float, @LeadTime int, 
	@UpcomingDeliveryDate date,	@UpcomingDeliveryTime varchar(10), @DaysToNextDelivery float, @NextDeliveryDate date
	DECLARE report_cursor CURSOR FOR 
		
	Select * from [@tmpVMIData]			
	
	OPEN report_cursor;
	FETCH NEXT FROM report_cursor 
		INTO @StoreSetupId, @Supplier, @StoreId, @ProductId, @PlanogramCapacityMax, @PlanogramCapacityMin, @DateRange,@PAD, @LeadTime, @UpcomingDeliveryDate, @UpcomingDeliveryTime, @DaysToNextDelivery, @NextDeliveryDate
	
	while @@FETCH_STATUS = 0
		begin
		
		Declare @LastTransDate Datetime
		
		Delete from PO_TempPurchaseOrderHistoryData  where SupplierID=@Supplier and StoreId=@StoreId and ProductId=@ProductId and DeliveryDate=@UpcomingDeliveryDate
		
		-- Get the Last Transaction Date for the selected Supplier and Store
		set @LastTransDate=NULL
		Select top 1 @LastTransDate =  SaleDateTime from StoreTransactions ST
		inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		where BucketType=1 and SupplierID= @Supplier and StoreID= @StoreId 
		order by SaleDateTime Desc		
		
		--===============================================================================================================
		---Calculations to Exclude SeasonDates from AvgDailySales Calculations
		--===============================================================================================================
		
		begin try
			Drop Table #tmpPOSDates
		end try
		begin catch
		end catch
		
		Select distinct SaleDateTime into #tmpPOSDates from StoreTransactions ST 
						inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
						where BucketType=1 and SupplierID= @Supplier and StoreID= @StoreId and ProductId=@ProductId
						and SaleDateTime < @LastTransDate and SaleDateTime>GETDATE()- 365
		
		Declare @SeasonStart date,  @SeasonEnd date						
		DECLARE seasondate_cursor CURSOR FOR 
			select distinct StartDate, EndDate from PO_Seasonality where StoreSetupId=@StoreSetupId 
			union all
			select distinct ActiveStartDate, ActiveLastDate from ProductPrices 
			where SupplierID=@SupplierId and ChainID=@ChainId and StoreID=@StoreId and ProductID=@ProductId and ProductPriceTypeID=2
		
		OPEN seasondate_cursor;
			FETCH NEXT FROM seasondate_cursor INTO @SeasonStart, @SeasonEnd
		while @@FETCH_STATUS = 0
		begin
			Delete from #tmpPOSDates where SaleDateTime between @SeasonStart and @SeasonEnd
			FETCH NEXT FROM seasondate_cursor INTO @SeasonStart, @SeasonEnd
		end
		CLOSE seasondate_cursor;
		DEALLOCATE seasondate_cursor;
		--===============================================================================================================

		Declare @DailySales float = NULL
		Select @DailySales = SUM(Qty) from StoreTransactions ST 
						inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
						where BucketType=1 and SupplierID= @Supplier and StoreID= @StoreId and ProductId=@ProductId 
						and SaleDateTime in ( select top (@DateRange) SaleDatetime from #tmpPOSDates order by SaleDateTime Desc)
		select * from #tmpPOSDates
		select @DailySales, @DateRange, @DailySales/@DateRange
		
		--Last Count Date
		Declare @LastCountDate varchar(10)=NULL
		Select top 1 @LastCountDate=convert(varchar(10),SaleDateTime,101) 
		from StoreTransactions ST where ST.TransactionTypeID in (10, 11)
		and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		order by StoreTransactionID Desc
		
		Declare @LastTransactionDateForSeasonality varchar(10)
		set @LastTransactionDateForSeasonality= case when @LastCountDate>@LastTransDate then convert(varchar(10),@LastCountDate,101) else convert(varchar(10),@LastTransDate,101) end
		
		--===============================================================================================================
		-- (Begin) Season/Promo Calculations
		--===============================================================================================================
		--Get all the seasons supposed to happen between LastCountDate to DeliveryDate
		Declare @SeasonFillRate float, @ChangeRate float, 
		@SeasonDays int=0, @TotalSeasonDays int =0, @InventoryRequiredForSeason int=0,
		@SeasonDaysBeforeDeliveryDate int=0, @TotalSeasonDaysBeforeDeliveryDate int =0, @InventoryRequiredForSeasonBeforeDeliveryDate int=0
		
		DECLARE season_cursor CURSOR FOR 
			select StartDate, EndDate, FillRate, ChangeInAvgSales from PO_Seasonality 
			where StoreSetupId=@StoreSetupId 
			and ((StartDate between @LastTransactionDateForSeasonality and @NextDeliveryDate) or (EndDate between @LastTransactionDateForSeasonality and @NextDeliveryDate) )
			
			union all
			
			select distinct ActiveStartDate, ActiveLastDate, @PAD as FillRate,'10' as ChangeRate from ProductPrices 
			where SupplierID=@SupplierId and ChainID=@ChainId and StoreID=@StoreId and ProductID=@ProductId and ProductPriceTypeID=2
			and ((ActiveStartDate between @LastTransactionDateForSeasonality and @NextDeliveryDate) or (ActiveLastDate between @LastTransactionDateForSeasonality and @NextDeliveryDate) )
		
		OPEN season_cursor;
			FETCH NEXT FROM season_cursor INTO @SeasonStart, @SeasonEnd, @SeasonFillRate, @ChangeRate
		while @@FETCH_STATUS = 0
		begin
			 set @SeasonDaysBeforeDeliveryDate=0
			 --Calculate Seasondays between Last count and Delivery Date
			 --Season Started before Last Count and will end before Delivery Date 
			if(@SeasonStart<@LastTransactionDateForSeasonality and @SeasonEnd<=@UpcomingDeliveryDate)
			begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @LastTransactionDateForSeasonality, @SeasonEnd)
			end
			
			--Season Started before Last Count and will end after DeliveryDate 
			else if(@SeasonStart<@LastTransactionDateForSeasonality and @SeasonEnd>@UpcomingDeliveryDate)
			Begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @LastTransactionDateForSeasonality, @UpcomingDeliveryDate)
			end
			
			--Season start after Last count date and will end before DeliveryDate 
			else if(@SeasonStart>=@LastTransactionDateForSeasonality and @SeasonStart<=@UpcomingDeliveryDate  and @SeasonEnd<=@UpcomingDeliveryDate)
			Begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @SeasonStart, @SeasonEnd)
			end
			
			--Season start after Last count date and will end after DeliveryDate 
			else if(@SeasonStart>=@LastTransactionDateForSeasonality and @SeasonStart<=@UpcomingDeliveryDate and @SeasonEnd>@UpcomingDeliveryDate)
			Begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @SeasonStart, @UpcomingDeliveryDate)
			end
			
			set @TotalSeasonDaysBeforeDeliveryDate += @SeasonDaysBeforeDeliveryDate
			set @InventoryRequiredForSeasonBeforeDeliveryDate += CEILING(((ROUND(@DailySales/@DateRange,1) * (1+@ChangeRate/100)) * (@SeasonDaysBeforeDeliveryDate))) 
			 
			 set @SeasonDays=0
			 --Calculate Seasondays between Delivery Date and Next Delivery Date
			--Season Already Started and will end before NextDeliveryDate 
			if(@SeasonStart<@UpcomingDeliveryDate and @SeasonEnd<=@NextDeliveryDate)
			begin
				set @SeasonDays = DATEDIFF(d, @UpcomingDeliveryDate, @SeasonEnd)
			end
			
			--Season Already Started and will end after NextDeliveryDate 
			else if(@SeasonStart<@UpcomingDeliveryDate and @SeasonEnd>@NextDeliveryDate)
			Begin
				set @SeasonDays = DATEDIFF(d, @UpcomingDeliveryDate, @NextDeliveryDate)
			end
			
			--Season start after DeliveryDate and will end before NextDeliveryDate 
			else if(@SeasonStart>=@UpcomingDeliveryDate and @SeasonEnd<=@NextDeliveryDate)
			Begin
				set @SeasonDays = DATEDIFF(d, @SeasonStart, @SeasonEnd)
			end
			
			--Season start after DeliveryDate and will end after NextDeliveryDate 
			else if(@SeasonStart>=@UpcomingDeliveryDate and @SeasonEnd>@NextDeliveryDate)
			Begin
				set @SeasonDays = DATEDIFF(d, @SeasonStart, @NextDeliveryDate)
			end
			set @TotalSeasonDays += @SeasonDays + @SeasonDaysBeforeDeliveryDate
			set @InventoryRequiredForSeason += CEILING(((ROUND(@DailySales/@DateRange,1) * (1+@ChangeRate/100)) * (@SeasonDays)) * (1+(@SeasonFillRate/100))) + @InventoryRequiredForSeasonBeforeDeliveryDate 
			
			FETCH NEXT FROM season_cursor INTO @SeasonStart, @SeasonEnd, @SeasonFillRate, @ChangeRate
		end
		CLOSE season_cursor;
		DEALLOCATE season_cursor;
		
		Declare @SupplierItemNumber varchar(50)=NULL, @RawStoreIdentifier varchar(50)=NULL, @Route varchar(50)=NULL
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------
		--      DELIVERIES DATA (ACTUAL AND GOODS IN TRANSIT)
		--------------------------------------------------------------------------------------------------------------------------------------------------------------
		Declare @ActualDeliveredUnits int, @ActualDeliveryDate date, @GoodsInTransit int, @GoodsInTransitHistory int, @TotalDeliveredUnits int

		Select @ActualDeliveredUnits = SUM(isnull(qty*QtySign,0)),
			   @ActualDeliveryDate = max(SaleDateTime)
		from StoreTransactions ST 
		inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		where T.BucketType=2 and T.TransactionTypeId not in (39,21,8,14) and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		and SaleDateTime > case when @InventoryTakenBeforeDeliveries=1 then dateadd(d,-1,@LastCountDate) else @LastCountDate end  
		and SaleDateTime < @UpcomingDeliveryDate
		group by ST.SupplierId, ST.StoreId, ST.ProductId, ST.TransactionTypeId

		Select @GoodsInTransitHistory=SUM(isnull([Order Units],0)) from PO_PurchaseOrderHistoryData_Revised PD 
		where PD.SupplierID=@Supplier and PD.StoreID=@StoreId and PD.ProductId=@ProductId and DeleteFlag=0 
		and [Upcoming Delivery Date] > isnull(@ActualDeliveryDate, @LastCountDate) and [Upcoming Delivery Date] < cast(@UpcomingDeliveryDate as date)
									
		Select @GoodsInTransit= SUM(isnull([Qty],0)) from StoreTransactions S 
		where S.SupplierID=@Supplier and S.StoreID=@StoreId and S.ProductId=@ProductId and S.TransactionTypeId =39
		and SaleDateTime > isnull(@ActualDeliveryDate, @LastCountDate) and SaleDateTime < cast(@UpcomingDeliveryDate as date)
		
		set @TotalDeliveredUnits = isnull(@ActualDeliveredUnits,0) + isnull(@GoodsInTransitHistory,0) + isnull(@GoodsInTransit,0)
		
--		select @GoodsInTransit, @GoodsInTransitHistory, @ActualDeliveredUnits
		----Uncomment below lines to check individual actual delivery records

		--Select *
		--from StoreTransactions ST 
		--inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		--where T.BucketType=2 and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ProductId=@ProductId --and  T.TransactionTypeId <>39 
		--and SaleDateTime > @LastCountDate and SaleDateTime<@UpcomingDeliveryDate

		----Uncomment below lines to check individual delivery records in PO History Table.
		--Select * from PO_PurchaseOrderHistoryData_Revised PD 
		--where PD.SupplierID=@Supplier and PD.StoreID=@StoreId and PD.ProductId=@ProductId and DeleteFlag=0 
		-- and [Upcoming Delivery Date] > @LastCountDate and [Upcoming Delivery Date] < cast(@UpcomingDeliveryDate as date)
		 
		--------------------------------------------------------------------------------------------------------------------------------------------------------------
		--      POS UNITS DATA
		--------------------------------------------------------------------------------------------------------------------------------------------------------------
		Declare @POSUnits int, @POSDate date

		Select @POSDate=max(SaleDateTime) from StoreTransactions S 
		inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
		where T.BucketType=1 and S.SupplierID=@Supplier and S.StoreID=@StoreId
		and SaleDateTime > @LastCountDate and SaleDateTime < @UpcomingDeliveryDate
						  
		Select @POSUnits = SUM(isnull(qty,0)*QtySign)
			  from StoreTransactions ST 
		inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		where T.BucketType=1 and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		and SaleDateTime > case when @InventoryTakenBeginOfDay=1 then dateadd(d,-1,@LastCountDate) else @LastCountDate end  
		and SaleDateTime < @UpcomingDeliveryDate
		group by ST.SupplierId, ST.StoreId, ST.ProductId, ST.TransactionTypeId

		----Uncomment below lines to check individual POS Records
		--Select *
		--from StoreTransactions ST 
		--inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		--where T.BucketType=1 and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ProductId=@ProductId 
		--and SaleDateTime > @LastCountDate and SaleDateTime<@UpcomingDeliveryDate

		--------------------------------------------------------------------------------------------------------------------------------------------------------------
		--      CREDIT UNITS DATA
		--------------------------------------------------------------------------------------------------------------------------------------------------------------

		Declare @CreditUnits int

		Select @CreditUnits = SUM(isnull(qty,0)) from StoreTransactions ST 
		where ST.TransactionTypeID in (21,8,14)
		and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		and SaleDateTime > case when @InventoryTakenBeforeDeliveries=1 then dateadd(d,-1,@LastCountDate) else @LastCountDate end  
		and SaleDateTime < @UpcomingDeliveryDate
		 
		insert into PO_TempPurchaseOrderHistoryData 
		select top 1 @StoreSetupId, @PODate, SupplierID, StoreId, ProductId, convert(varchar(10),SaleDateTime,101) as LastCountDate, 
		case when TransactionTypeID=10 then 'PM' else 'AM' end as LastCountTime, Qty as LastCountQty, 
		@ActualDeliveryDate, NULL, NULL, @POSDate, 
		isnull(@POSUnits,0) as POSUnits, isnull(@CreditUnits,0) as CreditUnits, @TotalDeliveredUnits as DeliveredUnits, 
		ROUND(@DailySales/@DateRange,1) as AvgDailySales,
		DATEDIFF(d, SaleDateTime, @UpcomingDeliveryDate) as [DaysToDelivery],
		DATEDIFF(d, SaleDateTime, @UpcomingDeliveryDate) + @DaysToNextDelivery as [DaysToNextDelivery],
		@PlanogramCapacityMin as MinCapacity, @PlanogramCapacityMax as MaxCapacity, @PAD as PAD, @LeadTime,
		@UpcomingDeliveryDate, @UpcomingDeliveryTime, @NextDeliveryDate, 
		
		case when TransactionTypeID=10 and @UpcomingDeliveryTime='PM' then 0
			 when TransactionTypeID=11 and @UpcomingDeliveryTime='AM' then 0
			 when TransactionTypeID=10 and @UpcomingDeliveryTime='AM' then -0.5
			 when TransactionTypeID=11 and @UpcomingDeliveryTime='PM' then 0.5
		end as DeliveryTimeFactor,
		
		case when TransactionTypeID=10 and RIGHT(@DaysToNextDelivery,2)='.5' then 'AM'
			 when TransactionTypeID=10 and RIGHT(@DaysToNextDelivery,2)<>'.5' then 'PM'
			 when TransactionTypeID=11 and RIGHT(@DaysToNextDelivery,2)='.5' then 'PM'
			 when TransactionTypeID=11 and RIGHT(@DaysToNextDelivery,2)<>'.5' then 'AM'
		end as NextDeliveryTime, DATEDIFF(d, isnull(@POSDate,@LastCountDate),@UpcomingDeliveryDate) as [MissingPOSDaysToDelivery],
		@TotalSeasonDays, @InventoryRequiredForSeason, @TotalSeasonDaysBeforeDeliveryDate, @InventoryRequiredForSeasonBeforeDeliveryDate,
		@SupplierItemNumber, @RawStoreIdentifier, @Route
		from StoreTransactions ST where ST.TransactionTypeID in (10, 11)
		and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		order by StoreTransactionID Desc
			
	FETCH NEXT FROM report_cursor 
		INTO @StoreSetupId, @Supplier, @StoreId, @ProductId, @PlanogramCapacityMax, @PlanogramCapacityMin, @DateRange,@PAD, @LeadTime, @UpcomingDeliveryDate, @UpcomingDeliveryTime, @DaysToNextDelivery, @NextDeliveryDate
		
END

CLOSE report_cursor;
DEALLOCATE report_cursor;

Select * from PO_TempPurchaseOrderHistoryData
--Drop the temp tables 
	begin try
			drop table #tmpPO
			drop table #tmpPO1
	end try
	begin catch
	end catch
	
	--InventoryOnLastDelivery is a field that we don't use any more as decided on 5/6/2013 to not use perpetual inventory calcultaed during the VMI process. 
	--We decided to use the last count as the only starting point to the calculation.We kept the fielt in the formula to not disrupt the table structure as it is being used by CDC process.
	
	Select  StoreSetupID, POGenerationDate, SupplierID, StoreId, ProductId, LastCountQty, POSUnits, CreditUnits,DeliveredUnits,  
			LastCountDate ,LastCountTime, LastPOSDate, LastDeliveryDate, LastDeliveryTime, InventoryOnLastDelivery,
			AvgDailySales, DaysToDelivery, DaysToNextDelivery, LeadTime, MissingPOSDaysToDelivery,
			DeliveryDate, DeliveryTime, NextDeliveryDate, DeliveryTimeFactor,NextDeliveryTime,
			PAD, MaxCapacity, MinCapacity,
			(isnull(InventoryOnLastDelivery, LastCountQty) - isnull(POSUnits,0) - isnull(CreditUnits,0) + isnull(DeliveredUnits,0) 
			- CEILING(isnull(AvgDailySales,0)*(MissingPOSDaysToDelivery - ISNULL(TotalSeasonDaysBeforeDeliveryDate,0) + DeliveryTimeFactor))) 
			+ isnull(InventoryRequiredForSeasonDaysBeforeDeliveryDate,0) as [EndingInventoryOnNextDeliveryDate],
			CEILING((isnull(AvgDailySales,0)*(DaysToNextDelivery-DaysToDelivery- DeliveryTimeFactor-ISNULL(TotalSeasonDays,0))) * (1+(PAD/100))) 
			+ isnull(InventoryRequiredForSeasonDays,0) as [QtyNeeded], SupplierItemNumber, RawStoreIdentifier, Route
			
	into #tmpPO
	from PO_TempPurchaseOrderHistoryData 
	
	--Select * from #tmpPO
	
	Select StoreSetupID, POGenerationDate, SupplierID, StoreId, ProductId, LastCountQty, POSUnits, CreditUnits,DeliveredUnits,  
			LastCountDate ,LastCountTime, LastPOSDate, LastDeliveryDate, LastDeliveryTime, InventoryOnLastDelivery,
			AvgDailySales, DaysToDelivery, DaysToNextDelivery, LeadTime, MissingPOSDaysToDelivery,
			DeliveryDate, DeliveryTime, NextDeliveryDate, DeliveryTimeFactor,NextDeliveryTime,
			PAD, MaxCapacity, MinCapacity,
			[EndingInventoryOnNextDeliveryDate] as [Inv on Hand], [QtyNeeded], 
			case when [EndingInventoryOnNextDeliveryDate]>0 then
				[EndingInventoryOnNextDeliveryDate]
			else
				0
			end as [EndingInventoryOnNextDeliveryDate],
			
			case when [EndingInventoryOnNextDeliveryDate]<=0 then
				[QtyNeeded] 
			else
				[QtyNeeded]  - [EndingInventoryOnNextDeliveryDate] 
			end as [Qnt Needed], 
			
			case when ([QtyNeeded] + MinCapacity - [EndingInventoryOnNextDeliveryDate])  > MaxCapacity then
				MaxCapacity
			when ([QtyNeeded] + MinCapacity - [EndingInventoryOnNextDeliveryDate])  < 0 then
				0
			else
				[QtyNeeded] + MinCapacity - [EndingInventoryOnNextDeliveryDate]
			end as [PO Units],
				
			SupplierItemNumber, RawStoreIdentifier, Route 
	into #tmpPO1
	from #tmpPO
	
	--select * from #tmpPO1
	
	UPDATE V
	SET
	   DeleteFlag = 1
	FROM
		PO_PurchaseOrderHistoryData_Revised V
		Inner join [#tmpPO1] T on T.StoreSetupID=V.StoreSetupID and T.DeliveryDate=V.[Upcoming Delivery Date]
	
	Insert into PO_PurchaseOrderHistoryData_Revised 
		Select StoreSetupID, POGenerationDate, S.SupplierId, S.SupplierName, C.ChainId, C.ChainName, 
		ST.Custom1 as Banner, ST.StoreId, ST.StoreIdentifier, 
		P.ProductId, left(p.ProductName,22) as ProductName, PD.IdentifierValue as [UPC],
		LastCountDate, LastCountTime, LastPOSDate, LastDeliveryDate, LastDeliveryTime, InventoryOnLastDelivery,
		LeadTime, (DaysToDelivery + DeliveryTimeFactor) as DaysToDelivery, 
		(MissingPOSDaysToDelivery+ DeliveryTimeFactor) as MissingPOSDaysToDelivery, 
		convert(varchar(10), DeliveryDate, 101) as [Upcoming Delivery Date], 
		DeliveryTime as [Upcoming Delivery Time],
		DaysToNextDelivery-(DaysToDelivery + DeliveryTimeFactor) as DaysToNextDelivery, convert(varchar(10), NextDeliveryDate, 101)  as  [Subsequent Delivery Date], 
		NextDeliveryTime as [Subsequent Delivery Time],
		POSUnits, LastCountQty, CreditUnits, DeliveredUnits, AvgDailySales, [QtyNeeded], 
		[EndingInventoryOnNextDeliveryDate], 
		case when [Qnt Needed]>0 then 
			[Qnt Needed]
		else
			NULL
		end as [Sale Driven Reorder Qty], MinCapacity, MaxCapacity, 
		
		case when [PO Units]>0 then [PO Units]  else NULL end as [PO Units],
		case when [PO Units]>0 then [PO Units]  else NULL end as [Order Units], 
		
		case when [Inv on Hand]<0 then
			abs([Inv on Hand])
		else
			NULL
		end as [Shortage Before Delivery],
		
		case when [Qnt Needed]-MaxCapacity>0 then  
			[Qnt Needed]-MaxCapacity
		else	
			NULL
		end	as [Potential Shortage],
		
		case when [PO Units] is null and [EndingInventoryOnNextDeliveryDate]>[QtyNeeded] then  
			abs([EndingInventoryOnNextDeliveryDate]-[QtyNeeded])
		else	
			NULL
		end	as [Potential Surplus], 0, SupplierItemNumber, RawStoreIdentifier, Route, GETDATE()
		
		from [#tmpPO1] t
		inner join Suppliers S on S.SupplierID=T.SupplierID
		inner join Stores ST on ST.StoreID= T.StoreId
		inner join Chains C on C.ChainID=St.ChainID
		inner join Products P on P.ProductID=t.ProductId
		inner join ProductIdentifiers PD on PD.ProductID=t.ProductId and PD.ProductIdentifierTypeID=2 
					 
	UPDATE V
	SET
	   V.[Order Units] = T.[Order Units]
	FROM
		PO_PurchaseOrderHistoryData_Revised V
		Inner join PO_PurchaseOrderHistoryData_Revised T on T.StoreSetupID=V.StoreSetupID and T.[Upcoming Delivery Date]=V.[Upcoming Delivery Date]
		where T.DeleteFlag=1 and T.[PO Units]<>T.[Order Units]
	
	UPDATE PO_PurchaseOrderHistoryData_Revised
	SET  [Potential Shortage] = case when ( [Sale Driven Reorder Qty] > [Order Units]) then [Sale Driven Reorder Qty] - [Order Units] else Null end, 
	[Potential Surplus]= case when  ([Order Units]  > [Sale Driven Reorder Qty]) then [Order Units]  - [Sale Driven Reorder Qty] else Null end
	
	Truncate table PO_TempPurchaseOrderHistoryData
	
	Delete From PO_PurchaseOrderHistoryData_Revised where DeleteFlag=1
	
	UPDATE V
	SET
	   V.RawStoreIdentifier=T.RawStoreIdentifier,
	   V.SupplierItemNumber=T.SupplierItemNumber,
	   V.Route=T.Route
	FROM
		PO_PurchaseOrderHistoryData_Revised V
		Inner join (Select distinct SupplierID, StoreID, ProductId, RawStoreIdentifier, SupplierItemNumber, Route 
					from StoreTransactions where TransactionTypeID in (5,8) and SupplierID=@SupplierId and ChainId=@ChainId  
					)  as T on T.SupplierID=V.SupplierId and T.StoreId=V.StoreId and T.ProductId=V.ProductId 
	Where (V.RawStoreIdentifier is null or V.SupplierItemNumber is null or V.Route is null) and V.SupplierID=@SupplierId and V.ChainId=@ChainId 
	
	select * from PO_PurchaseOrderHistoryData_Revised order by POGenerationDate
End
GO
