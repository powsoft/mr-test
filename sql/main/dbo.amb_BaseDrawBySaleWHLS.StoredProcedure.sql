USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_BaseDrawBySaleWHLS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_BaseDrawBySaleWHLS] '-1','-1','-1','','-1','1900-01-01','1900-01-01','WR1428','24503'
--exec [amb_BaseDrawBySaleWHLS] 'BN','-1','-1','','-1','1900-01-01','1900-01-01','WR1428','24503'


CREATE procedure [dbo].[amb_BaseDrawBySaleWHLS]
(
	@ChainID varchar(10),
	@State varchar(10),
	@City varchar(10),
	@StoreNumber varchar(10),
	@Title varchar(20),
	@StartDate varchar(20),
	@EndDate varchar(20) ,
	@SupplierIdentifier varchar(10),
	@SupplierID varchar(10)
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
		

Print(@allnew)

	IF (@allnew=0 or @allnew=2) 
		BEGIN
			SET @sqlQueryStoreLegacy='SELECT Distinct OnR.StoreID, WL.WholesalerName,
							WL.WholesalerID,SL.StoreNumber, SL.StoreName,
							SL.Address, SL.City, SL.State,SL.ZipCode
							
							FROM     [IC-HQSQL2].iControl.dbo.OnR OnR  
							INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
							INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
							INNER JOIN  [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID 
							INNER JOIN  [IC-HQSQL2].iControl.dbo.BaseOrder  BO ON WL.WholesalerID = BO.WholesalerID  
							and SL.StoreID = BO.StoreID 
							AND SL.ChainID = BO.ChainID 
							
							where 1 = 1 
							AND WL.WholesalerID=''' + @SupplierIdentifier + ''''			
			
			IF(@ChainID<>'-1')
				Begin
				
					SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' And OnR.ChainID=''' + @ChainID + ''''
				END	
				
			IF(@StoreNumber<>'')		 
				SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy	+' AND SL.Storeid Like ''%'+@StoreNumber+'%''' 
			
			IF(@City<>'-1')      
				SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' AND SL.City Like '''+@City+ ''' '
			
			IF(@State<>'-1')    
				SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' AND SL.State Like '''+@State+''''
			
			IF(@Title<>'-1')
				SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' AND P.AbbrvName = ''' + @Title+''''
			
			 if(CAST(@oldStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @sqlQueryStoreLegacy += '  AND OnR.WeekEnding >= ''' + CONVERT(varchar, +@oldStartdate,101) +  ''''
			
			if(CAST(@oldenddate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @sqlQueryStoreLegacy +=' AND OnR.WeekEnding <= ''' + CONVERT(varchar, +@oldenddate,101) + ''''		
			
			
			
			SET @sqlQueryLegacy='SELECT Distinct  (''Store # : '' + SL.StoreNumber + '', '' + SL.StoreName + ''/n Location:  '' + SL.Address + '', '' + SL.City + '','' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,
			WL.WholesalerName, WL.WholesalerID, 
								OnR.StoreID,OnR.ChainID,SL.	StoreNumber, 
								SL.StoreName,SL.Address, SL.City,
								SL.State, SL.ZipCode, 
								OnR.CostToStore4Wholesaler, OnR.CostToWholesaler,
								OnR.Bipad, P.AbbrvName AS Title, 
								OnR.CostToStore, OnR.SuggRetail,    
								Sum(OnR.Mon) AS MonDraws, Sum(OnR.Tue) AS TueDraws,Sum(OnR.Wed) AS WedDraws, 
								Sum(OnR.Thur) AS ThurDraws, Sum(OnR.Fri) AS FriDraws, Sum(OnR.Sat) AS SatDraws, 
								Sum(OnR.Sun) AS SunDraws,Sum(OnR.MonR) AS MonReturns, Sum(OnR.TueR) AS TueReturns, 
								Sum(OnR.WedR) AS WedReturns, Sum(OnR.ThurR) AS ThurReturns, 
								Sum(OnR.FriR) AS FriReturns,Sum(OnR.SatR) AS SatReturns,
								Sum(OnR.SunR) AS SunReturns, Sum(OnR.MonS) AS MonShort,
								Sum(OnR.TueS) AS TueShort, Sum(OnR.WedS) AS WedShort,Sum(OnR.ThurS) AS ThurShort, 
								Sum(OnR.FriS) AS FriShort, Sum(OnR.SatS) AS SatShort, 
								Sum(OnR.SunS) AS SunShort,
								Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun) AS [TTL Draws], 
								Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS [TT Returns],
								Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS [TTL Shortages],
								Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-
								([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
								([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) AS NetSales,
								Sum((onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-
								([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
								([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([CostToStore4Wholesaler]-										
								[CostToWholesaler])) AS Profit,(Sum(onr.mon)-Sum([mons])-
								Sum([monr]))/Count(onr.bipad) AS AvgMonSale,
								BO.Mon AS MonBase,(Sum(onr.Tue)-Sum([Tues])-Sum([Tuer]))/Count(onr.bipad) 
								AS AvgTueSale, 
								BO.Tue AS TueBase,
								(Sum(onr.wed)-Sum([weds])-Sum([wedr]))/Count(onr.bipad) AS AvgWedSale,
								BO.Wed AS WedBase,
								(Sum(onr.Thur)-Sum([Thurs])-Sum([Thurr]))/Count(onr.bipad) AS AvgThurSale, 
								BO.Thur AS ThurBase, 
								(Sum(onr.Fri)-Sum([fris])-Sum([frir]))/Count(onr.bipad)  AS AvgFriSale,
								BO.Fri AS FriBase, 
								(Sum(onr.Sat)-Sum([Sats])-Sum([Satr]))/Count(onr.bipad) AS AvgSatSale,
								BO.Sat AS SatBase,
								(Sum(onr.sun)-Sum([suns])-Sum([sunr]))/Count(onr.bipad) AS AvgSunSale, 
								BO.Sun AS SunBase, Count(OnR.Bipad) AS NoOfWeeksInRange,0 AS Dbtype
									      
								FROM (((  [IC-HQSQL2].iControl.dbo.OnR OnR  INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad) 
								INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID)
								INNER JOIN  [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID)
								INNER JOIN  [IC-HQSQL2].iControl.dbo.BaseOrder BO  ON (SL.StoreID = BO.StoreID)
								AND(SL.ChainID = BO.ChainID) AND (P.Bipad = BO.Bipad)
								where 1 = 1 '												
		
			IF(@ChainID<>'-1')
				SET @sqlQueryLegacy = @sqlQueryLegacy +' And OnR.ChainID=''' + @ChainID + ''''	
		
			IF(@StoreNumber<>'')		 
				SET @sqlQueryLegacy = @sqlQueryLegacy	+' AND SL.Storeid Like ''%'+@StoreNumber+'%''' 
				
			IF(@City<>'-1')      
				SET @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.City Like '''+@City+ ''' '
			
			IF(@State<>'-1')    
				SET @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.State Like '''+@State+''''
			
			IF(@Title<>'-1')
				SET @sqlQueryLegacy = @sqlQueryLegacy +' AND P.AbbrvName = ''' + @Title+''''
				
			if(CAST(@oldStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy += '  AND OnR.WeekEnding >= ''' + CONVERT(varchar, +@oldStartdate,101) +  ''''
			
		if(CAST(@oldenddate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy +=' AND OnR.WeekEnding <= ''' + CONVERT(varchar, +@oldenddate,101) + ''''		 
		
			
			SET @sqlQueryLegacy = @sqlQueryLegacy +'GROUP BY WL.WholesalerName, 
												  WL.WholesalerID, P.TitleName,
												  OnR.StoreID,OnR.ChainID, SL.StoreNumber, SL.StoreName, 
												  SL.Address, SL.City, SL.State, SL.ZipCode, 
												  OnR.Bipad, P.AbbrvName,  OnR.[CostToStore4Wholesaler], 
												  OnR.[CostToWholesaler], OnR.CostToStore, OnR.SuggRetail,
												  BO.Mon, BO.Tue, BO.Wed, BO.Thur,
												  BO.Fri, BO.Sat, BO.Sun, OnR.ChainID '
							  
			SET @sqlQueryLegacy = @sqlQueryLegacy + ' HAVING 1=1  AND WL.WholesalerID=''' + @SupplierIdentifier + ''''
	END		
			

	/*  Get the Data from the new database (DataRue_Main) */			
				
	IF (@allnew=1 or  @allnew=2) 
		BEGIN 
		     /* Get the data into tmp table for Draws */
			IF object_id('tempdb.dbo.##tempRegulateBaseDrawBySaleWHL') is not null 
				BEGIN
				  drop table ##tempRegulateBaseDrawBySaleWHL;
				END
			
			SET @strquery='select distinct st.ChainID,st.SupplierID,s.LegacySystemStoreIdentifier as storeid,
							st.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempRegulateBaseDrawBySaleWHL
							
							from dbo.Storetransactions_forward st
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
							INNER JOIN dbo.Products P ON	st.ProductID = P.ProductID	
							
							where TransactionTypeID in (29) 
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and st.supplierid=' + @SupplierID 
			
			IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
			
			IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''	
			
			IF(@Title<>'-1')
				SET @strquery = @strquery +' AND P.ProductName = ''' + @Title+''''
						
			IF(@State<>'-1')    
				SET @strquery = @strquery +' and	a.State like '''+@State+''''
									
			if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

			if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + '''' 
	
			EXEC(@strquery)		
			
			/* Get the data into tmp table for POS */
			IF object_id('tempdb.dbo.##tempRegulateBaseDrawBySaleWHLPOS') is not null
				BEGIN
				   drop table ##tempRegulateBaseDrawBySaleWHLPOS
				END	
					
			SET @strquery=' Select distinct st.ChainID,st.SupplierID,
							s.LegacySystemStoreIdentifier as storeid,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempRegulateBaseDrawBySaleWHLPOS								
							
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID
							INNER JOIN dbo.Products P ON	st.ProductID = P.ProductID	 										
							
							where 1=1
							and st.supplierid=' + @SupplierID + '
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
			
			IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''							
			
			IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''							   

			IF(@State<>'-1')    
				SET @strquery = @strquery +' and	a.State like '''+@State+''''
			
			IF(@Title<>'-1')
				SET @strquery = @strquery +' AND P.ProductName = ''' + @Title+''''		
										
			if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

			if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + ''''
			
			EXEC(@strquery)
				
			--Get the final data into final tmp table

			IF object_id('tempdb.dbo.##tempRegulateBaseDrawBySaleWHLFinalData') is not null
				BEGIN
				    DROP Table ##tempRegulateBaseDrawBySaleWHLFinalData
			    END	


			SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "supplieridentifier",
							CAST(NULL as nvarchar(50)) as "Chainidentifier",
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
							CAST(NULL as money) as "SuggRetail",
							CAST(NULL as nvarchar(50)) as MonBase,
							CAST(NULL as nvarchar(50)) as TueBase,
							CAST(NULL as nvarchar(50)) as WedBase,
							CAST(NULL as nvarchar(50)) as ThurBase,
							CAST(NULL as nvarchar(50)) as FriBase, 
							CAST(NULL as nvarchar(50)) as SatBase, 
							CAST(NULL as nvarchar(50)) as SunBase
						into ##tempRegulateBaseDrawBySaleWHLFinalData 
						from
						(select * FROM 
							(SELECT * from ##tempRegulateBaseDrawBySaleWHL ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
							(SELECT * from ##tempRegulateBaseDrawBySaleWHLPOS)p
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
				f.supplieridentifier=(select distinct supplieridentifier from dbo.suppliers  
				where supplierid=f.supplierid),
				f.Chainidentifier=(select distinct Chainidentifier from dbo.Chains  
				where chainid=f.chainid),
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
				AND SupplierID=f.supplierid and ProductPriceTypeID=3),
				F.MonBase=(Select Distinct  MonLimitQty  From dbo.StoreSetup Where ProductID=f.productid
				AND ChainID=F.chainid 	AND StoreID=f.storeid AND SupplierID=f.supplierid),
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
				from ##tempRegulateBaseDrawBySaleWHLFinalData f'

			EXEC(@strquery)
			
			--Return the Data
			SET @sqlQueryStoreNew=' select distinct StoreID, wholesalername as WholeSalerName,
									supplieridentifier as WholesalerID,storename,StoreNumber,address,City,State,zipcode 
									from ##tempRegulateBaseDrawBySaleWHLFinalData';
											
			SET @sqlQueryNew=' select distinct ( ''Store Number: '' + StoreNumber + '','' + StoreName  + ''/n Location: '' + address + '', '' + City + '','' + State + '', '' + zipcode ) as StoreInfo, WholeSalerName,						
								supplieridentifier as WholesalerID,storeid,Chainidentifier as ChainId,StoreNumber,	storename,address,City,
								State,zipcode,0 as CostToStore4Wholesaler,0 as CostToWholesaler,bipad,title,costtostore,
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
								sundayPOS)*(suggretail-CostToStore)) AS Profit,
								sum(mondayPOS)/Count(bipad) AS AvgMonSale,
								sum(tuesdayPOS)/Count(bipad) AS AvgTueSale,
								sum(wednesdayPOS)/Count(bipad) AS AvgWedSale,
								sum(thursdayPOS)/Count(bipad) AS AvgThuSale,
								sum(fridayPOS)/Count(bipad) AS AvgFriSale,
								sum(saturdayPOS)/Count(bipad) AS AvgSatSale,
								sum(sundayPOS)/Count(bipad) AS AvgSunSale,
								MonBase,
								TueBase, 
								WedBase,
								ThurBase,
								FriBase, 
								SatBase, 
								SunBase,
								Count(bipad) AS NoOfWeeksInRange,
								1 as Dbtype				

								From 
								##tempRegulateBaseDrawBySaleWHLFinalData
								group by chainid,supplieridentifier,wholesalername,StoreID,Chainidentifier,productid,storename,StoreNumber,address,City,
								State,zipcode,wholesalername,bipad,title,costtostore,suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,fridaydraw,
								saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,fridayPOS,saturdayPOS,sundayPOS,
								MonBase,TueBase,WedBase,ThurBase,FriBase, SatBase,SunBase  
								;'
	END
	
	IF(@allnew=2)
			BEGIN
				--SET @sqlQueryFinal=@sqlQueryStoreLegacy+ ' union ' +@sqlQueryStoreNew				
				--EXEC(@sqlQueryFinal)				
				SET @sqlQueryFinal=@sqlQueryLegacy+ ' union ' +@sqlQueryNew
				EXEC(@sqlQueryFinal)
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
	    END
END
GO
