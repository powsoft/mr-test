USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewDeliveryProfitSummaryPUB_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [amb_ViewDeliveryProfitSummaryPUB_Beta] 'DOWJ','35321','-1','-1','-1','1900-01-01','','','StoreName ASC',1,25,0
-- EXEC [amb_ViewDeliveryProfitSummaryPUB_Beta] 'Default','0','BN','-1','-1','01/01/1900','','-1','StoreName ASC',1,25,0

CREATE procedure [dbo].[amb_ViewDeliveryProfitSummaryPUB_Beta]
(
   @PublisherIdentifier varchar(20),
	@PublisherID varchar(20),
	@ChainID varchar(20),
	@State varchar(20),
	@City varchar(30),
	@WeekEnd varchar(20),
	@Store varchar(20),
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
Declare @sqlQueryOld varchar(8000)
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

/* (STEP 1)--------- GET DATA FROM THE OLD DATABASE (iControl)---------*/
IF (@DBType=0 or @DBType=2) 
	BEGIN
		SET @sqlQueryOld= ' SELECT  WL.WholesalerName, OnR.StoreID, SL.StoreNumber,SL.StoreName, 
							SL.Address, SL.City, SL.State,SL.ZipCode, Convert(varchar,OnR.WeekEnding,101) as WeekEnding,
							Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]) AS Draws,
							Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS Returns,
							Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS Shortages,
							Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
							([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))AS NetSales,
							Sum(([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
							([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([CostToStore4Wholesaler]-[CostToWholesaler])) AS Profit,
							CASE 
									WHEN  Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
									([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))>0  
										THEN  
											Case 
												WHEN Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun])>0 

												THEN Cast(cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
												([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) as decimal) 
												/cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]) as decimal) as Decimal(18,4))

												else cast(0 as decimal(18,4))
											END
									else  cast(0 as decimal (18,4))
								END  as salesRatio  

							 FROM   [IC-HQSQL\ICONTROL].iControl.dbo.OnR OnR  INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.Products P ON OnR.Bipad = P.Bipad 
							 INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
							 INNER JOIN  [IC-HQSQL\ICONTROL].iControl.dbo.Wholesalerslist WL ON OnR.WholesalerID = WL.WholesalerID Where 1 =1'						 
							 
	IF(@Store<>'')
		    SET @sqlQueryOld += ' AND SL.Storeid Like ''%'+ @Store +'%'' '
		      
		IF(@ChainID<>'-1')
			SET @sqlQueryOld += ' AND OnR.ChainID = '''+ @ChainID + ''' ' 
		     
		IF(@City<>'-1')
			SET @sqlQueryOld += '  AND SL.City = ''' + @City +''' '	
		    
		IF(@State<>'-1')
			SET @sqlQueryOld += '  AND SL.State= '''+ @State +''' '
		  
  	    IF(cast( @Weekend as date) <> cast( '01/01/1900' as date))
			SET @sqlQueryOld +='  AND OnR.WeekEnding= '''+ CONVERT(VARCHAR,+@WeekEnd,101) +''' '
		  
		IF(@WholesalerID<>'-1')
		    SET @sqlQueryOld += '  AND OnR.WholesalerID= '''+ @WholesalerID +'''' 

			SET @sqlQueryOld += ' GROUP BY OnR.ChainID, OnR.WholesalerID, WL.WholesalerName, OnR.StoreID,SL.StoreNumber, 
							 SL.StoreName, SL.Address,SL.City, SL.State, SL.ZipCode, 
							 OnR.WeekEnding,OnR.ChainID,P.PublisherID ' 
		                           
		SET @sqlQueryOld += ' HAVING  P.PublisherID='''+@PublisherIdentifier+''' '

	 
	END


/* (STEP 2)--------- GET DATA FROM THE NEW DATABASE (DataTrue_Main)---------*/
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
							INNER JOIN dbo.Suppliers Sup ON Sup.SupplierID=ST.SupplierID
							INNER JOIN dbo.Chains C ON ST.ChainID=C.ChainID
							INNER JOIN dbo.Stores S ON S.StoreID=ST.StoreID
							INNER JOIN dbo.Addresses A ON A.OwnerEntityID=ST.StoreID
							
							where TransactionTypeID in (29) and S.LegacySystemStoreIdentifier like ''%'+@Store+'%'' 
							and  M.ManufacturerId=' + @PublisherID 
						
		IF(@ChainID<>'-1')					
			SET @strquery += ' AND C.ChainIdentifier='''+@ChainID+''''	
		
		IF(@Store<>'')
		    SET @strquery += ' AND S.LegacySystemStoreIdentifier like ''%'+@Store+'%'''
		    						
		IF(@WholesalerID<>'-1')
			SET @strquery += ' AND Sup.SupplierIdentifier='''+@WholesalerID+''' ' 
			
		IF(@State<>'-1')
			SET @strquery += '  AND A.State= '''+ @State +''' '
				     
		IF(@City<>'-1')
			SET @strquery += '  AND A.City = ''' + @City +''' '	
					
		IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery += ' AND SaleDateTime >= ''' +  convert(varchar, +@newStartdate,101) +  ''''
			
		IF(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
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
						INNER JOIN dbo.Suppliers Sup ON Sup.SupplierID=ST.SupplierID
						INNER JOIN dbo.Chains C ON ST.ChainID=C.ChainID
						INNER JOIN dbo.Stores S ON S.StoreID=ST.StoreID
						INNER JOIN dbo.Addresses A ON A.OwnerEntityID=ST.StoreID 										
						
						Where 1=1 and  M.ManufacturerId =' + @PublisherID
		
		IF(@ChainID<>'-1')					
			SET @strquery += ' AND C.ChainIdentifier='''+@ChainID+''''	
		
		IF(@Store<>'')
		    SET @strquery += ' AND S.LegacySystemStoreIdentifier like ''%'+@Store+'%'''
		    						
		IF(@WholesalerID<>'-1')
			SET @strquery += ' AND Sup.SupplierIdentifier='''+@WholesalerID+''' ' 
			
		IF(@State<>'-1')
			SET @strquery += '  AND A.State= '''+ @State +''' '
				     
		IF(@City<>'-1')
			SET @strquery += '  AND A.City = ''' + @City +''' '	
					
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
					CAST(NULL as MONEY) as "CostToStore",
					CAST(NULL as MONEY) as "SuggRetail",
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
							
							F.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=F.productid 
							AND ChainID=f.chainid and StoreID=F.storeid AND SupplierID=F.supplierid and ProductPriceTypeID=3),
							
							F.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid 
							AND ChainID=F.chainid and StoreID=F.storeid AND SupplierID=F.supplierid and ProductPriceTypeID=3),
							
							F.WeekEnding=(select distinct top 1 Saledatetime from dbo.Storetransactions_forward 
							where supplierid=F.supplierid and ChainId=f.ChainId and StoreID=F.StoreID 
							and ProductId=F.ProductId and TransactionTypeID in (29))
							
							FROM ##tempViewDeliveryProfitDetailsFinalData F '
			
		EXEC(@strquery)
		
			--Return the Data
		
	   SET @sqlQueryNew='SELECT  WholeSalerName,LegacySystemStoreIdentifier as StoreId,StoreNumber,
						StoreName,Address,City,State,ZipCode,Convert(Varchar,Convert(datetime,WeekEnding),101) as WeekEnding,
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS [Draws],
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+
						sundaydraw-(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS [Returns],
						0 AS [Shortages],
						Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS NetSales, 
						Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
						sundayPOS)*(suggretail-CostToStore)) AS Profit,
						CASE
							WHEN SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)>0
								THEN
									CASE
										WHEN SUM(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) >0
											THEN 
												Cast(cast(SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) as decimal)
												/cast(SUM(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) as decimal) as decimal(18,4))
										ELSE cast(0  as decimal(18,4))
									END
							ELSE cast(0  as decimal(18,4))
						END AS salesRatio				

						FROM  ##tempViewDeliveryProfitDetailsFinalData

						GROUP BY WholeSalerName,LegacySystemStoreIdentifier,StoreNumber,StoreName,Address,City,State,ZipCode,WeekEnding '		

	END
	
/* (STEP 3)--------- Exec Final Query ---------*/			
	IF(@DBType=2)
		BEGIN	
			SET @sqlQueryFinal=' SELECT DISTINCT * FROM  ( '+ @sqlQueryOld + ' union ' + @sqlQueryNew	+' )as temp '											
			set @sqlQueryFinal = [dbo].GetPagingQuery_New(@sqlQueryFinal, @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
			EXEC(@sqlQueryFinal)
		
		END
	ELSE IF(@DBType=1)
		BEGIN
			set @sqlQueryNew = [dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  (  '+@sqlQueryNew+'	) as temp ', @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
			EXEC(@sqlQueryNew)
		END
	ELSE IF(@DBType=0)
		BEGIN
			set @sqlQueryOld = [dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  (  '+@sqlQueryOld+'	) as temp ', @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
			EXEC(@sqlQueryOld)
		END

END
GO
