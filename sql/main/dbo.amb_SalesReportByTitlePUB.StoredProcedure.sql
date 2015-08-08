USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_SalesReportByTitlePUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_SalesReportByTitlePUB] 'DOWJ','35321','STC','BN','-1','-1','1900-01-01','1900-01-01'
--exec [amb_SalesReportByTitlePUB] 'DOWJ','35321','-1','-1','-1','-1','1900-01-01','1900-01-01'
--exec [amb_Sales

CREATE procedure [dbo].[amb_SalesReportByTitlePUB]
(
@PublisherIdentifier varchar(20),
@PublisherID varchar(20),
@WholesalerId varchar(10),
@ChainID varchar(10),
@State varchar(10),
@Title varchar(20),
@StartDate varchar(20),
@EndDate varchar(20) 
)

as 
BEGIN
DECLARE @sqlQueryFinal varchar(8000)
DECLARE @sqlQueryStoreLegacy varchar(8000)
DECLARE @sqlQueryStoreNew varchar(8000)
DECLARE @sqlQueryLegacy varchar(8000)
DECLARE @strquery varchar(8000)
DECLARE @sqlQueryNew varchar(8000)
DECLARE @oldStartdate varchar(8000)
DECLARE @oldenddate varchar(8000)
DECLARE @newStartdate varchar(8000)
DECLARE @newenddate varchar(8000)
DECLARE @allnew int --0 for old database,1 from new database, 2 from mixed
DECLARE @chain_migrated_date date



IF(@ChainID<>'-1')
BEGIN
	SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) 
	FROM  dbo.chains_migration 
	WHERE chainid = @ChainID;
	
	IF(CAST(@chain_migrated_date AS DATE) > CAST('01/01/1900' AS DATE))
		BEGIN
			IF(CAST(@StartDate AS DATE)  >= CAST(@chain_migrated_date AS DATE))
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
				End

			ELSE IF(CAST(@EndDate AS DATE)>= CAST(@chain_migrated_date AS DATE)  
				    and CAST(@StartDate AS DATE) <= CAST(@chain_migrated_date AS DATE))
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
IF (@allnew=0 or  @allnew=2) 
     BEGIN	
		SET @sqlQueryLegacy='SELECT P.AbbrvName as TitleName, OnR.ChainID,OnR.CostToStore,OnR.SuggRetail, Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun])
							 AS Draws,Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS Returns, 
							Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS Shortages,
							Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]
							+[fris]+[SatS]+[SunS])) AS NetSales,Sum(([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+
							[SatR]+[SunR])-([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))*([CostToStore4Wholesaler]-[CostToWholesaler])) AS Profit,
							
							CASE 
									WHEN  Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
											([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))>0  
									THEN  
										Case 
											WHEN Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun])>0	
													
											THEN cast(cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
											([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) as decimal) /
											cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun])as decimal)as decimal (18,4))
											
											else cast(0 as decimal (18,4))
										END
									else  cast(0 as decimal (18,4))
							END  as salesRatio

						 FROM [IC-HQSQL2].iControl.dbo.OnR Onr
						 INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad
						
						 INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID   
						 WHERE P.PublisherID='''+ @PublisherIdentifier +''' '
							
		 IF(CAST(@oldStartdate AS DATE) <> CAST('1900-01-01' AS DATE) ) 
				 SET @sqlQueryLegacy = @sqlQueryLegacy +' and OnR.WeekEnding >= ''' + convert(varchar, +@oldStartdate,101) +  ''''
		
		 IF(CAST(@oldenddate AS DATE) <> CAST('1900-01-01' AS DATE) ) 
			    SET @sqlQueryLegacy = @sqlQueryLegacy +' AND OnR.WeekEnding <= ''' + convert(varchar, +@oldenddate,101) + ''''				 
				 
		 IF(@WholesalerId<>'-1')
				SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND OnR.WholesalerID like '''+@WholesalerId+'%'''
				
		 IF(@Title<>'-1')
			    SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND P.TitleName like '''+@Title+'%'''
			    
		IF(@ChainID<>'-1')
			   SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND OnR.ChainID = '''+@ChainID+''''
			   
		IF(@State<>'-1')
			   SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.State = '''+@State+'''' 
		       
		SET @sqlQueryLegacy= @sqlQueryLegacy+ ' GROUP BY  OnR.ChainID,P.AbbrvName,OnR.CostToStore,OnR.SuggRetail  ' 
		--SET @sqlQueryLegacy= @sqlQueryLegacy+ ' ORDER BY OnR.ChainID '
	END	


