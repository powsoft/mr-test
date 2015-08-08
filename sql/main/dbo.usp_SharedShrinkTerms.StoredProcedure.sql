USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SharedShrinkTerms]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_SharedShrinkTerms]
    @ChainId varchar(10),
    @SupplierId varchar(10),
    @AggregateMethod varchar(20)
as --exec usp_SharedShrinkTerms '-1','-1','Banner'
Begin
    Declare @sqlQuery varchar(4000)

    set @sqlQuery = ' Select     S.SupplierName, C.ChainName,
      (cast(SupplierShrinkRatio * 100 as varchar)  + '' %'') as [SupplierShrinkRatio], 
      (cast(RetailerShrinkRatio * 100 as varchar)  + '' %'') as [RetailerShrinkRatio], 
      (cast(FromShrinkUnitsDIVPOSUnits * 100 as varchar)  + '' %'') as [FromShrinkUnitsDIVPOSUnits], 
      (cast(ToShrinkUnitsDIVPOSUnits * 100 as varchar)  + '' %'') as [ToShrinkUnitsDIVPOSUnits], 
      ShrinkPercentRangeAggregationMethod,'
      If (@AggregateMethod='Store') 
       set @sqlQuery += ' St.StoreIdentifier as ShrinkPercentRangeAggregationValue,SS.ShrinkPercentRangeAggregationValue as StoreID,'
      else
       set @sqlQuery += 'SS.ShrinkPercentRangeAggregationValue,'''' as StoreID,'
      
       
       set @sqlQuery += ' SS.SharedShrinkID, convert(varchar(10),SS.ActiveStartDate, 101) as ActiveStartDate, convert(varchar(10),SS.ActiveLastDate,101) as ActiveLastDate'
       set @sqlQuery += ' from dbo.SharedShrinkTerms SS'
       set @sqlQuery += ' inner join Suppliers S on S.SupplierId=SS.SupplierId'
			 set @sqlQuery += ' inner join Chains C on C.ChainId = SS.ChainId '
			 If (@AggregateMethod='Store') 
			 begin 
					set @sqlQuery += ' inner join Stores St  on St.StoreID = SS.ShrinkPercentRangeAggregationValue '
			 End 
                
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainID= ' + @ChainId

    if(@SupplierId<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierID= ' + @SupplierId                
    if(@AggregateMethod<>'-1')
		Begin
					IF(@AggregateMethod='Chain')
					set @sqlQuery = @sqlQuery + ' and ShrinkPercentRangeAggregationMethod='''''
					If (@AggregateMethod='Banner')
					set @sqlQuery = @sqlQuery + ' and ShrinkPercentRangeAggregationMethod=''Banner'''
					If (@AggregateMethod='Store')
					set @sqlQuery = @sqlQuery + ' and ShrinkPercentRangeAggregationMethod=''Store'''
    End
    set @sqlQuery = @sqlQuery + ' order by  1,2 DESC'
                
    exec (@sqlQuery);
    
end
GO
