USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewDeliveryProfitDetailsWHLS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [amb_ViewDeliveryProfitDetailsWHLS] 'BN','-1','-1','','04/15/2012','ENT','24178'
-- exec [amb_ViewDeliveryProfitDetailsWHLS] '-1','-1','-1','158','1900-01-01','WR1428','24503'
CREATE procedure [dbo].[amb_ViewDeliveryProfitDetailsWHLS]
(
	@ChainID varchar(10),
	@State varchar(10),
	@City varchar(10),
	@StoreNumber varchar(10),
	@Weekend varchar(25),
	@SupplierIdentifier varchar(10),
	@SupplierID varchar(10)
)

AS
BEGIN
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
Declare @DBType int --0 from old database,1 from new database, 2 from mixed
DECLARE @chain_migrated_date date
	
IF(@ChainID<>'-1')
BEGIN
	SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) FROM dbo.chains_migration WHERE   chainid = @ChainID;
	if(cast(@chain_migrated_date as date) > cast('01/01/1900' as date))
		begin
			if(cast(@WeekEnd as date) > cast('01/01/1900' as date))
				begin
					
					select @BillingControlDay=BillingControlDay 
					from dbo.BillingControl bc
					inner join dbo.chains c on c.chainid=bc.chainid
					where  c.chainidentifier=@ChainID 

					SET @TodayDayOfWeek = datepart(dw, (@WeekEnd))
					--get the last day of the previous week (last Sunday)
					SET @EndDate = DATEADD(dd, @BillingControlDay -(@TodayDayOfWeek ), @WeekEnd)
					--get the first day of the previous week (the Monday before last)
					SET @StartDate = DATEADD(dd,@BillingControlDay -((@TodayDayOfWeek)+6), @WeekEnd)

					if(cast(@WeekEnd as date) >= cast(@chain_migrated_date as date))
						Begin
							set @dbType=2
							if(cast(@StartDate as date) >= cast(@chain_migrated_date as date))
								set @newStartdate=@StartDate
							else
								set @newStartdate=DATEADD(dd,1,@chain_migrated_date)
							set @newEnddate=@EndDate
						END
					else if(cast(@WeekEnd as date) < cast(@chain_migrated_date as date))
							set @dbType=0
				END
			Else
				set @dbType=0
		END
	Else
		begin
			set @dbType=0
		end
	END
ELSE
	set @DBType=2
	
	

