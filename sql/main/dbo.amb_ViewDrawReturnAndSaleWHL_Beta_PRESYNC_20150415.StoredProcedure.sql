USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewDrawReturnAndSaleWHL_Beta_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--0(new) exec amb_ViewDrawReturnAndSaleWHL_Beta 'BN','-1','-1','2908','1900-01-01','1900-01-01','Wolfe','28943','[TTL Returns] DESC',1,25,0
--1(old) exec [amb_ViewDrawReturnAndSaleWHL] 'BN','-1','-1','','02/02/2005','02/02/2010','ENT','24178'
--2(mix) exec [amb_ViewDrawReturnAndSaleWHL_Beta] 'DQ','-1','-1','','09/15/2013','09/22/2013','CLL','24164'
-- exec [amb_ViewDrawReturnAndSaleWHL_Beta] 'CF','-1','-1','5401','03/03/2014','03/30/2014','WR651','26582'

-- exec [amb_ViewDrawReturnAndSaleWHL_Beta] '-1','-1','-1','','01/05/2015','01/11/2015','WNA','24269'

CREATE procedure [dbo].[amb_ViewDrawReturnAndSaleWHL_Beta_PRESYNC_20150415]
(
	@ChainID varchar(10),
	@State varchar(20),
	@City varchar(20),
	@StoreNumber varchar(10),
	@StartDate varchar(20),
	@EndDate varchar(20) ,
	@SupplierIdentifier varchar(10),
	@SupplierID varchar(10)
	
)
AS

