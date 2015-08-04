USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DeliveryActivityCHN_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dbo.chains_migration where chainid=40393
--Exec [amb_DeliveryActivityCHN_Beta] 'SV','40393','CA','Valencia','','1900/01/01','StoreID asc',1,25,0
--Exec [amb_DeliveryActivityCHN_Beta] '42493','BN','%','%','','1900/01/01','StoreID asc',1,25,0
--Exec [amb_DeliveryActivityCHN_Beta] 'KNG','42501','-1','-1','','11/11/2012'
CREATE procedure [dbo].[amb_DeliveryActivityCHN_Beta]
(
@ChainIdentifier varchar(10),
@ChainID varchar(10),
@State varchar(10),
@City varchar(20),
@StoreNumber varchar(20),
@WeekEnd varchar(20) 
)
as 
BEGIN

declare @sqlQueryNew varchar(8000)
declare @strquery varchar(8000)	

if object_id('tempdb.dbo.##tempDeliveryActivityCHN') is not null
	DROP TABLE ##tempDeliveryActivityCHN;
			
SET @strquery = 'select st.ChainID,
						st.SupplierID,
						st.storeid,
						st.ProductID,
						Qty,
						TransactionTypeID,
						datename(W,SaleDateTime)+ ''Draw'' as "wDay" 
						
						into ##tempDeliveryActivityCHN

				   FROM DataTrue_Report.dbo.Storetransactions_forward st
						INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
						INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

						where TransactionTypeID in (29)
						and st.ChainId=''' + @ChainID + '''
						and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
if(@City<>'-1')
	SET @strquery = @strquery + ' and a.City like ''' + @City + ''''							   

if(@State<>'-1')
	SET @strquery = @strquery + ' and	a.State like ''' + @State + ''''

if(CAST(@WeekEnd as DATE) > CAST('1900-01-01' as DATE))
	SET @strquery = @strquery + ' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) = ''' + convert(VARCHAR, +@WeekEnd, 101) + ''''

EXEC (@strquery)

			--Get the data into tmp table for POS	

if object_id('tempdb.dbo.##tempDeliveryActivityPOSCHN') is not null
	DROP TABLE ##tempDeliveryActivityPOSCHN;
	
SET @strquery = 'select st.ChainID,
						st.SupplierID,
						st.storeid,
						st.ProductID,
						Qty,
						st.TransactionTypeID,
						datename(W,SaleDateTime)+ ''POS'' as "POSDay"
						
						into ##tempDeliveryActivityPOSCHN

				   FROM DataTrue_Report.dbo.Storetransactions st
						INNER JOIN DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
						INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
						INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

						where st.ChainId=''' + @ChainID + '''
						and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''

if(@City<>'-1')
	SET @strquery = @strquery + ' and a.City like ''' + @City + ''''							   

if(@State<>'-1')
	SET @strquery = @strquery + ' and	a.State like ''' + @State + ''''

if(CAST(@WeekEnd as DATE ) > CAST('1900-01-01' as DATE))
	SET @strquery = @strquery + ' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID) = ''' + convert(VARCHAR, +@WeekEnd, 101) + ''''
	
EXEC (@strquery)			

			--Get the final data into final tmp table

if object_id('tempdb.dbo.##tempDeliveryActivityCHNFinalData') is not null
	DROP TABLE ##tempDeliveryActivityCHNFinalData
	
SET @strquery = 'Select distinct tmpdraws.*,
						tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
						tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
						CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",
						CAST(NULL as nvarchar(50)) as "StoreName",
						CAST(NULL as nvarchar(50)) as "StoreNumber",
						CAST(NULL as nvarchar(100)) as "Address",
						CAST(NULL as nvarchar(50)) as "City",
						CAST(NULL as nvarchar(50)) as "State",
						CAST(NULL as nvarchar(50)) as "ZipCode",
						CAST(NULL as nvarchar(50)) as "WholesalerName",
						CAST(NULL as nvarchar(50)) as "BiPad",
						CAST(NULL as nvarchar(225)) as "TitleName",
						CAST(NULL as MONEY) as "CostToStore",
						CAST(NULL as money) as "SuggRetail"
						into ##tempDeliveryActivityCHNFinalData
						from
						(select * FROM 
						(SELECT * from ##tempDeliveryActivityCHN ) p
						pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
						(SELECT * from ##tempDeliveryActivityPOSCHN)p
						pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
						) as p1
						) tmpPOS 
						on tmpdraws.chainid=tmpPOS.chainid and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid and tmpdraws.productid=tmpPOS.productid'
EXEC (@strquery)


--Update the required fields
SET @strquery = 'update f set 
					f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
					f.StoreName=(select distinct StoreName from dbo.Stores  where StoreID=f.StoreID),
					f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
					f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers where SupplierID=f.supplierid),
					f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=f.productid),
					f.TitleName=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),
					f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
					and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
					f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
					and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3)
					from ##tempDeliveryActivityCHNFinalData f'
EXEC (@strquery)		 
						 
SET @sqlQueryNew = ' select distinct (''Store #: '' + StoreNumber + ''/n Location: '' 
										+ storename + '', '' + address + '', '' + City + '', 
										'' + State + '', '' + zipcode ) as StoreInfo,
										wholesalername,
										LegacySystemStoreIdentifier as StoreID,
										bipad,
										TitleName,
										storename,
										StoreNumber,
										address,
										City,
										State,
										zipcode,
										ISNULL(costtostore,0) AS costtostore,
										ISNULL(suggretail,0) AS suggretail,
										ISNULL(mondaydraw,0) as Mon,
										ISNULL(Tuesdaydraw,0) as Tue,
										ISNULL(wednesdaydraw,0) as Wed,
										ISNULL(thursdaydraw,0) as Thur,
										ISNULL(fridaydraw,0) as Fri,
										ISNULL(saturdaydraw,0) as Sat,
										ISNULL(sundaydraw,0) as Sun,
										ISNULL(mondaydraw,0)-ISNULL(mondayPOS,0) as MonR,
										ISNULL(tuesdaydraw,0)-ISNULL(tuesdayPOS,0) as TueR,
										ISNULL(wednesdaydraw,0)-ISNULL(wednesdayPOS,0) as WedR,
										ISNULL(thursdaydraw,0)-ISNULL(thursdayPOS,0) as ThurR,
										ISNULL(fridaydraw,0)-ISNULL(fridayPOS,0) as FriR,
										ISNULL(saturdaydraw,0)-ISNULL(saturdayPOS,0) as SatR,
										ISNULL(sundaydraw,0)-ISNULL(sundayPOS,0) as SunR,
										''0'' AS MonS,
										''0'' AS TueS, 
										''0'' AS WedS,
										''0'' AS ThurS, 
										''0'' AS FriS,
										''0'' AS SatS, 
										''0'' AS SunS,
										ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+
										ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0) AS Draws,
										ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+
										ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+
										ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) AS Returns,
										0 AS Shortages,
										(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+
										ISNULL(saturdayPOS,0)+isnull(sundayPOS,0)) AS NetSales, 
										(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+
										ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0)) AS Profit
										
										from ##tempDeliveryActivityCHNFinalData';
		
		SET @sqlQueryNew= @sqlQueryNew + ' Order By wholesalername,bipad'
		
		EXEC (@sqlQueryNew)			
END
GO
