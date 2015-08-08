USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawsManagementWHLS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [amb_DrawsManagementWHLS] 'BN','-1','-1','','02/01/2009','10/11/2012','ENT','24178'
-- exec [amb_DrawsManagementWHLS] 'CVS','NY','ROCHESTER','0466','1900-01-01','1900-01-01','Wolfe','28943'
-- exec [amb_DrawsManagementWHLS] '-1','-1','-1','','01-01-1900','01-01-1900','WR1428','24503'
CREATE procedure [dbo].[amb_DrawsManagementWHLS]
(
	@ChainID varchar(10),
	@State varchar(10),
	@City varchar(20),
	@StoreNumber varchar(10),
	@StartDate varchar(50),
	@EndDate varchar(50),
	@SupplierIdentifier varchar(10),
	@SupplierID varchar(10)	
)

AS 
BEGIN
Declare @strquery varchar(8000)
Declare @sqlQueryFinal varchar(8000)
Declare @sqlQueryStoreLegacy varchar(8000)
Declare @sqlQueryStoreNew varchar(8000)
Declare @sqlQueryLegacy varchar(8000)
Declare @sqlQueryNew varchar(8000)
Declare @oldStartdate varchar(30)
Declare @oldenddate varchar(30)
Declare @newStartdate varchar(30)
Declare @newenddate varchar(30)
Declare @allnew int --0 for old database,1 from new database, 2 from mixed
DECLARE @chain_migrated_date date


IF(@ChainID<>'-1')
	BEGIN
		SELECT  @chain_migrated_date = CAST(datemigrated as VARCHAR)
		FROM    dbo.chains_migration
		WHERE   chainid = @ChainID;
		
		IF(CAST(@chain_migrated_date AS DATE) > CAST('01/01/1900'AS DATE))
			BEGIN
				IF(CAST(@StartDate AS DATE) >= CAST(@chain_migrated_date AS DATE))
					BEGIN
						SET @allnew=1
						SET @newStartdate=@StartDate
						SET @newEnddate=@EndDate
					END
				ELSE IF(CAST(@EndDate AS DATE) < CAST(@chain_migrated_date AS DATE))
					BEGIN
						SET @allnew=0
						SET @oldStartdate=@StartDate
						SET @oldenddate=@EndDate
					END
				ELSE IF(CAST(@EndDate AS DATE) >= CAST(@chain_migrated_date AS DATE)
				 and CAST(@startdate AS DATE) <= CAST(@chain_migrated_date AS DATE))
					BEGIN
						SET @allnew=2
						SET @oldStartdate=@StartDate
						SET @oldenddate=DATEADD(dd, -1, @chain_migrated_date)
						SET @newStartdate=@chain_migrated_date
						SET @newEnddate=@EndDate
					END
			END
		ELSE
			BEGIN
				SET @allnew=0
				SET @oldStartdate=@StartDate
				SET @oldenddate=@EndDate
			END
	END
ELSE
    BEGIN
		SET @allnew=2
		SET @oldStartdate=@StartDate
		SET @oldenddate=@EndDate
		SET @newStartdate=@StartDate
		SET @newEnddate=@EndDate
	END	

