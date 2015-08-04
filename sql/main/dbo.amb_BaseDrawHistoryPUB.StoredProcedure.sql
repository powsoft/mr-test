USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_BaseDrawHistoryPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_BaseDrawHistoryPUB 'DOWJ','35321','CF','-1','STC','','-1'  (OLD)
--exec amb_BaseDrawHistoryPUB 'DEFAULT','35321','BN','-1','STC','','-1' (NEW)
--exec amb_BaseDrawHistoryPUB 'DEFAULT','0','-1','-1','STC','','-1' (Both)
CREATE procedure [dbo].[amb_BaseDrawHistoryPUB]
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

	Declare @sqlQuery varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @Dbtype int --0 for Old DataBase,1 for New DataBase,2 for Mixed
	DECLARE @chain_migrated Varchar(20)

	If(@ChainID<>'-1')
		BEGIN
			Select 	@Chain_Migrated=ChainID FROM dbo.chains_migration WHERE   chainid = @ChainID;
			If(@chain_migrated is null)
				SET @Dbtype=0
			Else
				SET @Dbtype=1
		END
	ELSE
		SET @Dbtype=2

		IF(@Dbtype=0 OR @Dbtype=2)
			BEGIN
				SET @sqlQuery=' SELECT distinct (''Store #: '' + SL.StoreName + ''; Store Number: '' + SL.StoreNumber 
									+ '';  Account Number: '' + SL.StoreId + '';/n Location: '' + SL.StoreName + '', '' + SL.Address 
									+ '', '' + SL.City + '', '' + SL.State + '', '' + SL.ZipCode ) as StoreInfo, P.AbbrvName AS Title,B.WholesalerID,
									 B.Frozen,PP.CostToStore, PP.SuggRetail,B.Mon,B.Tue, B.Wed,B.Thur, B.Fri,B.Sat,B.Sun,P.Bipad,SL.StoreID
									 
								FROM  [IC-HQSQL2].iControl.dbo.BaseOrder B
									INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON B.Bipad = P.Bipad
									INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON B.StoreID = SL.StoreID AND B.ChainID = SL.ChainID 
									INNER JOIN  [IC-HQSQL2].iControl.dbo.ProductsPrices  PP ON B.WholesalerID = PP.WholesalerID AND B.ChainID = PP.ChainID AND P.Bipad = PP.Bipad' 

				SET @sqlQuery = @sqlQuery + ' WHERE P.PublisherID=''' + @PublisherIdentifier + ''' AND B.Stopped=0 AND SL.Active=1 AND P.Active=1 '
	 
				IF(@WholesalerID<>'-1')
					SET @sqlQuery= @sqlQuery+ ' AND B.WholesalerID = ''' + @WholesalerID+''''
				IF(@Title<>'-1')
					SET @sqlQuery= @sqlQuery+ ' AND P.AbbrvName = ''' + @Title+''''
				IF(@StoreNumber<>'')
					SET @sqlQuery= @sqlQuery+ ' AND SL.StoreId Like ''%'+@StoreNumber+'%'''
				IF(@State<>'-1')
					SET @sqlQuery= @sqlQuery+ ' AND SL.State = '''+@State+'''' 
				IF(@ChainID<>'-1')
					SET @sqlQuery= @sqlQuery+ ' AND SL.ChainID = '''+@ChainID+''''
			END
	   
	   IF(@Dbtype=1 OR @Dbtype=2)
			BEGIN 
				SET @sqlQueryNew=' Select distinct (''Store #: '' + S.StoreName + ''; Store Number: '' + S.StoreIdentifier
									+ '';  Account Number: '' + S.LegacySystemStoreIdentifier + '';/n Location: '' + S.StoreName + '', '' + A.Address1
									+ '', '' + A.City + '', '' + A.State + '', '' + A.PostalCode ) as StoreInfo,p.ProductName as Title,
									SUP.SupplierIdentifier as  WholesalerID, '''' as Frozen,PP.UnitPrice as CostToStore, PP.UnitRetail as SuggRetail,
									ss.MonLimitQty as Mon,ss.TueLimitQty as Tue, SS.WedLimitQty as Wed,ss.ThuLimitQty as Thur, SS.FriLimitQty as Fri, 
									SS.SatLimitQty as Sat, SS.SunLimitQty as Sun,PI.Bipad , S.LegacySystemStoreIdentifier as StoreID
									
								FROM dbo.StoreSetup SS
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
				   
			END
			
	IF(@Dbtype=0)
		begin
			EXEC(@sqlQuery)
		end
	IF(@Dbtype=1)
		begin
			EXEC(@sqlQueryNew)	
		end
	IF(@Dbtype=2)
		begin
			EXEC(@sqlQuery +'union'+ @sqlQueryNew )
		End
	End
GO
