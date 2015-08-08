USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_BestToWorstStoresRankPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_BestToWorstStoresRankPUB 'DOWJ','35321','WR682','BN','-1','-1','1900/01/01','1900/01/01'
CREATE procedure [dbo].[amb_BestToWorstStoresRankPUB]
(
@PublisherIdentifier varchar(10),
@PublisherId varchar(10),
@WholesalerId varchar(10),
@ChainID varchar(10),
@State varchar(40),
@Title varchar(40),
@StartDate varchar(20),
@EndDate varchar(20)
)

as 
BEGIN
	Declare @sqlQueryFinal varchar(8000)
	Declare @strquery varchar(8000)
	Declare @sqlQueryStoreLegacy varchar(8000)
	Declare @sqlQueryStoreNew varchar(8000)
	Declare @sqlQueryLegacy varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @oldStartdate varchar(8000)
	Declare @oldenddate varchar(8000)
	Declare @newStartdate varchar(8000)
	Declare @newenddate varchar(8000)
	Declare @allnew int --0 for old database,1 from new database, 2 from mixed
	DECLARE @chain_migrated_date date
	
IF(@ChainID<>'-1')
	BEGIN
		SELECT  @chain_migrated_date = CAST(datemigrated as VARCHAR)
		FROM    dbo.chains_migration
		WHERE   chainid = @ChainID;
		
		IF(CAST(@chain_migrated_date AS DATE) > CAST('1900-01-01'AS DATE))
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


/* ------(STEP 1) GET DATA FROM THE OLD DATABASE (iControl)-------- */		
IF (@allnew=0 or @allnew=2)
	BEGIN	
		SET @sqlQueryStoreLegacy='SELECT OnR.ChainID,SL.State,SL.StoreName,TitleName, 
								Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]) AS Draws, 
								Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS Returns, 
								Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])AS Shortages, 
								Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])
								-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))AS NetSales,
								Sum(([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])
								-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([CostToStore4Wholesaler]-[CostToWholesaler])) AS Profit, 
								sum(mon-mons-monr) as MonResults, 
								sum(tue-tues-tuer) as TueResults,
							    sum(Wed-Weds-WedR) as WedResults,
							    sum(Thur-ThurS-ThurR) as ThurResults,
							    sum(Fri-FriS-FriR) as FriResults,
							    sum(Sat-SatS-SatR) as SatResults,
							    sum(Sun-SunS-SunR) as SunResults,
							    CASE 
									WHEN  Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
									([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))>0  
										THEN  
											Case 
												WHEN Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun])>0 

												THEN cast(cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]
												-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
												([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) as decimal) 
												/cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]) as decimal)as decimal (18,4))

												else cast(0 as decimal (18,4))
											END
									else  cast(0 as decimal (18,4))
								END  as salesRatio
							    FROM  [IC-HQSQL2].iControl.dbo.OnR OnR  
								INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
								INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
								WHERE 1=1 AND P.PublisherID=''' + @PublisherIdentifier + ''''
									
	if(@WholesalerId<>'-1')
		set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + ' AND OnR.WholesalerID LIKE ''' + @WholesalerId + ''''
	
	if(@ChainID<>'-1')		  
		set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + ' AND OnR.ChainID Like '''+ @ChainID + ''''
		
	if(@State<>'-1')		  
		set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +'  AND SL.State Like'''+ @State +''''	
	
	if(@Title<>'-1')
		set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + ' AND P.TitleName Like ''' + @Title + ''''
		
	if(CAST(@oldStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
		SET @sqlQueryStoreLegacy += '  AND OnR.WeekEnding >= ''' + CONVERT(varchar, +@oldStartdate,101) +  ''''
			
	if(CAST(@oldenddate AS DATE) <> CAST('1900-01-01' AS DATE))
		SET @sqlQueryStoreLegacy +=' AND OnR.WeekEnding <= ''' + CONVERT(varchar, +@oldenddate,101) + ''''

		SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' GROUP BY  OnR.ChainID,TitleName,SL.StoreName,SL.state '
		
	--print @sqlQueryStoreLegacy	
	END
		
/* -----(STEP 2) GET DATA FROM THE NEW DATABASE (DataTrue_Main)----- */

IF (@allnew=1 or  @allnew=2)
	BEGIN
	  /* Get the data into tmp table for Draws */
	IF object_id('tempdb.dbo.##tempBestToWorstStoresRankPUB') is not null 
		 BEGIN
			drop table ##tempBestToWorstStoresRankPUB;
		 END
			
			SET @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempBestToWorstStoresRankPUB
							
							from dbo.Storetransactions_forward st
							INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.products p ON p.ProductID=st.ProductID
							inner JOIN dbo.Suppliers sup on st.Supplierid=sup.Supplierid
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
							where TransactionTypeID in (29)							
							and M.ManufacturerID = ' + @PublisherId
							
	IF(@WholesalerID<>'-1')					
		SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''			
				
	IF(@ChainID<>'-1')					
		SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
	
	IF(@State<>'-1')    
		SET @strquery = @strquery +' and a.State like '''+@State+''''
		
	IF(@Title<>'-1')   
		SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''	
							
	if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
		SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

	if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
		SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + '''' 

	EXEC(@strquery)	

