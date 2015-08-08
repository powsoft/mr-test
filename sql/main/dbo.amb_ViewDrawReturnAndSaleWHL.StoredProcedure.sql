USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewDrawReturnAndSaleWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--0(new) exec [amb_ViewDrawReturnAndSaleWHL] 'BN','-1','-1','','11/06/2012','11/11/2012','ENT','24178'
--1(old) exec [amb_ViewDrawReturnAndSaleWHL] 'BN','-1','-1','','02/02/2005','02/02/2010','ENT','24178'
--2(mix) exec [amb_ViewDrawReturnAndSaleWHL] '-1','-1','-1','','02-01-2009','11/11/2012','ENT','24178'


CREATE procedure [dbo].[amb_ViewDrawReturnAndSaleWHL]
(
	@ChainID varchar(10),
	@State varchar(20),
	@City varchar(20),
	@StoreNumber varchar(10),
	@StartDate varchar(20),
	@EndDate varchar(20) ,
	@SupplierIdentifier varchar(10),
	@SupplierID varchar(10)
)
AS

BEGIN
	declare @sqlQueryFinal varchar(8000)
	Declare @sqlQueryStoreLegacy varchar(8000)
	Declare @sqlQueryStoreNew varchar(8000)
	Declare @sqlQueryLegacy varchar(8000)
	Declare @strquery varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @oldStartdate varchar(8000)
	Declare @oldenddate varchar(8000)
	Declare @newStartdate varchar(8000)
	Declare @newenddate varchar(8000)
	Declare @allnew int --0 for old database,1 from new database, 2 from mixed
	Declare @chain_migrated_date date

	SELECT  @chain_migrated_date = CAST(datemigrated as VARCHAR)
	FROM    dbo.chains_migration
	WHERE   chainid = @ChainID;
	
	
	IF(@ChainID<>'-1')
	BEGIN
	IF(CAST(@chain_migrated_date AS DATE) > CAST('01/01/1900' AS DATE))
		BEGIN
			IF(CAST( @StartDate AS DATE) >= CAST(@chain_migrated_date AS DATE))
				BEGIN 
					SET @allnew=1
					SET @newStartdate=@StartDate
					SET @newEnddate=@EndDate
				END
			ELSE IF(CAST( @EndDate AS DATE) < CAST(@chain_migrated_date AS DATE))
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
					SET @oldenddate=DATEADD(dd, 1, @chain_migrated_date )
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
		
		SET @sqlQueryLegacy= 'SELECT distinct ('' Store #: '' + SL.StoreNumber + ''/n Location: '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo, WL.WholesalerName, SL.StoreID, 
							SL.StoreNumber, SL.ChainID, SL.StoreName, SL. Address,
							SL.City, SL.State, SL.ZipCode, OnR.Bipad, P.AbbrvName AS Title,
							OnR.CostToStore4Wholesaler, OnR.CostToWholesaler, OnR.CostToStore, OnR.SuggRetail, 
							Sum(OnR.Mon) AS MonDraws, Sum(OnR.Tue) AS TueDraws, Sum(OnR.Wed) AS WedDraws, 
							Sum (OnR.Thur) AS ThurDraws, Sum(OnR.Fri) AS FriDraws, Sum(OnR.Sat) AS SatDraws,
							Sum(OnR.Sun) AS SunDraws, Sum(OnR.MonR) AS MonReturns, Sum (OnR.TueR) AS TueReturns,
							Sum(OnR.WedR) AS WedReturns, Sum(OnR.ThurR) AS ThurReturns, Sum(OnR.FriR) AS FriReturns, 
							Sum(OnR.SatR) AS SatReturns, Sum(OnR.SunR) AS SunReturns, Sum(OnR.MonS) AS MonShort,
							Sum(OnR.TueS) AS TueShort, Sum(OnR.WedS) AS WedShort, Sum(OnR.ThurS)AS ThurShort,
							Sum(OnR.FriS) AS FriShort, Sum(OnR.SatS) AS SatShort, Sum(OnR.SunS) AS SunShort,
							Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun) AS [TTL Draws],
							Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS [TT Returns], 
							Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS [TTL Shortages],
							Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+
							[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) AS NetSales,
							Sum((onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]
							+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*
							(-[CostToWholesaler]+[CostToStore4Wholesaler])) AS Profit, 
							(Sum(onr.mon)-Sum([mons])-Sum([monr]))/Count(onr.bipad) AS AvgMonSale,																						     BO.Mon AS MonBase, (Sum(onr.Tue)-Sum([Tues])-Sum([Tuer]))/Count(onr.bipad) AS AvgTueSale,																 BO.Tue AS TueBase, (Sum(onr.wed) -Sum([weds])-Sum([wedr]))/Count(onr.bipad) AS AvgWedSale,								
							 BO.Wed AS WedBase,(Sum(onr.Thur)-Sum([Thurs])-Sum([Thurr]))/Count(onr.bipad) AS AvgThurSale,															 BO.Thur AS ThurBase, (Sum(onr.Fri)-Sum([fris])-Sum([frir]))/Count(onr.bipad) AS AvgFriSale, 
							 BO.Fri AS FriBase, (Sum(onr.Sat)-Sum([Sats])-Sum([Satr]))/Count(onr.bipad) AS AvgSatSale,																 BO.Sat AS SatBase, (Sum(onr.sun)-Sum([suns])-  Sum([sunr]))/Count(onr.bipad) AS AvgSunSale,							
							 BO.Sun AS SunBase, Count(OnR.Bipad) AS NoOfWeeksInRange  

							 FROM  [IC-HQSQL2].iControl.dbo.OnR OnR  
							 INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad 
							 INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID
							 INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist   WL ON OnR.WholesalerID = WL.WholesalerID
							 INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder BO  ON P.Bipad = BO.Bipad 
							 AND SL.ChainID =BO.ChainID 
							 AND SL.StoreID = BO.StoreID 
							 Where 1=1 '	

		IF(@ChainID<>'-1')
					SET @sqlQueryLegacy = @sqlQueryLegacy +' And OnR.ChainID=''' + @ChainID + ''''	
			
		IF(@StoreNumber<>'')		 
					SET @sqlQueryLegacy = @sqlQueryLegacy	+' AND SL.Storeid Like ''%'+@StoreNumber+'%''' 
					
		IF(@City<>'-1')      
					SET @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.City Like '''+@City+ ''' '
				
		IF(@State<>'-1')    
					SET @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.State Like '''+@State+''''			
					
		IF(CAST(@oldStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
			       SET @sqlQueryLegacy = @sqlQueryLegacy +'  and OnR.WeekEnding >= ''' + convert(varchar, +@oldStartdate,101) +''''

		IF(CAST(@oldenddate AS DATE ) <> CAST('1900-01-01' AS DATE))
				  SET @sqlQueryLegacy = @sqlQueryLegacy +' AND OnR.WeekEnding <= ''' + convert(varchar, +@oldenddate,101) + ''''			 
		
		
		SET @sqlQueryLegacy = @sqlQueryLegacy +' GROUP BY  WL.WholesalerID,WL.WholesalerName, SL.StoreID,
												 SL.StoreNumber,SL.ChainID, SL.StoreName,SL.Address,																	         SL.City,SL.State, SL.ZipCode, OnR.Bipad, P.AbbrvName, 
												 OnR.CostToStore4Wholesaler, OnR.CostToWholesaler, OnR.CostToStore, OnR.SuggRetail,																	             BO.Mon, BO.Tue, BO.Wed, BO.Thur, 
												 BO.Fri, BO.Sat, BO.Sun, BO.WholesalerID'
														
		set @sqlQueryLegacy = @sqlQueryLegacy + ' HAVING WL.WholesalerID=''' + @SupplierIdentifier + ''''
											 
	END
	
	
	/* Get data from the new database (DataTrue_Main) */
	IF (@allnew=1 or @allnew=2) 
		BEGIN
			--Get the data in to tmp table for draws
			IF object_id('tempdb.dbo.##tempViewDrawReturnAndSaleDraws') is not null
				BEGIN
					Drop Table ##tempViewDrawReturnAndSaleDraws;
				END
		
			SET @strquery='select distinct st.ChainID,st.SupplierID,s.LegacySystemStoreIdentifier as storeid,
							st.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempViewDrawReturnAndSaleDraws
							from dbo.Storetransactions_forward st
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
							where TransactionTypeID in (29) 
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and st.supplierid=' + @SupplierID 
			
			IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
			
			IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''	
			
			IF(@State<>'-1')    
				SET @strquery = @strquery +' and	a.State like '''+@State+''''
									
			IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
		
			IF(CAST(@newEnddate AS DATE) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
					
			EXEC(@strquery)		
			
			--Get the data into tmp table for POS
			
			IF object_id('tempdb.dbo.##tempViewDrawReturnAndSalePOS') is not null
				BEGIN
					DROP TABLE ##tempViewDrawReturnAndSalePOS
				END	
					
			SET @strquery='select distinct st.ChainID,st.SupplierID,
							s.LegacySystemStoreIdentifier as storeid,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempViewDrawReturnAndSalePOS						
							
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 										
							
							where 1=1
							and st.supplierid=' + @SupplierID + '
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
			
			IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''							
			
			IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''							   

			IF(@State<>'-1')    
				SET @strquery = @strquery +' and a.State like '''+@State+''''
										
			IF(CAST( @newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' and SaleDateTime >= ''' +  convert(varchar, +@newStartdate,101) +  ''''
				
			IF(CAST( @newEnddate AS DATE) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
				
			EXEC(@strquery)		
			
			
			IF object_id('tempdb.dbo.##tempViewDrawReturnAndSaleFinalData') is not null
				BEGIN
					DROP TABLE ##tempViewDrawReturnAndSaleFinalData
			    END	
			
			SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "WholesalerName",
							CAST(NULL as nvarchar(50)) as "StoreNumber",
							CAST(NULL as nvarchar(50)) as "Chainidentifier",
							CAST(NULL as nvarchar(50)) as "StoreName",
							CAST(NULL as nvarchar(100)) as "Address",
							CAST(NULL as nvarchar(50)) as "City",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "ZipCode",
							CAST(NULL as nvarchar(225)) as "Title",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as MONEY) as "SuggRetail",
							CAST(NULL as nvarchar(50)) as "BiPad",
							CAST(NULL as nvarchar(50)) as "supplieridentifier"
							
							into ##tempViewDrawReturnAndSaleFinalData 
							FROM
							(SELECT * FROM 
								(SELECT * from ##tempViewDrawReturnAndSaleDraws ) p
								 pivot( sum(Qty) for  wDay in
								  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
								  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
							) tmpdraws
							join
							( SELECT * FROM 
								(SELECT * FROM ##tempViewDrawReturnAndSalePOS)p
								 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
								 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								) as p1
							) tmpPOS 
							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid '

		    EXEC(@strquery)
			
			
			--Update the required fields
			SET @strquery='update f set 
							f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers
							where SupplierID=f.supplierid),
							f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores 
							where StoreID=f.StoreID),
							f.chainidentifier=(select distinct chainidentifier from dbo.chains  
							where chainid=f.chainid),
							f.StoreName=(select distinct StoreName from dbo.Stores  
							where StoreID=f.StoreID),
							f.address=(select distinct Address1 from dbo.Addresses 
							where OwnerEntityID=f.StoreID),
							f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
							f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
							f.zipcode=(select distinct PostalCode from dbo.Addresses
							where OwnerEntityID=f.StoreID),
							f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers 
							where ProductID=f.productid),
							f.title=(SELECT DISTINCT  ProductName  from dbo.Products 
							where ProductID=f.productid),
							f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
							where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
							AND SupplierID=f.supplierid and ProductPriceTypeID=3),
							f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices 
							where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
							AND SupplierID=f.supplierid and ProductPriceTypeID=3),
							f.supplieridentifier=(select distinct supplieridentifier from dbo.suppliers  
							where supplierid=f.supplierid)
							from ##tempViewDrawReturnAndSaleFinalData f'
				
		 EXEC(@strquery)
				
				
				--Return the Data
		
									
		 SET @sqlQueryNew='select distinct (''Store #: '' + StoreNumber + ''/n Location: '' 
										+ storename + '', '' + address + '', '' + City + '', 
										'' + State + '', '' + zipcode ) as StoreInfo,WholeSalerName,storeid,StoreNumber,chainidentifier as chainid,
							storename,address,City,State,zipcode,bipad,title,0 as CostToStore4Wholesaler,
							0 as CostToWholesaler,costtostore,suggretail,			
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
							saturdayPOS+sundayPOS)) AS [TTL Returns],
							0 AS [TTL Shortages],
							Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
							sundayPOS) AS NetSales, 
							Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
							sundayPOS)*(suggretail-CostToStore)) AS Profit,
							sum(mondayPOS)/Count(bipad) AS AvgMonSale,
							sum(tuesdayPOS)/Count(bipad) AS AvgTueSale,
							sum(wednesdayPOS)/Count(bipad) AS AvgWedSale,
							sum(thursdayPOS)/Count(bipad) AS AvgThuSale,
							sum(fridayPOS)/Count(bipad) AS AvgFriSale,
							sum(saturdayPOS)/Count(bipad) AS AvgSatSale,
							sum(sundayPOS)/Count(bipad) AS AvgSunSale,
							mondaydraw AS MonBase,
							tuesdaydraw AS TueBase, 
							wednesdaydraw AS WedBase,
							thursdaydraw AS ThurBase,
							fridaydraw AS FriBase, 
							saturdaydraw AS SatBase, 
							sundaydraw AS SunBase,
							Count(bipad) AS NoOfWeeksInRange
												
							FROM ##tempViewDrawReturnAndSaleFinalData
							
							GROUP BY chainidentifier,supplieridentifier,wholesalername,StoreID,productid,storename,
							StoreNumber,address,City,State,zipcode,wholesalername,bipad,title,costtostore,suggretail,
							mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,fridaydraw,saturdaydraw,sundaydraw ,
							mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,fridayPOS,saturdayPOS,sundayPOS ;'	
	END


/*---Final Query Exec---*/
	IF(@allnew=2)
		BEGIN
		SET @sqlQueryFinal=@sqlQueryLegacy+ ' UNION ' +@sqlQueryNew
			EXEC(@sqlQueryFinal)
	    END
	ELSE IF(@allnew=1)
		BEGIN
			
			EXEC(@sqlQueryNew)
	    END
	ELSE IF(@allnew=0)
		BEGIN
			
			EXEC(@sqlQueryLegacy)
	   END	
END
GO
