USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ShrinkRules]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ShrinkRules]
@SupplierID varchar(50),
@ChainId varchar(50),
@Banner varchar(100),
@ShrinkCalculation varchar(100),
@OtherOptions varchar(100)

-- [usp_ShrinkRules] '40393','-1','-1','1','1'
as

Begin

Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'SELECT SR.SID,C.ChainName,S.SupplierName,B.Banner,
					 CASE WHEN SR.ShrinkCalculationMethod = 1  THEN ''Weighted Avg Cost'' 
					 WHEN SR.ShrinkCalculationMethod = 2 THEN ''LIFO'' 
					 WHEN SR.ShrinkCalculationMethod = 3 THEN ''FIFO''  
					 ELSE '''' END AS [Shrink Calculation Method],
					 CASE WHEN SR.NoCountSubmittedOnUPCWithinStoreCount = 1 then ''Enter 0''
					 WHEN SR.NoCountSubmittedOnUPCWithinStoreCount = 2 THEN ''Data rolls into next settlement''
					 ELSE '''' END AS [No Count Submitted On UPC With in Store Count]
						FROM ShrinkRules SR
						INNER JOIN Chains C ON C.ChainID=SR.ChainID
						INNER JOIN Suppliers S on S.SupplierID=SR.SupplierID
						INNER JOIN SupplierBanners B ON B.Banner=SR.Banner and B.SupplierID=S.SupplierID and B.ChainID=C.ChainID
					    and B.Status=''Active''
						WHERE 1=1 and SR.IsDelete=0 '
                 
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId
        
    if(@SupplierID<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierID=' + @SupplierID    

    if(@Banner<>'-1')
        set @sqlQuery = @sqlQuery + ' and B.Banner=''' + @Banner + ''''
        
    if (@ShrinkCalculation<>'-1')
		set @sqlQuery+= ' and SR.ShrinkCalculationMethod = ' + @ShrinkCalculation 

    if(@OtherOptions<>'')
        set @sqlQuery = @sqlQuery + ' and SR.NoCountSubmittedOnUPCWithinStoreCount=' + @OtherOptions 

    EXEC(@sqlQuery)
    print(@sqlQuery)
End
GO