/* Get the data into tmp table for POS */
	IF object_id('tempdb.dbo.##tempBestToWorstStoresRankPUBPOS') is not null
		BEGIN
			drop table ##tempBestToWorstStoresRankPUBPOS
		END	
			
		   SET @strquery=' Select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempBestToWorstStoresRankPUBPOS								
							
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.products p ON p.ProductID=st.ProductID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							inner JOIN dbo.Suppliers sup on st.Supplierid=sup.Supplierid
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
							where 1 = 1						
							and M.ManufacturerID = ' + @PublisherId
				
	IF(@WholesalerID<>'-1')					
		 SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''	
		 					
	IF(@ChainID<>'-1')					
		 SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''														   

	IF(@State<>'-1')    
		 SET @strquery = @strquery +' and	a.State like '''+@State+''''
		 				
	IF(@Title<>'-1')   
		 SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''
									
	if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
		 SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

	if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
		 SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + ''''
	
	EXEC(@strquery)	 
						
--Get the final data into final tmp table

	IF object_id('tempdb.dbo.##tempBestToWorstStoresRankPUBFinalData') is not null
		BEGIN
			DROP Table ##tempBestToWorstStoresRankPUBFinalData
		END	
				
			SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "StoreName",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "chainidentifier",
							CAST(NULL as nvarchar(225)) as "Title",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as money) as "SuggRetail"
						
							into ##tempBestToWorstStoresRankPUBFinalData 
							from
							(select * FROM 
								(SELECT * from ##tempBestToWorstStoresRankPUB ) p
									pivot( sum(Qty) for  wDay in
									(MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
									FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
								) tmpdraws
							join
							( select * from 
								(SELECT * from ##tempBestToWorstStoresRankPUBPOS)p
								pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
								WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								) as p1
							) tmpPOS 
							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid'
    
	EXEC(@strquery)	
	
	/*----UPDATE THE TEMP TABLE----- */
		 SET @strquery='update f set	
					f.StoreName=(select distinct StoreName from dbo.Stores  
					where StoreID=f.StoreID),		
					f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid),
					f.title=(SELECT DISTINCT  ProductName  from dbo.Products 
					where ProductID=f.productid),
					f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
					where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
					AND SupplierID=f.supplierid and ProductPriceTypeID=3),
					f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices 
					where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
					AND SupplierID=f.supplierid and ProductPriceTypeID=3)
					
					from ##tempBestToWorstStoresRankPUBFinalData f'
	
	EXEC(@strquery)
		 
		 SET @sqlQueryNew='select distinct chainidentifier as ChainID, State,StoreName,title as TitleName,
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS Draws,
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-
						(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS Returns,
						0 AS Shortages,
						Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS NetSales,
						Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)*
						(suggretail-CostToStore)) AS Profit,
						Sum(mondayPOS) as MonResults,
						Sum(tuesdayPOS) as TueResults,
						Sum(wednesdayPOS) as WedResults,
						Sum(thursdayPOS) as ThurResults,
						Sum(fridayPOS) as FriResults,
						Sum(saturdayPOS) as SatResults,
						Sum(sundayPOS) as SunResults,
						CASE
							WHEN SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)>0
								THEN
									CASE
										WHEN SUM(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) >0
											THEN 
												cast(cast(SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) as decimal)
												/cast(SUM(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) as decimal) as decimal (18,4))
										ELSE cast(0  as decimal (18,4))
									END
							ELSE cast(0  as decimal (18,4))
						END AS salesRatio
						From 
						##tempBestToWorstStoresRankPUBFinalData
						group by chainidentifier,title,StoreName,State,suggretail,CostToStore;'	

	END
		
/*----(STEP 3) FINAL QUERY EXEC--------*/	
	IF(@allnew=2)
		BEGIN
			SET @sqlQueryFinal=@sqlQueryStoreLegacy+ ' union ' +@sqlQueryNew 
			--+ ' order by state,StoreName'
			--print @sqlQueryFinal
			EXEC(@sqlQueryFinal)
			
		END
	ELSE IF(@allnew=1)
		BEGIN
			--print @sqlQueryNew
			EXEC(@sqlQueryNew) 
			--+ ' order by state,StoreName')
		END
	ELSE IF(@allnew=0)
		BEGIN
			--print @sqlQueryStoreLegacy
			EXEC(@sqlQueryStoreLegacy)
			--+ ' order by state,StoreName')
		END
END
GO
