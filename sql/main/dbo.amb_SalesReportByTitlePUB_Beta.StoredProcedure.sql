USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_SalesReportByTitlePUB_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_SalesReportByTitlePUB_Beta] 'DOWJ','35321','STC','BN','-1','-1','1900-01-01','1900-01-01','ChainID ASC','1','25',0
--exec [amb_SalesReportByTitlePUB_Beta] 'DOWJ','35321','-1','-1','-1','-1','1900-01-01','1900-01-01','ChainID ASC','1','25',0


CREATE procedure [dbo].[amb_SalesReportByTitlePUB_Beta]
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
	DECLARE @strquery varchar(8000)
	DECLARE @sqlQueryNew varchar(8000)

     /*-------Get the data into tmp table for Draws---------*/	
	IF object_id('tempdb.dbo.##SalesReportByTitle') is not null
		BEGIN
			DROP TABLE ##SalesReportByTitle;
		END
	
	SET @strquery='SELECT distinct st.ChainID,
								   st.SupplierID,
								   s.storeid,
								   st.ProductID,
								   P.ProductName,
								   C.ChainIdentifier,
								   Qty,TransactionTypeID,
								   datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					
					INTO ##SalesReportByTitle
					
					FROM DataTrue_Report.dbo.Storetransactions_forward St
							INNER JOIN DataTrue_Report.dbo.Brands B ON St.BrandID=B.BrandID
							INNER JOIN DataTrue_Report.dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN DataTrue_Report.dbo.Chains C ON C.ChainID=St.ChainID
							INNER JOIN DataTrue_Report.dbo.Suppliers SUP ON SUP.SupplierID=St.SupplierID
							INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=St.StoreID
							INNER JOIN DataTrue_Report.dbo.Addresses A ON A.OwnerEntityID=St.StoreID
							INNER JOIN DataTrue_Report.dbo.Products P ON P.ProductID=St.ProductID
							INNER JOIN DataTrue_Report.dbo.ProductPrices PP ON PP.ProductID=P.ProductID
							
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
			   
	IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  >= ''' + convert(varchar, +@StartDate,101) +  ''''
			
	IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  <= ''' + convert(varchar, +@EndDate,101) + ''''	   			

	EXEC(@strquery)
	
		
	/*-------Get the data into tmp table for POS---------*/					
	IF object_id('tempdb.dbo.##SalesReportByTitlePOS') is not null
		BEGIN
		   DROP TABLE ##SalesReportByTitlePOS;
		END
	
	SET @strquery='SELECT distinct 
							st.ChainID,
							st.SupplierID,
							st.ProductID,
							s.storeid,
							P.ProductName,
							C.ChainIdentifier,
							Qty,
							st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"		
							
				   INTO ##SalesReportByTitlePOS
				   
				   FROM DataTrue_Report.dbo.Storetransactions St
						   INNER JOIN DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
						   INNER JOIN DataTrue_Report.dbo.Brands B ON St.BrandID=B.BrandID
						   INNER JOIN DataTrue_Report.dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
						   INNER JOIN DataTrue_Report.dbo.Chains C ON C.ChainID=St.ChainID
						   INNER JOIN DataTrue_Report.dbo.Suppliers SUP ON SUP.SupplierID=St.SupplierID
						   INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=St.StoreID
						   INNER JOIN DataTrue_Report.dbo.Addresses A ON A.OwnerEntityID=St.StoreID
						   INNER JOIN DataTrue_Report.dbo.Products P ON P.ProductID=St.ProductID
						   INNER JOIN DataTrue_Report.dbo.ProductPrices PP ON PP.ProductID=P.ProductID
						   
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
			   
	IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
		SET @strquery = @strquery +' AND  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  >= ''' + convert(varchar, +@StartDate,101) +  ''''
			
	IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
		SET @strquery = @strquery +' AND  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  <= ''' + convert(varchar, +@EndDate,101) + ''''
				
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
					
					INTO ##SalesReportByTitleFinalData 
					
					FROM
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
									
		EXEC(@strquery)
		
		--Update the required fields
			SET @strquery='update f set			
									f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeidAND SupplierID=f.supplierid and ProductPriceTypeID=3),
									
									f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3)
									
							From ##SalesReportByTitleFinalData f'
	
     EXEC(@strquery)
			
	 SET @sqlQueryNew=' select chainidentifier as chainid,
						ProductName as Title,
						suggretail,
						CostToStore,
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS Draws,
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS Returns,
						0 AS Shortages,
						Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) AS NetSales,
						Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0))) AS Profit,
						CASE
							WHEN SUM(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))>0
							
							THEN
								CASE
									WHEN SUM(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) >0
									  THEN 
										CAST(CAST(SUM(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) as Decimal)/CAST(SUM(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0))as Decimal)as decimal (18,4))
									ELSE cast(0  as decimal (18,4))
								END
							ELSE cast(0  as decimal (18,4))
						END AS salesRatio			
						
						FROM ##SalesReportByTitleFinalData 
						
						GROUP BY chainidentifier,ProductName,suggretail,CostToStore'
	
	EXEC(@sqlQueryNew)
	
END
GO
