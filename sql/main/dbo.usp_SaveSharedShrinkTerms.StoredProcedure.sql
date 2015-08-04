USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveSharedShrinkTerms]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_SaveSharedShrinkTerms]
     @SharedShrinkId int,
     @ChainId varchar(10),
     @SupplierId varchar(10),
     @SupplierShrinkRatio money ,
     @RetailerShrinkRatio money,
     @FromShrinkUnitsDIVPOSUnits money ,
     @ToShrinkUnitsDIVPOSUnits money ,
     @ShrinkPercentRangeAggregationMethod varchar(50),
     @ShrinkPercentRangeAggregationValue varchar(50),
     @ActiveStartDate datetime,
     @ActiveLastDate datetime,
     @CalculationMethod varchar(20)

as
     
if (@SharedShrinkId > 0)
	begin
		Update [dbo].[SharedShrinkTerms] Set
				[SupplierShrinkRatio]= @SupplierShrinkRatio,
				[RetailerShrinkRatio] =  @RetailerShrinkRatio,
				[FromShrinkUnitsDIVPOSUnits] = @FromShrinkUnitsDIVPOSUnits,
				[ToShrinkUnitsDIVPOSUnits] = @ToShrinkUnitsDIVPOSUnits,
				[ShrinkPercentRangeAggregationMethod] = @ShrinkPercentRangeAggregationMethod,
				[ShrinkPercentRangeAggregationValue] = @ShrinkPercentRangeAggregationValue,
				[ActiveStartDate] = @ActiveStartDate,
				[ActiveLastDate] =  @ActiveLastDate,
				[CalculationMethod] = @CalculationMethod
		where [SharedShrinkID] =@SharedShrinkId
	end

else

	begin
		INSERT INTO [dbo].[SharedShrinkTerms]
           ([ChainID]
           ,[SupplierID]
           ,[SupplierShrinkRatio]
           ,[RetailerShrinkRatio]
           ,[FromShrinkUnitsDIVPOSUnits]
           ,[ToShrinkUnitsDIVPOSUnits]
           ,[ShrinkPercentRangeAggregationMethod]
           ,[ShrinkPercentRangeAggregationValue]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[CalculationMethod])
     VALUES
           (@ChainId
           ,@SupplierId
           ,@SupplierShrinkRatio
           ,@RetailerShrinkRatio
           ,@FromShrinkUnitsDIVPOSUnits
           ,@ToShrinkUnitsDIVPOSUnits
           ,@ShrinkPercentRangeAggregationMethod
           ,@ShrinkPercentRangeAggregationValue
           ,@ActiveStartDate
           ,@ActiveLastDate
           ,@CalculationMethod)
	end
GO
