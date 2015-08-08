USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_SalesReportByStatePUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_SalesReportByStatePUB 'DOWJ','35321','-1','BN','-1','-1','01/01/2009','12/12/2012','-1'
Create procedure [dbo].[amb_SalesReportByStatePUB]
(
@PublisherIdentifier varchar(10),
@PublisherId varchar(10),
@WholesalerID varchar(10),
@ChainID varchar(10),
@State varchar(10),
@Title varchar(20),
@StartDate varchar(20),
@EndDate varchar(20),
@days varchar(12)
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
Declare @allnew int --0 for old database,1 from new database, 2 from mixed
DECLARE @chain_migrated_date date

Declare @draws varchar(200), @returs varchar(200),@shortages varchar(200),@concatS varchar(5)
set @concatS=''
set @draws=''
set @returs=''
set @shortages=''

IF(@ChainID<>'-1')
BEGIN
	SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) 
	FROM    dbo.chains_migration 
	WHERE   chainid = @ChainID;
	
	IF(CAST(@chain_migrated_date AS DATE) > CAST('01/01/1900' AS DATE))
		BEGIN
			IF(CAST(@StartDate AS DATE)  >= CAST(@chain_migrated_date AS DATE))
				Begin
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

			ELSE IF(CAST(@EndDate AS DATE)  >= CAST(@chain_migrated_date AS DATE)  
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
IF (@allnew=0 or @allnew=2) 
	BEGIN
		SET @sqlQueryLegacy = ' SELECT OnR.ChainID,SL.State, ' 
		
								 if(@days='-1' or @days = 'Mon')
									BEGIN
										set @draws=@draws+ '[mon]'
										set @returs=@returs+'[monActualRet]'
										set @shortages=@shortages+'[mons]'
										set @concatS='+'
									END

								if(@days='-1' or @days = 'Tue')
									BEGIN
										set @draws=@draws+@concatS +'[Tue]'
										set @returs=@returs+@concatS+'[TueActualRet]'
										set @shortages=@shortages+@concatS+'[Tues]'
										set @concatS='+'
									END
								if(@days='-1' or @days = 'Wed')
									BEGIN
										set @draws=@draws+@concatS+ '[Wed]'
										set @returs=@returs+@concatS+'[WedActualRet]'
										set @shortages=@shortages+@concatS+'[Weds]'
										set @concatS='+'
									END
								if(@days='-1' or @days = 'Thur')
									BEGIN
										set @draws=@draws+@concatS+ '[Thur]'
										set @returs=@returs+@concatS+'[ThurActualRet]'
										set @shortages=@shortages+@concatS+'[Thurs]'
										set @concatS='+'
									END
								if(@days='-1' or @days = 'Fri')
									BEGIN
										set @draws=@draws+@concatS+ '[Fri]'
										set @returs=@returs+@concatS+'[FriActualRet]'
										set @shortages=@shortages+@concatS+'[Fris]'
										set @concatS='+'
									END
								if(@days='-1' or @days = 'Sat')
									BEGIN
										set @draws=@draws+@concatS+ '[Sat]'
										set @returs=@returs+@concatS+'[SatActualRet]'
										set @shortages=@shortages+@concatS+'[Sats]'
										set @concatS='+'
									END
								if(@days='-1' or @days = 'Sun')
									BEGIN
							 			set @draws=@draws+@concatS+ '[Sun]'
										set @returs=@returs+@concatS+'[SunActualRet]'
										set @shortages=@shortages+@concatS+'[Suns]'
										set @concatS='+'
									END
									
	  set @sqlQueryLegacy = @sqlQueryLegacy + ' Sum('+@draws+') AS Draws,Sum('+@returs+') AS Returns, Sum('+@shortages+') AS Shortages, 
						Sum('+@draws+'-('+@returs+')-('+@shortages+')) AS NetSales,
						Sum(('+@draws+'-('+@returs+')-('+@shortages+'))*([CostToStore4Wholesaler]-[CostToWholesaler]))AS Profit ,
						CASE 
							WHEN  Sum('+@draws+'-('+@returs+')-('+@shortages+'))>0  
								THEN  
									Case 
										WHEN Sum('+@draws+')>0 

										THEN cast(cast(Sum('+@draws+'-('+@returs+')-('+@shortages+')) as decimal) /cast(Sum('+@draws+') as decimal) as decimal (18,4)) 
										

										else cast(0 as decimal (18,4))
									END
							else  cast(0 as decimal (18,4))
						END  as salesRatio 
						FROM(( [IC-HQSQL2].iControl.dbo.OnR OnR   
						INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad) 
						INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL   ON OnR.StoreID = SL.StoreID) 
						INNER JOIN [IC-HQSQL2].iControl.dbo.Wholesalerslist  WL ON OnR.WholesalerID = WL.WholesalerID 
						WHERE ((P.PublisherID) Like '''+ @PublisherIdentifier +'%'') ' 
			
		if(@WholesalerID<>'-1')
			set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND ((OnR.WholesalerID) LIKE '''+ @WholesalerID +'%'') '
			
		if(@ChainID<>'-1')
			set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND ((OnR.ChainID) LIKE '''+ @ChainID + ''') '
			
		if(@State<>'-1')
			set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND ((SL.State) Like '''+ @State +'%'' ) '
			
		if(@Title<>'-1')
			set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND P.TitleName like '''+ @Title + '%'' '
		
		IF(CAST(@oldStartdate AS DATE) <> CAST('1900-01-01' AS DATE) ) 
			SET @sqlQueryLegacy += ' and OnR.WeekEnding >= ''' + convert(varchar, +@oldStartdate,101) +  ''''
		
		IF(CAST(@oldenddate AS DATE) <> CAST('1900-01-01' AS DATE) ) 
			SET @sqlQueryLegacy += ' AND OnR.WeekEnding <= ''' + convert(varchar, +@oldenddate,101) + ''''
				
			set @sqlQueryLegacy= @sqlQueryLegacy+ 'GROUP BY OnR.ChainID, SL.State '
			
	
	END		
				
/* -----(STEP 2) GET DATA FROM THE NEW DATABASE (DataTrue_Main)----- */
IF (@allnew=1 or  @allnew=2) 
BEGIN
	/*-------Get the data into tmp table for Draws---------*/		
	IF object_id('tempdb.dbo.##tempSalesReportByStateDraws') is not null
		BEGIN
			Drop Table ##tempSalesReportByStateDraws;
		END
	
	SET @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
					st.ProductID,Qty,TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					into ##tempSalesReportByStateDraws
					
					from dbo.Storetransactions_forward st
					INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
					INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
					inner JOIN dbo.Chains c on st.ChainID=c.ChainID
					INNER JOIN dbo.products p ON p.ProductID=st.ProductID
					inner JOIN dbo.Suppliers sup on st.Supplierid=sup.Supplierid
					INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
					INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
					where TransactionTypeID in (29)							
					and M.ManufacturerID = ' + @PublisherId
		
		IF(@WholesalerID<>'-1')					
			SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''	
		 
		IF(@ChainID<>'-1')   
			SET @strquery = @strquery +'and c.ChainIdentifier='''+@ChainID+''''
			
		IF(@State<>'-1')    
			SET @strquery = @strquery +' and a.State like '''+@State+''''
				
		IF(@Title<>'-1')   
			SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''
										   								
		IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
			
		IF(CAST(@newEnddate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
								
	EXEC (@strquery)
/* Get the data into tmp table for POS */

	IF object_id('tempdb.dbo.##tempSalesReportByStatePOS') is not null
		BEGIN
			drop table ##tempSalesReportByStatePOS
		END	
			
		   SET @strquery=' Select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempSalesReportByStatePOS								
							
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.products p ON p.ProductID=st.ProductID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
							inner JOIN dbo.Suppliers sup on st.Supplierid=sup.Supplierid
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 								
							where 1 = 1						
							and M.ManufacturerID = ' + @PublisherId
					
		IF(@WholesalerID<>'-1')					
			 SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''	
			 					
		IF(@ChainID<>'-1')					
			 SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''														   

		IF(@State<>'-1')    
			 SET @strquery = @strquery +' and	a.State like '''+@State+''''
			 				
		IF(@Title<>'-1')   
			 SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''
										
		if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
			 SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

		if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
			 SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + ''''
		 
	--PRINT(@strquery)
	EXEC(@strquery)
	
	--Get the final data into final tmp table

	IF object_id('tempdb.dbo.##tempSalesReportByStateFinalData') is not null
		BEGIN
			DROP Table ##tempSalesReportByStateFinalData
		END	
				
			SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "StoreName",
							CAST(NULL as nvarchar(50)) as "StoreNumber",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "wholesalerid",
							CAST(NULL as nvarchar(50)) as "chainidentifier",
							CAST(NULL as nvarchar(225)) as "Title",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as money) as "SuggRetail"
						
							into ##tempSalesReportByStateFinalData 
							from
							(select * FROM 
								(SELECT * from ##tempSalesReportByStateDraws ) p
									pivot( sum(Qty) for  wDay in
									(MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
									FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
								) tmpdraws
							join
							( select * from 
								(SELECT * from ##tempSalesReportByStatePOS)p
								pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
								WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								) as p1
							) tmpPOS 
							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid'
	--PRINT(@strquery)
	EXEC(@strquery)
		
/*----UPDATE THE TEMP TABLE----- */

		 SET @strquery='update f set	
					f.StoreName=(select distinct StoreName from dbo.Stores  
					where StoreID=f.StoreID),		
					f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.Wholesalerid=(SELECT DISTINCT Supplieridentifier from dbo.Suppliers where SupplierID=f.supplierid),
					f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid),
					f.title=(SELECT DISTINCT  ProductName  from dbo.Products 
					where ProductID=f.productid),
					f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
					where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
					AND SupplierID=f.supplierid and ProductPriceTypeID=3),
					f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices 
					where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
					AND SupplierID=f.supplierid and ProductPriceTypeID=3)
					
					from ##tempSalesReportByStateFinalData f'
	--PRINT(@strquery)
	EXEC(@strquery)	
	
	set @draws='';
	set @returs='';
	set @concatS='';
	Declare @POS as varchar(200)='';
	SET @sqlQueryNew='select distinct chainidentifier as ChainID, State,'
	
	if(@days='-1' or @days = 'Mon')
		BEGIN
		
			set @draws=@draws+ '[MondayDraw]'
			set @returs=@returs+'MondayDraw-MondayPOS'
			set @POS=@POS+'[MondayPOS]'
			set @concatS='+'
		END

	if(@days='-1' or @days = 'Tue')
		BEGIN
			set @draws=@draws+@concatS +'[TuesdayDraw]'
			set @returs=@returs+@concatS+'TuesdayDraw-TuesdayPOS'
			set @POS=@POS+@concatS+'[TuesdayPOS]'
			set @concatS='+'
		END
	if(@days='-1' or @days = 'Wed')
		BEGIN
			set @draws=@draws+@concatS+ '[WednesdayDraw]'
			set @returs=@returs+@concatS+'WednesdayDraw-WednesdayPOS'
			set @POS=@POS+@concatS+'[WednesdayPOS]'
			set @concatS='+'
		END
	if(@days='-1' or @days = 'Thur')
		BEGIN
			set @draws=@draws+@concatS+ '[ThursdayDraw]'
			set @returs=@returs+@concatS+'ThursdayDraw-ThursdayPOS'
			set @POS=@POS+@concatS+'[ThursdayPOS]'
			set @concatS='+'
		END
	if(@days='-1' or @days = 'Fri')
		BEGIN
			set @draws=@draws+@concatS+ '[FridayDraw]'
			set @returs=@returs+@concatS+'FridayDraw-FridayPOS'
			set @POS=@POS+@concatS+'[FridayPOS]'
			set @concatS='+'
		END
	if(@days='-1' or @days = 'Sat')
		BEGIN
			set @draws=@draws+@concatS+ '[SaturdayDraw]'
			set @returs=@returs+@concatS+'SaturdayDraw-SaturdayPOS'
			set @POS=@POS+@concatS+'[SaturdayPOS]'
			set @concatS='+'
		END
	if(@days='-1' or @days = 'Sun')
		BEGIN
 			set @draws=@draws+@concatS+ '[SundayDraw]'
			set @returs=@returs+@concatS+'SundayDraw-SundayPOS'
			set @POS=@POS+@concatS+'[SundayPOS]'
			set @concatS='+'
		END
			SET @sqlQueryNew=@sqlQueryNew+'	Sum('+@draws+') AS Draws,
											Sum('+@returs+') AS Returns, 
											0 AS Shortages, 
											Sum('+@POS+') AS NetSales,
											Sum('+@POS+')*(SuggRetail-costtostore) AS Profit,
											CASE
											WHEN SUM('+@POS+')>0
												THEN
													CASE
														WHEN SUM('+@draws+') >0
															THEN 
																cast(cast(SUM('+@POS+') as decimal)/cast(SUM('+@draws+') as decimal)as decimal (18,4)) 
														ELSE cast(0  as decimal (18,4))
													END
											ELSE cast(0  as decimal (18,4))
										END AS salesRatio
						From 
						##tempSalesReportByStateFinalData
						group by chainidentifier,State,SuggRetail,costtostore;'	

	END
		
/*----(STEP 3) FINAL QUERY EXEC--------*/	
	IF(@allnew=2)
		BEGIN
			SET @sqlQueryFinal=@sqlQueryLegacy+ ' union ' +@sqlQueryNew
			EXEC(@sqlQueryFinal)
		END
	ELSE IF(@allnew=1)
		EXEC(@sqlQueryNew)
	ELSE IF(@allnew=0)
		EXEC(@sqlQueryLegacy)
END
GO
