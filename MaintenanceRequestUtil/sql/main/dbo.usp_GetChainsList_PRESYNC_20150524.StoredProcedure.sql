USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetChainsList_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetChainsList_PRESYNC_20150524]
 @ManufacturerId varchar(50),
 @ChainId varchar(20),
 @SupplierId varchar(20),
 @BannerName varchar(500)
as
-- exec usp_GetChainsList '','','79891','D&W,Davis Oil,Family Fare,Valu Land,VG''''s,Xpress Mart'

Begin

Declare @sqlQuery varchar(4000)
	set @BannerName = replace(@BannerName, '''''', '''')
	set @BannerName = replace(@BannerName, '''', '''''')
	set @sqlQuery = 'Select distinct C.ChainId, C.ChainName from Chains C with (nolock) where 1 = 1 and chainId<>0'
		
	if(@ManufacturerId <> '-1' and @ManufacturerId <> '') 
		set @sqlQuery = @sqlQuery + ' and C.ChainId in (select distinct SS.ChainId
										from Manufacturers M with (nolock)
										inner join Brands B with (nolock) on B.ManufacturerId=M.ManufacturerId
										inner join ProductBrandAssignments PBA with (nolock) on PBA.BrandId=B.BrandID
										inner join StoreSetup SS with (nolock) on SS.ProductId=PBA.ProductID
										where M.ManufacturerId= ' + @ManufacturerId + ')'

	if(@ChainId <> '-1' and @ChainId <> '') 
		set @sqlQuery  = @sqlQuery  + ' and C.ChainId =' + @ChainId
                                                 
	if(@SupplierId <> '-1' and @SupplierId <> '')  
		--set @sqlQuery = @sqlQuery + ' and C.ChainId in (Select distinct ss.ChainId from StoreSetup ss					
		--								inner JOIN SupplierBanners sb ON sb.SupplierId=ss.SupplierID 								
		--								AND sb.ChainID=ss.ChainID AND sb.Banner <> '''' AND sb.Status=''Active''
		--								where ss.SupplierId=' + @SupplierId + ')'
										
		set @sqlQuery = @sqlQuery + ' and C.ChainId in (Select distinct ChainId from SupplierBanners with (nolock) where SupplierId=' + @SupplierId + ')'
					
	if(@BannerName <> '-1' and @BannerName <> '' and @BannerName <>'FULL') 
		set @sqlQuery = @sqlQuery + ' and C.ChainId in (Select distinct ChainId from Stores with (nolock) where Custom1 
										in(SELECT * FROM dbo.split('''+ @BannerName + ''', '','')))'
				
	 --set @sqlQuery = @sqlQuery + '  and  (select count(*) from SupplierBanners where supplierid=' + @SupplierID + ' and chainid=c.chainid) > 0'
	set @sqlQuery = @sqlQuery + ' order by C.ChainName '
	
exec(@sqlQuery); 
print (@sqlQuery); 
End
GO
