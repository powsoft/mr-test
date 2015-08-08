USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_BestToWorstStoresRankPUB_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [amb_BestToWorstStoresRankPUB_Beta] 'DEFAULT','0','-1','-1','-1','-1','1900/01/01','1900/01/01'
CREATE procedure [dbo].[amb_BestToWorstStoresRankPUB_Beta]
(
@PublisherIdentifier varchar(10),
@PublisherId varchar(10),
@WholesalerId varchar(10),
@ChainID varchar(10),
@State varchar(40),
@Title varchar(40),
@StartDate varchar(20),
@EndDate varchar(20)
)

as 
BEGIN
	Declare @strquery varchar(8000)
	Declare @sqlQueryNew varchar(8000)
		
	  /* Get the data into tmp table for Draws */
	IF object_id('tempdb.dbo.##tempBestToWorstStoresRankPUB') is not null 
		 BEGIN
			DROP TABLE ##tempBestToWorstStoresRankPUB;
		 END
			
	SET @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
					st.ProductID,Qty,TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					into ##tempBestToWorstStoresRankPUB
					
					from DataTrue_Report.dbo.Storetransactions_forward st
					INNER JOIN DataTrue_Report.dbo.Brands B ON st.BrandID=B.BrandID
					INNER JOIN DataTrue_Report.dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
					INNER JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
					INNER JOIN DataTrue_Report.dbo.products p ON p.ProductID=st.ProductID
					INNER JOIN DataTrue_Report.dbo.Suppliers sup on st.Supplierid=sup.Supplierid
					INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
					INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
					WHERE TransactionTypeID in (29)	AND M.ManufacturerID = ' + @PublisherId
					
	IF(@WholesalerID<>'-1')					
		SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''			
				
	IF(@ChainID<>'-1')					
		SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
	
	IF(@State<>'-1')    
		SET @strquery = @strquery +' and a.State like '''+@State+''''
		
	IF(@Title<>'-1')   
		SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''	
							
	IF(CAST(@StartDate AS DATE ) <> CAST('1900-01-01' AS DATE))
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + CONVERT(varchar, +@StartDate,101) +  ''''

	IF(CAST(@EndDate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + CONVERT(varchar, +@EndDate,101) + '''' 

	EXEC(@strquery)	

/* Get the data into tmp table for POS */
	IF object_id('tempdb.dbo.##tempBestToWorstStoresRankPUBPOS') is not null
		BEGIN
			DROP TABLE ##tempBestToWorstStoresRankPUBPOS
		END	
			
   SET @strquery=' Select distinct st.ChainID,st.SupplierID,s.storeid,
					st.ProductID,Qty,st.TransactionTypeID,
					datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
					into ##tempBestToWorstStoresRankPUBPOS								
					
					from DataTrue_Report.dbo.Storetransactions st
					INNER JOIN DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
					INNER JOIN DataTrue_Report.dbo.Brands B ON st.BrandID=B.BrandID
					INNER JOIN DataTrue_Report.dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
					INNER JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
					INNER JOIN DataTrue_Report.dbo.products p ON p.ProductID=st.ProductID
					INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
					INNER JOIN DataTrue_Report.dbo.Suppliers sup on st.Supplierid=sup.Supplierid
					INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
					WHERE 1 = 1 AND M.ManufacturerID = ' + @PublisherId
				
	IF(@WholesalerID<>'-1')					
		 SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''	
		 					
	IF(@ChainID<>'-1')					
		 SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''														   

	IF(@State<>'-1')    
		 SET @strquery = @strquery +' and	a.State like '''+@State+''''
		 				
	IF(@Title<>'-1')   
		 SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''
									
	IF(CAST(@StartDate AS DATE ) <> CAST('1900-01-01' AS DATE))
		 SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + CONVERT(varchar, +@StartDate,101) +  ''''

	IF(CAST(@EndDate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
		 SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + CONVERT(varchar, +@EndDate,101) + ''''
	
	EXEC(@strquery)	 
						
--Get the final data into final tmp table

	 IF object_id('tempdb.dbo.##tempBestToWorstStoresRankPUBFinalData') is not null
		BEGIN
			DROP Table ##tempBestToWorstStoresRankPUBFinalData
		END	
				
	SET @strquery='Select distinct tmpdraws.*,
					tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
					WednesdayPOS,tmpPOS.ThursdayPOS,
					tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
					CAST(NULL as nvarchar(50)) as "StoreName",
					CAST(NULL as nvarchar(50)) as "State",
					CAST(NULL as nvarchar(50)) as "chainidentifier",
					CAST(NULL as nvarchar(225)) as "Title",
					CAST(NULL as MONEY) as "CostToStore",
					CAST(NULL as money) as "SuggRetail"
				
					into ##tempBestToWorstStoresRankPUBFinalData 
					from
					(select * FROM 
						(SELECT * from ##tempBestToWorstStoresRankPUB ) p
							pivot( sum(Qty) for  wDay in
							(MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
					join
					( select * from 
						(SELECT * from ##tempBestToWorstStoresRankPUBPOS)p
						pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
						WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
						) as p1
					) tmpPOS 
					on tmpdraws.chainid=tmpPOS.chainid
					and tmpdraws.supplierid=tmpPOS.supplierid
					and tmpdraws.storeid=tmpPOS.storeid
					and tmpdraws.productid=tmpPOS.productid'
    
	EXEC(@strquery)	
	
	/*----UPDATE THE TEMP TABLE----- */
	 SET @strquery='update f set	
				f.StoreName=(select distinct StoreName from dbo.Stores where StoreID=f.StoreID),		
				f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid),
				f.title=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),
				f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
				AND SupplierID=f.supplierid and ProductPriceTypeID=3),
				f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
				AND SupplierID=f.supplierid and ProductPriceTypeID=3)
				
				from ##tempBestToWorstStoresRankPUBFinalData f'
	
		EXEC(@strquery)
		 
	    SET @sqlQueryNew='select chainidentifier as ChainID, 
						State,
						StoreName,
						title as TitleName,
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS Draws,
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS Returns,
						0 AS Shortages,
						Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) AS NetSales,
						Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0))) AS Profit,
						Sum(ISNULL(mondayPOS,0)) as MonResults,
						Sum(ISNULL(tuesdayPOS,0)) as TueResults,
						Sum(ISNULL(wednesdayPOS,0)) as WedResults,
						Sum(ISNULL(thursdayPOS,0)) as ThurResults,
						Sum(ISNULL(fridayPOS,0)) as FriResults,
						Sum(ISNULL(saturdayPOS,0)) as SatResults,
						Sum(ISNULL(sundayPOS,0)) as SunResults,
						CASE
							WHEN SUM(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))>0
								THEN
									CASE
										WHEN SUM(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) >0
											THEN 
												cast(cast(SUM(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) as decimal)
												/cast(SUM(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) as decimal) as decimal (18,4))
										ELSE cast(0  as decimal (18,4))
									END
							ELSE cast(0  as decimal (18,4))
						END AS salesRatio
						
						From  ##tempBestToWorstStoresRankPUBFinalData
						GROUP BY chainidentifier,title,StoreName,State,suggretail,CostToStore 
						ORDER BY State,StoreName,title '	

	EXEC(@sqlQueryNew) 

END
GO
