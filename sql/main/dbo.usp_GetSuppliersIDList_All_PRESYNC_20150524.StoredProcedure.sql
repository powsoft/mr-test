USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSuppliersIDList_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_GetSuppliersIDList_All] '','40393,42490,44125,44285','','',0
CREATE procedure [dbo].[usp_GetSuppliersIDList_All_PRESYNC_20150524]
 @ManufacturerId varchar(50),
 @ChainId varchar(2000),
 @SupplierId varchar(20),
 @BannerName varchar(max),
 @AlcoholLogin int
as

Begin

Declare @sqlQuery varchar(4000)
	
	set @sqlQuery = 'Select distinct S.SupplierId from Suppliers S 
					 where S.SupplierId<>35113 '
		
	if(@ManufacturerId <> '-1' and @ManufacturerId <> '') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (select distinct SS.SupplierId
										from Manufacturers M 
										inner join Brands B on B.ManufacturerId=M.ManufacturerId
										inner join ProductBrandAssignments PBA on PBA.BrandId=B.BrandID
										inner join StoreSetup SS on SS.ProductId=PBA.ProductID
										where M.ManufacturerId= ' + @ManufacturerId + ')'
	
	if(@SupplierId <> '-1' and @SupplierId <> '') 
		set @sqlQuery  = @sqlQuery  + ' and S.SupplierId =' + @SupplierId

	if(@ChainId <> '-1' and @ChainId <> '') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (Select distinct SupplierId from StoreSetup where ChainId in (' + @ChainId + '))'
	else
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (select distinct SupplierId from dbo.StoreSetup ss where ChainId <> 35541)'
			
	if(@BannerName <> '-1' and @BannerName <> '') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (Select distinct SS.SupplierId from SupplierBanners SS where Status=''Active'' and Banner in(SELECT * FROM dbo.split('''+ @BannerName + ''', '','')))'
		
	if (@AlcoholLogin=1)
        set @sqlQuery = @sqlQuery + ' and S.SupplierId in (42255, 43415, 43417,43416) '
                    
	set @sqlQuery = @sqlQuery + ' order by S.SupplierId '
	
	
	print (@sqlQuery)
	return exec(@sqlQuery); 

End
GO
