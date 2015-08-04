USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewDeliveryProfitDetailsWHLS_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [amb_ViewDeliveryProfitDetailsWHLS] 'BN','-1','-1','','04/15/2012','ENT','24178'
-- exec amb_ViewDeliveryProfitDetailsWHLS_Beta 'BN','NY','NEW HARTFORD','','1900-01-01','Wolfe','28943','Title ASC',1,25,0

-- exec amb_ViewDeliveryProfitDetailsWHLS_Beta 'DQ','-1','-1','','1900-01-01','CLL','24164'

CREATE procedure [dbo].[amb_ViewDeliveryProfitDetailsWHLS_Beta]
(
	@ChainID varchar(10),
	@State varchar(10),
	@City varchar(30),
	@StoreNumber varchar(10),
	@Weekend varchar(25),
	@SupplierIdentifier varchar(10),
	@SupplierID varchar(10)
)

AS
BEGIN
Declare @strquery varchar(8000)
Declare @sqlQueryNew varchar(8000)

		IF object_id('tempdb.dbo.##tempViewDeliveryProfitDetailsDraws') is not null		
	
		--Get the data in to tmp table for draws
				BEGIN
					drop table ##tempViewDeliveryProfitDetailsDraws;
				END
			
			SET @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempViewDeliveryProfitDetailsDraws
							from DataTrue_Report.dbo.Storetransactions_forward st
							inner JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
							where TransactionTypeID in (29) 
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and st.supplierid=' + @SupplierID 
						
		IF(@ChainID<>'-1')					
			SET @strquery += ' and c.ChainIdentifier='''+@ChainID+''''
		
		IF(@City<>'-1')   
			SET @strquery += ' and a.City like '''+@City+''''	
		
		IF(@State<>'-1')    
			SET @strquery += ' and	a.State like '''+@State+''''
								
		IF(CAST(@Weekend AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery += ' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)+7
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) = ''' + convert(varchar, +@Weekend,101) +  ''''
	
		
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
						
						from DataTrue_Report.dbo.Storetransactions st
						inner join DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid 
						and tt.buckettype=1
						inner JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
						INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
						INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 										
						
						where 1=1
						and st.supplierid=' + @SupplierID + '
						and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
		
		IF(@ChainID<>'-1')					
			SET @strquery += ' and c.ChainIdentifier='''+@ChainID+''''							
		
		IF(@City<>'-1')   
			SET @strquery += ' and a.City like '''+@City+''''							   

		IF(@State<>'-1')    
			SET @strquery += ' and	a.State like '''+@State+''''
									
		IF(CAST(@Weekend AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @strquery += ' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)+7
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) = ''' +  convert(varchar, +@Weekend,101) +  ''''
			
						
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
	   
SET @sqlQueryNew='select  (''Store #: '' + StoreNumber + ''/n Location: '' 
						+ storename + '', '' + address + '', '' + City + '', 
						'' + State + '', '' + zipcode ) as StoreInfo,
						WholeSalerName,
						SupplierIdentifier as WholesalerID,
						LegacySystemStoreIdentifier as storeid,
						StoreNumber,
						storename,
						address,
						City,
						State,
						zipcode,
						bipad,
						title,
						0 as CostToStore4Wholesaler,
						0 as CostToWholesaler,
						ISNULL(costtostore,0) AS costtostore,
						ISNULL(suggretail,0) AS suggretail,
						sum(ISNULL(mondaydraw,0)) as Mon,
						sum(ISNULL(tuesdaydraw,0)) as Tue,
						sum(ISNULL(wednesdaydraw,0)) as Wed,
						sum(ISNULL(thursdaydraw,0)) as Thur,
						sum(ISNULL(fridaydraw,0)) as Fri,
						sum(ISNULL(saturdaydraw,0)) as Sat,sum(ISNULL(sundaydraw,0)) as Sun,
						sum(ISNULL(mondaydraw,0)-ISNULL(mondayPOS,0)) as MonR,
						sum(ISNULL(tuesdaydraw,0)-ISNULL(tuesdayPOS,0)) as TueR,
						sum(ISNULL(wednesdaydraw,0)-ISNULL(wednesdayPOS,0)) as WedR,
						sum(ISNULL(thursdaydraw,0)-ISNULL(thursdayPOS,0)) as ThurR,
						sum(ISNULL(fridaydraw,0)-ISNULL(fridayPOS,0)) as FriR,
						sum(ISNULL(saturdaydraw,0)-ISNULL(saturdayPOS,0)) as SatR,
						sum(ISNULL(sundaydraw,0)-ISNULL(sundayPOS,0)) as SunR,
						''0'' AS MonS,
						''0'' AS TueS, 
						''0'' AS WedS,
						''0'' AS ThurS, 
						''0'' AS FriS,
						''0'' AS SatS, 
						''0'' AS SunS,						
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS [Draws],
						Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+
						ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS [Returns],
						0 AS [Shortages],
						Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+
						ISNULL(sundayPOS,0)) AS NetSales, 
						Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+
						ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0))) AS Profit				

						FROM  ##tempViewDeliveryProfitDetailsFinalData
						
						GROUP BY LegacySystemStoreIdentifier,supplieridentifier,wholesalername,StoreID,
						productid,storename,StoreNumber,address,City,State,zipcode,wholesalername,bipad,
						title,costtostore,suggretail,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,
						fridaydraw,saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,
						fridayPOS,saturdayPOS,sundayPOS 
						
						Order By LegacySystemStoreIdentifier,title '		

		
		EXEC(@sqlQueryNew)		
END
GO
