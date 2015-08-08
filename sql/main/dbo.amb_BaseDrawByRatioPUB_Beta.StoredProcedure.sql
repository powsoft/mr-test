USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_BaseDrawByRatioPUB_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_BaseDrawByRatioPUB '-1','-1','','','-1','1900-01-01','1900-01-01','35321','DOWJ','-1'
--exec [amb_BaseDrawByRatioPUB_Beta] 'TA','CA','EMERYVILLE','','BARRONS','11/11/2007','11/11/2007','35321','DOWJ','365','WholesalerID ASC','1','25',1
--'DOWJ','35321','STC','BN','-1','-1','','1900-01-01','1900-01-01'
CREATE procedure [dbo].[amb_BaseDrawByRatioPUB_Beta]
(
@ChainID varchar(10),
@State varchar(10),
@City varchar(10),
@StoreNumber varchar(10),
@Title varchar(20),
@StartDate varchar(20),
@EndDate varchar(20) ,
@PublisherID varchar(20),
@PublisherIdentifier varchar(10),
@WholesalerID varchar(20),
@OrderBy varchar(100),
@StartIndex int,
@PageSize int,
@DisplayMode int
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
	Declare @allnew int --0 from old database,1 from new database, 2 from mixed
	DECLARE @chain_migrated_date date
	Declare @sqlQuery varchar(4000)
	
	
	IF(@ChainID<>'-1')
	BEGIN
		SELECT  @chain_migrated_date = CAST(datemigrated as VARCHAR)
		FROM    dbo.chains_migration
		WHERE   chainid = @ChainID;
		
		IF(CAST(@chain_migrated_date AS DATE) > CAST('1900-01-01' AS DATE))
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
	print @allnew 
		IF (@allnew=0 or @allnew=2)
		BEGIN
set @sqlQueryLegacy=' SELECT  (''Store # : '' + SL.StoreNumber + '', '' + SL.StoreName + ''/n Location:  '' + SL.Address + '', '' + SL.City + '','' + SL.State + '', '' + SL.ZipCode ) as StoreInfo, WL.WholesalerName, WL.WholesalerID, OnR.StoreID, SL.									StoreNumber, SL.StoreName, SL.Address, SL.City, SL.State,
					SL.ZipCode, OnR.[CostToStore4Wholesaler], OnR.[CostToWholesaler], 
					OnR.Bipad,P.TitleName AS Title, OnR.CostToStore, OnR.SuggRetail, 
					Sum(OnR.Mon) AS MonDraws, Sum(OnR.Tue) AS TueDraws, Sum(OnR.Wed) AS WedDraws, Sum(OnR.Thur) AS ThurDraws,
					Sum(OnR.Fri) AS FriDraws, Sum(OnR.Sat) AS SatDraws, Sum(OnR.Sun) AS SunDraws, Sum(OnR.MonR) AS MonReturns,
					Sum(OnR.TueR) AS TueReturns, Sum(OnR.WedR) AS WedReturns, Sum(OnR.ThurR) AS ThurReturns, Sum(OnR.FriR) AS									FriReturns, Sum(OnR.SatR) AS SatReturns, Sum(OnR.SunR) AS SunReturns, Sum(OnR.MonS) AS MonShort,
					Sum(OnR.TueS) AS TueShort, Sum(OnR.WedS) AS WedShort, Sum(OnR.ThurS) AS ThurShort, Sum(OnR.FriS) AS FriShort,
				  Sum(OnR.SatS) AS SatShort, Sum(OnR.SunS) AS SunShort, Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.						Sun) AS [TTL Draws], Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS [TT Returns], 
				  Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS [TTL Shortages],
				  Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+
				  [SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))	AS NetSales, 
				  Sum((onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+								[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([CostToStore4Wholesaler]-[CostToWholesaler]))
				  AS Profit, (Sum(onr.mon)-Sum([mons])-Sum([monr]))/Count(onr.bipad) AS AvgMonSale, BO.Mon AS MonBase,
					(Sum(onr.Tue)-Sum([Tues])-Sum([Tuer]))/Count(onr.bipad) AS AvgTueSale, BO.Tue AS TueBase,
					(Sum(onr.wed)-Sum([weds])-Sum([wedr]))/Count(onr.bipad) AS AvgWedSale, BO.Wed AS WedBase,
				  (Sum(onr.Thur)-Sum([Thurs])-Sum([Thurr]))/Count(onr.bipad) AS AvgThurSale, BO.Thur AS ThurBase, 
				  (Sum(onr.Fri)-Sum([fris])-Sum([frir]))/Count(onr.bipad) AS AvgFriSale, BO.Fri AS FriBase, 
				  (Sum(onr.Sat)-Sum([Sats])-Sum([Satr]))/Count(onr.bipad) AS AvgSatSale, BO.Sat AS SatBase,
				  (Sum(onr.sun)-Sum([suns])-Sum([sunr]))/Count(onr.bipad) AS AvgSunSale, BO.Sun AS SunBase,
				  Count(OnR.Bipad) AS NoOfWeeksInRange,BO.Hol ,''0'' as dbType
    
    
					FROM  [IC-HQSQL2].iControl.dbo.OnR OnR  
					INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad 
					INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
					INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID						
					INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder BO  ON SL.StoreID = BO.StoreID AND SL.ChainID = BO.ChainID
					AND P.Bipad = BO.Bipad '
    

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
			
			IF(@Title<>'-1')
				SET @sqlQueryLegacy = @sqlQueryLegacy +' AND P.AbbrvName = ''' + @Title+''''
				
			if(CAST(@oldStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy += '  AND OnR.WeekEnding >= ''' + CONVERT(varchar, +@oldStartdate,101) +  ''''
			
		if(CAST(@oldenddate AS DATE ) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryLegacy +=' AND OnR.WeekEnding <= ''' + CONVERT(varchar, +@oldenddate,101) + ''''		 
		
SET @sqlQueryLegacy = @sqlQueryLegacy + ' GROUP BY WL.WholesalerName,  WL.WholesalerID, 
				OnR.StoreID, SL.StoreNumber, SL.StoreName, SL.Address, SL.City, 
				SL.State, SL.ZipCode, OnR.Bipad, P.TitleName, OnR.[CostToStore4Wholesaler],
				OnR.[CostToWholesaler], OnR.CostToStore, OnR.SuggRetail, BO.Mon, BO.Tue, BO.Wed,
				BO.Thur, BO.Fri, BO.Sat, BO.Sun, OnR.ChainID, P.PublisherID,BO.Hol  '

		SET @sqlQueryLegacy = @sqlQueryLegacy + ' HAVING 1=1  AND P.PublisherID=''' + @PublisherIdentifier + ''''  

END

/*  Get the Data from the new database (DataRue_Main) */		

IF (@allnew=1 or  @allnew=2) 	
	
	BEGIN 
		     /* Get the data into tmp table for Draws */
			IF object_id('tempdb.dbo.##tempBaseDrawByRatioPUBDraw') is not null 
				BEGIN
				  drop table ##tempBaseDrawByRatioPUBDraw;
				END
				
				SET @strquery='select distinct st.ChainID,st.SupplierID,St.Storeid,
							st.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempBaseDrawByRatioPUBDraw
							
							from Storetransactions_forward st
							INNER JOIN Brands B ON st.BrandID=B.BrandID
							INNER JOIN Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN Suppliers sup  ON st.SupplierId=Sup.SupplierId
							inner JOIN Chains c on st.ChainID=c.ChainID
							INNER JOIN Stores s ON s.StoreID=st.StoreID
							INNER JOIN Addresses a ON a.OwnerEntityID=st.StoreID 
							INNER JOIN Products P ON	st.ProductID = P.ProductID	
							
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
				
				IF(@Title<>'-1')
				SET @strquery = @strquery +' AND P.ProductName = ''' + @Title+''''
									
				if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

				if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + '''' 
	 
				EXEC(@strquery)			
				
				/* Get the data into tmp table for POS */
			IF object_id('tempdb.dbo.##tempBaseDrawByRatioPUBPOS') is not null
				BEGIN
				   drop table ##tempBaseDrawByRatioPUBPOS
				END	
				SET @strquery=' Select distinct st.ChainID,st.SupplierID,St.Storeid,							
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempBaseDrawByRatioPUBPOS								
							
							from Storetransactions st
							inner join transactiontypes tt on tt.transactiontypeid=st.transactiontypeid 
							and tt.buckettype=1
							INNER JOIN Brands B ON st.BrandID=B.BrandID
							INNER JOIN Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN Suppliers sup  ON st.SupplierId=Sup.SupplierId
							inner JOIN Chains c on st.ChainID=c.ChainID
							INNER JOIN Stores s ON s.StoreID=st.StoreID
							INNER JOIN Addresses a ON a.OwnerEntityID=st.StoreID
							INNER JOIN Products P ON	st.ProductID = P.ProductID	 										
							
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
				
				IF(@Title<>'-1')
				SET @strquery = @strquery +' AND P.ProductName = ''' + @Title+''''
									
				if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

				if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + ''''
				
				exec(@strquery)			
				--Get the final data into final tmp table

			IF object_id('tempdb.dbo.##tempFinalData') is not null
				BEGIN
				    DROP Table ##tempFinalData
			    END	
			    
			    	SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "legacySystemStoreIdentifier",
							CAST(NULL as nvarchar(50)) as "supplieridentifier",
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
						into ##tempFinalData
						from
						(select * FROM 
							(SELECT * from ##tempBaseDrawByRatioPUBDraw ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
							(SELECT * from ##tempBaseDrawByRatioPUBPOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
							 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						on  tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'
												
			EXEC(@strquery)
			--Update the required fields
			SET @strquery='update f set 
				f.legacySystemStoreIdentifier=(select distinct legacySystemStoreIdentifier from dbo.Stores  
				where StoreID=f.StoreID),
				f.supplieridentifier=(select distinct supplieridentifier from dbo.suppliers  
				where supplierid=f.supplierid),
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
				from ##tempFinalData f'

			EXEC(@strquery)
		--Return the Data
			
											
			SET @sqlQueryNew=' select  ( ''Store Number: '' + StoreNumber + '','' + StoreName  + ''/n Location: '' + address + '', '' + City + '','' + State + '', '' + zipcode ) as StoreInfo, WholeSalerName,						
								supplieridentifier as WholesalerID,legacySystemStoreIdentifier as storeid,
								StoreNumber,	storename,address,City,
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
								MonBase,
								sum(tuesdayPOS)/Count(bipad) AS AvgTueSale,
								TueBase, 
								sum(wednesdayPOS)/Count(bipad) AS AvgWedSale,
								WedBase,
								sum(thursdayPOS)/Count(bipad) AS AvgThuSale,
								ThurBase,
								sum(fridayPOS)/Count(bipad) AS AvgFriSale,
								FriBase,
								sum(saturdayPOS)/Count(bipad) AS AvgSatSale,
								SatBase, 
								sum(sundayPOS)/Count(bipad) AS AvgSunSale,	
								SunBase,
								Count(bipad) AS NoOfWeeksInRange,
								0 as Hol,''1'' as dbType					

								From 
								##tempFinalData
								group by chainid,supplieridentifier,wholesalername,StoreID,productid,storename,StoreNumber,address,City,
								State,zipcode,wholesalername,bipad,title,costtostore,suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,fridaydraw,
								saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,fridayPOS,saturdayPOS,sundayPOS,
								MonBase,TueBase,WedBase,ThurBase,FriBase, SatBase,SunBase,legacySystemStoreIdentifier  
								'
	END
	
	IF(@allnew=2)
			BEGIN			
			Set @sqlQueryFinal= 'SELECT DISTINCT * FROM  ( ' + @sqlQueryLegacy +'union'+' ' +  @sqlQueryNew	+ '	) as temp '
			set @sqlQueryFinal = [dbo].GetPagingQuery_New(@sqlQueryFinal, @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)	
			--print (@sqlQueryFinal)
				EXEC(@sqlQueryFinal)
		   END
	ELSE IF(@allnew=1)
		BEGIN			
			set @sqlQueryNew = [dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  (  '+@sqlQueryNew+'	) as temp ', @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
			EXEC(@sqlQueryNew)
		END
	ELSE IF(@allnew=0)
		BEGIN			
			set @sqlQueryLegacy = [dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  (  '+@sqlQueryLegacy+'	) as temp ', @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
			EXEC(@sqlQueryLegacy)
	    END
END
GO
