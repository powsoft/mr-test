USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_BaseDrawBySaleWHLS_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_BaseDrawBySaleWHLS_Beta] '-1','-1','-1','','-1','1900-01-01','1900-01-01','WR1428','24503','StoreNumber ASC',1,25,0
--exec [amb_BaseDrawBySaleWHLS_Beta] 'BN','-1','-1','','-1','1900-01-01','1900-01-01','WR1428','24503','StoreNumber ASC',1,25,0

--exec [amb_BaseDrawBySaleWHLS_Beta] 'DQ','-1','-1','','-1','1900-01-01','1900-01-01','CLL','24164'

CREATE procedure [dbo].[amb_BaseDrawBySaleWHLS_Beta]
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
	/*@OrderBy varchar(100),
	@StartIndex int,
	@PageSize int,
	@DisplayMode int*/
)

as 
BEGIN
	Declare @strquery varchar(8000)
	Declare @sqlQueryNew varchar(8000)


     /* Get the data into tmp table for Draws */
	IF object_id('tempdb.dbo.##tempRegulateBaseDrawBySaleWHL') is not null 
		BEGIN
		  drop table ##tempRegulateBaseDrawBySaleWHL;
		END
	
	SET @strquery='select distinct st.ChainID,st.SupplierID,s.LegacySystemStoreIdentifier as storeid,
					st.ProductID,Qty,TransactionTypeID,
					datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					into ##tempRegulateBaseDrawBySaleWHL
					
					from DataTrue_Report.dbo.Storetransactions_forward st
					inner JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
					INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
					INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
					INNER JOIN DataTrue_Report.dbo.Products P ON	st.ProductID = P.ProductID	
					
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
							
	if(CAST(@StartDate AS DATE ) <> CAST('1900-01-01' AS DATE))
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime)))+7, ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + CONVERT(varchar, +@StartDate,101) +  ''''

	if(CAST(@EndDate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime)))+7, ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + CONVERT(varchar, +@EndDate,101) + '''' 

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
					
					from DataTrue_Report.dbo.Storetransactions st
					inner join DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
					inner JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
					INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
					INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID
					INNER JOIN DataTrue_Report.dbo.Products P ON	st.ProductID = P.ProductID	 										
					
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
								
	if(CAST(@StartDate AS DATE ) <> CAST('1900-01-01' AS DATE))
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime)))+7, ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + CONVERT(varchar, +@StartDate,101) +  ''''

	if(CAST(@EndDate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime)))+7, ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + CONVERT(varchar, +@EndDate,101) + ''''
	
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
		f.supplieridentifier=(select distinct supplieridentifier from dbo.suppliers where supplierid=f.supplierid),
		
		f.Chainidentifier=(select distinct Chainidentifier from dbo.Chains where chainid=f.chainid),
		
		f.StoreName=(select distinct StoreName from dbo.Stores  where LegacySystemStoreIdentifier=f.StoreID),
		
		f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores  where LegacySystemStoreIdentifier=f.StoreID),
		
		f.address=(select distinct Address1 from dbo.Addresses A inner JOIN Stores S on S.StoreID=A.OwnerEntityID where S.LegacySystemStoreIdentifier=f.StoreID),
		f.city=(select distinct city from dbo.Addresses A inner JOIN Stores S on S.StoreID=A.OwnerEntityID where S.LegacySystemStoreIdentifier=f.StoreID),
		f.state=(select distinct state from dbo.Addresses A inner JOIN Stores S on S.StoreID=A.OwnerEntityID where S.LegacySystemStoreIdentifier=f.StoreID),
		f.zipcode=(select distinct PostalCode from dbo.Addresses A inner JOIN Stores S on S.StoreID=A.OwnerEntityID where S.LegacySystemStoreIdentifier=f.StoreID),
		f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers where SupplierID=f.supplierid),
		
		f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=f.productid),
		
		f.title=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),
		
		f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices PP inner join Stores S on PP.StoreID=S.StoreID where ProductID=f.productid AND							    PP.ChainID=f.chainid and S.LegacySystemStoreIdentifier=f.storeid AND  SupplierID=f.supplierid and ProductPriceTypeID=3),
		
		f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices PP inner join Stores S on PP.StoreID=S.StoreID where ProductID=f.productid 
						AND PP.ChainID=f.chainid and S.LegacySystemStoreIdentifier=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),

		F.MonBase=(Select Distinct  MonLimitQty  From dbo.StoreSetup SS inner join Stores S on S.StoreID=SS.storeid
				   Where SS.ProductID=f.productid AND SS.ChainID=F.chainid AND S.LegacySystemStoreIdentifier=f.storeid AND SS.SupplierID=f.supplierid),
				   
		F.TueBase=(Select Distinct  TueLimitQty  From dbo.StoreSetup SS inner join Stores S on S.StoreID=SS.storeid Where SS.ProductID=f.productid								AND	SS.ChainID=F.chainid AND S.LegacySystemStoreIdentifier=f.storeid AND SS.SupplierID=f.supplierid),
		
		F.WedBase=(Select Distinct  WedLimitQty  From dbo.StoreSetup SS inner join Stores S on S.StoreID=SS.storeid Where SS.ProductID=f.productid								AND	SS.ChainID=F.chainid AND S.LegacySystemStoreIdentifier=f.storeid AND SS.SupplierID=f.supplierid),
		
		F.ThurBase=(Select Distinct  ThuLimitQty  From dbo.StoreSetup SS inner join Stores S on S.StoreID=SS.storeid Where SS.ProductID=f.productid								AND SS.ChainID=F.chainid AND S.LegacySystemStoreIdentifier=f.storeid AND SS.SupplierID=f.supplierid),
		
		F.FriBase=(Select Distinct  FriLimitQty  From dbo.StoreSetup SS inner join Stores S on S.StoreID=SS.storeid Where SS.ProductID=f.productid								AND	SS.ChainID=F.chainid AND S.LegacySystemStoreIdentifier=f.storeid AND SS.SupplierID=f.supplierid),
		
		F.SatBase=(Select Distinct SatLimitQty  From dbo.StoreSetup SS inner join Stores S on S.StoreID=SS.storeid Where SS.ProductID=f.productid								AND SS.ChainID=F.chainid AND S.LegacySystemStoreIdentifier=f.storeid AND SS.SupplierID=f.supplierid),
		
		F.SunBase=(Select Distinct  SunLimitQty  From dbo.StoreSetup SS inner join Stores S on S.StoreID=SS.storeid Where SS.ProductID=f.productid AND								SS.ChainID=F.chainid AND S.LegacySystemStoreIdentifier=f.storeid AND SS.SupplierID=f.supplierid)
					
		from ##tempRegulateBaseDrawBySaleWHLFinalData f'

	EXEC(@strquery)
	
	--Return the Data
	
									
	SET @sqlQueryNew=' select  ( ''Store Number: '' + StoreNumber + '','' + StoreName  + ''/n Location: '' + address + '', '' + City + '','' + State + '', '' + zipcode ) as StoreInfo, WholeSalerName,						
						supplieridentifier as WholesalerID,storeid,Chainidentifier as ChainId,StoreNumber,	storename,address,City,
						State,zipcode,0 as CostToStore4Wholesaler,0 as CostToWholesaler,bipad,title,
						ISNULL(costtostore,0) AS CostToStore,
						ISNULL(suggretail,0) As SuggRetail,			
						sum(ISNULL(mondaydraw,0)) as MonDraws,
						sum(ISNULL(tuesdaydraw,0)) as TueDraws,
						sum(ISNULL(wednesdaydraw,0)) as WedDraws,
						sum(ISNULL(thursdaydraw,0)) as ThurDraws,
						sum(ISNULL(fridaydraw,0)) as FriDraws,
						sum(ISNULL(saturdaydraw,0)) as SatDraws,
						sum(ISNULL(sundaydraw,0)) as SunDraws,
						sum(ISNULL(mondaydraw,0)-ISNULL(mondayPOS,0)) as MonReturns,
						sum(ISNULL(tuesdaydraw,0)-ISNULL(tuesdayPOS,0)) as TueReturns,
						sum(ISNULL(wednesdaydraw,0)-ISNULL(wednesdayPOS,0)) as WedReturns,
						sum(ISNULL(thursdaydraw,0)-ISNULL(thursdayPOS,0)) as ThurReturns,
						sum(ISNULL(fridaydraw,0)-ISNULL(fridayPOS,0)) as FriReturns,
						sum(ISNULL(saturdaydraw,0)-ISNULL(saturdayPOS,0)) as SatReturns,
						sum(ISNULL(sundaydraw,0)-ISNULL(sundayPOS,0)) as SunReturns,						
						''0'' AS MonShort,
						''0'' AS TueShort, 
						''0'' AS WedShort,
						''0'' AS ThurShort, 
						''0'' AS FriShort,
						''0'' AS SatShort, 
						''0'' AS SunShort,						
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS [TTL Draws],
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS [TT Returns],
						0 AS [TTL Shortages],
						Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ ISNULL(sundayPOS,0)) AS NetSales, 
						Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0))) AS Profit,
						sum(ISNULL(mondayPOS,0))/Count(bipad) AS AvgMonSale,
						sum(ISNULL(tuesdayPOS,0))/Count(bipad) AS AvgTueSale,
						sum(ISNULL(wednesdayPOS,0))/Count(bipad) AS AvgWedSale,
						sum(ISNULL(thursdayPOS,0))/Count(bipad) AS AvgThuSale,
						sum(ISNULL(fridayPOS,0))/Count(bipad) AS AvgFriSale,
						sum(ISNULL(saturdayPOS,0))/Count(bipad) AS AvgSatSale,
						sum(ISNULL(sundayPOS,0))/Count(bipad) AS AvgSunSale,
						ISNULL(MonBase,0) AS MonBase,
						ISNULL(TueBase,0) AS TueBase, 
						ISNULL(WedBase,0) AS WedBase,
						ISNULL(ThurBase,0) AS ThurBase,
						ISNULL(FriBase,0) AS FriBase, 
						ISNULL(SatBase,0) AS SatBase, 
						ISNULL(SunBase,0) AS SunBase,
						Count(bipad) AS NoOfWeeksInRange,
						1 as Dbtype				

						From 
						##tempRegulateBaseDrawBySaleWHLFinalData
						group by chainid,supplieridentifier,wholesalername,StoreID,Chainidentifier,productid,storename,StoreNumber,address,City,
						State,zipcode,wholesalername,bipad,title,costtostore,suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,fridaydraw,
						saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,fridayPOS,saturdayPOS,sundayPOS,
						MonBase,TueBase,WedBase,ThurBase,FriBase, SatBase,SunBase 
						Order By storeid,title '
EXEC(@sqlQueryNew)


/*SET @sqlQueryFinal=[dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  ( ' +@sqlQueryNew+'	) as temp ', @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
EXEC(@sqlQueryFinal)*/

END
GO
