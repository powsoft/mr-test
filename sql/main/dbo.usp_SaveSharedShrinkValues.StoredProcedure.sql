USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveSharedShrinkValues]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SaveSharedShrinkValues]
     @SharedShrinkId int,
     @SupplierShrinkRatio money ,
     @RetailerShrinkRatio money,
     @FromShrinkUnitsDIVPOSUnits money ,
     @ToShrinkUnitsDIVPOSUnits money ,
     @ShrinkPercentRangeAggregationMethod varchar(50),
     @ActiveStartDate datetime,
     @ActiveLastDate datetime

as
     
if (@SharedShrinkId > 0)

begin
        Update [dbo].[SharedShrinkValues] Set
                [SupplierShrinkRatio]= @SupplierShrinkRatio,
                [RetailerShrinkRatio] =  @RetailerShrinkRatio,
                [FromShrinkUnitsDIVPOSUnits] = @FromShrinkUnitsDIVPOSUnits,
                [ToShrinkUnitsDIVPOSUnits] = @ToShrinkUnitsDIVPOSUnits,
                [ShrinkPercentRangeAggregationMethod] = @ShrinkPercentRangeAggregationMethod,
                [ActiveStartDate] = @ActiveStartDate,
                [ActiveLastDate] =  @ActiveLastDate
        where [SharedShrinkID] =@SharedShrinkId
end
GO
