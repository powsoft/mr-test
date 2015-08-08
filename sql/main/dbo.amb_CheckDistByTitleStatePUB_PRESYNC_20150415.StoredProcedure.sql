USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_CheckDistByTitleStatePUB_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[amb_CheckDistByTitleStatePUB_PRESYNC_20150415]
(
@PublisherIdentifier varchar(20),
@PublisherID varchar(20),
@ChainID varchar(20),
@State varchar(20)
)
--Exec amb_CheckDistByTitleStatePUB 'DOWJ','35321','CVS','IA'
--Exec amb_CheckDistByTitleStatePUB 'USA','35519','SV','-1'

as 
BEGIN
	
Declare @sqlQueryNew Varchar(8000)	

SET @sqlQueryNew=' SELECT distinct  M.ManufacturerIdentifier as  PublisherID, 
									C.ChainIdentifier as ChainID, 
									A.State, 
									Sup.SupplierIdentifier as WholesalerID, 
									P.ProductName as  Title 
									
						FROM dbo.StoreSetup SS with (nolock) 
							INNER JOIN dbo.Brands B  with (nolock) ON SS.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M  with (nolock) ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN dbo.Chains C  with (nolock) ON C.ChainID=SS.ChainID
							INNER JOIN dbo.Addresses A  with (nolock) ON A.OwnerEntityID=SS.StoreID
							INNER JOIN dbo.Suppliers Sup  with (nolock) ON Sup.SupplierID=ss.SupplierID
							INNER JOIN dbo.Products P  with (nolock) ON P.ProductID=SS.ProductID 
						
						Where 1=1 AND C.ChainIdentifier in (Select chainid from chains_migration)
						AND M.ManufacturerId=' + @PublisherId 

		IF (@ChainID<>'-1')
			 set @sqlQueryNew= @sqlQueryNew+ ' AND C.ChainIdentifier = ''' + @ChainID+''''

		IF (@State<>'-1')
			 set @sqlQueryNew= @sqlQueryNew+ ' AND A.State = ''' + @State+''''		        

   EXEC(@sqlQueryNew)	
   PRINT(@sqlQueryNew)	
End
GO
