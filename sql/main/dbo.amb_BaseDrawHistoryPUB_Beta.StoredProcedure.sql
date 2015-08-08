USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_BaseDrawHistoryPUB_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec[amb_BaseDrawHistoryPUB_New] 'NYT','35412','-1','-1','WR1866','','-1', 'StoreName ASC',1,25,0  (OLD)
--exec [amb_BaseDrawHistoryPUB_Beta] 'DEFAULT','0','-1','-1','-1','','-1' (NEW)
--exec [amb_BaseDrawHistoryPUB] 'NYT','35412','-1','-1','-1','','-1' (Both)
--SELECT * from Suppliers where SupplierIdentifier='default'
--EXEC [amb_BaseDrawHistoryPUB_New] 'NYT','35412','-1','-1','-1','','-1','StoreName ASC',1,25,1
--amb_BaseDrawHistoryPUB_Beta 'NYT','35412','-1','-1','-1','','-1','WholesalerID asc',1,25,0
CREATE procedure [dbo].[amb_BaseDrawHistoryPUB_Beta]
(
@PublisherIdentifier varchar(10),
@PublisherId varchar(10),
@ChainID varchar(10),
@State varchar(10),
@WholesalerID varchar(10),
@StoreNumber varchar(10),
@Title varchar(20)
)

as 
BEGIN

	
	Declare @sqlQueryNew varchar(8000)
	
				SET @sqlQueryNew='  Select distinct  (''Store #: '' + S.StoreName + ''; Store Number: '' + S.StoreIdentifier
									+ '';  Account Number: '' + S.LegacySystemStoreIdentifier + '';/n Location: '' + S.StoreName + '', '' + A.Address1
									+ '', '' + A.City + '', '' + A.State + '', '' + A.PostalCode ) as StoreInfo,p.ProductName as Title,
									SUP.SupplierIdentifier as  WholesalerID, '''' as Frozen,PP.UnitPrice as CostToStore, PP.UnitRetail as SuggRetail,
									ss.MonLimitQty as Mon,ss.TueLimitQty as Tue, SS.WedLimitQty as Wed,ss.ThuLimitQty as Thur, SS.FriLimitQty as Fri, 
									SS.SatLimitQty as Sat, SS.SunLimitQty as Sun,PI.Bipad , S.LegacySystemStoreIdentifier as StoreID FROM dbo.StoreSetup SS
									INNER JOIN dbo.Brands B ON ss.BrandID=B.BrandID
									INNER JOIN dbo.Stores S ON S.StoreID=ss.StoreID
									INNER JOIN dbo.Addresses A ON A.OwnerEntityID=SS.StoreID
									INNER JOIN dbo.Products P ON P.ProductID=SS.ProductID
									INNER JOIN dbo.ProductPrices PP ON PP.ProductID=P.ProductID
									INNER JOIN dbo.ProductIdentifiers PI ON PI.ProductID=P.ProductID AND PI.ProductIdentifierTypeID=8
									INNER JOIN dbo.Suppliers SUP ON SUP.SupplierID=SS.SupplierID
									INNER JOIN dbo.Chains C ON C.ChainID=SS.ChainID
								WHERE 1=1 AND C.ChainIdentifier in (Select chainid from chains_migration) 
									AND B.ManufacturerId=' + @PublisherId 
				 
				IF(@WholesalerID<>'-1')
				   SET @sqlQueryNew= @sqlQueryNew+ ' AND SUP.SupplierIdentifier = ''' + @WholesalerID+''''
				   
				IF(@Title<>'-1')
				   SET @sqlQueryNew= @sqlQueryNew+ ' AND P.ProductName = ''' + @Title+''''
				   
				IF(@StoreNumber<>'')
				   SET @sqlQueryNew= @sqlQueryNew+ ' AND S.StoreIdentifier like  ''%'+@StoreNumber+'%'''
				   
				IF(@State<>'-1')
				   SET @sqlQueryNew= @sqlQueryNew+ ' AND a.State = '''+@State+'''' 
				   
				IF(@ChainID<>'-1')
				   SET @sqlQueryNew= @sqlQueryNew+ ' AND C.ChainIdentifier = '''+@ChainID+''''
				 SET @sqlQueryNew=  @sqlQueryNew+ ' order by  StoreInfo, p.ProductName '
			
			EXEC(@sqlQueryNew)	
		
	End
GO
