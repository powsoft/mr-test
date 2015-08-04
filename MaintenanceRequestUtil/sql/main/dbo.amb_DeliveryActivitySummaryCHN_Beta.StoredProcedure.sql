USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DeliveryActivitySummaryCHN_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from ##tempDeliveryActivityCHNSummaryFinalData
--exec [amb_DeliveryActivitySummaryCHN] 'BN','42493','IA','SIOUX CITY','','1900/01/01'
--EXEC amb_DeliveryActivitySummaryCHN_Beta 'DQ','62362','-1','-1','','1900/01/01'
CREATE procedure [dbo].[amb_DeliveryActivitySummaryCHN_Beta]
(
	@ChainIdentifier varchar(10),
	@ChainID varchar(10),
	@State varchar(20),
	@City varchar(20),
	@StoreNumber varchar(10),
	@WeekEndDate varchar(20)
)
as 
BEGIN
	Declare @sqlQueryNew varchar(8000)
	Declare @strquery varchar(8000)
	
	IF object_id('tempdb.dbo.##tempDeliveryActivitySummaryCHN') is not null
		DROP TABLE  ##tempDeliveryActivitySummaryCHN;
	
	SET @strquery='select distinct st.ChainID,
	                               st.SupplierID,
	                               st.storeid,
	                               st.ProductID,
	                               Qty,
								   TransactionTypeID,
								   datename(W,SaleDateTime)+ ''Draw'' as "wDay"
								    
								into ##tempDeliveryActivitySummaryCHN

						   FROM DataTrue_Report.dbo.Storetransactions_forward st
								INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
								INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

								where TransactionTypeID in (29)
								AND st.ChainId='''+@ChainID+'''
								AND s.StoreIdentifier like ''%'+@StoreNumber+'%'''
	IF(@City<>'-1')   
		SET @strquery = @strquery +' AND a.City like '''+@City+''''							   

	IF(@State<>'-1')    
		SET @strquery = @strquery +' AND	a.State like '''+@State+''''

	IF(Cast(@WeekEndDate as date) <> Cast('1900-01-01' as date))
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
											FROM BillingControl BC WHERE BC.ChainID = st.ChainID
											AND BC.EntityIDToInvoice = st.SupplierID) = ''' + convert(varchar, +@WeekEndDate,101) +  ''''

	EXEC(@strquery)

	--Get the data into tmp table for POS	

	IF object_id('tempdb.dbo.##tempDeliveryActivityPOSSummaryCHN') is not null
		DROP TABLE  ##tempDeliveryActivityPOSSummaryCHN;

	SET @strquery='select distinct st.ChainID,
								st.SupplierID,
								st.storeid,
								st.ProductID,
								Qty,
								st.TransactionTypeID,
								datename(W,SaleDateTime)+ ''POS'' as "POSDay"
								
								into ##tempDeliveryActivityPOSSummaryCHN

						   FROM DataTrue_Report.dbo.Storetransactions st
								INNER JOIN DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid AND tt.buckettype=1
								INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
								INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

								where st.ChainId='''+@ChainID+''' 
								AND s.StoreIdentifier like ''%'+@StoreNumber+'%'''

	IF(@City<>'-1')   
		SET @strquery = @strquery +' AND a.City like '''+@City+''''							   

	IF(@State<>'-1')    
		SET @strquery = @strquery +' AND	a.State like '''+@State+''''

	IF(Cast(@WeekEndDate as date ) <> Cast('1900-01-01' as Date))
		SET @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
											FROM BillingControl BC WHERE BC.ChainID = st.ChainID
											AND BC.EntityIDToInvoice = st.SupplierID) = ''' + convert(varchar, +@WeekEndDate,101) +  ''''
	

	EXEC(@strquery)			

	--Get the final data into final tmp table

	IF object_id('tempdb.dbo.##tempDeliveryActivityCHNSummaryFinalData') is not null
		DROP TABLE  ##tempDeliveryActivityCHNSummaryFinalData

	SET @strquery='Select distinct tmpdraws.*,
				tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
				tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
				CAST(NULL as nvarchar(50)) as "StoreIdentifier",
				CAST(NULL as nvarchar(100)) as "Address",
				CAST(NULL as nvarchar(50)) as "State",
				CAST(NULL as nvarchar(50)) as "ZipCode",
				CAST(NULL as nvarchar(50)) as "WholesalerName",
				CAST(NULL as MONEY) as "CostToStore",
				CAST(NULL as money) as "SuggRetail"
				into ##tempDeliveryActivityCHNSummaryFinalData
				from
				(select * FROM 
				(SELECT * from ##tempDeliveryActivitySummaryCHN ) p
				pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
				) tmpdraws
				join
				( select * from 
				(SELECT * from ##tempDeliveryActivityPOSSummaryCHN)p
				pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
				) as p1
				) tmpPOS 
				on tmpdraws.chainid=tmpPOS.chainid AND tmpdraws.supplierid=tmpPOS.supplierid
				AND tmpdraws.storeid=tmpPOS.storeid AND tmpdraws.productid=tmpPOS.productid'

	EXEC(@strquery)


	--Update the required fields
	SET @strquery='update f SET 
					f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers where SupplierID=f.supplierid),
					f.StoreIdentifier=(select distinct StoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
					f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID),
					f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
					AND StoreID=f.storeid AND SupplierID=f.supplierid AND ProductPriceTypeID=3),
					f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
					AND StoreID=f.storeid AND SupplierID=f.supplierid AND ProductPriceTypeID=3)	
	
	from ##tempDeliveryActivityCHNSummaryFinalData f'

	EXEC(@strquery)
	
	SET @sqlQueryNew=' select distinct wholesalername,
				StoreIdentifier as StoreID, 
				(Address + '', '' + State + '', ''+ ZipCode) as StoreInfo,
				Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS Draws,
				Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-
				(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS Returns,
				0 AS Shortages,
				SUM(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) AS NetSales, 
				Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0)) AS Profit,
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
				
				from ##tempDeliveryActivityCHNSummaryFinalData
				
				group by chainid, wholesalername, StoreIdentifier, address, State, zipcode, suggretail, CostToStore
					
			    Order By StoreID, StoreInfo, wholesalername '

	
	EXEC(@sqlQueryNew)
End
GO
