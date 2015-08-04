USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Generate_Purchase_Data_Manual]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Delivery Date - Lead time =  PO generation Date
-- exec [usp_Generate_Purchase_Data_Manual] '44246','44199', '', '-1', '', '2013-04-27','2013-05-01'
CREATE procedure [dbo].[usp_Generate_Purchase_Data_Manual]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50),
@Banner varchar(50),
@UPC varchar(50), 
@PODate varchar(20),
@ExpectedDeliveryDate varchar(20)
as 
Begin
set nocount on
	begin try
		Drop table [@tmpPOData]
		Drop Table [#tmpSaleDates]
	end try
	begin catch
	end catch
	
	Declare @strSQL varchar(2000)
	
	set @strSQL= 'select distinct SS.StoreSetupId, SS.SupplierID, SS.StoreID, SS.ProductID, POC.PlanogramCapacityMax, POC.PlanogramCapacityMin, POC.DateRange, POC.FillRate, POC.LeadTime, 
		''' + @ExpectedDeliveryDate + ''' as DeliveryDate, rtrim(POD.DeliveryTime) as DeliveryTime,  POD.DaysToNextDelivery, 
		dateadd(d, isnull(POD.DaysToNextDelivery,1),''' + @ExpectedDeliveryDate + ''' ) as NextDeliveryDate
		into [@tmpPOData]
		from PO_Criteria POC 
		inner join PO_DeliveryDates POD on POD.StoreSetupId=POC.StoreSetupID
		inner join StoreSetup SS on SS.StoreSetupID = POC.StoreSetupID
		inner join Stores S on S.StoreID = SS.StoreID
		Inner join SupplierBanners SB on SB.SupplierId = SS.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
		inner join ProductIdentifiers P on P.ProductId= SS.ProductId
		where  (POC.ReplenishmentType=''Daily'' 
		or (POC.ReplenishmentType=''Weekly'' and LEN(POD.DeliveryDayOrDate)< 3  and datePart(weekday,''' + @ExpectedDeliveryDate + ''')=POD.DeliveryDayOrDate)
		or (POC.ReplenishmentType=''Monthly'' and LEN(POD.DeliveryDayOrDate)< 3 and datename(dd,''' + @ExpectedDeliveryDate + ''')=POD.DeliveryDayOrDate)
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
	Select * from [@tmpPOData]
	Declare @StoreSetupId varchar(10), @Supplier varchar(10), @StoreId varchar(10), @ProductId varchar(10), @PlanogramCapacityMax int, @PlanogramCapacityMin int, @DateRange int, @PAD float, @LeadTime int, 
	@DeliveryDate date,	@DeliveryTime varchar(10), @DaysToNextDelivery float, @NextDeliveryDate date
	DECLARE report_cursor CURSOR FOR 
		
	Select * from [@tmpPOData]			
	
	OPEN report_cursor;
	FETCH NEXT FROM report_cursor 
		INTO @StoreSetupId, @Supplier, @StoreId, @ProductId, @PlanogramCapacityMax, @PlanogramCapacityMin, @DateRange,@PAD, @LeadTime, @DeliveryDate, @DeliveryTime, @DaysToNextDelivery, @NextDeliveryDate
	
	while @@FETCH_STATUS = 0
		begin
		Declare @DailySales float
		Declare @LastTransDate Datetime
		
		Delete from PO_TempPurchaseOrderHistoryData  where SupplierID=@Supplier and StoreId=@StoreId and ProductId=@ProductId and DeliveryDate=@DeliveryDate and POGenerationDate=@PODate
		
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
			Drop Table [#tmpSaleDates]
		end try
		begin catch
		end catch
	
		Select distinct SaleDateTime into [#tmpSaleDates] from StoreTransactions ST 
						inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
						where BucketType=1 and SupplierID= @Supplier and StoreID= @StoreId and ProductId=@ProductId
						and SaleDateTime<=@LastTransDate and SaleDateTime >= dateadd(d, -1 * @DateRange, @LastTransDate)
		
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
			Delete from [#tmpSaleDates] where SaleDateTime between @SeasonStart and @SeasonEnd
			FETCH NEXT FROM seasondate_cursor INTO @SeasonStart, @SeasonEnd
		end
		CLOSE seasondate_cursor;
		DEALLOCATE seasondate_cursor;
		--===============================================================================================================
		
		set @DailySales=NULL
		Select @DailySales = SUM(Qty) from StoreTransactions ST 
						inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
						where BucketType=1 and SupplierID= @Supplier and StoreID= @StoreId and ProductId=@ProductId 
						and SaleDateTime in ( select top (@DateRange) SaleDatetime from [#tmpSaleDates] order by SaleDateTime Desc)
		
		
		--Last Count Date
		Declare @LastCountDate varchar(10)
		set @LastCountDate=NULL
		Select top 1 @LastCountDate=convert(varchar(10),SaleDateTime,101) 
		from StoreTransactions ST where ST.TransactionTypeID in (10, 11)
		and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		order by StoreTransactionID Desc
		
		Declare @LastTransactionDateForSeasonality varchar(10)
		
		set @LastTransactionDateForSeasonality= case when @LastCountDate>@LastTransDate then convert(varchar(10),@LastCountDate,101) else convert(varchar(10),@LastTransDate,101) end
		
		print 'last count' + cast(@LastCountDate  as varchar)
		print 'last trans' + cast(@LastTransactionDateForSeasonality as varchar)
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
			if(@SeasonStart<@LastTransactionDateForSeasonality and @SeasonEnd<=@DeliveryDate)
			begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @LastTransactionDateForSeasonality, @SeasonEnd)
			end
			
			--Season Started before Last Count and will end after DeliveryDate 
			else if(@SeasonStart<@LastTransactionDateForSeasonality and @SeasonEnd>@DeliveryDate)
			Begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @LastTransactionDateForSeasonality, @DeliveryDate)
			end
			
			--Season start after Last count date and will end before DeliveryDate 
			else if(@SeasonStart>=@LastTransactionDateForSeasonality and @SeasonStart<=@DeliveryDate  and @SeasonEnd<=@DeliveryDate)
			Begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @SeasonStart, @SeasonEnd)
			end
			
			--Season start after Last count date and will end after DeliveryDate 
			else if(@SeasonStart>=@LastTransactionDateForSeasonality and @SeasonStart<=@DeliveryDate and @SeasonEnd>@DeliveryDate)
			Begin
				set @SeasonDaysBeforeDeliveryDate = DATEDIFF(d, @SeasonStart, @DeliveryDate)
			end
			
			set @TotalSeasonDaysBeforeDeliveryDate += @SeasonDaysBeforeDeliveryDate
			set @InventoryRequiredForSeasonBeforeDeliveryDate += CEILING(((ROUND(@DailySales/@DateRange,1) * (1+@ChangeRate/100)) * (@SeasonDaysBeforeDeliveryDate))) 
			 
			 set @SeasonDays=0
			 --Calculate Seasondays between Delivery Date and Next Delivery Date
			--Season Already Started and will end before NextDeliveryDate 
			if(@SeasonStart<@DeliveryDate and @SeasonEnd<=@NextDeliveryDate)
			begin
				set @SeasonDays = DATEDIFF(d, @DeliveryDate, @SeasonEnd)
			end
			
			--Season Already Started and will end after NextDeliveryDate 
			else if(@SeasonStart<@DeliveryDate and @SeasonEnd>@NextDeliveryDate)
			Begin
				set @SeasonDays = DATEDIFF(d, @DeliveryDate, @NextDeliveryDate)
			end
			
			--Season start after DeliveryDate and will end before NextDeliveryDate 
			else if(@SeasonStart>=@DeliveryDate and @SeasonEnd<=@NextDeliveryDate)
			Begin
				set @SeasonDays = DATEDIFF(d, @SeasonStart, @SeasonEnd)
			end
			
			--Season start after DeliveryDate and will end after NextDeliveryDate 
			else if(@SeasonStart>=@DeliveryDate and @SeasonEnd>@NextDeliveryDate)
			Begin
				set @SeasonDays = DATEDIFF(d, @SeasonStart, @NextDeliveryDate)
			end
			set @TotalSeasonDays += @SeasonDays + @SeasonDaysBeforeDeliveryDate
			set @InventoryRequiredForSeason += CEILING(((ROUND(@DailySales/@DateRange,1) * (1+@ChangeRate/100)) * (@SeasonDays)) * (1+(@SeasonFillRate/100))) + @InventoryRequiredForSeasonBeforeDeliveryDate 
			
			FETCH NEXT FROM season_cursor INTO @SeasonStart, @SeasonEnd, @SeasonFillRate, @ChangeRate
		end
		CLOSE season_cursor;
		DEALLOCATE season_cursor;
		
		--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		--===============================================================================================================
		-- (Begin) Counting for already predicted deliveries stored in the History Table
		--===============================================================================================================
		--Last Delivery Date
		Declare @LastDeliveryDate varchar(10), @LastDeliveryTime varchar(2), @LastDeliveredUnits int, @InventoryOnLastDelivery int, @PendingDeliveryDate varchar(10), @PendingDeliveredUnits int
		set @LastDeliveryDate=NULL
		set @LastDeliveryTime=NULL
		set @LastDeliveredUnits=NULL
		set @InventoryOnLastDelivery=NULL
		
		Select top 1 @LastDeliveryDate=convert(varchar(10),[Upcoming Delivery Date],101) ,
		@LastDeliveryTime= [Upcoming Delivery Time], @LastDeliveredUnits=[Order Units], @InventoryOnLastDelivery=EndingInventoryOnNextDeliveryDate
		from PO_PurchaseOrderHistoryDataManual PD 
		where DeleteFlag=0 and PD.StoreSetupId=@StoreSetupId and [Upcoming Delivery Date]>cast(@LastCountDate as date) and [Upcoming Delivery Date]< cast(@DeliveryDate as date)
		order by [Upcoming Delivery Date] Desc
		
		--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		--===============================================================================================================
		-- (Begin) Counting for Pending Deliveries marked with TransactionTypeId=39 in StoreTransactions Table
		--===============================================================================================================
		
		set @LastDeliveryDate=ISNULL(@LastDeliveryDate,@LastCountDate)
		
		Select top 1 @PendingDeliveryDate=convert(varchar(10),SaleDateTime,101), @PendingDeliveredUnits=sum(Qty)
		from StoreTransactions ST 
		where ST.TransactionTypeID=39 and ST.SupplierID=@SupplierId and ST.ChainID=@ChainId and ST.StoreID=@StoreId and ST.ProductID=@ProductId 
		and SaleDateTime>cast(@LastDeliveryDate as date) and SaleDateTime< cast(@DeliveryDate as date)
		group by convert(varchar(10),SaleDateTime,101)
		order by convert(varchar(10),SaleDateTime,101) Desc
		
		set @LastDeliveryDate=ISNULL(@PendingDeliveryDate,@LastDeliveryDate)
		set @LastDeliveredUnits = ISNULL(@PendingDeliveredUnits,@LastDeliveredUnits)
		
		--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		Declare @POSUnits int, @POSDate varchar(10)
		set @POSUnits=NULL
		set @POSDate=NULL
		
		
		Select @POSUnits = SUM(qty),@POSDate = convert(varchar(10),MAX(SaleDateTime),101)
		from StoreTransactions ST 
		inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		where T.BucketType=1 and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		and SaleDateTime > isnull(@LastDeliveryDate, @LastCountDate) and SaleDateTime < @DeliveryDate
		
		Declare @SupplierItemNumber varchar(50), @RawStoreIdentifier varchar(50), @Route varchar(50)
		set @SupplierItemNumber=NULL
		set @RawStoreIdentifier=NULL
		set @Route=NULL
		
		
		Declare @CreditUnits int
		set @CreditUnits=NULL
		
		Select @CreditUnits = SUM(qty) from StoreTransactions ST 
		where ST.TransactionTypeID in (21,8,14)
		and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		and SaleDateTime > isnull(@LastDeliveryDate, @LastCountDate) and SaleDateTime < @DeliveryDate
		
		Declare @DeliveredUnits int, @ActualDeliveryDate date
		set @DeliveredUnits=NULL
		Select @DeliveredUnits = SUM(qty) from StoreTransactions ST 
		inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		where T.BucketType=2 and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		and SaleDateTime >= isnull(@LastDeliveryDate, @LastCountDate) and SaleDateTime < @DeliveryDate
		
		--Test for any delivery activity at store level even if the product is not delivered actually but was in the pending orders or history table.
		Select @ActualDeliveryDate = max(SaleDateTime) from StoreTransactions ST 
		inner join TransactionTypes T on T.TransactionTypeID=ST.TransactionTypeID
		where T.BucketType=2 and ST.SupplierID=@Supplier and ST.StoreID=@StoreId 
		and SaleDateTime >= isnull(@LastDeliveryDate, @LastCountDate) and SaleDateTime < @DeliveryDate
		
		if(@ActualDeliveryDate is not null and @DeliveredUnits is null)
		begin
			set @DeliveredUnits=0
			set @LastDeliveredUnits=0
		end
		 
		insert into PO_TempPurchaseOrderHistoryData 
		select top 1 @StoreSetupId, @PODate, SupplierID, StoreId, ProductId, convert(varchar(10),SaleDateTime,101) as LastCountDate, 
		case when TransactionTypeID=10 then 'PM' else 'AM' end as LastCountTime, Qty as LastCountQty, 
		@LastDeliveryDate, @LastDeliveryTime, @InventoryOnLastDelivery, @POSDate, 
		isnull(@POSUnits,0) as POSUnits, isnull(@CreditUnits,0) as CreditUnits, (isnull(@DeliveredUnits,@LastDeliveredUnits)) as DeliveredUnits, 
		ROUND(@DailySales/@DateRange,1) as AvgDailySales,
		DATEDIFF(d, SaleDateTime, @DeliveryDate) as [DaysToDelivery],
		DATEDIFF(d, SaleDateTime, @DeliveryDate) + @DaysToNextDelivery as [DaysToNextDelivery],
		@PlanogramCapacityMin as MinCapacity, @PlanogramCapacityMax as MaxCapacity, @PAD as PAD, @LeadTime,
		@DeliveryDate, @DeliveryTime, @NextDeliveryDate, 
		
		case when TransactionTypeID=10 and @DeliveryTime='PM' then 0
			 when TransactionTypeID=11 and @DeliveryTime='AM' then 0
			 when TransactionTypeID=10 and @DeliveryTime='AM' then -0.5
			 when TransactionTypeID=11 and @DeliveryTime='PM' then 0.5
		end as DeliveryTimeFactor,
		
		case when TransactionTypeID=10 and RIGHT(@DaysToNextDelivery,2)='.5' then 'AM'
			 when TransactionTypeID=10 and RIGHT(@DaysToNextDelivery,2)<>'.5' then 'PM'
			 when TransactionTypeID=11 and RIGHT(@DaysToNextDelivery,2)='.5' then 'PM'
			 when TransactionTypeID=11 and RIGHT(@DaysToNextDelivery,2)<>'.5' then 'AM'
		end as NextDeliveryTime, DATEDIFF(d, ISNULL(@LastDeliveryDate,isnull(@POSDate,@LastCountDate)), @DeliveryDate) as [MissingPOSDaysToDelivery],
		@TotalSeasonDays, @InventoryRequiredForSeason, @TotalSeasonDaysBeforeDeliveryDate, @InventoryRequiredForSeasonBeforeDeliveryDate,
		@SupplierItemNumber, @RawStoreIdentifier, @Route
		from StoreTransactions ST where ST.TransactionTypeID in (10, 11)
		and ST.SupplierID=@Supplier and ST.StoreID=@StoreId and ST.ProductID=@ProductId
		order by StoreTransactionID Desc
			
		
	FETCH NEXT FROM report_cursor 
		INTO @StoreSetupId, @Supplier, @StoreId, @ProductId, @PlanogramCapacityMax, @PlanogramCapacityMin, @DateRange,@PAD, @LeadTime, @DeliveryDate, @DeliveryTime, @DaysToNextDelivery, @NextDeliveryDate
		
END

CLOSE report_cursor;
DEALLOCATE report_cursor;

--Select * from PO_TempPurchaseOrderHistoryData
--Drop the temp tables 
	begin try
			drop table #tmpPO
			drop table #tmpPO1
	end try
	begin catch
	end catch

	
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
			
	into [#tmpPO]
	from PO_TempPurchaseOrderHistoryData 
	
	--Select * from [#tmpPO]
	
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
			
			case when [EndingInventoryOnNextDeliveryDate]<=0 and [QtyNeeded] > MaxCapacity then 
				MaxCapacity
			when [EndingInventoryOnNextDeliveryDate]<=0 and [QtyNeeded] < MinCapacity then 
				MinCapacity
			when [EndingInventoryOnNextDeliveryDate]<=0 and [QtyNeeded] > 0 then
				[QtyNeeded] 
			when [EndingInventoryOnNextDeliveryDate]>0 and [EndingInventoryOnNextDeliveryDate]-[QtyNeeded]>0 and ([EndingInventoryOnNextDeliveryDate]-[QtyNeeded])<MinCapacity then 					
				MinCapacity- ([EndingInventoryOnNextDeliveryDate]-[QtyNeeded])
			when [EndingInventoryOnNextDeliveryDate]>0 and ([EndingInventoryOnNextDeliveryDate]-[QtyNeeded]) > MaxCapacity then 					
				MaxCapacity- ([EndingInventoryOnNextDeliveryDate]-[QtyNeeded])
			when [EndingInventoryOnNextDeliveryDate]>0 and [QtyNeeded] < MinCapacity then 					
				MinCapacity  - [EndingInventoryOnNextDeliveryDate]
			when [EndingInventoryOnNextDeliveryDate]>0 and [QtyNeeded]- [EndingInventoryOnNextDeliveryDate] > 0 and [QtyNeeded]- [EndingInventoryOnNextDeliveryDate]>MaxCapacity then
				MaxCapacity- [EndingInventoryOnNextDeliveryDate]
			when [EndingInventoryOnNextDeliveryDate]>0 and [QtyNeeded]- [EndingInventoryOnNextDeliveryDate] > 0 and [QtyNeeded]- [EndingInventoryOnNextDeliveryDate]<MaxCapacity then
				[QtyNeeded]  - [EndingInventoryOnNextDeliveryDate]
			else
				NULL
			end as [PO Units],
			SupplierItemNumber, RawStoreIdentifier, Route 
	into [#tmpPO1]
	from [#tmpPO]
	
	
	UPDATE V
	SET
	   DeleteFlag = 1
	FROM
		PO_PurchaseOrderHistoryDataManual V
		Inner join [#tmpPO1] T on T.StoreSetupID=V.StoreSetupID and T.DeliveryDate=V.[Upcoming Delivery Date]
	
	Insert into PO_PurchaseOrderHistoryDataManual 
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
		PO_PurchaseOrderHistoryDataManual V
		Inner join PO_PurchaseOrderHistoryDataManual T on T.StoreSetupID=V.StoreSetupID and T.[Upcoming Delivery Date]=V.[Upcoming Delivery Date]
		where T.DeleteFlag=1 and T.[PO Units]<>T.[Order Units]
	
	UPDATE PO_PurchaseOrderHistoryDataManual
	SET  [Potential Shortage] = case when ( [Sale Driven Reorder Qty] > [Order Units]) then [Sale Driven Reorder Qty] - [Order Units] else Null end, 
	[Potential Surplus]= case when  ([Order Units]  > [Sale Driven Reorder Qty]) then [Order Units]  - [Sale Driven Reorder Qty] else Null end
	
	Delete From PO_PurchaseOrderHistoryDataManual where DeleteFlag=1
	
	UPDATE V
	SET
	   V.RawStoreIdentifier=T.RawStoreIdentifier,
	   V.SupplierItemNumber=T.SupplierItemNumber,
	   V.Route=T.Route
	FROM
		PO_PurchaseOrderHistoryDataManual V
		Inner join (Select distinct SupplierID, StoreID, ProductId, RawStoreIdentifier, SupplierItemNumber, Route 
					from StoreTransactions where TransactionTypeID in (5,8) and SupplierID=@SupplierId and ChainId=@ChainId  
					)  as T on T.SupplierID=V.SupplierId and T.StoreId=V.StoreId and T.ProductId=V.ProductId 
	Where (V.RawStoreIdentifier is null or V.SupplierItemNumber is null or V.Route is null) and V.SupplierID=@SupplierId and V.ChainId=@ChainId 
	
End
GO
