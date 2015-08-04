USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GenerateSalesReportByStateWHL_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_GenerateSalesReportByStateWHL 'Wr1428','24503','-1','-1','PRESS','11/06/2006','11/15/2012'

-- exec amb_GenerateSalesReportByStateWHL 'CLL','24164','DQ','-1','-1','01/01/1900','01/01/1900'

--exec amb_GenerateSalesReportByStateWHL 'WNA','24269','SV','-1','-1','01/05/2015','01/11/2015'

CREATE procedure [dbo].[amb_GenerateSalesReportByStateWHL_PRESYNC_20150415]
(
	@supplieridentifier as varchar(20),
	@supplierid as varchar(20),
	@ChainID varchar(20),
	@State varchar(10),
	@Title varchar(250),
	@StartDate varchar(20),
	@EndDate varchar(20) 

)
as 
BEGIN

Declare @strquery varchar(8000)
Declare @sqlQueryNew varchar(8000)

	/*-------Get the data into tmp table for Draws---------*/		
	IF object_id('tempdb.dbo.##SalesReportByStateDraws') is not null
		BEGIN
			Drop Table ##SalesReportByStateDraws;
		END
	
	SET @strquery='select  st.ChainID,st.SupplierID,s.StoreID as storeid,
					st.ProductID,Qty,TransactionTypeID,
					datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					
					into ##SalesReportByStateDraws
					
					from dbo.Storetransactions_forward st  with(nolock)
					INNER JOIN dbo.suppliers sup with(nolock) ON sup.supplierid=st.supplierid 
					INNER JOIN dbo.products p with(nolock) ON p.productid=st.productid 
					inner JOIN dbo.Chains c with(nolock) on st.ChainID=c.ChainID
					INNER JOIN dbo.Stores s with(nolock) ON s.StoreID=st.StoreID
					INNER JOIN dbo.Addresses a with(nolock) ON a.OwnerEntityID=st.StoreID 
					LEFT JOIN DataTrue_Main.dbo.BillingControl BC with (nolock) on BC.EntityIDToInvoice=ST.SupplierID and BC.chainid=ST.chainid
					where TransactionTypeID in (29)
					and st.supplierid='''+@supplierid+''''
		
		IF(@ChainID<>'-1')   
			SET @strquery = @strquery +'and c.ChainIdentifier='''+@ChainID+''''
			
		IF(@Title<>'-1')   
			SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''
										   
		IF(@State<>'-1')    
			SET @strquery = @strquery +' and	a.State like '''+@State+''''
										
		IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) AS Date) >= CAST(''' +@StartDate +  ''' AS DATE)'
			
		IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) AS Date) <= CAST(''' + @EndDate + ''' AS DATE)'
								
		EXEC(@strquery)
				
				
		/*-------Get the data into tmp table for POS---------*/				
		IF object_id('tempdb.dbo.##SalesReportByStatePOS') is not null
			BEGIN
				DROP TABLE ##SalesReportByStatePOS;
			END
		
		SET @strquery='select  ST.ChainID,ST.SupplierID,s.StoreID as storeid,
						sup.Supplieridentifier,c.ChainIdentifier,a.state,
					    ST.ProductID,Qty,ST.TransactionTypeID,
					    CAST(ST.RuleCost as MONEY) as CostToStore,
						CAST(ST.RuleRetail as MONEY) as SuggRetail,
						datename(W,SaleDateTime)+ ''POS'' as "POSDay"
					
						into ##SalesReportByStatePOS
					
						FROM dbo.Storetransactions ST with(nolock) 
						INNER JOIN dbo.transactiontypes tt with(nolock) on tt.transactiontypeid=ST.transactiontypeid and tt.buckettype=1
						INNER JOIN dbo.suppliers sup with(nolock) ON sup.supplierid=ST.supplierid 
						INNER JOIN dbo.products p with(nolock) ON p.productid=ST.productid 
						INNER JOIN dbo.Chains c with(nolock) on ST.ChainID=c.ChainID
						INNER JOIN dbo.Stores s with(nolock) ON s.StoreID=ST.StoreID
						INNER JOIN dbo.Addresses a with(nolock) ON a.OwnerEntityID=ST.StoreID 
						LEFT JOIN DataTrue_Main.dbo.BillingControl BC with (nolock) on BC.EntityIDToInvoice=ST.SupplierID and BC.chainid=ST.chainid						
						where 1=1 and ST.supplierid='''+@supplierid+''''
		
		IF(@ChainID<>'-1')   
			SET @strquery = @strquery +'and c.ChainIdentifier='''+@ChainID+''''
			
		IF(@Title<>'-1')   
			SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''
										   
		IF(@State<>'-1')    
			SET @strquery = @strquery +' and a.State like '''+@State+''''
										
		IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' AND cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) AS Date) >= CAST(''' + @StartDate + ''' AS DATE)' 
		
		IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01'AS DATE)) 
			SET @strquery = @strquery +' AND cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) AS Date) <= CAST(''' + @EndDate + ''' AS DATE)'
								
		EXEC(@strquery)
		
		
		/*----Get the final data into final tmp table(Draws and POS)----*/		
		IF object_id('tempdb.dbo.##SalesReportByStateFinalData') is not null
		BEGIN
			DROP TABLE ##SalesReportByStateFinalData
		END


		SET @strquery='Select distinct tmpPOS.ChainID
									  , tmpPOS.SupplierId
									  , tmpPOS.StoreID
									  , tmpPOS.ProductID
									  , tmpdraws.MondayDraw
									  , tmpdraws.TuesdayDraw
									  , tmpdraws.WednesdayDraw
									  , tmpdraws.ThursdayDraw
									  , tmpdraws.FridayDraw
									  , tmpdraws.SaturdayDraw
									  , tmpdraws.SundayDraw
									  , tmpPOS.MondayPOS
									  , tmpPOS.TuesdayPOS
									  , tmpPOS.WednesdayPOS
									  , tmpPOS.ThursdayPOS
									  , tmpPOS.FridayPOS
									  , tmpPOS.SaturdayPOS
									  , tmpPOS.SundayPOS
									  , tmpPOS.CostToStore
									  , tmpPOS.SuggRetail
									  , tmpPOS.State
									  , tmpPOS.Supplieridentifier AS WholesalerID
									  , tmpPOS.ChainIdentifier
						
						into ##SalesReportByStateFinalData 
						from
						( select * from 
							(SELECT * from ##SalesReportByStatePOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS
						LEFT JOIN
						(select * FROM 
							(SELECT * from ##SalesReportByStateDraws ) p
							 pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) 
							 as Draw_eachday
						) tmpdraws
						 
						on tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'

			EXEC(@strquery)
			
			/*----UPDATE THE TEMP TABLE----- 
			SET @strquery='update f set 
				
						 f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
						 
						 f.Wholesalerid=(SELECT DISTINCT Supplieridentifier from dbo.Suppliers where SupplierID=f.supplierid),
						 
						 f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid)
						 
						 from ##SalesReportByStateFinalData  f'
			EXEC(@strquery)*/
				
				
			SET @sqlQueryNew=' select distinct State,
								chainidentifier as ChainID ,
								WholesalerID,
								Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS Draws,
								Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS Returns,
								0 AS Shortages,
								Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) AS NetSales,
								Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0))) AS Profit
								
								FROM ##SalesReportByStateFinalData 
								
								GROUP BY 
							         chainidentifier,
							         Wholesalerid,
							         State  '				
			
	
		EXEC(@sqlQueryNew)
			/*----Get the final data into final tmp table(Draws and POS)----*/		
		IF object_id('tempdb.dbo.##SalesReportByStateDraws') is not null
		BEGIN
			 exec ('DROP TABLE ##SalesReportByStateDraws')
		END
		IF object_id('tempdb.dbo.##SalesReportByStatePOS') is not null
		BEGIN
			 exec ('DROP TABLE ##SalesReportByStatePOS')
		END
		
		IF object_id('tempdb.dbo.##SalesReportByStateFinalData') is not null
		BEGIN
			exec ('DROP TABLE ##SalesReportByStateFinalData')
		END
		
END
GO