IF (@allnew=0 or @allnew=2) 
	BEGIN
		SET @sqlQueryStoreLegacy='SELECT distinct OnR.StoreID,OnR.ChainID,SL.StoreNumber, SL.StoreName, SL.Address, SL.City, 
					   SL.State, SL.ZipCode,WL.WholesalerID
					   FROM  [IC-HQSQL2].iControl.dbo.OnR OnR   
					   INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
					   INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID
					   INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID
					   INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder BO  ON  WL.WholesalerID = BO.WholesalerID
					   AND SL.StoreID = BO.StoreID AND SL.ChainID = BO.ChainID AND P.Bipad = BO.Bipad ' 


		SET @sqlQueryStoreLegacy+=' WHERE 1=1 AND WL.WholesalerID='''+@SupplierIdentifier+''''

			if(@StoreNumber<>'')
				SET @sqlQueryStoreLegacy+=' AND OnR.StoreID like ''%'+@StoreNumber+'%'' '
				
			if(@City<>'-1')
				SET @sqlQueryStoreLegacy+=' AND SL.City= '''+@City+''''
				
			if(@State<>'-1')
				SET @sqlQueryStoreLegacy+=' AND SL.State = '''+@State+''' ' 
				
			if(@ChainID<>'-1')
				SET @sqlQueryStoreLegacy+= ' AND OnR.ChainID = '''+@ChainID+''''
				
		   if(CAST(@oldStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @sqlQueryStoreLegacy += '  AND OnR.WeekEnding >= ''' + CONVERT(varchar, +@oldStartdate,101) +  ''''
			
			if(CAST(@oldenddate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @sqlQueryStoreLegacy +=' AND OnR.WeekEnding <= ''' + CONVERT(varchar, +@oldenddate,101) + ''''		
			

		SET @sqlQueryLegacy=' SELECT distinct
		                       ('' Chain ID  : ''+ OnR.ChainID + '' Store # : '' + SL.StoreNumber + '', '' + SL.StoreName + ''/n Location:  '' + SL.Address + '', '' + SL.City + '','' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,
							    WL.WholesalerName, WL.WholesalerID,OnR.ChainID, OnR.StoreID, 
								SL.StoreNumber, SL.StoreName, SL.Address, SL.City, SL.State,
								SL.ZipCode, OnR.Bipad, P.AbbrvName AS Title,  OnR.[CostToStore4Wholesaler], 
								OnR.[CostToWholesaler], OnR.CostToStore, OnR.SuggRetail, Sum(OnR.Mon) AS MonDraws, Sum(OnR.Tue) AS TueDraws, 
								Sum(OnR.Wed) AS WedDraws, Sum(OnR.Thur) AS ThurDraws, Sum(OnR.Fri) AS FriDraws, Sum(OnR.Sat) AS SatDraws, 
								Sum(OnR.Sun) AS SunDraws, Sum(OnR.MonR) AS MonReturns, Sum(OnR.TueR) AS TueReturns, Sum(OnR.WedR) AS WedReturns, 
								Sum(OnR.ThurR) AS ThurReturns, Sum(OnR.FriR) AS FriReturns, Sum(OnR.SatR) AS SatReturns, Sum(OnR.SunR) AS SunReturns,
								Sum(OnR.MonS) AS MonShort, Sum(OnR.TueS) AS TueShort, Sum(OnR.WedS) AS WedShort, Sum(OnR.ThurS) AS ThurShort, 
								Sum(OnR.FriS) AS FriShort, Sum(OnR.SatS) AS SatShort, Sum(OnR.SunS) AS SunShort,
								Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun) AS [TTL Draws],
								Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS [TT Returns], 
								Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS [TTL Shortages],
								Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
								([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) AS NetSales, 
								Sum((onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
								([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))* ([CostToStore4Wholesaler]-[CostToWholesaler])) AS Profit,
								(Sum(onr.mon)-Sum([mons])-Sum([monr]))/Count(onr.bipad) AS AvgMonSale, 
								BO.Mon AS MonBase, (Sum(onr.Tue)-Sum([Tues])-Sum([Tuer]))/Count(onr.bipad) AS AvgTueSale,
								BO.Tue AS TueBase, (Sum(onr.wed)-Sum([weds])-Sum([wedr]))/Count(onr.bipad) AS AvgWedSale,
								BO.Wed AS WedBase, (Sum(onr.Thur)-Sum([Thurs])-Sum([Thurr]))/Count(onr.bipad) AS AvgThurSale,
								BO.Thur AS ThurBase, (Sum(onr.Fri)-Sum([fris])-Sum([frir]))/Count(onr.bipad) AS AvgFriSale, 
								BO.Fri AS FriBase, (Sum(onr.Sat)-Sum([Sats])-Sum([Satr]))/Count(onr.bipad) AS AvgSatSale, 
								BO.Sat AS SatBase, (Sum(onr.sun)-Sum([suns])-Sum([sunr]))/Count(onr.bipad) AS AvgSunSale, 
								BO.Sun AS SunBase, Count(OnR.Bipad) AS NoOfWeeksInRange,0 AS Dbtype

								FROM  [IC-HQSQL2].iControl.dbo.OnR OnR   
								INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
								INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
								INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID 
								INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder  BO ON  WL.WholesalerID = BO.WholesalerID  
								and SL.StoreID = BO.StoreID AND SL.ChainID = BO.ChainID AND P.Bipad = BO.Bipad  '
						
		SET @sqlQueryLegacy+=' WHERE 1=1 '

		if(@StoreNumber<>'')
			SET @sqlQueryLegacy+=' AND OnR.StoreID like ''%'+@StoreNumber+'%'' '
				
		if(@City<>'-1')
			SET @sqlQueryLegacy+=' AND SL.City= '''+@City+''''
				
		if(@State<>'-1')
			SET @sqlQueryLegacy+=' AND SL.State = '''+@State+''' ' 
				
		if(@ChainID<>'-1')
			SET @sqlQueryLegacy+= ' AND OnR.ChainID = '''+@ChainID+''''
				
		if(CAST(@oldStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy += '  AND OnR.WeekEnding >= ''' + CONVERT(varchar, +@oldStartdate,101) +  ''''
			
		if(CAST(@oldenddate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy +=' AND OnR.WeekEnding <= ''' + CONVERT(varchar, +@oldenddate,101) + ''''
        
		SET @sqlQueryLegacy+='	GROUP BY WL.WholesalerName,  WL.WholesalerID, OnR.StoreID,OnR.ChainID, SL.StoreNumber,SL.StoreID, 
									SL.StoreName, SL.Address, SL.City, SL.State, SL.ZipCode, OnR.Bipad, 
									P.AbbrvName,  OnR.[CostToStore4Wholesaler], OnR.[CostToWholesaler], OnR.CostToStore, OnR.SuggRetail, 
									BO.Mon, BO.Tue, BO.Wed, BO.Thur, BO.Fri, BO.Sat, BO.Sun, OnR.ChainID  '
									
		 SET @sqlQueryLegacy+=' HAVING 1=1 AND WL.WholesalerID='''+@SupplierIdentifier+''' '	
		
	END
	
	IF (@allnew=1 or @allnew=2) 
		BEGIN
			IF object_id('tempdb.dbo.##tempDrawsMgmtWHLDraws') is not null  /*  STEP(2) Get the Draws in the temp table ##tempDrawsMgmtWHLDraws  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLDraws;
				END

			SET @strquery= 'SELECT DISTINCT SF.ChainID,SF.SupplierID,S.StoreID,C.ChainIdentifier,
							SF.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempDrawsMgmtWHLDraws

							from dbo.Storetransactions_forward SF
							INNER JOIN dbo.Chains C on SF.ChainID=C.ChainID
							INNER JOIN dbo.Stores S ON S.StoreID=SF.StoreID
							INNER JOIN dbo.Addresses A ON A.OwnerEntityID=SF.StoreID 
							INNER JOIN dbo.Products P ON	SF.ProductID = P.ProductID	
 
							WHERE 1=1 AND TransactionTypeID in (29) AND SF.SupplierID='+@SupplierID 
			if(@ChainID<>'-1')					
				SET @strquery = @strquery +' and C.ChainIdentifier='''+@ChainID+''''

			if(@City<>'-1')   
				SET @strquery = @strquery +' and A.City like '''+@City+''''	
		
			if(@State<>'-1')    
				SET @strquery = @strquery +' and A.State like '''+@State+''''
				
			if(@StoreNumber<>'')    
				SET @strquery = @strquery +' and S.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''	

			if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

			if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + ''''
							

			EXEC(@strquery)	
			
			IF object_id('tempdb.dbo.##tempDrawsMgmtWHLPOS') is not null  /*  STEP(3) Get the Draws in the temp table ##tempDrawsMgmtWHLPOS  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLPOS;
				END

			SET @strquery= 'SELECT DISTINCT ST.ChainID,ST.SupplierID,
							S.StoreID,C.ChainIdentifier,
							ST.ProductID,Qty,ST.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as POSDay						
							into ##tempDrawsMgmtWHLPOS								

							from dbo.Storetransactions ST
							INNER JOIN dbo.transactiontypes TT ON TT.transactiontypeid=ST.transactiontypeid and TT.BucketType=1
							inner JOIN dbo.Chains C on ST.ChainID=c.ChainID
							INNER JOIN dbo.Stores S ON S.StoreID=ST.StoreID
							INNER JOIN dbo.Addresses A ON A.OwnerEntityID=ST.StoreID 			
							INNER JOIN dbo.Products P ON	ST.ProductID = P.ProductID	
														
							WHERE 1=1 AND TT.TransactionTypeID in (29) AND ST.SupplierID='+@SupplierID 
							
			if(@ChainID<>'-1')					
				SET @strquery = @strquery +' and C.ChainIdentifier='''+@ChainID+''''

			if(@City<>'-1')   
				SET @strquery = @strquery +' and A.City like '''+@City+''''	
		
			if(@State<>'-1')    
				SET @strquery = @strquery +' and A.State like '''+@State+''''
				
			if(@StoreNumber<>'')    
				SET @strquery = @strquery +' and S.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''	

			if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

			if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + '''' 

			EXEC(@strquery)				
		
		   IF object_id('tempdb.dbo.##tempDrawsMgmtWHLFinal') is not null /*  STEP(4) Get the FinalData in the temp table ##tempDrawsMgmtWHLFinal  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLFinal
				END	
						
			SET @strquery= 'Select distinct tmpdraws.*,tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as SupplierIdentifier,
							CAST(NULL as nvarchar(50)) as legacysystemstoreidentifier,
							CAST(NULL as nvarchar(50)) as StoreName,
							CAST(NULL as nvarchar(50)) as StoreNumber,
							CAST(NULL as nvarchar(100)) as Address,
							CAST(NULL as nvarchar(50)) as City,
							CAST(NULL as nvarchar(50)) as State,
							CAST(NULL as nvarchar(50)) as ZipCode,
							CAST(NULL as nvarchar(50)) as WholesalerName,
							CAST(NULL as nvarchar(50)) as BiPad,
							CAST(NULL as nvarchar(225)) as Title,
							CAST(NULL as MONEY) as CostToStore,
							CAST(NULL as money) as SuggRetail,
							CAST(NULL as nvarchar(50)) as MonBase,
							CAST(NULL as nvarchar(50)) as TueBase,
							CAST(NULL as nvarchar(50)) as WedBase,
							CAST(NULL as nvarchar(50)) as ThurBase,
							CAST(NULL as nvarchar(50)) as FriBase, 
							CAST(NULL as nvarchar(50)) as SatBase, 
							CAST(NULL as nvarchar(50)) as SunBase,
							CAST(NULL as nvarchar(50)) as IdentifierValue
							into ##tempDrawsMgmtWHLFinal 
							from
							(
							  SELECT * FROM 
								(
								   SELECT * from ##tempDrawsMgmtWHLDraws) P
								   pivot( sum(Qty) for wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)
								 ) as Draw_eachday
							) tmpdraws
							JOIN
							(
							  SELECT * from 
								(
								   SELECT * from ##tempDrawsMgmtWHLPOS) P
								   pivot( sum(Qty) for POSDay in (MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								 ) as POS_eachday
							) tmpPOS 

							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid '
							
				EXEC(@strquery)			


			SET @strquery='Update F Set 
			
							F.SupplierIdentifier=(Select Distinct SupplierIdentifier From dbo.Suppliers Where SupplierId=F.SupplierId),
							
							F.legacysystemstoreidentifier=(Select Distinct legacysystemstoreidentifier From dbo.stores Where storeid=F.storeid),

							F.StoreName=(Select Distinct StoreName From dbo.Stores  Where StoreID=F.StoreID),

							F.StoreNumber=(Select Distinct StoreIdentifier From dbo.Stores Where StoreID=F.StoreID),

							F.address=(Select Distinct Address1 From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.city=(Select Distinct city From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.state=(Select Distinct state From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.zipcode=(Select Distinct PostalCode From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.WholesalerName=(Select Distinct SupplierName From dbo.Suppliers Where SupplierID=F.supplierid),

							F.Bipad=(Select Distinct Bipad from dbo.productidentifiers Where ProductID=F.productid),
								F.IdentifierValue=(Select Distinct IdentifierValue from dbo.productidentifiers Where ProductID=F.productid),			

							F.title=(Select Distinct ProductName From dbo.Products Where ProductID=F.productid),

							F.CostToStore=(Select Distinct  UnitPrice From dbo.ProductPrices Where ProductID=F.productid AND ChainID=F.chainid 
							AND StoreID=F.storeid AND SupplierID=F.supplierid AND ProductPriceTypeID=3),

							F.SuggRetail=(Select Distinct  UnitRetail  From dbo.ProductPrices Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
							
							F.MonBase=(Select Distinct  MonLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.TueBase=(Select Distinct  TueLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.WedBase=(Select Distinct  WedLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.ThurBase=(Select Distinct  ThuLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.FriBase=(Select Distinct  FriLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.SatBase=(Select Distinct SatLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.SunBase=(Select Distinct  SunLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid)

							from ##tempDrawsMgmtWHLFinal F '
							
				EXEC(@strquery)				
				
				SET @sqlQueryStoreNew=' Select Distinct legacysystemstoreidentifier as StoreID,ChainIdentifier as ChainID,StoreNumber,StoreName,Address,City,
				                        State,Zipcode,SupplierIdentifier as WholesalerID 
                                        From ##tempDrawsMgmtWHLFinal  '
										
			    SET @sqlQueryNew='Select Distinct
			                       ('' Chain ID: '' + ChainIdentifier + ''Store Number: '' + StoreNumber + '','' + StoreName  + ''/n Location: '' + address + '', '' + City + '','' + State + '', '' + zipcode ) as StoreInfo, 
			                        WholeSalerName,Supplieridentifier as WholesalerID,ChainIdentifier as ChainID,
			                        legacysystemstoreidentifier as StoreID,StoreNumber,
									StoreName,Address,City,State,zipcode,Bipad,Title,0 as CostToStore4Wholesaler,0 as CostToWholesaler,CostToStore,SuggRetail,	
									sum(mondaydraw) as MonDraws,
									sum(tuesdaydraw) as TueDraws,
									sum(wednesdaydraw) as WedDraws,
									sum(thursdaydraw) as ThurDraws,
									sum(fridaydraw) as FriDraws,
									sum(saturdaydraw) as SatDraws,
									sum(sundaydraw) as SunDraws,
									sum(mondaydraw-mondayPOS) as MonReturns,
									sum(tuesdaydraw-tuesdayPOS) as TueReturns,
									sum(wednesdaydraw-wednesdayPOS) as WedReturns,
									sum(thursdaydraw-thursdayPOS) as ThurReturns,
									sum(fridaydraw-fridayPOS) as FriReturns,
									sum(saturdaydraw-saturdayPOS) as SatReturns,
									sum(sundaydraw-sundayPOS) as SunReturns,						
									''0'' AS MonShort,''0'' AS TueShort, ''0'' AS WedShort,
									''0'' AS ThurShort, ''0'' AS FriShort,''0'' AS SatShort, 
									''0'' AS SunShort,						
									Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+
									fridaydraw+saturdaydraw+sundaydraw) AS [TTL Draws],
 								    Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+
									sundaydraw-(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+
									saturdayPOS+sundayPOS)) AS [TT Returns],
									0 AS [TTL Shortages],
									Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
									sundayPOS) AS NetSales, 
									Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
									sundayPOS)*(suggretail-CostToStore)) AS Profit,
									sum(mondayPOS)/Count(bipad) AS AvgMonSale,sum(tuesdayPOS)/Count(bipad) AS AvgTueSale,
									sum(wednesdayPOS)/Count(bipad) AS AvgWedSale,sum(thursdayPOS)/Count(bipad) AS AvgThuSale,
									sum(fridayPOS)/Count(bipad) AS AvgFriSale,sum(saturdayPOS)/Count(bipad) AS AvgSatSale,
									sum(sundayPOS)/Count(bipad) AS AvgSunSale,
									MonBase,TueBase,WedBase,ThurBase,FriBase, SatBase,SunBase,Count(bipad) AS NoOfWeeksInRange,1 as Dbtype				

									From ##tempDrawsMgmtWHLFinal
									
									GROUP BY ChainIdentifier,chainid,supplieridentifier,wholesalername,legacysystemstoreidentifier,productid,
									storename,StoreNumber,address,City,State,zipcode,wholesalername,bipad,title,costtostore,
									suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,fridaydraw,saturdaydraw,sundaydraw ,
									mondayPOS,tuesdayPOS,wednesdayPOS,thursdayPOS ,fridayPOS,saturdayPOS,sundayPOS ,MonBase,TueBase,
									WedBase,ThurBase,FriBase, SatBase,SunBase' 												
		END
	print @allnew	
	IF(@allnew=2)
		BEGIN
			---SET @sqlQueryFinal=@sqlQueryStoreLegacy+ ' UNION ' +@sqlQueryStoreNew				
			---EXEC(@sqlQueryFinal)
							
			SET @sqlQueryFinal=@sqlQueryLegacy+ ' UNION ' +@sqlQueryNew
			EXEC(@sqlQueryFinal)
			print(@sqlQueryFinal)
		END

	ELSE IF(@allnew=1)
		BEGIN
			--EXEC(@sqlQueryStoreNew)
			EXEC(@sqlQueryNew)
		END

	ELSE IF(@allnew=0)
		BEGIN
			--EXEC (@sqlQueryStoreLegacy)
			EXEC(@sqlQueryLegacy)
			print (@sqlQueryLegacy)
		END	
END
GO
