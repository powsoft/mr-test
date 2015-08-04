USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawsregulationPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[amb_DrawsregulationPUB]
(
	@PublisherIdentifier varchar(10),
	@PublisherId varchar(10),
	@WholesalerID varchar(10),
	@ChainID varchar(10),
	@City varchar(50),
	@State varchar(40),
	@StoreNumber varchar(50),
	@StartDate varchar(20),
	@EndDate varchar(20)	
)
--exec [amb_DrawsregulationPUB] 'DOWJ','35321','365','BN','-1','-1','','1900-01-01','11/11/2012'
--exec [amb_DrawsregulationPUB] 'DOWJ','35321','365','-1','-1','-1','','1900-01-01','1900-01-01'
AS

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
	Declare @allnew int --0 from old database,1 from new database, 2 from mixed
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


	IF (@allnew=0 or @allnew=2)
		BEGIN
			set @sqlQueryLegacy='SELECT distinct ('' Store #: '' + SL.StoreNumber + '','' + SL.StoreName + ''/n Location: '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo, WL.WholesalerName, OnR.StoreID, OnR.Bipad, 
					P.AbbrvName AS Title, OnR.CostToStore,OnR.SuggRetail, 
					Sum((onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*(-[CostToWholesaler]+[CostToStore4Wholesaler])) AS Profit,
					Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun) AS [TTL Draws], 
					Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS [TT Returns],
				  Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS [TTL Shortages],
					Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) AS NetSales,		
					Sum(OnR.Mon) AS MonDraws, Sum(OnR.Tue) AS TueDraws, Sum(OnR.Wed) AS WedDraws,
					Sum(OnR.Thur) AS ThurDraws, Sum(OnR.Fri) AS FriDraws, Sum(OnR.Sat) AS SatDraws, Sum(OnR.Sun) AS SunDraws,
					Sum(OnR.MonR) AS MonReturns, Sum(OnR.TueR) AS TueReturns, Sum(OnR.WedR) AS WedReturns, Sum(OnR.ThurR) AS									ThurReturns, Sum(OnR.FriR) AS FriReturns, Sum(OnR.SatR) AS SatReturns, Sum(OnR.SunR) AS SunReturns, 
					Sum(OnR.MonS) AS MonShort, Sum(OnR.TueS) AS TueShort, Sum(OnR.WedS) AS WedShort, Sum(OnR.ThurS) AS ThurShort,							
					Sum(OnR.FriS) AS FriShort, Sum(OnR.SatS) AS SatShort, Sum(OnR.SunS) AS SunShort
					
				  FROM [IC-HQSQL2].iControl.dbo.OnR OnR   
				  INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
				  INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID				  
				  INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID
				  where 1 = 1 '
			
			IF(@WholesalerID<>'-1')
					SET @sqlQueryLegacy = @sqlQueryLegacy +' And OnR.Wholesalerid=''' + @WholesalerID + ''''
						  
			IF(@ChainID<>'-1')
				SET @sqlQueryLegacy = @sqlQueryLegacy +' And OnR.ChainID=''' + @ChainID + ''''	
		
			IF(@StoreNumber<>'')		 
				SET @sqlQueryLegacy = @sqlQueryLegacy	+' AND SL.Storeid Like ''%'+@StoreNumber+'%''' 
				
			IF(@City<>'-1')      
				SET @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.City Like '''+@City+ ''' '
			
			IF(@State<>'-1')    
				SET @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.State Like '''+@State+''''			
				
			if(CAST(@oldStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy += '  AND OnR.WeekEnding >= ''' + CONVERT(varchar, +@oldStartdate,101) +  ''''
			
			if(CAST(@oldenddate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy +=' AND OnR.WeekEnding <= ''' + CONVERT(varchar, +@oldenddate,101) + ''''	



			set @sqlQueryLegacy=@sqlQueryLegacy +' GROUP BY OnR.ChainID, OnR.WholesalerID, WL.WholesalerName,SL.StoreNumber,
				SL.StoreName, SL.Address, SL.City, SL.State,SL.ZipCode ,
			OnR.StoreID, OnR.Bipad, P.AbbrvName, onr.CostToStore4Wholesaler, 
			onr.CostToWholesaler, OnR.CostToStore, OnR.SuggRetail,P.PublisherID'
			 
			 SET @sqlQueryLegacy = @sqlQueryLegacy + ' HAVING 1=1  AND P.PublisherID=''' + @PublisherIdentifier + ''''
 END

	
	IF (@allnew=1 or  @allnew=2)
	BEGIN
	  /* Get the data into tmp table for Draws */
	  IF object_id('tempdb.dbo.##tempDrawsregulationPUB') is not null 
				BEGIN
				  drop table ##tempDrawsregulationPUB;
				END
				SET @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempDrawsregulationPUB
							
							from dbo.Storetransactions_forward st
							INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							inner JOIN dbo.Suppliers sup on st.Supplierid=sup.Supplierid
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
							where TransactionTypeID in (29)							
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and M.ManufacturerID=' + @PublisherId
				IF(@WholesalerID<>'-1')					
				SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''			
							
				IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
			
				IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''				
				
				IF(@State<>'-1')    
				SET @strquery = @strquery +' and	a.State like '''+@State+''''
									
				if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

				if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + '''' 
	
				EXEC(@strquery)	
				
				/* Get the data into tmp table for POS */
			IF object_id('tempdb.dbo.##tempDrawsregulationPUBPOS') is not null
				BEGIN
				   drop table ##tempDrawsregulationPUBPOS
				END		
			SET @strquery=' Select distinct st.ChainID,st.SupplierID,
							s.storeid,st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempDrawsregulationPUBPOS								
							
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							inner JOIN dbo.Suppliers sup on st.Supplierid=sup.Supplierid
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
							where 1 = 1	 					
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and M.ManufacturerID=' + @PublisherId
				
			IF(@WholesalerID<>'-1')					
				SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''						
			IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''							
			
			IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''							   

			IF(@State<>'-1')    
				SET @strquery = @strquery +' and	a.State like '''+@State+''''				
										
			if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

			if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + ''''
			
			EXEC(@strquery)	 										
							
		--Get the final data into final tmp table

		IF object_id('tempdb.dbo.##tempDrawsregulationPUBFinalData') is not null
				BEGIN
				    DROP Table ##tempDrawsregulationPUBFinalData
			   END			
				SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "legacySystemStoreIdentifier",
							CAST(NULL as nvarchar(50)) as "StoreName",
							CAST(NULL as nvarchar(50)) as "StoreNumber",
							CAST(NULL as nvarchar(100)) as "Address",
							CAST(NULL as nvarchar(50)) as "City",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "ZipCode",
							CAST(NULL as nvarchar(50)) as "WholesalerName",
							CAST(NULL as nvarchar(50)) as "BiPad",
							CAST(NULL as nvarchar(225)) as "Title",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as money) as "SuggRetail"
						
						into ##tempDrawsregulationPUBFinalData 
						from
						(select * FROM 
							(SELECT * from ##tempDrawsregulationPUB ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
							(SELECT * from ##tempDrawsregulationPUBPOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
							 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						on tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'

			EXEC(@strquery)
			
			--Update the required fields
			SET @strquery='update f set			
				f.legacySystemStoreIdentifier=(select distinct legacySystemStoreIdentifier from dbo.Stores  
				where StoreID=f.StoreID),
				f.StoreName=(select distinct StoreName from dbo.Stores  
				where StoreID=f.StoreID),
				f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores 
				where StoreID=f.StoreID),
				f.address=(select distinct Address1 from dbo.Addresses 
				where OwnerEntityID=f.StoreID),
				f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.zipcode=(select distinct PostalCode from dbo.Addresses
				where OwnerEntityID=f.StoreID),
				f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers
				where SupplierID=f.supplierid),
				f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers 
				where ProductID=f.productid),
				f.title=(SELECT DISTINCT  ProductName  from dbo.Products 
				where ProductID=f.productid),
				f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
				where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
				AND SupplierID=f.supplierid and ProductPriceTypeID=3),
				f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices 
				where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
				AND SupplierID=f.supplierid and ProductPriceTypeID=3)
				
				from ##tempDrawsregulationPUBFinalData f'

			EXEC(@strquery)
					--Return the Data
			
			SET @sqlQueryNew=' select distinct (''Store #: '' + StoreNumber + '','' + StoreName + ''/n Location: '' 
										+ storename + '', '' + address + '', '' + City + '', 
										'' + State + '', '' + zipcode ) as StoreInfo, WholeSalerName,legacySystemStoreIdentifier as storeid,bipad,title,costtostore,
								suggretail,			
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
								''0'' AS MonShort,
								''0'' AS TueShort, 
								''0'' AS WedShort,
								''0'' AS ThurShort, 
								''0'' AS FriShort,
								''0'' AS SatShort, 
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
								sundayPOS)*(suggretail-CostToStore)) AS Profit
								From 
								##tempDrawsregulationPUBFinalData
								group by chainid,wholesalername,legacySystemStoreIdentifier,productid,wholesalername,storename,StoreNumber,address,City,State,zipcode ,bipad,title,costtostore,suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,fridaydraw,
								saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,fridayPOS,saturdayPOS,sundayPOS;'							 
	END
	

	print @allnew
	IF(@allnew=2)
			BEGIN
				SET @sqlQueryFinal=@sqlQueryStoreLegacy+ ' union ' +@sqlQueryStoreNew
					
				EXEC(@sqlQueryFinal)				
				SET @sqlQueryFinal=@sqlQueryLegacy+ ' union ' +@sqlQueryNew
				--print (@sqlQueryFinal)
				EXEC(@sqlQueryFinal)
		   END
	ELSE IF(@allnew=1)
		BEGIN
			--print (@sqlQueryStoreNew)
			EXEC(@sqlQueryStoreNew)
			--print (@sqlQueryNew)
			EXEC(@sqlQueryNew)
		END
	ELSE IF(@allnew=0)
		BEGIN
			--print (@sqlQueryStoreLegacy)
			EXEC (@sqlQueryStoreLegacy)
			--print (@sqlQueryLegacy)
			EXEC(@sqlQueryLegacy)
	    END 
	

 END
GO
