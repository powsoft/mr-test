USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_saleReportsByStateDCR]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---exec amb_saleReportsByStateDCR 'DOWJ','35321','BN','-1','-1','01/01/2009','12/12/2012','-1','-1'
---exec amb_saleReportsByStateDCR 'DOWJ','35321','BN','STC','-1','01/01/2009','12/12/2012','-1','-1'
 --=============================================
 --Author:		<Author,,Name>
 --alter date: <alter Date,,>
 --Description:	<Description,,>
 --=============================================
CREATE PROCEDURE [dbo].[amb_saleReportsByStateDCR]
(
	@PublisherIdentifier varchar(10),
    @PublisherID varchar(15),
    @ChainID varchar(20),
    @WholesalerID varchar(10),
    @TitleName varchar(20),
    @StartDate varchar(15),
    @EndDate varchar(15),
    @State varchar(15),
	@days varchar(12)
)
AS

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
		SET @sqlQueryLegacy = ' SELECT SL.State, OnR.ChainID, ' 

								if(@days='-1' or @days = 'Mon')
								BEGIN
									SET @draws=@draws+ '[mon]'
									SET @returs=@returs+'[monActualRet]'
									SET @shortages=@shortages+'[mons]'
									SET @concatS='+'
								END

								if(@days='-1' or @days = 'Tue')
								BEGIN
									SET @draws=@draws+@concatS +'[Tue]'
									SET @returs=@returs+@concatS+'[TueActualRet]'
									SET @shortages=@shortages+@concatS+'[Tues]'
									SET @concatS='+'
								END
								if(@days='-1' or @days = 'Wed')
								BEGIN
									SET @draws=@draws+@concatS+ '[Wed]'
									SET @returs=@returs+@concatS+'[WedActualRet]'
									SET @shortages=@shortages+@concatS+'[Weds]'
									SET @concatS='+'
								END
								if(@days='-1' or @days = 'Thur')
								BEGIN
									SET @draws=@draws+@concatS+ '[Thur]'
									SET @returs=@returs+@concatS+'[ThurActualRet]'
									SET @shortages=@shortages+@concatS+'[Thurs]'
									SET @concatS='+'
								END
								if(@days='-1' or @days = 'Fri')
								BEGIN
									SET @draws=@draws+@concatS+ '[Fri]'
									SET @returs=@returs+@concatS+'[FriActualRet]'
									SET @shortages=@shortages+@concatS+'[Fris]'
									SET @concatS='+'
								END
								if(@days='-1' or @days = 'Sat')
								BEGIN
									SET @draws=@draws+@concatS+ '[Sat]'
									SET @returs=@returs+@concatS+'[SatActualRet]'
									SET @shortages=@shortages+@concatS+'[Sats]'
									SET @concatS='+'
								END
								if(@days='-1' or @days = 'Sun')
								BEGIN
									SET @draws=@draws+@concatS+ '[Sun]'
									SET @returs=@returs+@concatS+'[SunActualRet]'
									SET @shortages=@shortages+@concatS+'[Suns]'
									SET @concatS='+'
								END

		SET @sqlQueryLegacy = @sqlQueryLegacy+ 'Sum('+ @draws+ ') AS Draws, SUM( '+@returs+') AS Returns, SUM('+@shortages+') AS Shortages,
							SUM(' + @draws+ '-('+@returs+')-('+@shortages+')) AS NetSales,Sum(('+@draws+'-('+@returs+')-('+@shortages+'))*
							([CostToStore4Wholesaler]-[CostToWholesaler])) AS Profit,
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
							FROM (( [IC-HQSQL2].iControl.dbo.OnR OnR   
							INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad) 
							INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID =SL.StoreID) 
							INNER JOIN  [IC-HQSQL2].iControl.dbo.Wholesalerslist WL  ON OnR.WholesalerID = WL.WholesalerID  '
		 
		
		IF(@WholesalerId<>'-1')
			SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND OnR.WholesalerID = '''+@WholesalerID+''''
		IF(@TitleName<>'-1')
			SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND P.AbbrvName = '''+@TitleName+''''
		IF(@State<>'-1')
			SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.State = '''+@State+''''
		IF(@ChainID<>'-1')
		    SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND OnR.ChainID = '''+@ChainID+''''       
		
		IF(CAST(@oldStartdate AS DATE) <> CAST('1900-01-01' AS DATE) ) 
			SET @sqlQueryLegacy += ' and OnR.WeekEnding >= ''' + convert(varchar, +@oldStartdate,101) +  ''''
		
		IF(CAST(@oldenddate AS DATE) <> CAST('1900-01-01' AS DATE) ) 
			SET @sqlQueryLegacy += ' AND OnR.WeekEnding <= ''' + convert(varchar, +@oldenddate,101) + ''''
				
		 SET @sqlQueryLegacy= @sqlQueryLegacy+ ' GROUP BY OnR.ChainID, SL.State,P.PublisherID '
		    
		 SET @sqlQueryLegacy= @sqlQueryLegacy+ ' HAVING P.PublisherID = '''+@PublisherIdentifier +''''
		       
		 -- set @strQuery= @strQuery+ ' ORDER BY OnR.ChainID '
		       
		 exec(@strQuery)
	END

/* -----(STEP 2) GET DATA FROM THE NEW DATABASE (DataTrue_Main)----- */
IF (@allnew=1 or  @allnew=2) 
BEGIN
	/*-------Get the data into tmp table for Draws---------*/		
	IF object_id('tempdb.dbo.##tempSalesReportByStateDCRDraws') is not null
		BEGIN
			Drop Table ##tempSalesReportByStateDCRDraws;
		END
	
	SET @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
					st.ProductID,Qty,TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					into ##tempSalesReportByStateDCRDraws
					
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
				
	IF(@TitleName<>'-1')   
			SET @strquery = @strquery +' and p.productname like '''+@TitleName+'%'''
										   								
	IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
			
	IF(CAST(@newEnddate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
								
	EXEC (@strquery)
/* Get the data into tmp table for POS */

	IF object_id('tempdb.dbo.##tempSalesReportByStateDCRPOS') is not null
		BEGIN
			drop table ##tempSalesReportByStateDCRPOS
		END	
			
		   SET @strquery=' Select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempSalesReportByStateDCRPOS								
							
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
			 				
		IF(@TitleName<>'-1')   
			 SET @strquery = @strquery +' and p.productname like '''+@TitleName+'%'''
										
		if(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
			 SET @strquery = @strquery +' AND SaleDateTime >= ''' + CONVERT(varchar, +@newStartdate,101) +  ''''

		if(CAST(@newEnddate AS DATE ) <> CAST('1900-01-01' AS DATE)) 
			 SET @strquery = @strquery +' AND SaleDateTime <= ''' + CONVERT(varchar, +@newEnddate,101) + ''''
		 
	--PRINT(@strquery)
	EXEC(@strquery)
	
	--Get the final data into final tmp table

	IF object_id('tempdb.dbo.##tempSalesReportByStateDCRFinalData') is not null
		BEGIN
			DROP Table ##tempSalesReportByStateDCRFinalData
		END	
				
			SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "chainidentifier",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as money) as "SuggRetail"
						
							into ##tempSalesReportByStateDCRFinalData 
							from
							(select * FROM 
								(SELECT * from ##tempSalesReportByStateDCRDraws ) p
									pivot( sum(Qty) for  wDay in
									(MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
									FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
								) tmpdraws
							join
							( select * from 
								(SELECT * from ##tempSalesReportByStateDCRPOS)p
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
					f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid),
					f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
					where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
					AND SupplierID=f.supplierid and ProductPriceTypeID=3),
					f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices 
					where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
					AND SupplierID=f.supplierid and ProductPriceTypeID=3)
					
					from ##tempSalesReportByStateDCRFinalData f'
	--PRINT(@strquery)
	EXEC(@strquery)	
	
	SET @draws='';
	SET @returs='';
	SET @concatS='';
	Declare @POS as varchar(200)='';
	SET @sqlQueryNew='select distinct chainidentifier as ChainID, State,'
	
	if(@days='-1' or @days = 'Mon')
		BEGIN
		
			SET @draws=@draws+ '[MondayDraw]'
			SET @returs=@returs+'MondayDraw-MondayPOS'
			SET @POS=@POS+'[MondayPOS]'
			SET @concatS='+'
		END

	if(@days='-1' or @days = 'Tue')
		BEGIN
			SET @draws=@draws+@concatS +'[TuesdayDraw]'
			SET @returs=@returs+@concatS+'TuesdayDraw-TuesdayPOS'
			SET @POS=@POS+@concatS+'[TuesdayPOS]'
			SET @concatS='+'
		END
	if(@days='-1' or @days = 'Wed')
		BEGIN
			SET @draws=@draws+@concatS+ '[WednesdayDraw]'
			SET @returs=@returs+@concatS+'WednesdayDraw-WednesdayPOS'
			SET @POS=@POS+@concatS+'[WednesdayPOS]'
			SET @concatS='+'
		END
	if(@days='-1' or @days = 'Thur')
		BEGIN
			SET @draws=@draws+@concatS+ '[ThursdayDraw]'
			SET @returs=@returs+@concatS+'ThursdayDraw-ThursdayPOS'
			SET @POS=@POS+@concatS+'[ThursdayPOS]'
			SET @concatS='+'
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
			SET @draws=@draws+@concatS+ '[SaturdayDraw]'
			SET @returs=@returs+@concatS+'SaturdayDraw-SaturdayPOS'
			SET @POS=@POS+@concatS+'[SaturdayPOS]'
			SET @concatS='+'
		END
	if(@days='-1' or @days = 'Sun')
		BEGIN
 			SET @draws=@draws+@concatS+ '[SundayDraw]'
			SET @returs=@returs+@concatS+'SundayDraw-SundayPOS'
			SET @POS=@POS+@concatS+'[SundayPOS]'
			SET @concatS='+'
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
																cast(cast(SUM('+@POS+') as decimal)/cast(SUM('+@draws+') as decimal) as decimal (18,4))
														ELSE cast(0  as decimal (18,4))
													END
											ELSE cast(0  as decimal (18,4))
										END AS salesRatio
						From 
						##tempSalesReportByStateDCRFinalData
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
