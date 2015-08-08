USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DeliveryAndNetProfitDetailViewPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [amb_DeliveryAndNetProfitDetailViewPUB] 'DOWJ','35321','CVS','','01/01/1900'
-- EXEC [amb_DeliveryAndNetProfitDetailViewPUB] 'NEWSD','35418','-1','','1900-01-01'

CREATE procedure [dbo].[amb_DeliveryAndNetProfitDetailViewPUB]
(
	@PublisherIdentifier varchar(50),
	@PublisherId varchar(50),
	@ChainId varchar(50),
	@Store varchar(50),
	@WeekEnd varchar(50)
)

as 
BEGIN

Declare @sqlQuery varchar(4000)
Declare @sqlQueryFinal varchar(8000)
Declare @strquery varchar(8000)
Declare @sqlQueryLegacy varchar(8000)
Declare @sqlQueryStoreLegacy varchar(8000)
Declare @sqlQueryNew varchar(8000)
Declare @sqlQueryStoreNew varchar(8000)
DECLARE @BillingControlDay INT 
Declare @newStartdate varchar(20)='1900/01/01'
Declare @newenddate varchar(20)='1900/01/01'
DECLARE @TodayDayOfWeek INT
DECLARE @EndDate DateTime='1900/01/01'
DECLARE @StartDate DateTime='1900/01/01'
Declare @DBType int --0 for old database,1 from new database, 2 from mixed
DECLARE @chain_migrated_date date
	
IF(@ChainID<>'-1')
BEGIN
	SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) 
	FROM dbo.chains_migration WHERE   chainid = @ChainId;
	
	IF(cast(@chain_migrated_date as date) > cast('01/01/1900' as date))
		BEGIN
			IF(cast(@WeekEnd as date) > cast('01/01/1900' as date))
				BEGIN
					
					select @BillingControlDay=BillingControlDay 
					from dbo.BillingControl bc
					inner join dbo.chains c on c.chainid=bc.chainid
					where  c.chainidentifier=@ChainID 

					SET @TodayDayOfWeek = datepart(dw, (@WeekEnd))
					--get the last day of the previous week (last Sunday)
					SET @EndDate = DATEADD(dd, @BillingControlDay -(@TodayDayOfWeek ), @WeekEnd)
					--get the first day of the previous week (the Monday before last)
					SET @StartDate = DATEADD(dd,@BillingControlDay -((@TodayDayOfWeek)+6), @WeekEnd)

					IF(cast(@WeekEnd as date) >= cast(@chain_migrated_date as date))
						BEGIN
							SET @dbType=2
							IF(cast(@StartDate as date) >= cast(@chain_migrated_date as date))
								SET @newStartdate=@StartDate
							ELSE
								SET @newStartdate=DATEADD(dd,1,@chain_migrated_date)
							SET @newEnddate=@EndDate
						END
					ELSE IF(cast(@WeekEnd as date) < cast(@chain_migrated_date as date))
							SET @dbType=0
				END
			Else
				SET @dbType=0
		END
	Else
		BEGIN
			SET @dbType=0
		END
	END
ELSE
	SET @DBType=2
	
	

