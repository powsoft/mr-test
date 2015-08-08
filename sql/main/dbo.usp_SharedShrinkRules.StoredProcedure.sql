USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SharedShrinkRules]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_SharedShrinkRules]
@SupplierID varchar(50),
@ChainId varchar(50),
@Banner varchar(100),
@SharedShrinkMax varchar(100),
@MaxShrinkCap varchar(100)

-- [usp_ShrinkRules] '-1','-1','-1','1','1'
as

Begin

Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'SELECT SR.SSID,C.ChainName,S.SupplierName,B.Banner,
					 CASE WHEN SR.SharedShrinkMaxCalculated = 1 THEN ''Net Delivery $''
					 WHEN SR.SharedShrinkMaxCalculated = 2 THEN ''POS $''
					 ELSE '''' END AS [Shared Shrink Max $ is Calculated as a % of],
					 CASE WHEN SR.MaxShrinkCapAppliedToMaxPercentages = 1 THEN ''Yes''
					 ELSE ''No'' END AS [Max Shrink Cap Applied to Max Percentages]
						FROM SharedShrinkRules SR
						INNER JOIN Chains C ON C.ChainID=SR.ChainID
						INNER JOIN Suppliers S on S.SupplierID=SR.SupplierID
						INNER JOIN SupplierBanners B ON B.Banner=SR.Banner and B.SupplierID=S.SupplierID and B.ChainID=C.ChainID
					    and B.Status=''Active''
						WHERE 1=1 and SR.IsDelete = 0 '
                 
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId
        
    if(@SupplierID<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierID=' + @SupplierID    

    if(@Banner<>'-1')
        set @sqlQuery = @sqlQuery + ' and B.Banner=''' + @Banner + ''''
        
    if (@SharedShrinkMax<>'-1')
		set @sqlQuery+= ' and SR.SharedShrinkMaxCalculated = ' + @SharedShrinkMax 

    if(@MaxShrinkCap<>'')
        set @sqlQuery = @sqlQuery + ' and SR.MaxShrinkCapAppliedToMaxPercentages=' + @MaxShrinkCap 

    EXEC(@sqlQuery)
End
GO
