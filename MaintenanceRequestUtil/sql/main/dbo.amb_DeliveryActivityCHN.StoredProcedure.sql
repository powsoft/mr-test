USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DeliveryActivityCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dbo.chains_migration where chainid=40393
--Exec amb_DeliveryActivityCHN 'SV','40393','CA','Valencia','','1900/01/01'
--Exec amb_DeliveryActivityCHN '42493','BN','%','%','','1900/01/01'
--Exec amb_DeliveryActivityCHN 'KNG','42501','-1','-1','','11/11/2012'
CREATE procedure [dbo].[amb_DeliveryActivityCHN]
(
@ChainIdentifier varchar(10),
@ChainID varchar(10),
@State varchar(10),
@City varchar(20),
@StoreNumber varchar(20),
@WeekEnd varchar(20) 
)
as 
BEGIN

	declare @sqlQueryFinal varchar(8000)	
	Declare @sqlQueryStoreNew varchar(8000)
	Declare @sqlQueryLegacy varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @oldStartdate varchar(8000)
	Declare @oldenddate varchar(8000)
	Declare @newStartdate varchar(8000)
	Declare @newenddate varchar(8000)
	Declare @dbType int --0 from Old,1 from New, 2 from mixed
	DECLARE @chain_migrated_date date

SELECT @chain_migrated_date = cast(datemigrated AS VARCHAR)
FROM
	dbo.chains_migration
WHERE
	chainid = @ChainIdentifier;

	if(cast(@chain_migrated_date as date) > cast('01/01/1900' as date))
		begin
			if(cast(@WeekEnd as date) > cast('01/01/1900' as date))
				begin
					DECLARE @BillingControlDay INT
SELECT @BillingControlDay = BillingControlDay
FROM
	dbo.BillingControl bc
	INNER JOIN dbo.chains c
		ON c.chainid = bc.chainid
WHERE
	c.chainidentifier = @ChainID 

					DECLARE @TodayDayOfWeek INT
					DECLARE @EndDate DateTime=null
					DECLARE @StartDate DateTime=null
SET @TodayDayOfWeek = datepart (dw, (@WeekEnd))
--get the last day of the previous week (last Sunday)
SET @EndDate = dateadd(dd, @BillingControlDay - (@TodayDayOfWeek), @WeekEnd)
--get the first day of the previous week (the Monday before last)
SET @StartDate = dateadd(dd, @BillingControlDay - ((@TodayDayOfWeek) + 6), @WeekEnd)

					if(cast(@WeekEnd as date) >= cast(@chain_migrated_date as date))
						Begin
SET @dbType = 2
							if(cast(@StartDate as date) >= cast(@chain_migrated_date as date))
SET @newStartdate = @StartDate
							else SET @newStartdate = dateadd(dd, 1, @chain_migrated_date)
SET @newEnddate = @EndDate
						END
					else if(cast(@WeekEnd as date) < cast(@chain_migrated_date as date)) SET @dbType = 0
				END
			Else SET @dbType = 0
		END
	Else
		begin
SET @dbType = 0
SET @oldStartdate = @StartDate
SET @oldenddate = @EndDate
		end
		
	IF (@dbType=0 or  @dbType=2) 
		BEGIN
