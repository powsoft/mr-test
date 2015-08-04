USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SharedShrinkValues]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_SharedShrinkValues]
    @ChainId varchar(10),
    @SupplierId varchar(10)
as
Begin
    Declare @sqlQuery varchar(4000)

    set @sqlQuery = ' Select     S.SupplierName, C.ChainName,
      (cast(SupplierShrinkRatio * 100 as varchar)  + '' %'') as [SupplierShrinkRatio], 
      (cast(RetailerShrinkRatio * 100 as varchar)  + '' %'') as [RetailerShrinkRatio], 
      (cast(FromShrinkUnitsDIVPOSUnits * 100 as varchar)  + '' %'') as [FromShrinkUnitsDIVPOSUnits], 
      (cast(ToShrinkUnitsDIVPOSUnits * 100 as varchar)  + '' %'') as [ToShrinkUnitsDIVPOSUnits], 
      ShrinkPercentRangeAggregationMethod as [ShrinkPercentRangeAggregationMethod], 
      SS.SharedShrinkID,SS.ShrinkPercentRangeAggregationMethod,SS.ActiveStartDate, SS.ActiveLastDate
      from dbo.SharedShrinkValues SS
      inner join Suppliers S on S.SupplierId=SS.SupplierId
      inner join Chains C on C.ChainId = SS.ChainId '
                
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainID= ' + @ChainId

    if(@SupplierId<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierID= ' + @SupplierId                
    
    
    set @sqlQuery = @sqlQuery + ' order by 1,2 '
                
    exec (@sqlQuery);
end
GO
