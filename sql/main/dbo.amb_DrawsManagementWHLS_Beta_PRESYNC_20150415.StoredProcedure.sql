USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawsManagementWHLS_Beta_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [amb_DrawsManagementWHLS] 'BN','-1','-1','','02/01/2009','10/11/2012','ENT','24178'
-- exec [amb_DrawsManagementWHLS] 'CVS','NY','ROCHESTER','0466','1900-01-01','1900-01-01','Wolfe','28943'
-- exec [amb_DrawsManagementWHLS_Beta] '-1','-1','-1','','01-01-1900','01-01-1900','WR1428','24503','StoreNumber ASC',1,25,0

-- exec [amb_DrawsManagementWHLS_Beta] 'DOIL','-1','-1','','1900-01-01','1900-01-01','WR1488','24538'
-- exec [amb_DrawsManagementWHLS_Beta] 'DQ','-1','-1','','02/01/2009','10/11/2013','CLL','24164'
--SELECT * FROM Suppliers Where Suppliername LIKE 'hami%'
-- exec [amb_DrawsManagementWHLS_Beta] 'CF','-1','-1','','03/03/2014','06/30/2014','HNA','28792'

CREATE procedure [dbo].[amb_DrawsManagementWHLS_Beta_PRESYNC_20150415]
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
Declare @sqlQueryNew varchar(8000)

	
			IF object_id('tempdb.dbo.##tempDrawsMgmtWHLDraws') is not null  /*  STEP(2) Get the Draws in the temp table ##tempDrawsMgmtWHLDraws  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLDraws;
				END

			SET @strquery= 'SELECT  SF.ChainID,
									SF.SupplierID,
									S.StoreID,
									C.ChainIdentifier,
									SF.ProductID,
									Qty,
									TransactionTypeID,
									datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempDrawsMgmtWHLDraws

							from dbo.Storetransactions_forward SF with (nolock) 
							INNER JOIN dbo.Chains C  with (nolock) on SF.ChainID=C.ChainID
							INNER JOIN dbo.Stores S  with (nolock) ON S.StoreID=SF.StoreID
							INNER JOIN dbo.Addresses A  with (nolock) ON A.OwnerEntityID=SF.StoreID 
							INNER JOIN dbo.Products P  with (nolock) ON	SF.ProductID = P.ProductID	
							LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = SF.SupplierID AND BC.ChainID = C.ChainID
							
							WHERE 1=1 AND TransactionTypeID in (29) AND SF.SupplierID='+@SupplierID 
			if(@ChainID<>'-1')					
				SET @strquery = @strquery +' and C.ChainIdentifier='''+@ChainID+''''

			if(@City<>'-1')   
				SET @strquery = @strquery +' and A.City like '''+@City+''''	
		
			if(@State<>'-1')    
				SET @strquery = @strquery +' and A.State like '''+@State+''''
				
			if(@StoreNumber<>'')    
				SET @strquery = @strquery +' and S.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''	

			if(CAST(@StartDate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND CAST(dbo.GetWeekEnd_TimeOutFix(SF.SaleDateTime, BC.BillingControlDay) AS DATE) >= cast( '''+@StartDate +  ''' as date)'

			if(CAST(@EndDate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND CAST(dbo.GetWeekEnd_TimeOutFix(SF.SaleDateTime, BC.BillingControlDay) AS DATE) <= cast (''' +@EndDate + ''' as date)'
							

			EXEC(@strquery)	
			print(@strquery)	
			
			IF object_id('tempdb.dbo.##tempDrawsMgmtWHLPOS') is not null  /*  STEP(3) Get the Draws in the temp table ##tempDrawsMgmtWHLPOS  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLPOS;
				END

			SET @strquery= 'SELECT  ST.ChainID,ST.SupplierID,
							S.StoreID,
							C.ChainIdentifier,
							ST.ProductID,
							Qty,
							ST.TransactionTypeID,
							CAST(ST.RuleCost AS MONEY) AS CostToStore,
							CAST(ST.RuleRetail AS MONEY) AS SuggRetail,
							datename(W,SaleDateTime)+ ''POS'' as POSDay	
												
							into ##tempDrawsMgmtWHLPOS								

							from dbo.Storetransactions ST with (nolock) 
							INNER JOIN dbo.transactiontypes TT  with (nolock) ON TT.transactiontypeid=ST.transactiontypeid and TT.BucketType=1 --AND TT.TransactionTypeID in (29)
							inner JOIN dbo.Chains C  with (nolock) on ST.ChainID=c.ChainID
							INNER JOIN dbo.Stores S  with (nolock) ON S.StoreID=ST.StoreID
							INNER JOIN dbo.Addresses A  with (nolock) ON A.OwnerEntityID=ST.StoreID 			
							INNER JOIN dbo.Products P  with (nolock) ON	ST.ProductID = P.ProductID	
							LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ST.SupplierID AND BC.ChainID = C.ChainID
							 						
							WHERE 1=1  AND ST.SupplierID='+@SupplierID 
							
			if(@ChainID<>'-1')					
				SET @strquery = @strquery +' and C.ChainIdentifier='''+@ChainID+''''

			if(@City<>'-1')   
				SET @strquery = @strquery +' and A.City like '''+@City+''''	
		
			if(@State<>'-1')    
				SET @strquery = @strquery +' and A.State like '''+@State+''''
				
			if(@StoreNumber<>'')    
				SET @strquery = @strquery +' and S.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''	

			if(CAST(@StartDate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND CAST(dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay) AS DATE) >= cast (''' + @StartDate +  ''' as date)'

			if(CAST(@EndDate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND CAST(dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay) AS DATE) <=  cast('''  +@EndDate + ''' as date)' 

			EXEC(@strquery)		
			print(@strquery)	
								
		
		   IF object_id('tempdb.dbo.##tempDrawsMgmtWHLFinal') is not null /*  STEP(4) Get the FinalData in the temp table ##tempDrawsMgmtWHLFinal  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLFinal
				END	
						
			SET @strquery= 'Select distinct tmpdraws.MondayDraw,
							tmpdraws.TuesdayDraw,
							tmpdraws.WednesdayDraw,
							tmpdraws.ThursdayDraw,
							tmpdraws.FridayDraw,
							tmpdraws.SaturdayDraw,
							tmpdraws.SundayDraw,
						     tmpPOS.ChainID,
						     tmpPOS.SupplierID,
							tmpPOS.StoreID,
							tmpPOS.ChainIdentifier,
							tmpPOS.ProductID,
							tmpPOS.MondayPOS,
							tmpPOS.TuesdayPOS,
							tmpPOS.WednesdayPOS,
							tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,
							tmpPOS.SaturdayPOS,
							tmpPOS.SundayPOS,
							tmpPOS.CostToStore,
							tmpPOS.SuggRetail,
							tmpPOS.CostToStore AS CostToStore4Wholesaler,
							tmpPOS.CostToStore AS CostToWholesaler,
							CAST(NULL as nvarchar(250)) as SupplierIdentifier,
							CAST(NULL as nvarchar(50)) as legacysystemstoreidentifier,
							CAST(NULL as nvarchar(50)) as StoreName,
							CAST(NULL as nvarchar(50)) as StoreNumber,
							CAST(NULL as nvarchar(300)) as Address,
							CAST(NULL as nvarchar(50)) as City,
							CAST(NULL as nvarchar(50)) as State,
							CAST(NULL as nvarchar(50)) as ZipCode,
							CAST(NULL as nvarchar(250)) as WholesalerName,
							CAST(NULL as nvarchar(50)) as BiPad,
							CAST(NULL as nvarchar(225)) as Title,
							CAST(NULL as nvarchar(50)) as MonBase,
							CAST(NULL as nvarchar(50)) as TueBase,
							CAST(NULL as nvarchar(50)) as WedBase,
							CAST(NULL as nvarchar(50)) as ThurBase,
							CAST(NULL as nvarchar(50)) as FriBase, 
							CAST(NULL as nvarchar(50)) as SatBase, 
							CAST(NULL as nvarchar(50)) as SunBase
							--CAST(NULL as nvarchar(50)) as IdentifierValue
							into ##tempDrawsMgmtWHLFinal 
							from
							(
							  SELECT * from 
								(
								   SELECT * from ##tempDrawsMgmtWHLPOS) P
								   pivot( sum(Qty) for POSDay in (MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								 ) as POS_eachday
							) tmpPOS 
							left JOIN
							(
							  SELECT * FROM 
								(
								   SELECT * from ##tempDrawsMgmtWHLDraws) P
								   pivot( sum(Qty) for wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)
								 ) as Draw_eachday
							) tmpdraws
							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid '
							
				EXEC(@strquery)			
				print(@strquery)

			SET @strquery='Update F Set 
			
							F.SupplierIdentifier=(Select Distinct SupplierIdentifier From dbo.Suppliers Where SupplierId=F.SupplierId),
							
							F.legacysystemstoreidentifier=(Select Distinct legacysystemstoreidentifier From dbo.stores Where storeid=F.storeid),

							F.StoreName=(Select Distinct  StoreName From dbo.Stores  Where StoreID=F.StoreID),

							F.StoreNumber=(Select Distinct  StoreIdentifier From dbo.Stores Where StoreID=F.StoreID),

							F.address=(Select Distinct  Address1 From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.city=(Select Distinct  city From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.state=(Select Distinct  state From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.zipcode=(Select Distinct  PostalCode From dbo.Addresses Where OwnerEntityID=F.StoreID),

							F.WholesalerName=(Select Distinct SupplierName From dbo.Suppliers Where SupplierID=F.supplierid),

							F.Bipad=(Select Distinct Bipad from dbo.productidentifiers Where ProductID=F.productid and ProductIdentifierTypeID in(2,8)),
							
							--F.IdentifierValue=(Select Distinct top 1 IdentifierValue from dbo.productidentifiers Where ProductID=F.productid and ProductIdentifierTypeID in(2,8)),			

							F.title=(Select Distinct ProductName From dbo.Products Where ProductID=F.productid),

							F.MonBase=(Select Distinct TOP 1  MonLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.TueBase=(Select Distinct TOP 1 TueLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.WedBase=(Select Distinct TOP 1  WedLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.ThurBase=(Select Distinct TOP 1  ThuLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.FriBase=(Select Distinct  TOP 1 FriLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.SatBase=(Select Distinct TOP 1 SatLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid),
							
							F.SunBase=(Select Distinct TOP 1 SunLimitQty  From dbo.StoreSetup Where ProductID=f.productid AND ChainID=F.chainid 
							AND StoreID=f.storeid AND SupplierID=f.supplierid)

							from ##tempDrawsMgmtWHLFinal F '
							
				EXEC(@strquery)
				print(@strquery)				
				
				SET @sqlQueryNew='Select 
									   (legacysystemstoreidentifier +'', Site # '' + StoreNumber + ''\nLocation: '' + address + '', '' + City + '','' + State + '', '' + zipcode ) as StoreInfo, 
										WholeSalerName,
										Supplieridentifier as WholesalerID,
										ChainIdentifier as ChainID,
										legacysystemstoreidentifier as StoreID,
										StoreNumber,
										StoreName,
										Address,
										City,
										State,
										zipcode,
										Bipad,
										Title,
										CostToStore4Wholesaler,
										CostToWholesaler,
										ISNULL(CostToStore,0) AS CostToStore,
										ISNULL(SuggRetail,0) AS SuggRetail,	
										sum(ISNULL(mondaydraw,0)) as MonDraws,
										sum(ISNULL(tuesdaydraw,0)) as TueDraws,
										sum(ISNULL(wednesdaydraw,0)) as WedDraws,
										sum(ISNULL(thursdaydraw,0)) as ThurDraws,
										sum(ISNULL(fridaydraw,0)) as FriDraws,
										sum(ISNULL(saturdaydraw,0)) as SatDraws,
										sum(ISNULL(sundaydraw,0)) as SunDraws,
										sum(ISNULL(mondaydraw,0)-ISNULL(mondayPOS,0)) as MonReturns,
										sum(ISNULL(tuesdaydraw,0)-ISNULL(tuesdayPOS,0)) as TueReturns,
										sum(ISNULL(wednesdaydraw,0)-ISNULL(wednesdayPOS,0)) as WedReturns,
										sum(ISNULL(thursdaydraw,0)-ISNULL(thursdayPOS,0)) as ThurReturns,
										sum(ISNULL(fridaydraw,0)-ISNULL(fridayPOS,0)) as FriReturns,
										sum(ISNULL(saturdaydraw,0)-ISNULL(saturdayPOS,0)) as SatReturns,
										sum(ISNULL(sundaydraw,0)-ISNULL(sundayPOS,0)) as SunReturns,						
										0 AS MonShort,
										0 AS TueShort, 
										0 AS WedShort,
										0 AS ThurShort, 
										0 AS FriShort,
										0 AS SatShort, 
										0 AS SunShort,						
										Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS [TTL Draws],
										Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS [TT Returns],
										0 AS [TTL Shortages],
										Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ ISNULL(sundayPOS,0)) AS NetSales, 
										Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ ISNULL(sundayPOS,0)) * ([CostToStore4Wholesaler]-[CostToWholesaler])) AS Profit,
										
									CASE WHEN Count(bipad)>0 THEN sum(ISNULL(mondayPOS,0))/Count(bipad) ELSE 0 END AS AvgMonSale,
			cast(ISNULL(MonBase,0) as smallint) AS MonBase,
										
										CASE WHEN Count(bipad)>0 THEN sum(ISNULL(tuesdayPOS,0))/Count(bipad) ELSE 0 END AS AvgTueSale,
			cast(ISNULL(TueBase,0)  as smallint) AS TueBase,							
										CASE WHEN Count(bipad)>0 THEN sum(ISNULL(wednesdayPOS,0))/Count(bipad) ELSE 0 END AS AvgWedSale,
			cast(ISNULL(WedBase,0)  as smallint) AS WedBase,							
										CASE WHEN Count(bipad)>0 THEN sum(ISNULL(thursdayPOS,0))/Count(bipad) ELSE 0 END AS AvgThuSale,
			
										cast(ISNULL(ThurBase,0) as smallint) AS ThurBase,
										CASE WHEN Count(bipad)>0 THEN sum(ISNULL(fridayPOS,0))/Count(bipad) ELSE 0 END AS AvgFriSale,
										cast(ISNULL(FriBase,0) as smallint) as FriBase, 							
										CASE WHEN Count(bipad)>0 THEN sum(ISNULL(saturdayPOS,0))/Count(bipad) ELSE 0 END AS AvgSatSale,
			
										
										cast(ISNULL(SatBase,0) as smallint) AS SatBase,							
										CASE WHEN Count(bipad)>0 THEN sum(ISNULL(sundayPOS,0))/Count(bipad) ELSE 0 END AS AvgSunSale,
			
										cast(ISNULL(SunBase,0) as smallint) AS SunBase,														
										
										Count(bipad) AS NoOfWeeksInRange,
										1 as Dbtype				

							From ##tempDrawsMgmtWHLFinal
							
							GROUP BY ChainIdentifier,
									chainid,
									supplieridentifier,
									wholesalername,
									legacysystemstoreidentifier,
									productid,
									storename,
									StoreNumber,
									address,
									City,
									State,
									zipcode,
									wholesalername,
									bipad,
									title,
									CostToStore4Wholesaler,
									CostToWholesaler,
									costtostore,
									suggretail,
									mondaydraw,
									tuesdaydraw,
									wednesdaydraw,
									thursdaydraw,
									fridaydraw,
									saturdaydraw,
									sundaydraw ,
									mondayPOS,
									tuesdayPOS,
									wednesdayPOS,
									thursdayPOS ,
									fridayPOS,
									saturdayPOS,
									sundayPOS ,
									MonBase,
									TueBase,
									WedBase,
									ThurBase,
									FriBase, 
									SatBase,
									SunBase
									
							Order By legacysystemstoreidentifier,
							         title ' 
			 EXEC(@sqlQueryNew)	
			 print(@sqlQueryNew)
			  	
	IF object_id('tempdb.dbo.##tempDrawsMgmtWHLDraws') is not null  /*  STEP(2) Get the Draws in the temp table ##tempDrawsMgmtWHLDraws  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLDraws;
				END
		IF object_id('tempdb.dbo.##tempDrawsMgmtWHLPOS') is not null  /*  STEP(3) Get the Draws in the temp table ##tempDrawsMgmtWHLPOS  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLPOS;
				END			
		 IF object_id('tempdb.dbo.##tempDrawsMgmtWHLFinal') is not null /*  STEP(4) Get the FinalData in the temp table ##tempDrawsMgmtWHLFinal  */
				BEGIN
				  DROP table ##tempDrawsMgmtWHLFinal
				END					 
END
GO