/* -----(STEP 2) GET DATA FROM THE NEW DATABASE (DataTrue_Main)----- */
IF (@allnew=1 or  @allnew=2) 
	BEGIN
	
     /*-------Get the data into tmp table for Draws---------*/	
	IF object_id('tempdb.dbo.##SalesReportByTitle') is not null
		BEGIN
			DROP TABLE ##SalesReportByTitle;
		END
	
	SET @strquery='SELECT distinct st.ChainID,st.SupplierID,s.storeid,st.ProductID,P.ProductName,C.ChainIdentifier,Qty,TransactionTypeID,
					datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					into ##SalesReportByTitle
					
					FROM dbo.Storetransactions_forward St
					INNER JOIN dbo.Brands B ON St.BrandID=B.BrandID
					INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
					INNER JOIN dbo.Chains C ON C.ChainID=St.ChainID
					INNER JOIN dbo.Suppliers SUP ON SUP.SupplierID=St.SupplierID
					INNER JOIN dbo.Stores s ON s.StoreID=St.StoreID
					INNER JOIN dbo.Addresses A ON A.OwnerEntityID=St.StoreID
					INNER JOIN dbo.Products P ON P.ProductID=St.ProductID
					INNER JOIN dbo.ProductPrices PP ON PP.ProductID=P.ProductID
					WHERE 1=1  AND TransactionTypeID in (29)	
					AND C.ChainIdentifier in (Select chainid from chains_migration) 
					AND M.ManufacturerId=' + @PublisherId 
					
	IF(@WholesalerId<>'-1')
				SET @strquery= @strquery+ ' AND SUP.SupplierIdentifier like '''+@WholesalerId+'%'''
				
    IF(@Title<>'-1')
			    SET @strquery= @strquery+ ' AND P.ProductName like '''+@Title+'%'''
			    
	IF(@ChainID<>'-1')
			   SET @strquery= @strquery+ ' AND C.ChainIdentifier  = '''+@ChainID+''''
			   
	IF(@State<>'-1')
			   SET @strquery= @strquery+ ' AND A.State = '''+@State+''''	
			   
	IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
			
	IF(CAST(@newEnddate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''	   			
	PRINT(@strquery)				
	EXEC(@strquery)
	
		
		/*-------Get the data into tmp table for POS---------*/					
		IF object_id('tempdb.dbo.##SalesReportByTitlePOS') is not null
		BEGIN
		   DROP TABLE ##SalesReportByTitlePOS;
		END
		
		SET @strquery='SELECT distinct st.ChainID,st.SupplierID,st.ProductID,s.storeid,P.ProductName,C.ChainIdentifier,Qty,st.TransactionTypeID,
						datename(W,SaleDateTime)+ ''POS'' as "POSDay"		
					   into ##SalesReportByTitlePOS
					   FROM dbo.Storetransactions St
					   inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
					   INNER JOIN dbo.Brands B ON St.BrandID=B.BrandID
					   INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
					   INNER JOIN dbo.Chains C ON C.ChainID=St.ChainID
					   INNER JOIN dbo.Suppliers SUP ON SUP.SupplierID=St.SupplierID
					   INNER JOIN dbo.Stores s ON s.StoreID=St.StoreID
					   INNER JOIN dbo.Addresses A ON A.OwnerEntityID=St.StoreID
					   INNER JOIN dbo.Products P ON P.ProductID=St.ProductID
					   INNER JOIN dbo.ProductPrices PP ON PP.ProductID=P.ProductID
					   WHERE 1=1 AND C.ChainIdentifier in (Select chainid from chains_migration) 
					   AND M.ManufacturerId=' + @PublisherId 
					
	IF(@WholesalerId<>'-1')
				SET @strquery= @strquery+ ' AND SUP.SupplierIdentifier like '''+@WholesalerId+'%'''
				
    IF(@Title<>'-1')
			    SET @strquery= @strquery+ ' AND P.ProductName like '''+@Title+'%'''
			    
	IF(@ChainID<>'-1')
			   SET @strquery= @strquery+ ' AND C.ChainIdentifier  = '''+@ChainID+''''
			   
	IF(@State<>'-1')
			   SET @strquery= @strquery+ ' AND A.State = '''+@State+''''	
			   
	IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
			
	IF(CAST(@newEnddate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
	
	PRINT(@strquery)				
	EXEC(@strquery)
	
		
		/*----Get the final data into final tmp table(Draws and POS)----*/		
		IF object_id('tempdb.dbo.##SalesReportByTitleFinalData') is not null
			BEGIN
				DROP TABLE ##SalesReportByTitleFinalData
			END
		SET @strquery='Select distinct tmpdraws.*,
						tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
						WednesdayPOS,tmpPOS.ThursdayPOS,
						tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,					
						CAST(NULL as MONEY) as "CostToStore",
						CAST(NULL as money) as "SuggRetail"
						into ##SalesReportByTitleFinalData 
						from
						(select * FROM 
							(SELECT * from ##SalesReportByTitle ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
							(SELECT * from ##SalesReportByTitlePOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
							 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						on tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'
						
		PRINT(@strquery)				
		EXEC(@strquery)
		
		--Update the required fields
			SET @strquery='update f set			
			f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
			where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
			AND SupplierID=f.supplierid and ProductPriceTypeID=3),
			f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices 
			where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
			AND SupplierID=f.supplierid and ProductPriceTypeID=3)
			
			From ##SalesReportByTitleFinalData f'
			PRINT(@strquery)
			EXEC(@strquery)
			
	 SET @sqlQueryNew=' select distinct chainidentifier as chainid,ProductName as Title,suggretail,CostToStore,
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS Draws,
						Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-
						(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS Returns,
						0 AS Shortages,
						Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS NetSales,
						Sum((mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)*
						(suggretail-CostToStore)) AS Profit,
						CASE
							WHEN SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)>0
							
							THEN
								CASE
									WHEN SUM(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) >0
									  THEN 
										CAST(CAST(SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) as Decimal)/CAST(SUM												(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw)as Decimal)as decimal (18,4))
									ELSE cast(0  as decimal (18,4))
								END
							ELSE cast(0  as decimal (18,4))
						END AS salesRatio			
						
						FROM ##SalesReportByTitleFinalData 
						GROUP BY chainidentifier,ProductName,suggretail,CostToStore'
	End
		
/*----(STEP 3) FINAL QUERY EXEC--------*/		
	IF(@allnew=2)
		BEGIN
			SET @sqlQueryFinal=@sqlQueryLegacy + ' UNION ' + @sqlQueryNew + ' order by Chainid '
			PRINT(@sqlQueryLegacy + ' UNION ' + @sqlQueryNew)
			EXEC(@sqlQueryFinal)
		END
	ELSE IF(@allnew=1)
		BEGIN
			PRINT(@sqlQueryNew)
			EXEC(@sqlQueryNew + ' order by Chainid ')
		END
	ELSE IF(@allnew=0)
		BEGIN
			PRINT(@sqlQueryLegacy)
			EXEC(@sqlQueryLegacy + ' order by Chainid ')
		END
END
GO