BEGIN
	
	Declare @sqlQueryNew varchar(8000)
	Declare @strquery varchar(8000)
	
	
			--Get the data in to tmp table for draws
			IF object_id('tempdb.dbo.##tempViewDrawReturnAndSaleDraws') is not null
				BEGIN
					Drop Table ##tempViewDrawReturnAndSaleDraws;
				END
		
			SET @strquery='select  st.ChainID,
							st.SupplierID,
							s.LegacySystemStoreIdentifier as storeid,
							st.ProductID,
							Qty,
							TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempViewDrawReturnAndSaleDraws
							from dbo.Storetransactions_forward st WITH (NOLOCK) 
							inner JOIN dbo.Chains c  WITH (NOLOCK) on st.ChainID=c.ChainID
							INNER JOIN dbo.Stores s  WITH (NOLOCK) ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a  WITH (NOLOCK) ON a.OwnerEntityID=st.StoreID 
							LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ST.SupplierID AND BC.ChainID = C.ChainID
							
							where TransactionTypeID in (29) 
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and st.supplierid=' + @SupplierID 
			
			IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
			
			IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''	
			
			IF(@State<>'-1')    
				SET @strquery = @strquery +' and	a.State like '''+@State+''''
									
			IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' and  CAST(dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay) AS DATE) >= cast(''' +@StartDate+  ''' as date)'
		
			IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND  CAST(dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay) AS DATE) <= cast(''' +@EndDate + ''' as date)'
			
			EXEC(@strquery)		
			print(@strquery)	
			--Get the data into tmp table for POS
			
			IF object_id('tempdb.dbo.##tempViewDrawReturnAndSalePOS') is not null
				BEGIN
					DROP TABLE ##tempViewDrawReturnAndSalePOS
				END	
					
			SET @strquery='select  st.ChainID,
							st.SupplierID,
							sup.SupplierName,
							sup.SupplierIdentifier,
							s.LegacySystemStoreIdentifier as storeid,
							S.StoreName,
							S.StoreIdentifier,
							C.ChainIdentifier,
							st.ProductID,
							A.Address1,
							A.City,
							A.State,
							A.PostalCode,
							S.StoreID AS StoreIDNew,
							st.Qty,
							st.TransactionTypeID,
							CAST(RuleCost as MONEY) as CostToStore,
							CAST(RuleRetail as MONEY) as SuggRetail,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempViewDrawReturnAndSalePOS						
							
							from dbo.Storetransactions st WITH (NOLOCK) 
							inner join dbo.transactiontypes tt  WITH (NOLOCK) on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							inner JOIN dbo.Chains c  WITH (NOLOCK) on st.ChainID=c.ChainID
							INNER JOIN dbo.Suppliers Sup  WITH (NOLOCK) ON Sup.SupplierID=st.SupplierID
							INNER JOIN dbo.Stores s  WITH (NOLOCK) ON s.StoreID=st.StoreID
							INNER JOIN dbo.Addresses a  WITH (NOLOCK) ON a.OwnerEntityID=st.StoreID 										
							LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ST.SupplierID AND BC.ChainID = C.ChainID
							
							where 1=1
							and st.supplierid=' + @SupplierID + '
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
			
			IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''							
			
			IF(@City<>'-1')   
				SET @strquery = @strquery +' and a.City like '''+@City+''''							   

			IF(@State<>'-1')    
				SET @strquery = @strquery +' and a.State like '''+@State+''''
										
			IF(CAST( @StartDate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' and  CAST(dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay) AS DATE) >= cast('''  +@StartDate +  ''' as date)'
				
			IF(CAST( @EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND CAST(dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay) AS DATE) <= cast(''' +@EndDate + ''' as date)'
				
			EXEC(@strquery)		
			print(@strquery)	
			
			IF object_id('tempdb.dbo.##tempViewDrawReturnAndSaleFinalData') is not null
				BEGIN
					DROP TABLE ##tempViewDrawReturnAndSaleFinalData
			    END	
			
			SET @strquery='Select distinct tmpdraws.MondayDraw,
							tmpdraws.TuesdayDraw,
							tmpdraws.WednesdayDraw,
							tmpdraws.ThursdayDraw,
						    tmpdraws.FridayDraw,
						    tmpdraws.SaturdayDraw,
						    tmpdraws.SundayDraw,
						    tmpPOS.ChainID,
							tmpPOS.SupplierID,
							tmpPOS.storeid,
							tmpPOS.ProductID,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							tmpPOS.CostToStore,tmpPOS.SuggRetail,
							tmpPOS.CostToStore as CostToStore4Wholesaler,
							tmpPOS.CostToStore as CostToWholesaler,
							tmpPOS.SupplierName as WholesalerName,
							tmpPOS.StoreIdentifier as StoreNumber,
							tmpPOS.ChainIdentifier as Chainidentifier,
							tmpPOS.StoreName as StoreName,
							tmpPOS.Address1 as Address,
							tmpPOS.City as City,
							tmpPOS.State as State,
							tmpPOS.PostalCode as ZipCode,
							tmpPOS.SupplierIdentifier as Supplieridentifier,
							tmpPOS.StoreIDNew as StoreIDNew,
							CAST(NULL as nvarchar(250)) as Title,
							CAST(NULL as nvarchar(50)) as BiPad
							
							into ##tempViewDrawReturnAndSaleFinalData 
							FROM							
							( SELECT * FROM 
								(SELECT * FROM ##tempViewDrawReturnAndSalePOS)p
								 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
								 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								) as p1
							) tmpPOS 
							LEFT join
							(SELECT * FROM 
								(SELECT * from ##tempViewDrawReturnAndSaleDraws ) p
								 pivot( sum(Qty) for  wDay in
								  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
								  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
							) tmpdraws
							
							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid '

		    EXEC(@strquery)
			print(@strquery)	
			
			--Update the required fields
			SET @strquery='update f set 
						f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=f.productid and ProductIdentifierTypeID in(2,8)),
						f.title=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid)
				from ##tempViewDrawReturnAndSaleFinalData f'
		
		 EXEC(@strquery)
		print(@strquery)	
				
				--Return the Data
		
									
		 SET @sqlQueryNew='select  (f.StoreID +'', Site # '' + StoreNumber + ''\n Location: '' + address + '', '' + City + '', '' + State + '', '' + zipcode ) as StoreInfo,
										WholesalerName,
										f.StoreID,
										StoreNumber,
										chainidentifier as ChainID,
										StoreName,
										Address,
										City,
										State,
										ZipCode,
										Bipad,
										Title,
										CostToStore4Wholesaler,
										CostToWholesaler,
										CostToStore,
										SuggRetail,	
										SUV.SupplierAccountNumber,		
										Sum(ISNULL(mondaydraw,0)) as MonDraws,
										Sum(ISNULL(tuesdaydraw,0)) as TueDraws,
										Sum(ISNULL(wednesdaydraw,0)) as WedDraws,
										Sum(ISNULL(thursdaydraw,0)) as ThurDraws,
										Sum(ISNULL(fridaydraw,0)) as FriDraws,
										Sum(ISNULL(saturdaydraw,0)) as SatDraws,
										Sum(ISNULL(sundaydraw,0)) as SunDraws,
										ISNULL(sum(ISNULL(mondaydraw,0)-ISNULL(mondayPOS,0)),0) as MonReturns,
										ISNULL(sum(ISNULL(tuesdaydraw,0)-ISNULL(tuesdayPOS,0)),0) as TueReturns,
										ISNULL(sum(ISNULL(wednesdaydraw,0)-ISNULL(wednesdayPOS,0)),0) as WedReturns,
										ISNULL(sum(ISNULL(thursdaydraw,0)-ISNULL(thursdayPOS,0)),0) as ThurReturns,
										ISNULL(sum(ISNULL(fridaydraw,0)-ISNULL(fridayPOS,0)),0) as FriReturns,
										ISNULL(sum(ISNULL(saturdaydraw,0)-ISNULL(saturdayPOS,0)),0) as SatReturns,
										ISNULL(sum(ISNULL(sundaydraw,0)-ISNULL(sundayPOS,0)),0) as SunReturns,						
										0 AS MonShort,
										0 AS TueShort, 
										0 AS WedShort,
										0 AS ThurShort, 
										0 AS FriShort,
										0 AS SatShort, 
										0 AS SunShort,						
										Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS [TTL Draws],
										
										Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS [TTL Returns],
										0 AS [TTL Shortages],
										
										ISNULL(Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)),0) AS NetSales, 
										
										Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))*(-[CostToWholesaler]+[CostToStore4Wholesaler])) AS Profit,
										case when Count(bipad)=0 then 0 else 
										sum(ISNULL(MondayPOS,0))/Count(bipad) end AS AvgMonSale,
										ISNULL(Cast(mondaydraw AS smallint),0) AS MonBase,
										case when Count(bipad)=0 then 0 else 							
										sum(ISNULL(tuesdayPOS,0))/Count(bipad) end AS AvgTueSale,
										ISNULL(Cast(tuesdaydraw AS smallint),0) AS TueBase, 
										case when Count(bipad)=0 then 0 else 							
										sum(ISNULL(wednesdayPOS,0))/Count(bipad) end AS AvgWedSale,
										ISNULL(Cast(wednesdaydraw AS smallint),0) AS WedBase,		
										case when Count(bipad)=0 then 0 else 					
										sum(ISNULL(thursdayPOS,0))/Count(bipad) end AS AvgThurSale,
										ISNULL(Cast(thursdaydraw AS smallint),0) AS ThurBase,
										
										case when Count(bipad)=0 then 0 else 							
										sum(ISNULL(fridayPOS,0))/Count(bipad) end AS AvgFriSale,								
										ISNULL(Cast(fridaydraw AS smallint),0) AS FriBase, 
										
										case when Count(bipad)=0 then 0 else 							
										ISNULL(sum(ISNULL(saturdayPOS,0))/Count(bipad),0) end AS AvgSatSale,				
										ISNULL(Cast(saturdaydraw AS smallint),0) AS SatBase,	
										
										case when Count(bipad)=0 then 0 else 						
										ISNULL(sum(ISNULL(sundayPOS,0))/Count(bipad),0) end AS AvgSunSale,
										ISNULL(Cast(sundaydraw AS smallint),0) AS SunBase,							
										ISNULL(Count(bipad),0) AS NoOfWeeksInRange
															
										FROM ##tempViewDrawReturnAndSaleFinalData f
										left JOIN StoresUniqueValues SUV ON SUV.StoreID=f.StoreIDNew AND SUV.SupplierID=f.SupplierID
										
										GROUP BY 
										chainidentifier,
										supplieridentifier,
										wholesalername,
										SUV.SupplierAccountNumber,
										f.StoreID,
										productid,
										storename,
										StoreNumber,
										address,
										City,
										State,
										zipcode,
										wholesalername,
										bipad,
										title,
										CostToStore4Wholesaler,
										CostToWholesaler,
										costtostore,
										suggretail,
										mondaydraw,
										tuesdaydraw,
										wednesdaydraw,
										thursdaydraw,
										fridaydraw,
										saturdaydraw,
										sundaydraw ,
										mondayPOS ,
										tuesdayPOS ,
										wednesdayPOS,
										thursdayPOS ,
										fridayPOS,
										saturdayPOS,
										sundayPOS 
										
										Order BY f.storeid,StoreNumber,title '
					
print(@sqlQueryNew)
			EXEC(@sqlQueryNew)
			
			IF object_id('tempdb.dbo.##tempViewDrawReturnAndSaleDraws') is not null
				BEGIN
					Drop Table ##tempViewDrawReturnAndSaleDraws;
				END
	   IF object_id('tempdb.dbo.##tempViewDrawReturnAndSalePOS') is not null
				BEGIN
					DROP TABLE ##tempViewDrawReturnAndSalePOS
				END	
					
		IF object_id('tempdb.dbo.##tempViewDrawReturnAndSaleFinalData') is not null
				BEGIN
					DROP TABLE ##tempViewDrawReturnAndSaleFinalData
			    END				
					
END
GO
