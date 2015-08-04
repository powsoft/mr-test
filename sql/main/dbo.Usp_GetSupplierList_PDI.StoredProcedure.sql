USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[Usp_GetSupplierList_PDI]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Usp_GetSupplierList_PDI]
 @ManufacturerId varchar(50),
 @ChainId varchar(20),
 @SupplierId varchar(20),
 @BannerName varchar(max),
 @AlcoholLogin int
as

Begin

Declare @sqlQuery varchar(4000)
	
	set @BannerName = replace(@BannerName, '''''', '''')
	set @BannerName = replace(@BannerName, '''', '''''')

	set @sqlQuery = 'Select distinct S.SupplierId, S.SupplierName from Suppliers S WITH(NOLOCK) 
					 where S.SupplierId<>35113 '
		
	if(@ManufacturerId <> '-1' and @ManufacturerId <> '') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (select distinct SS.SupplierId
										from Manufacturers M WITH(NOLOCK)
										inner join Brands B WITH(NOLOCK) on B.ManufacturerId=M.ManufacturerId
										inner join ProductBrandAssignments PBA WITH(NOLOCK) on PBA.BrandId=B.BrandID
										inner join StoreSetup SS WITH(NOLOCK) on SS.ProductId=PBA.ProductID
										where M.ManufacturerId= ' + @ManufacturerId + ')'
	
	if(@SupplierId <> '-1' and @SupplierId <> '') 
		set @sqlQuery  = @sqlQuery  + ' and S.SupplierId =' + @SupplierId

	if(@ChainId <> '-1' and @ChainId <> '') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (Select distinct SupplierId from SupplierBanners WITH(NOLOCK) where ChainId in(' + @ChainId + '))'
	else
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (select distinct SupplierId from SupplierBanners ss WITH(NOLOCK) where ChainId <> 35541)'
			
	if(@BannerName <> '-1' and @BannerName <> '' and @BannerName <> 'FULL') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (Select distinct SS.SupplierId from SupplierBanners SS WITH(NOLOCK) where Status=''Active'' 
										and Banner in(SELECT * FROM dbo.split('''+ @BannerName + ''', '','')))'	
		
	if (@AlcoholLogin=1)
        set @sqlQuery = @sqlQuery + ' and S.SupplierId in (42255, 43415, 43417,43416) '
                    
	set @sqlQuery = @sqlQuery + ' and PDITradingPartner=1 order by S.SupplierName '
	
	exec(@sqlQuery); 
    print (@sqlQuery); 
End
GO
