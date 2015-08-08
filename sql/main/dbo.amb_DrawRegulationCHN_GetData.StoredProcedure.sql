USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawRegulationCHN_GetData]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_DrawRegulationCHN_GetData 'BN','42493','SIOUX CITY','IA','','01/01/1900','01/01/1900'
--Exec amb_DrawRegulationCHN_GetData 'BN','42493','-1','AK','','01/01/1900','01/01/2009'
CREATE procedure [dbo].[amb_DrawRegulationCHN_GetData]
(
	@ChainIdentifier varchar(10),
	@ChainID varchar(10),
	@City varchar(50),
	@State varchar(40),
	@StoreNumber varchar(50),
	@StartDate varchar(20),
	@EndDate varchar(20)
)
as 
BEGIN
	declare @sqlQueryFinal varchar(8000)
	Declare @sqlQueryStoreLegacy varchar(8000)
	Declare @sqlQueryStoreNew varchar(8000)
	Declare @sqlQueryLegacy varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @oldStartdate varchar(8000)
	Declare @oldenddate varchar(8000)
	Declare @newStartdate varchar(8000)
	Declare @newenddate varchar(8000)
	Declare @allnew int --0 from old database,1 for new database, 2 from mixed
	DECLARE @chain_migrated_date date

	SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) FROM dbo.chains_migration WHERE   chainid = @ChainIdentifier;

	if(cast(@chain_migrated_date as date) > cast('01/01/1900' as date))
		begin
			if(cast( @StartDate as date) >= cast(@chain_migrated_date as date))
				Begin
					set @allnew=1
					set @newStartdate=@StartDate
					set @newEnddate=@EndDate
				END
			else if(cast(@EndDate as date ) < cast(@chain_migrated_date as date))
				begin
					set @allnew=0
					set @oldStartdate=@StartDate
					set @oldenddate=@EndDate
				End
			else if(cast(@EndDate as date ) >= cast(@chain_migrated_date as date) and cast(@startdate as date ) <= cast(@chain_migrated_date as date))
				begin
					set @allnew=2
					set @oldStartdate=@StartDate
					set @oldenddate=@chain_migrated_date
					set @newStartdate=DATEADD(dd, 1, @chain_migrated_date)
					set @newEnddate=@EndDate
				end
			end
	else
		begin
			set @allnew=0
			set @oldStartdate=@StartDate
			set @oldenddate=@EndDate
		end


	IF (@allnew=0 or  @allnew=2) 
		BEGIN
			set @sqlQueryStoreLegacy='SELECT distinct SL.StoreID,SL.StoreNumber,
																SL.StoreName,SL.Address, SL.City, 
																SL.State, SL.ZipCode 
																FROM  [IC-HQSQL2].iControl.dbo.OnR OnR  
																INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad 
																INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID
																INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist  WL ON OnR.WholesalerID = WL.WholesalerID
																INNER JOIN  [IC-HQSQL2].iControl.dbo.BaseOrder  BO 	ON SL.StoreID = BO.StoreID 
																AND SL.ChainID = BO.ChainID 
																AND P.Bipad = BO.Bipad'
																
			set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' WHERE OnR.ChainID=''' + @ChainIdentifier + ''' 
																AND SL.Storeid Like ''%'+@StoreNumber+'%''' 
			if(@City<>'-1')      
				set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' AND SL.City Like '''+@City+ ''' '
			
			if(@State<>'-1')    
				set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' AND SL.State Like '''+@State+''''
			
			if(cast(@oldStartdate as date ) > cast('1900-01-01' as date))
				set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +'  and OnR.WeekEnding >= ''' + convert(varchar, +@oldStartdate,101) +  ''''
			
			if(cast( @oldenddate as date ) > cast( '1900-01-01' as date))
				set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +'  AND OnR.WeekEnding <= ''' + convert(varchar, +@oldenddate,101) + ''''
 		
			set @sqlQueryLegacy=' SELECT distinct 
			(''Store Number: '' + SL.StoreNumber + ''; Account Number: '' + 
										SL.StoreId + '';/n Location: '' + SL.StoreName + '', '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,
											WL.WholesalerName, 
											SL.StoreID,
											OnR.Bipad, 
											P.AbbrvName AS Title,
											OnR.CostToStore, 
											OnR.SuggRetail, 
											Sum(OnR.Mon) AS MonDraws,
											Sum(OnR.Tue) AS TueDraws, 
											Sum(OnR.Wed) AS WedDraws,
											Sum(OnR.Thur) AS ThurDraws, 
											Sum(OnR.Fri) AS FriDraws,
											Sum(OnR.Sat) AS SatDraws, 
											Sum(OnR.Sun) AS SunDraws,
											Sum(OnR.MonR) AS MonReturns, 
											Sum(OnR.TueR) AS TueReturns,
											Sum(OnR.WedR) AS WedReturns, 
											Sum(OnR.ThurR) AS ThurReturns,
											Sum(OnR.FriR) AS FriReturns, 
											Sum(OnR.SatR) AS SatReturns,
											Sum(OnR.SunR) AS SunReturns, 
											Sum(OnR.MonS) AS MonShort,
											Sum(OnR.TueS) AS TueShort, 
											Sum(OnR.WedS) AS WedShort,
											Sum(OnR.ThurS) AS ThurShort, 
											Sum(OnR.FriS) AS FriShort,
											Sum(OnR.SatS) AS SatShort, 
											Sum(OnR.SunS) AS SunShort,
											(Sum(OnR.Mon)-Sum(OnR.MonR)-Sum(OnR.MonS)) as  MonNetSales,
											(Sum(OnR.Tue)-Sum(OnR.TueR)-Sum(OnR.TueS)) as  TueNetSales,
											(Sum(OnR.Wed)-Sum(OnR.WedR)-Sum(OnR.WedS)) as  WedNetSales,
											(Sum(OnR.Thur)-Sum(OnR.ThurR)-Sum(OnR.ThurS)) as  ThurNetSales,
											(Sum(OnR.Fri)-Sum(OnR.FriR)-Sum(OnR.FriS)) as  FriNetSales,
											(Sum(OnR.Sat)-Sum(OnR.SatR)-Sum(OnR.SatS)) as  SatNetSales,
											(Sum(OnR.Sun)-Sum(OnR.SunR)-Sum(OnR.SunS)) as  SunNetSales,
											Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun) AS [TTL Draws],
											Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS [TT Returns],
											Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS [TTL Shortages],
											Sum(onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) AS NetSales, 
											Sum((onr.mon+onr.Tue+onr.Wed+onr.Thur+onr.Fri+onr.Sat+onr.Sun-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([SuggRetail]-[CostToStore])) AS Profit,
											BO.Mon AS MonBase,
											BO.Tue AS TueBase, 
											BO.Wed AS WedBase, 
											BO.Thur AS ThurBase, 
											BO.Fri AS FriBase, 
											BO.Sat AS SatBase, 
											BO.Sun AS SunBase,					
											(Sum(onr.mon)-Sum([mons])-Sum([monr]))/Count(onr.bipad) AS AvgMonSale, 
											(Sum(onr.Tue)-Sum([Tues])-Sum([Tuer]))/Count(onr.bipad) AS AvgTueSale, 
											(Sum(onr.wed)-Sum([weds])-Sum([wedr]))/Count(onr.bipad) AS AvgWedSale, 
											(Sum(onr.Thur)-Sum([Thurs])-Sum([Thurr]))/Count(onr.bipad) AS AvgThurSale, 
											(Sum(onr.Fri)-Sum([fris])-Sum([frir]))/Count(onr.bipad) AS AvgFriSale,
											(Sum(onr.Sat)-Sum([Sats])-Sum([Satr]))/Count(onr.bipad) AS AvgSatSale,
											(Sum(onr.sun)-Sum([suns])-Sum([sunr]))/Count(onr.bipad) AS AvgSunSale, 
											
											Count(OnR.Bipad) AS NoOfWeeksInRange

											FROM  [IC-HQSQL2].iControl.dbo.OnR OnR  
											INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad 
											INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID
											INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID
											INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder BO  ON (SL.StoreID = BO.StoreID) AND (SL.ChainID = BO.ChainID) AND (P.Bipad = BO.Bipad)'

			set @sqlQueryLegacy = @sqlQueryLegacy +' WHERE OnR.ChainID=''' + @ChainIdentifier + '''
											 AND SL.storeid Like ''%'+@StoreNumber+'%''' 
			if(@City<>'-1')      
				set @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.City Like '''+@City+ ''''
				
			if(@State<>'-1')    
				set @sqlQueryLegacy = @sqlQueryLegacy +' AND SL.State Like '''+@State+''''
			
			if(cast( @oldStartdate as date) > cast( '1900-01-01' as date))
			set @sqlQueryLegacy = @sqlQueryLegacy +'  and OnR.WeekEnding >= ''' + convert(varchar, +@oldStartdate,101) +  ''' '
		
			if(cast( @oldenddate as date ) > cast( '1900-01-01' as date))	
			set @sqlQueryLegacy = @sqlQueryLegacy +'  AND OnR.WeekEnding <= ''' + convert(varchar, +@oldenddate,101) + ''''

			
			
			set @sqlQueryLegacy = @sqlQueryLegacy +' group by onr.WeekEnding,WL.WholesalerName, SL.StoreID,
											OnR.Bipad, P.AbbrvName ,SL.StoreNumber,
											SL.StoreName,SL.Address,SL.City,SL.State, 
										    SL.ZipCode,OnR.CostToStore, OnR.SuggRetail,
											onr.mon,onr.Tue,onr.Wed,onr.Thur,onr.Fri,onr.Sat,onr.Sun ,
											[monr],[tueR],[wedr],[ThurR],[Frir],[SatR],[SunR],
											[mons],[tues],[weds],[ThurS],[fris],[SatS],[SunS],
											BO.Mon ,BO.Tue , BO.Wed ,BO.Thur ,BO.Fri ,
											BO.Sat ,BO.Sun '
																		
		end
		
		
	IF (@allnew=1 or @allnew=2) 
		BEGIN
				--Get the data in to tmp table for draws	
				if object_id('tempdb.dbo.##tempDrawRegulationDrawsCHN') is not null
				begin
				 drop table ##tempDrawRegulationDrawsCHN;
				end
				declare @strquery varchar(8000)
				set @strquery='select distinct st.ChainID,st.SupplierID,st.storeid,
											st.ProductID,RuleCost,Qty,TransactionTypeID,
											datename(W,SaleDateTime)+ ''Draw'' as "wDay"
											
											into ##tempDrawRegulationDrawsCHN
											
											from dbo.Storetransactions_forward st
											INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
											INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
											
											where TransactionTypeID in (29)
											and st.chainid=''' + @ChainID +'''
											and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
				if(@City<>'-1')   
				set @strquery = @strquery +' and a.City like '''+@City+''''							   
				
				if(@State<>'-1')    
				set @strquery = @strquery +' and	a.State like '''+@State+''''
												
				if(cast(  @newStartdate as date) > cast( '1900-01-01' as date))
				set @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
				if(cast( @newEnddate as date ) > cast( '1900-01-01' as date)) 
				set @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
					
				EXEC(@strquery)
			
				--Get the data into tmp table for POS	
							
				if object_id('tempdb.dbo.##tempDrawRegulationPOSCHN') is not null
				begin
				 drop table ##tempDrawRegulationPOSCHN;
				end
				set @strquery='select distinct st.ChainID,st.SupplierID,st.storeid,
							st.ProductID,RuleCost,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"
						
							into ##tempDrawRegulationPOSCHN
						
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
							
							where st.chainid='''+ @ChainID +'''
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
												
					if(@City<>'-1')   
						set @strquery = @strquery +' and a.City like '''+@City+''''							   

					if(@State<>'-1')    
						set @strquery = @strquery +' and	a.State like '''+@State+''''
												
					if(CAST(@newStartdate as DATE) > CAST('1900-01-01' as DATE))
						set @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
					if(CAST(@newEnddate as DATE) > CAST('1900-01-01' as DATE)) 
						set @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
												
					EXEC(@strquery)			
					
				--Get the final data into final tmp table
				
				if object_id('tempdb.dbo.##tempDrawRegulationCHNFinalData') is not null
				begin
					drop table ##tempDrawRegulationCHNFinalData
				end


				set @strquery='Select distinct tmpdraws.*,
								tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
								tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
								CAST(NULL as nvarchar(50)) as "WholesalerName",
								CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",
								CAST(NULL as nvarchar(50)) as "StoreName",
								CAST(NULL as nvarchar(50)) as "StoreNumber",
								CAST(NULL as nvarchar(100)) as "Address",
								CAST(NULL as nvarchar(50)) as "City",
								CAST(NULL as nvarchar(50)) as "State",
								CAST(NULL as nvarchar(50)) as "ZipCode",
								CAST(NULL as nvarchar(50)) as "BiPad",
								CAST(NULL as nvarchar(225)) as "Title",
								CAST(NULL as MONEY) as "CostToStore",
								CAST(NULL as money) as "SuggRetail",
								CAST(NULL as money) as "MonBase",
								CAST(NULL as money) as "TueBase",
								CAST(NULL as money) as "WedBase",
								CAST(NULL as money) as "ThurBase",
								CAST(NULL as money) as "FriBase",
								CAST(NULL as money) as "SatBase",
								CAST(NULL as money) as "SunBase"
							into ##tempDrawRegulationCHNFinalData 
							from
							(select * FROM 
								(SELECT * from ##tempDrawRegulationDrawsCHN ) p
								 pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) 
								 as Draw_eachday
							) tmpdraws
							left join
							( select * from 
								(SELECT * from ##tempDrawRegulationPOSCHN)p
								 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								) as p1
							) tmpPOS 
							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid'
					
					exec(@strquery)
				

				--Update the required fields
				set @strquery='update f set 
				f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers where SupplierID=f.supplierid),
				f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
				f.StoreName=(select distinct StoreName from dbo.Stores  where StoreID=f.StoreID),
				f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
				f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=f.productid),
				f.title=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),
				f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
				and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
				f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
				and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
				f.MonBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
				f.TueBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
				f.WedBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
				f.ThurBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
				f.FriBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
				f.SatBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
				f.SunBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid )
				from ##tempDrawRegulationCHNFinalData f'
				exec(@strquery)
			
				--Return the Data
				set @sqlQueryStoreNew=' select distinct LegacySystemStoreIdentifier as StoreID,storename,StoreNumber,address,City,State,zipcode
																from ##tempDrawRegulationCHNFinalData';
			
				set @sqlQueryNew=' select distinct (''Store Number: '' + StoreNumber + ''; Account Number: '' + 
										LegacySystemStoreIdentifier + '';/n Location: '' 
										+ storename + '', '' + address + '', '' + City + '', 
										'' + State + '', '' + zipcode ) as StoreInfo, wholesalername,
										LegacySystemStoreIdentifier as StoreID,storename,StoreNumber,address,City,State,zipcode,
								       bipad,title,costtostore,suggretail,mondaydraw as MonDraws,tuesdaydraw as TueDraws,wednesdaydraw as WedDraws,
								  thursdaydraw as ThurDraws,fridaydraw as FriDraws,saturdaydraw as SatDraws,sundaydraw as SunDraws,
								  mondaydraw-mondayPOS as MonReturns,tuesdaydraw-tuesdayPOS as TueReturns,wednesdaydraw-wednesdayPOS as WedReturns,
								  thursdaydraw-thursdayPOS as ThurReturns,fridaydraw-fridayPOS as FriReturns,saturdaydraw-saturdayPOS as SatReturns,
									sundaydraw-sundayPOS as SunReturns,
									''0'' AS MonShort,''0'' AS TueShort, ''0'' AS WedShort,''0'' AS ThurShort, ''0'' AS FriShort,
									''0'' AS SatShort, ''0'' AS SunShort,
									mondayPOS as  MonNetSales,tuesdayPOS as  TueNetSales,wednesdayPOS as  WedNetSales,
									thursdayPOS as  ThurNetSales,fridayPOS as  FriNetSales,
									saturdayPOS as  SatNetSales,sundayPOS as  SunNetSales,

									Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS [TTL Draws],
									Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-
									(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS [TT Returns],
									0 AS [TTL Shortages],
									Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS NetSales,
									Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)*(suggretail-CostToStore)) AS Profit,

									MonBase,TueBase,WedBase,ThurBase,FriBase,SatBase,SunBase,

									mondayPOS AS AvgMonSale, tuesdayPOS AS AvgTueSale,wednesdayPOS AS AvgWedSale,  thursdayPOS AS AvgThurSale, 
									fridayPOS AS AvgFriSale,saturdayPOS AS AvgSatSale,sundayPOS AS AvgSunSale, 

									count(bipad) AS NoOfWeeksInRange
									from 
									##tempDrawRegulationCHNFinalData

									group by chainid,supplierid,LegacySystemStoreIdentifier,productid,wholesalername,bipad,title,costtostore,suggretail,
									mondaydraw ,tuesdaydraw,wednesdaydraw,thursdaydraw ,fridaydraw ,saturdaydraw ,sundaydraw,
									mondayPOS,tuesdayPOS,wednesdayPOS,thursdayPOS,fridayPOS,saturdayPOS,sundayPOS,MonBase,TueBase,WedBase,
									ThurBase,FriBase,SatBase,SunBase'
			
	end
	


	if(@allnew=2)
			begin
			
				--set @sqlQueryFinal=@sqlQueryStoreLegacy+ ' union ' +@sqlQueryStoreNew +' Order By StoreID,storename'
				--exec(@sqlQueryFinal)
				set @sqlQueryFinal=@sqlQueryLegacy+ ' union ' +@sqlQueryNew +' Order By wholesalername,bipad,title'
				exec(@sqlQueryFinal)
				
		end
	else IF(@allnew=1)
		begin		
		print @sqlQueryStoreNew
		print @sqlQueryNew
			--exec(@sqlQueryStoreNew+' Order By StoreID,storename')
			EXEC(@sqlQueryNew+' Order By wholesalername,bipad,title')
			
	end
	else IF(@allnew=0)
		begin
			--exec (@sqlQueryStoreLegacy+' Order By StoreID,storename')
			EXEC(@sqlQueryLegacy+' Order By wholesalername,bipad,title')			
	end

end
GO