IF (@DBType=0 or  @DBType=2) 
Begin
	
	SET @sqlQueryLegacy='SELECT  distinct ('' Store #: '' + SL.StoreNumber + ''/n Location: '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,WL.WholesalerName, WL.WholesalerID,
						OnR.StoreID, SL.StoreNumber,SL.StoreName, 
						SL.Address, SL.City, SL.State, SL.ZipCode, OnR.Bipad, 
						P.AbbrvName AS Title, CostToStore4Wholesaler, CostToWholesaler, OnR.CostToStore, 
						OnR.SuggRetail, OnR.Mon, OnR.Tue, OnR.Wed, OnR.Thur, OnR.Fri, OnR.Sat, 
						OnR.Sun, OnR.MonR, OnR.TueR, OnR.WedR, OnR.ThurR, OnR.FriR, OnR.SatR, OnR.SunR, OnR.MonS, 
						OnR.TueS, OnR.WedS, OnR.ThurS, OnR.FriS, OnR.SatS, OnR.SunS, 
						[mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun] AS Draws,[monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]	
						AS Returns,[mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]AS Shortages, 
						[mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
						([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS NetSales, 
						([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
						([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*
						([CostToStore4Wholesaler]-[CostToWholesaler]) AS Profit

						FROM   ( [IC-HQSQL2].iControl.dbo.OnR OnR  INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad) INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON 
						OnR.StoreID = SL.StoreID INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist WL ON OnR.WholesalerID = 
						WL.WholesalerID'
	IF(@ChainID<>'-1')
			SET @sqlQueryLegacy += ' And OnR.ChainID=''' + @ChainID + ''''	
			
	IF(@StoreNumber<>'')		 
			SET @sqlQueryLegacy += ' AND SL.Storeid Like ''%'+@StoreNumber+'%''' 
					
	IF(@City<>'-1')      
			SET @sqlQueryLegacy += ' AND SL.City Like '''+@City+ ''' '
				
	IF(@State<>'-1')    
			SET @sqlQueryLegacy += ' AND SL.State Like '''+@State+''''			
					
	IF(cast( @Weekend as date) <> cast( '01/01/1900' as date))
			SET @sqlQueryLegacy +='  AND ((OnR.WeekEnding)= '''+ CONVERT(VARCHAR,+@WeekEnd,101) +''') '
	
	SET @sqlQueryLegacy +=' GROUP BY OnR.ChainID, OnR.WholesalerID, WL.WholesalerID,
							 WL.WholesalerName, OnR.StoreID,SL.StoreNumber, SL.StoreName,
							 SL.Address, SL.City, SL.State,SL.ZipCode, OnR.Bipad, 
							 P.AbbrvName,CostToStore4Wholesaler, CostToWholesaler, OnR.CostToStore, OnR.SuggRetail,
							 OnR.Mon, OnR.Tue,OnR.Wed, OnR.Thur, OnR.Fri, OnR.Sat, OnR.Sun, OnR.MonR, 
							 OnR.TueR, OnR.WedR, OnR.ThurR, OnR.FriR, OnR.SatR,	OnR.SunR, OnR.MonS,OnR.TueS, OnR.WedS, 
							 OnR.ThurS, OnR.FriS, OnR.SatS, OnR.SunS,
							[mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun],[monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR],
							[mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS],
							[mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]
							+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) ' 
							
	SET @sqlQueryLegacy += ' HAVING WL.WholesalerID=''' + @SupplierIdentifier + ''''			
	
End


IF (@DBType=1 or @DBType=2)
	BEGIN
		IF object_id('tempdb.dbo.##tempViewDeliveryProfitDetailsDraws') is not null		
	
		--Get the data in to tmp table for draws
				BEGIN
					drop table ##tempViewDeliveryProfitDetailsDraws;
				END
			
			SET @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempViewDeliveryProfitDetailsDraws
							from dbo.Storetransactions_forward st
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
							where TransactionTypeID in (29) 
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and st.supplierid=' + @SupplierID 
						
		IF(@ChainID<>'-1')					
			SET @strquery += ' and c.ChainIdentifier='''+@ChainID+''''
		
		IF(@City<>'-1')   
			SET @strquery += ' and a.City like '''+@City+''''	
		
		IF(@State<>'-1')    
			SET @strquery += ' and	a.State like '''+@State+''''
								
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
			
		SET @strquery='select distinct st.ChainID,st.SupplierID,
						s.storeid,
						st.ProductID,Qty,st.TransactionTypeID,
						datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
						into ##tempViewDeliveryProfitDetailsPOS						
						
						from dbo.Storetransactions st
						inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid 
						and tt.buckettype=1
						inner JOIN dbo.Chains c on st.ChainID=c.ChainID
						INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
						INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 										
						
						where 1=1
						and st.supplierid=' + @SupplierID + '
						and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
		
		IF(@ChainID<>'-1')					
			SET @strquery += ' and c.ChainIdentifier='''+@ChainID+''''							
		
		IF(@City<>'-1')   
			SET @strquery += ' and a.City like '''+@City+''''							   

		IF(@State<>'-1')    
			SET @strquery += ' and	a.State like '''+@State+''''
									
		IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery += ' and SaleDateTime >= ''' +  convert(varchar, +@newStartdate,101) +  ''''
			
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
					CAST(NULL as nvarchar(50)) as "supplieridentifier"
					
					into ##tempViewDeliveryProfitDetailsFinalData 
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
					
		SET @strquery='update f set 
					f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers
					where SupplierID=f.supplierid),
					f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores 
					where StoreID=f.StoreID),
					f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores 
					where StoreID=f.StoreID),			
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
					from ##tempViewDeliveryProfitDetailsFinalData f'
			
		EXEC(@strquery)
		
			--Return the Data
	   
	   SET @sqlQueryNew='select distinct (''Store #: '' + StoreNumber + ''/n Location: '' 
										+ storename + '', '' + address + '', '' + City + '', 
										'' + State + '', '' + zipcode ) as StoreInfo,WholeSalerName,SupplierIdentifier as WholesalerID,LegacySystemStoreIdentifier as storeid,
						StoreNumber,storename,address,City,State,zipcode,bipad,title,0 as CostToStore4Wholesaler,0 as CostToWholesaler,
						costtostore,suggretail,sum(mondaydraw) as Mon,sum(tuesdaydraw) as Tue,sum(wednesdaydraw) as Wed,
						sum(thursdaydraw) as Thur,sum(fridaydraw) as Fri,sum(saturdaydraw) as Sat,sum(sundaydraw) as Sun,
						sum(mondaydraw-mondayPOS) as MonR,sum(tuesdaydraw-tuesdayPOS) as TueR,sum(wednesdaydraw-wednesdayPOS) as WedR,
						sum(thursdaydraw-thursdayPOS) as ThurR,sum(fridaydraw-fridayPOS) as FriR,sum(saturdaydraw-saturdayPOS) as SatR,
						sum(sundaydraw-sundayPOS) as SunR,''0'' AS MonS,''0'' AS TueS, ''0'' AS WedS,''0'' AS ThurS, ''0'' AS FriS,
						''0'' AS SatS, ''0'' AS SunS,						
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS [Draws],
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+
						sundaydraw-(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS [Returns],
						0 AS [Shortages],Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
						sundayPOS) AS NetSales, Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+
						sundayPOS)*(suggretail-CostToStore)) AS Profit				

						FROM  ##tempViewDeliveryProfitDetailsFinalData
						
						GROUP BY LegacySystemStoreIdentifier,supplieridentifier,wholesalername,StoreID,
						productid,storename,StoreNumber,address,City,State,zipcode,wholesalername,bipad,
						title,costtostore,suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,
						fridaydraw,saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,
						fridayPOS,saturdayPOS,sundayPOS ;'		

	END
			
IF(@DBType=2)
	BEGIN							
		SET @sqlQueryFinal=@sqlQueryStoreLegacy+ ' union ' +@sqlQueryStoreNew			
		EXEC(@sqlQueryFinal)				
		SET @sqlQueryFinal=@sqlQueryLegacy+ ' union ' +@sqlQueryNew
		EXEC(@sqlQueryFinal)
	END
ELSE IF(@DBType=1)
	BEGIN
		EXEC(@sqlQueryStoreNew)
		EXEC(@sqlQueryNew)
	END
ELSE IF(@DBType=0)
	BEGIN
		EXEC (@sqlQueryStoreLegacy)
		EXEC(@sqlQueryLegacy)
	END				
END
GO
