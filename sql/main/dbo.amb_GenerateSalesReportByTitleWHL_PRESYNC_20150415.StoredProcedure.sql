USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GenerateSalesReportByTitleWHL_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_GenerateSalesReportByTitleWHL 'WR1428','24503','BN','-1','-1','11/07/2012','11/15/2012'
--exec amb_GenerateSalesReportByTitleWHL 'CLL','24164','-1','-1','-1','09/30/2010','10/06/2013'
--exec amb_GenerateSalesReportByTitleWHL 'WR604','26565','-1','-1','-1','11/08/2013','12/04/2013'
--exec amb_GenerateSalesReportByTitleWHL 'GENN','28780','-1','-1','-1','01/20/2014','01/26/2014'

--exec amb_GenerateSalesReportByTitleWHL 'GENN','28780','DOIL','MI','-1','01/01/1900','01/01/1900'

--exec amb_GenerateSalesReportByTitleWHL 'CLL','24164','DQ','-1','-1','03/01/2014','03/31/2014'-- == month
--exec amb_GenerateSalesReportByTitleWHL 'BG','24143','CF','-1','BOSTON HERALD','03/03/2014','03/30/2014'-- == month

--exec amb_GenerateSalesReportByTitleWHL 'BG','24143','CF','-1','BOSTON HERALD','03/03/2014','03/30/2014'
--exec amb_GenerateSalesReportByTitleWHL 'WR651','26582','CF','-1','BOSTON HERALD','03/03/2014','03/30/2014'

--exec amb_GenerateSalesReportByTitleWHL 'HNA','28792','-1','-1','-1','05/05/2014','05/11/2014'
--exec amb_GenerateSalesReportByTitleWHL 'WR500','26239','CF','-1','MOUNTAIN EAGLE / HUDSON','02/03/2014','06/22/2014'

--exec amb_GenerateSalesReportByTitleWHL 'WR1414','28942','SV','-1','-1','01/25/2015','01/25/2015'

