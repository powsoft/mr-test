USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSharedShrinkValues]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetSharedShrinkValues]
 @SupplierId varchar(20),
 @ChainId varchar(20)
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'Select     
      (cast(FromShrinkUnitsDIVPOSUnits * 100 as varchar)  + '' %'') as [From Shrink $], 
      (cast(ToShrinkUnitsDIVPOSUnits * 100 as varchar)  + '' %'') as [To Shrink $], 
      (cast(SupplierShrinkRatio * 100 as varchar)  + '' %'') as [Supplier Shrink Ratio], 
      (cast(RetailerShrinkRatio * 100 as varchar)  + '' %'') as [Retailer Shrink Ratio], 
      ShrinkPercentRangeAggregationMethod as [Shrink Percent Range Aggregation Method], 
      convert(varchar(20), ActiveStartDate, 101) as [Start Date], 
      convert(varchar(20), ActiveLastDate , 101) as [Last Date]
      from SharedShrinkValues 
      where (FromShrinkUnitsDIVPOSUnits+ToShrinkUnitsDIVPOSUnits+SupplierShrinkRatio+RetailerShrinkRatio)<>0'

  if(@SupplierId <>'-1' ) 
   set @sqlQuery = @sqlQuery + ' and SupplierId = ' + @SupplierId 
   
  if(@ChainId <>'-1' ) 
   set @sqlQuery = @sqlQuery + ' and ChainID = ' + @ChainId 
   
  execute(@sqlQuery); 

End
GO