IF (@DBType=0 or  @DBType=2) 
BEGIN
    
    set @sqlQueryStoreLegacy='SELECT distinct SL.StoreID,SL.StoreName,SL.StoreNumber,
							  SL.Address,SL.City, SL.State,SL.ZipCode  
                 
							  FROM   [IC-HQSQL\ICONTROL].iControl.dbo.OnR OnR  
							  INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
							  INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID
							  INNER JOIN   [IC-HQSQL\ICONTROL].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID 

							  Where 1 = 1 AND P.PublisherID=''' + @PublisherIdentifier + ''''
							
	IF(@ChainID<>'-1')
			SET @sqlQueryStoreLegacy += ' And OnR.ChainID=''' + @ChainID + ''''	
			
	IF(@Store<>'')		 
			SET @sqlQueryStoreLegacy += ' AND SL.Storeid Like ''%'+@Store+'%''' 		
					
	IF(cast( @Weekend as date) <> cast( '01/01/1900' as date))
			SET @sqlQueryStoreLegacy +='  AND OnR.WeekEnding= '''+ CONVERT(VARCHAR,+@WeekEnd,101) +''' '
			
			
	SET @sqlQueryLegacy=' SELECT Distinct ('' Chain # : '' + SL.StoreName  + '' Store # '' + SL.StoreNumber  + '' /n Location # : '' + SL.Address +'', '' + SL.City + '','' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,WL.WholesalerName, OnR.StoreID, SL.StoreNumber,SL.StoreName,SL.Address, 
							SL.City, SL.State, SL.ZipCode, OnR.Bipad, P.AbbrvName AS Title, 
							CostToStore4Wholesaler, CostToWholesaler, OnR.CostToStore, OnR.SuggRetail,OnR.WeekEnding, 
							OnR.Mon, OnR.Tue, OnR.Wed, OnR.Thur, OnR.Fri, OnR.Sat, OnR.Sun, OnR.MonR, OnR.TueR, 
							OnR.WedR, OnR.ThurR, OnR.FriR, OnR.SatR, OnR.SunR, OnR.MonS, OnR.TueS, OnR.WedS, OnR.ThurS, 
							OnR.FriS, OnR.SatS, OnR.SunS, [mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun] AS Draws,	
							[monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR] AS Returns, 
							[mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS] AS Shortages, 
							[mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
							([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS NetSales, 
							([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
							([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([CostToStore4Wholesaler]-[CostToWholesaler]) AS Profit 
							
							FROM   [IC-HQSQL\ICONTROL].iControl.dbo.OnR OnR  
							INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
							INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
							INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID=WL.WholesalerID '

	SET @sqlQueryLegacy += ' GROUP BY  SL.StoreID,OnR.ChainID, OnR.WholesalerID, WL.WholesalerName, OnR.StoreID, SL.StoreNumber, 
							SL.StoreName, SL.Address, SL.City,SL.State, SL.ZipCode, 
							P.PublisherID, OnR.Bipad, P.AbbrvName,CostToStore4Wholesaler, CostToWholesaler, 
							OnR.CostToStore, OnR.SuggRetail, OnR.WeekEnding,OnR.Mon, OnR.Tue, OnR.Wed, OnR.Thur, 
							OnR.Fri, OnR.Sat, OnR.Sun, OnR.MonR, OnR.TueR, OnR.WedR, OnR.ThurR, OnR.FriR, OnR.SatR, 
							OnR.SunR, OnR.MonS,OnR.TueS, OnR.WedS, OnR.ThurS, OnR.FriS, OnR.SatS, OnR.SunS '

	SET @sqlQueryLegacy += ' HAVING 1=1 AND P.PublisherID=''' + @PublisherIdentifier + ''' '

	IF(@Store<>'')		 
		SET @sqlQueryLegacy += ' AND SL.Storeid Like ''%' + @Store + '%'' '

	IF(@ChainId<>'-1')	
		SET @sqlQueryLegacy += ' AND Onr.ChainID Like''' + @ChainId + ''' '
		
	IF(cast(@Weekend as date) <> cast( '01/01/1900' as date))
		SET @sqlQueryLegacy += '  AND OnR.WeekEnding= '''+ CONVERT(VARCHAR,+@WeekEnd,101) +''' '

END
			
			
IF (@DBType=1 or @DBType=2)
	BEGIN
		IF object_id('tempdb.dbo.##tempViewDeliveryProfitDetailsDraws') is not null		
	
		--Get the data in to tmp table for draws
				BEGIN
					drop table ##tempViewDeliveryProfitDetailsDraws;
				END
			
			SET @strquery='SELECT Distinct M.ManufacturerIdentifier AS PublisherID,ST.ChainID,ST.SupplierID,S.storeid,
							ST.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							
							INTO ##tempViewDeliveryProfitDetailsDraws
							
							FROM dbo.Storetransactions_forward ST
							INNER JOIN dbo.Brands B ON B.BrandID=st.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN dbo.Chains C ON ST.ChainID=C.ChainID
							INNER JOIN dbo.Stores S ON S.StoreID=ST.StoreID
							INNER JOIN dbo.Addresses A ON A.OwnerEntityID=ST.StoreID
							
							where TransactionTypeID in (29) and S.LegacySystemStoreIdentifier like ''%'+@Store+'%'' 
							and  M.ManufacturerId=' + @PublisherID 
						
		IF(@ChainID<>'-1')					
			SET @strquery += ' and C.ChainIdentifier='''+@ChainID+''''
								
		IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery += ' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
	
		IF(CAST( @newEnddate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery += ' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
				
		EXEC(@strquery)
		
		
		--Get the data into tmp table for POS
		IF object_id('tempdb.dbo.##tempViewDeliveryProfitDetailsPOS') is not null
			BEGIN
				drop table ##tempViewDeliveryProfitDetailsPOS
			END	
			
		SET @strquery='SELECT Distinct M.ManufacturerIdentifier AS PublisherID,ST.ChainID,ST.SupplierID,
						S.StoreId,ST.ProductID,Qty,ST.TransactionTypeID,
						datename(W,SaleDateTime)+ ''POS'' as "POSDay"
												
						INTO ##tempViewDeliveryProfitDetailsPOS						
						
						FROM dbo.Storetransactions ST
						INNER JOIN dbo.TransactionTypes TT on TT.TransactionTypeId=ST.TransactionTypeId and TT.Buckettype=1
						INNER JOIN dbo.Brands B ON B.BrandID=ST.BrandID
						INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
						INNER JOIN dbo.Chains C ON ST.ChainID=C.ChainID
						INNER JOIN dbo.Stores S ON S.StoreID=ST.StoreID
						INNER JOIN dbo.Addresses A ON A.OwnerEntityID=ST.StoreID 										
						
						Where 1=1 and  M.ManufacturerId =' + @PublisherID + '
						and S.LegacySystemStoreIdentifier like ''%'+@Store+'%'''
		
		IF(@ChainID<>'-1')					
			SET @strquery += ' AND C.ChainIdentifier='''+@ChainID+''''							
									
		IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery += ' AND SaleDateTime >= ''' +  convert(varchar, +@newStartdate,101) +  ''''
			
		IF(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery += ' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
						
		EXEC(@strquery)	
		
		
	  IF object_id('tempdb.dbo.##tempViewDeliveryProfitDetailsFinalData') is not null
			BEGIN
				Drop Table ##tempViewDeliveryProfitDetailsFinalData	
			END		
							
	  SET @strquery='Select distinct tmpdraws.*,
					tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
					WednesdayPOS,tmpPOS.ThursdayPOS,
					tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
					CAST(NULL as nvarchar(50)) as "WholesalerName",
					CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",	
				    CAST(NULL as nvarchar(50)) as "StoreNumber",			
					CAST(NULL as nvarchar(50)) as "StoreName",
					CAST(NULL as nvarchar(100)) as "Address",
					CAST(NULL as nvarchar(50)) as "City",
					CAST(NULL as nvarchar(50)) as "State",
					CAST(NULL as nvarchar(50)) as "ZipCode",
					CAST(NULL as nvarchar(225)) as "Title",
					CAST(NULL as MONEY) as "CostToStore",
					CAST(NULL as MONEY) as "SuggRetail",
					CAST(NULL as nvarchar(50)) as "BiPad",
					CAST(NULL as nvarchar(50)) as "supplieridentifier",
					CAST(NULL as nvarchar(50)) AS WeekEnding
		
					INTO ##tempViewDeliveryProfitDetailsFinalData 
					FROM
					(select * FROM 
						(SELECT * from ##tempViewDeliveryProfitDetailsDraws ) p
						 pivot( sum(Qty) for  wDay in
						  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
						  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
					) tmpdraws
					join
					( select * from 
						(SELECT * from ##tempViewDeliveryProfitDetailsPOS)p
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
					
		SET @strquery='update F set 
							F.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers
							where SupplierID=F.supplierid),
							
							F.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores 
							where StoreID=f.StoreID),
							
							F.StoreNumber=(select distinct StoreIdentifier from dbo.Stores where StoreID=F.StoreID),	
									
							F.StoreName=(select distinct StoreName from dbo.Stores where StoreID=F.StoreID),
							
							F.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=F.StoreID),
							
							F.city=(select distinct city from dbo.Addresses where OwnerEntityID=F.StoreID),
							
							F.state=(select distinct state from dbo.Addresses where OwnerEntityID=F.StoreID),
							
							F.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=F.StoreID),
							
							F.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=F.productid),
							
							F.title=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=F.productid),
							
							F.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=F.productid 
							AND ChainID=f.chainid and StoreID=F.storeid AND SupplierID=F.supplierid and ProductPriceTypeID=3),
							
							F.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid 
							AND ChainID=F.chainid and StoreID=F.storeid AND SupplierID=F.supplierid and ProductPriceTypeID=3),
							
							F.supplieridentifier=(select distinct supplieridentifier from dbo.suppliers where supplierid=F.supplierid),
							
							F.WeekEnding=(select distinct top 1 Saledatetime from dbo.Storetransactions_forward 
							where supplierid=F.supplierid and ChainId=f.ChainId and StoreID=F.StoreID 
							and ProductId=F.ProductId and TransactionTypeID in (29))
							
							FROM ##tempViewDeliveryProfitDetailsFinalData F '
			
		EXEC(@strquery)
		
			--Return the Data
	   SET @sqlQueryStoreNew=' select distinct LegacySystemStoreIdentifier as StoreID,storename,StoreNumber,address,City,State,zipcode 
							   FROM ##tempViewDeliveryProfitDetailsFinalData';
		
	   SET @sqlQueryNew='select distinct ('' Chain # : '' + StoreName +  ''  Store #'' + StoreNumber  + ''/n Location # : '' 
										+ StoreNumber + '', '' + address + '', '' + City + '', 
										'' + State + '', '' + zipcode ) as StoreInfo,WholeSalerName,LegacySystemStoreIdentifier as StoreId,StoreNumber,StoreName,Address,City,State,ZipCode,
						Bipad,Title,0 as CostToStore4Wholesaler,0 as CostToWholesaler,CostToStore,SuggRetail,WeekEnding,
						mondaydraw AS Mon,tuesdaydraw AS Tue,wednesdaydraw AS Wed,
						thursdaydraw AS Thur,fridaydraw AS Fri,saturdaydraw AS Sat,sundaydraw AS Sun,
						mondaydraw-mondayPOS as MonR, tuesdaydraw-tuesdayPOS as TueR, wednesdaydraw-wednesdayPOS as WedR,
						thursdaydraw-thursdayPOS as ThurR, fridaydraw-fridayPOS as FriR, saturdaydraw-saturdayPOS as SatR,
						sundaydraw-sundayPOS as SunR,0 AS MonS,0 AS TueS, 0 AS WedS,0 AS ThurS, 0 AS FriS,0 AS SatS,0 AS SunS,															Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS [Draws],
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+
						sundaydraw-(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS [Returns],
						0 AS [Shortages],
						Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS NetSales, 
						Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
						sundayPOS)*(suggretail-CostToStore)) AS Profit				

						FROM  ##tempViewDeliveryProfitDetailsFinalData
						
						GROUP BY LegacySystemStoreIdentifier,supplieridentifier,wholesalername,StoreID,
						productid,storename,StoreNumber,address,City,State,zipcode,wholesalername,bipad,
						title,costtostore,suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,
						fridaydraw,saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,
						fridayPOS,saturdayPOS,sundayPOS,WeekEnding ;'		

	END
print 	@DBType		
IF(@DBType=2)
	BEGIN							
		--SET @sqlQueryFinal=@sqlQueryStoreLegacy+ ' UNION ' +@sqlQueryStoreNew		
		--EXEC(@sqlQueryFinal)				
		SET @sqlQueryFinal=@sqlQueryLegacy+ ' UNION ' +@sqlQueryNew
		EXEC(@sqlQueryFinal)
		print @sqlQueryFinal
	END
ELSE IF(@DBType=1)
	BEGIN
		--EXEC(@sqlQueryStoreNew)
		EXEC(@sqlQueryNew)
	END
ELSE IF(@DBType=0)
	BEGIN
		--EXEC (@sqlQueryStoreLegacy)
		EXEC(@sqlQueryLegacy)
	END				
END
GO