SET @sqlQueryLegacy = 'SELECT distinct 
		('' Store #: '' + SL.StoreNumber + ''/n Location: '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,WL.WholesalerName, OnR.StoreID,OnR.Bipad, P.AbbrvName AS TitleName,SL.StoreNumber,
								SL.StoreName, SL.Address,SL.City, SL.State,SL.ZipCode,
								OnR.CostToStore, OnR.SuggRetail, 
								OnR.Mon,OnR.Tue, OnR.Wed, OnR.Thur, OnR.Fri, OnR.Sat, OnR.Sun, 
								OnR.MonR, OnR.TueR, OnR.WedR, OnR.ThurR, OnR.FriR, OnR.SatR, OnR.SunR, 
								OnR.MonS,OnR.TueS, OnR.WedS, OnR.ThurS, OnR.FriS, OnR.SatS, OnR.SunS, 
								[mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun] AS Draws, 
								[monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR] AS Returns,
								[mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS] AS Shortages,
								[mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
								([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS NetSales, 
								([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
								([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([SuggRetail]-[CostToStore]) AS Profit

								FROM   [IC-HQSQL2].iControl.dbo.OnR OnR  
								INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
								INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID
								INNER JOIN  [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID'
SET @sqlQueryLegacy = @sqlQueryLegacy + ' Where 1=1 AND OnR.ChainID=''' + @ChainIdentifier + ''' AND 
			SL.StoreNumber like ''%' + @StoreNumber + '%''' 
			if(@State<>'-1')
SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND SL.State like ''' + @State + '''' 
			if(@City<>'-1')
SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND SL.City like ''' + @City + '''' 
			if(cast(@WeekEnd as date)<>cast('1900/01/01' as date))
SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND OnR.WeekEnding = ''' + @WeekEnd + '''' 
		end
		
	IF (@dbType=1 or  @dbType=2) 
		BEGIN
			if object_id('tempdb.dbo.##tempDeliveryActivityCHN') is not null
DROP TABLE ##tempDeliveryActivityCHN;
			
			declare @strquery varchar(8000)
SET @strquery = 'select distinct st.ChainID,st.SupplierID,st.storeid,st.ProductID,Qty,
										TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' as "wDay" 
										into ##tempDeliveryActivityCHN

										from dbo.Storetransactions_forward st
										INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
										INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

										where TransactionTypeID in (29)
										and st.ChainId=''' + @ChainID + '''
										and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
			if(@City<>'-1')
SET @strquery = @strquery + ' and a.City like ''' + @City + ''''							   

			if(@State<>'-1')
SET @strquery = @strquery + ' and	a.State like ''' + @State + ''''

			if(CAST(@newStartdate as DATE) > CAST('1900-01-01' as DATE))
SET @strquery = @strquery + ' and SaleDateTime >= ''' + convert(VARCHAR, +@newStartdate, 101) + ''''
			if(CAST(@newEnddate as DATE) > CAST('1900-01-01' as DATE))
SET @strquery = @strquery + ' AND SaleDateTime <= ''' + convert(VARCHAR, +@newEnddate, 101) + ''''
EXEC (@strquery)

			--Get the data into tmp table for POS	

			if object_id('tempdb.dbo.##tempDeliveryActivityPOSCHN') is not null
DROP TABLE ##tempDeliveryActivityPOSCHN;
SET @strquery = 'select distinct st.ChainID,st.SupplierID,st.storeid,st.ProductID,Qty,
										st.TransactionTypeID,datename(W,SaleDateTime)+ ''POS'' as "POSDay"
										into ##tempDeliveryActivityPOSCHN

										from dbo.Storetransactions st
										inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
										INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
										INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

										where st.ChainId=''' + @ChainID + '''
										and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''

			if(@City<>'-1')
SET @strquery = @strquery + ' and a.City like ''' + @City + ''''							   

			if(@State<>'-1')
SET @strquery = @strquery + ' and	a.State like ''' + @State + ''''

			if(CAST(@newStartdate as DATE ) > CAST('1900-01-01' as DATE))
SET @strquery = @strquery + ' and SaleDateTime >= ''' + convert(VARCHAR, +@newStartdate, 101) + ''''
			if(CAST(@newEnddate as DATE ) > CAST('1900-01-01' as DATE))
SET @strquery = @strquery + ' AND SaleDateTime <= ''' + convert(VARCHAR, +@newEnddate, 101) + ''''
EXEC (@strquery)			

			--Get the final data into final tmp table

			if object_id('tempdb.dbo.##tempDeliveryActivityCHNFinalData') is not null
DROP TABLE ##tempDeliveryActivityCHNFinalData
SET @strquery = 'Select distinct tmpdraws.*,
						tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
						tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
						CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",
						CAST(NULL as nvarchar(50)) as "StoreName",
						CAST(NULL as nvarchar(50)) as "StoreNumber",
						CAST(NULL as nvarchar(100)) as "Address",
						CAST(NULL as nvarchar(50)) as "City",
						CAST(NULL as nvarchar(50)) as "State",
						CAST(NULL as nvarchar(50)) as "ZipCode",
						CAST(NULL as nvarchar(50)) as "WholesalerName",
						CAST(NULL as nvarchar(50)) as "BiPad",
						CAST(NULL as nvarchar(225)) as "TitleName",
						CAST(NULL as MONEY) as "CostToStore",
						CAST(NULL as money) as "SuggRetail"
						into ##tempDeliveryActivityCHNFinalData
						from
						(select * FROM 
						(SELECT * from ##tempDeliveryActivityCHN ) p
						pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
						(SELECT * from ##tempDeliveryActivityPOSCHN)p
						pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
						) as p1
						) tmpPOS 
						on tmpdraws.chainid=tmpPOS.chainid and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid and tmpdraws.productid=tmpPOS.productid'
EXEC (@strquery)


--Update the required fields
SET @strquery = 'update f set 
					f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
					f.StoreName=(select distinct StoreName from dbo.Stores  where StoreID=f.StoreID),
					f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
					f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers where SupplierID=f.supplierid),
					f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=f.productid),
					f.TitleName=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),
					f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
					and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
					f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
					and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3)
					from ##tempDeliveryActivityCHNFinalData f'
EXEC (@strquery)
SET @sqlQueryStoreNew = '	select distinct 
(''Store #: '' + StoreNumber + ''/n Location: '' 
										+ storename + '', '' + address + '', '' + City + '', 
										'' + State + '', '' + zipcode ) as StoreInfo,LegacySystemStoreIdentifier as StoreID,storename,
										StoreNumber,address,City,State,zipcode 
															from ##tempDeliveryActivityCHNFinalData';
SET @sqlQueryNew = ' select distinct wholesalername,LegacySystemStoreIdentifier as StoreID,bipad,TitleName,
			storename,StoreNumber,address,City,State,zipcode,costtostore,suggretail,
					mondaydraw as Mon,Tuesdaydraw as Tue,wednesdaydraw as Wed,thursdaydraw as Thur,fridaydraw as Fri,saturdaydraw as Sat,sundaydraw as Sun,
					mondaydraw-mondayPOS as MonR,tuesdaydraw-tuesdayPOS as TueR,wednesdaydraw-wednesdayPOS as WedR,thursdaydraw-thursdayPOS as ThurR,
					fridaydraw-fridayPOS as FriR,saturdaydraw-saturdayPOS as SatR,sundaydraw-sundayPOS as SunR,
					''0'' AS MonS,''0'' AS TueS, ''0'' AS WedS,''0'' AS ThurS, ''0'' AS FriS,''0'' AS SatS, ''0'' AS SunS,
					mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw AS Draws,
					mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS Returns,0 AS Shortages,
					(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS NetSales, 
					(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)*(suggretail-CostToStore) AS Profit
					
					from ##tempDeliveryActivityCHNFinalData';
		end
	
	if(@dbType=2)
		begin
SET @sqlQueryFinal = @sqlQueryLegacy + ' union ' + @sqlQueryNew + ' Order By StoreID,storename,wholesalername,bipad,TitleName'
EXEC (@sqlQueryFinal)
		end
	else IF(@dbType=1)
		begin
EXEC (@sqlQueryNew + ' Order By wholesalername,bipad,TitleName,StoreID,storename')		
		end
	else IF(@dbType=0)
		begin
EXEC (@sqlQueryLegacy + ' Order By wholesalername,bipad,TitleName,StoreID,storename')	
		end	
	
end
GO