CREATE procedure [dbo].[amb_GenerateSalesReportByTitleWHL_PRESYNC_20150415]
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
	IF object_id('tempdb.dbo.##SalesReportByTitleDraws') is not null
		BEGIN
			DROP TABLE ##SalesReportByTitleDraws;
		END
	

	SET @strquery='select  st.ChainID
					, st.SupplierID
					, s.storeid
					, st.ProductID,Qty
					, TransactionTypeID
					, datename(W,SaleDateTime)+ ''Draw'' as "wDay"
					, c.ChainIdentifier
					, sup.SupplierIdentifier
					, S.StoreIdentifier AS StoreNumber
					,s.LegacySystemStoreIdentifier as LegacyStoreIdentifier
					, ProductName AS TitleName
					
					
					INTO ##SalesReportByTitleDraws
					FROM  dbo.Storetransactions_forward st with(nolock) 
					INNER JOIN dbo.suppliers sup with(nolock)  ON sup.supplierid=st.supplierid 
					INNER JOIN dbo.products p with(nolock)  ON p.productid=st.productid 
					INNER JOIN dbo.Chains c with(nolock)  on st.ChainID=c.ChainID
					INNER JOIN dbo.Stores s with(nolock)  ON s.StoreID=st.StoreID and s.chainid=c.chainid
					INNER JOIN dbo.Addresses a with(nolock)  ON a.OwnerEntityID=s.StoreID
					left join (Select distinct ChainId, SupplierId, EntityIDToInvoice, BillingControlDay 
									from DataTrue_Main.dbo.BillingControl with(nolock) 
								   ) bc  on bc.EntityIDToInvoice=sup.supplierid and bc.chainid=st.chainid
					WHERE TransactionTypeID in (29)
					and st.supplierid='''+@supplierid+''''
		
		IF(@ChainID<>'-1')   
			SET @strquery = @strquery +'and c.ChainIdentifier='''+@ChainID+''''
			
		IF(@Title<>'-1')   
			SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''	
									   
		IF(@State<>'-1')    
			SET @strquery = @strquery +' and a.State like '''+@State+''''
										
		IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) as Date) >= CAST(''' + @StartDate +  ''' AS DATE)'
			
		IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) as Date) <= CAST(''' +@EndDate + ''' AS DATE)'
	
	print(@strquery)					
	EXEC(@strquery)
		
		
		
		/*-------Get the data into tmp table for POS---------*/					
		IF object_id('tempdb.dbo.##SalesReportByTitlePOS') is not null
		BEGIN
		   DROP TABLE ##SalesReportByTitlePOS;
		END
		
		SET @strquery='select  st.ChainID
		                , st.SupplierID
		                , s.storeid
		                , st.ProductID,Qty,st.TransactionTypeID
						, CAST(st.RuleCost AS MONEY) AS  CostToStore4Wholesaler
						, datename(W,SaleDateTime)+ ''POS'' as POSDay
						, c.ChainIdentifier
					    , sup.SupplierIdentifier
					    , S.StoreIdentifier AS StoreNumber
					    ,s.LegacySystemStoreIdentifier as LegacyStoreIdentifier
					    , ProductName AS TitleName
					    
						INTO ##SalesReportByTitlePOS
						FROM dbo.Storetransactions st with(nolock) 
						INNER JOIN dbo.transactiontypes tt with(nolock)  on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
						INNER JOIN dbo.suppliers sup with(nolock)  ON sup.supplierid=st.supplierid 
						INNER JOIN dbo.products p with(nolock)  ON p.productid=st.productid 
						INNER JOIN dbo.Chains c  with(nolock) on st.ChainID=c.ChainID
						INNER JOIN dbo.Stores s  with(nolock) ON s.StoreID=st.StoreID and s.chainid=c.chainid	
						INNER JOIN dbo.Addresses a with(nolock)  ON a.OwnerEntityID=s.StoreID
						left join (Select distinct ChainId, SupplierId, EntityIDToInvoice, BillingControlDay 
									from DataTrue_Main.dbo.BillingControl with(nolock) 
								   ) bc  on bc.EntityIDToInvoice=sup.supplierid and bc.chainid=st.chainid				
						WHERE 1=1 and st.supplierid='''+@supplierid+''''
		
		IF(@ChainID<>'-1')   
			SET @strquery = @strquery +'and c.ChainIdentifier='''+@ChainID+''''
			
		IF(@Title<>'-1')   
			SET @strquery = @strquery +' and p.productname like '''+@Title+'%'''
										   
		IF(@State<>'-1')    
			SET @strquery = @strquery +' and a.State like '''+@State+''''
										
		IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery = @strquery +' and cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) as date) >= CAST(''' + @StartDate +  ''' AS DATE)'
			
		IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
			SET @strquery = @strquery +' AND cast(dbo.GetWeekEnd_TimeOutFix(SaleDateTime,bc.BillingControlDay) as date)  <= CAST(''' + @EndDate + ''' AS DATE)'
		
		print(@strquery)				
		EXEC(@strquery)
		
		
		/*----Get the final data into final tmp table(Draws and POS)----*/		
		IF object_id('tempdb.dbo.##SalesReportByStateFinalData') is not null
			BEGIN
				DROP TABLE ##SalesReportByStateFinalData
			END
		
		SET @strquery='Select distinct 
						   tmpdraws.MondayDraw
						 , tmpdraws.TuesdayDraw
						 , tmpdraws.WednesdayDraw
						 , tmpdraws.ThursdayDraw
						 , tmpdraws.FridayDraw
						 , tmpdraws.SaturdayDraw
						 , tmpdraws.SundayDraw
						 , tmpPOS.ChainID
						 , tmpPOS.SupplierID
						 , tmpPOS.StoreID
						 , tmpPOS.ProductID
						 , tmpPOS.MondayPOS
						 , tmpPOS.TuesdayPOS
						 , tmpPOS.WednesdayPOS
						 , tmpPOS.ThursdayPOS
						 , tmpPOS.CostToStore4Wholesaler
						 , tmpPOS.CostToStore4Wholesaler AS CostToWholesaler
						 , tmpPOS.FridayPOS
						 , tmpPOS.SaturdayPOS
						 , tmpPOS.SundayPOS
						 , tmpPOS.ChainIdentifier
					     , tmpPOS.SupplierIdentifier AS Wholesaleridentifier
					     ,tmpPOS.LegacyStoreIdentifier  
					     , tmpPOS.StoreNumber
					     , tmpPOS.TitleName
						 --, CAST(NULL as nvarchar(50)) as "chainidentifier"
						 --, CAST(NULL as nvarchar(50)) as "Wholesaleridentifier"
						 --, CAST(NULL as nvarchar(50)) as "StoreNumber"
						 --, CAST(NULL as nvarchar(250)) as "TitleName"
						
						into ##SalesReportByTitleFinalData 
						from
						( select * from 
							(SELECT * from ##SalesReportByTitlePOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						LEFT JOIN
						(select * FROM 
							(SELECT * from ##SalesReportByTitleDraws ) p
							 pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) 
							 as Draw_eachday
						) tmpdraws
						
						on tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'
		
		 print(@strquery)			
	   EXEC(@strquery)
		

    	/*----UPDATE THE TEMP TABLE----- */
	   /*SET @strquery='update f set 
	   
						f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid),
						
						f.Wholesaleridentifier=(SELECT DISTINCT Supplieridentifier from dbo.Suppliers where SupplierID=f.supplierid),
						
						f.StoreNumber=(SELECT DISTINCT StoreIdentifier from dbo.Stores where storeid=f.storeid),
						
						f.TitleName=(SELECT DISTINCT  productname  from dbo.Products where ProductID=f.productid )
						
						from ##SalesReportByTitleFinalData  f'
				
		EXEC(@strquery)*/
				
				
		SET @sqlQueryNew=' select DISTINCT 
							chainidentifier as ChainID,
							Wholesaleridentifier as WholesalerID,
							--chainidentifier + '''' +StoreNumber AS [StoreID],
							LegacyStoreIdentifier as [StoreID],
							cast(StoreNumber as integer) AS StoreNumber,
							TitleName,
							Sum(ISNULL([mondayPOS],0)) as MonSales,
							sum(ISNULL([tuesdayPOS],0)) as TueSales,
							sum(ISNULL([wednesdayPOS],0)) as WedSales, 
							sum(ISNULL([thursdayPOS],0)) as ThurSales,
							sum(ISNULL([fridayPOS],0)) as FriSales,
							sum(ISNULL([saturdayPOS],0)) as SatSales,
							sum(ISNULL([sundayPOS],0)) AS SunSales,
							Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS Draws,
							Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS Returns,
							0 AS Shortages,
							Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) AS NetSales,
		                    Sum((ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) - (ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) * 
							(ISNULL([CostToStore4Wholesaler],0)-ISNULL([CostToWholesaler],0))) AS Profit
		                    
							
							FROM ##SalesReportByTitleFinalData 
							
							GROUP BY 
							    chainidentifier,
							    TitleName,
							    Wholesaleridentifier,
							      StoreNumber, LegacyStoreIdentifier
							     
							    
						    ORDER BY  chainidentifier ,StoreNumber '				
		print(@sqlQueryNew)
		EXEC(@sqlQueryNew)				
						    
		IF object_id('tempdb.dbo.##SalesReportByTitleFinalData') is not null
			BEGIN
				DROP TABLE ##SalesReportByTitleFinalData;
			END
		IF object_id('tempdb.dbo.##SalesReportByTitleDraws') is not null
			BEGIN
				DROP TABLE ##SalesReportByTitleDraws;
			END
			
		IF object_id('tempdb.dbo.##SalesReportByTitlePOS') is not null
			BEGIN
				DROP TABLE ##SalesReportByTitlePOS;
			END
END
GO
