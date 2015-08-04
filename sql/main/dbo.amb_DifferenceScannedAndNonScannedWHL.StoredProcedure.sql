USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DifferenceScannedAndNonScannedWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Exec amb_DifferenceScannedAndNonScannedWHL 'BN','-1','-1','02/05/2012','02/02/2012','ENT','24718'
--- Exec amb_DifferenceScannedAndNonScannedWHL '-1','-1','-1','11/06/2012','01/01/1900','5531017','40560'
--- Exec amb_DifferenceScannedAndNonScannedWHL 'BN','-1','-1','01/01/1900','01/01/1900','STC','35157'
--- EXEC amb_DifferenceScannedAndNonScannedWHL 'DQ','-1','-1','08/25/2013','08/25/2013','CLL','24164'

--- EXEC amb_DifferenceScannedAndNonScannedWHL 'DQ','-1','-1','09/01/2013','09/01/2013','CLL','24164'

CREATE PROCEDURE [dbo].[amb_DifferenceScannedAndNonScannedWHL]
(
		@ChainID VARCHAR(20) ,
		@State VARCHAR(10) ,
		@Title VARCHAR(30) ,
		@StartDate VARCHAR(50) ,
		@EndDate VARCHAR(50) ,
		@supplieridentifier varchar(10),
		@supplierid varchar(10)
 )
AS 
 BEGIN


Declare @sqlQueryNew varchar(8000)
Declare @strquery varchar(8000)

			--Get the data in to tmp table for draws	
			IF object_id('tempdb.dbo.##DifferenceScannedAndNonScannedDraws') is not null
				BEGIN
				  drop table ##DifferenceScannedAndNonScannedDraws;
				END
			
			SET @strquery='SELECT DISTINCT st.ChainID
							, st.SupplierID
							, s.storeid
							, st.ProductID
							, Qty
							, TransactionTypeID
							, ST.SaleDateTime as  SaleDateTime1
							, (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime) + 7
								 FROM
									 BillingControl BC
								 WHERE
									 BC.ChainID = st.ChainID
									 AND BC.EntityIDToInvoice = st.SupplierID) AS SaleDateTime
							, datename (W, SaleDateTime) + '' Draw'' as "wDay"
						
						into ##DifferenceScannedAndNonScannedDraws
						
						from DataTrue_Report.dbo.Storetransactions_forward st
						inner JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
						INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
						INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
						INNER JOIN DataTrue_Report.dbo.Products p ON p.productid=st.productid 
						where TransactionTypeID in (29)
						and st.supplierid='''+@supplierid+''''

			if(@ChainID<>'-1')   
				set @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''							
			
			if(@title<>'-1')   
				set @strquery = @strquery +' and p.productname like ''%'+@title+'%'''							   
			
			if(@State<>'-1')    
				set @strquery = @strquery +' and a.State like '''+@State+''''
											
			if(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
				set @strquery = @strquery +' and cast((SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)+7
													FROM BillingControl BC WHERE BC.ChainID = st.ChainID 
													AND BC.EntityIDToInvoice = st.SupplierID) as date) >= cast( ''' + @StartDate +  ''' as date)'
			
			if(CAST( @EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
				set @strquery = @strquery +' AND cast((SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)+7
													FROM BillingControl BC WHERE BC.ChainID = st.ChainID
													AND BC.EntityIDToInvoice = st.SupplierID) as date) <= cast(''' + @EndDate + ''' as date)'
		
			EXEC(@strquery)
			print(@strquery)
			
			
			--Get the data into tmp table for POS	
						
			IF object_id('tempdb.dbo.##DifferenceScannedAndNonScannedPOS') is not null
				BEGIN
					Drop Table ##DifferenceScannedAndNonScannedPOS
				END
			set @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
							 ST.SaleDateTime as  SaleDateTime1,
							(SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)+7
							FROM BillingControl BC WHERE BC.ChainID = st.ChainID AND BC.EntityIDToInvoice = st.SupplierID) as SaleDateTime,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"

							into ##DifferenceScannedAndNonScannedPOS

							From DataTrue_Report.dbo.Storetransactions st
							INNER join DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							INNER JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
							INNER JOIN DataTrue_Report.dbo.Products p ON p.productid=st.productid 
							Where  st.supplierid='''+@supplierid+''''
											
											
			IF(@ChainID<>'-1')   
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''							
			
			IF(@title<>'-1')   
				SET @strquery = @strquery +' and p.productname like ''%'+@title+'%'''							   
			
			IF(@State<>'-1')    
				SET @strquery = @strquery +' and a.State like '''+@State+''''
											
			IF(CAST( @StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery +' and cast((SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)+7
													FROM BillingControl BC WHERE BC.ChainID = st.ChainID
													AND BC.EntityIDToInvoice = st.SupplierID) as date )>= cast( ''' + @StartDate +  ''' as date)'
			
			IF(CAST(@EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
				SET @strquery = @strquery +' AND cast((SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)+7
													FROM BillingControl BC WHERE BC.ChainID = st.ChainID
													AND BC.EntityIDToInvoice = st.SupplierID) as date) <= cast(''' +@EndDate + ''' as date)'	
		
			EXEC(@strquery)
			print(@strquery)
				
			--Get the final data into final tmp table
			
			IF object_id('tempdb.dbo.##DifferenceScannedAndNonScannedFinalData') is not null
				BEGIN
					Drop Table ##DifferenceScannedAndNonScannedFinalData
				END


			SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "storeidentifier",
							CAST(NULL as nvarchar(50)) as "chainidentifier",
							CAST(NULL as nvarchar(50)) as "supplieridentifier",
							CAST(NULL as nvarchar(225)) as "TitleName",
							CAST(NULL as nvarchar(100)) as "Storename",
							CAST(NULL as nvarchar(100)) as "Address",
							CAST(NULL as nvarchar(50)) as "City",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "ZipCode",
							CAST(NULL as nvarchar(50)) as "StoreNumber",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as money) as "SuggRetail"
							into ##DifferenceScannedAndNonScannedFinalData 
							from
							(select * FROM 
								(SELECT * from ##DifferenceScannedAndNonScannedDraws ) p
								 pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) 
								 as Draw_eachday
							) tmpdraws
							join
							( select * from 
								(SELECT * from ##DifferenceScannedAndNonScannedPOS)p
								 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
								) as p1
							) tmpPOS 
							on tmpdraws.chainid=tmpPOS.chainid
							and tmpdraws.supplierid=tmpPOS.supplierid
							and tmpdraws.storeid=tmpPOS.storeid
							and tmpdraws.productid=tmpPOS.productid
							and tmpdraws.SaleDateTime1=tmpPOS.SaleDateTime1 '
			
			EXEC(@strquery)
            

			--Update the required fields
			SET @strquery='update f set 
								f.StoreName=(select distinct StoreName from dbo.Stores  where StoreID=f.StoreID),
								f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
								f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
								f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
								f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
								f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID),
								f.supplieridentifier=(SELECT DISTINCT Supplieridentifier from dbo.Suppliers where SupplierID=f.supplierid),
								f.TitleName=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),
								f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
								and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
								f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
								and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
								f.storeidentifier=(SELECT DISTINCT legacysystemstoreidentifier from dbo.stores where storeid=f.storeid),
								f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid)
							from ##DifferenceScannedAndNonScannedFinalData f'
				
			 EXEC(@strquery)

			--Return the Data
			
		
			SET @sqlQueryNew='  SELECT DISTINCT 0 AS PhCnt

							, isnull(mondaydraw, 0) + isnull(tuesdaydraw, 0) + isnull(wednesdaydraw, 0) + isnull(thursdaydraw, 0) + isnull(fridaydraw, 0) + isnull(saturdaydraw, 0) + isnull(sundaydraw, 0) AS TTLDraws
							, isnull((isnull(mondaydraw, 0) + isnull(tuesdaydraw, 0) + isnull(wednesdaydraw, 0) + isnull(thursdaydraw, 0) + isnull(fridaydraw, 0) + isnull(saturdaydraw, 0) + isnull(sundaydraw, 0) - (isnull(mondayPOS, 0) + isnull(tuesdayPOS, 0) + isnull(wednesdayPOS, 0) + isnull(thursdayPOS, 0) + isnull(fridayPOS, 0) + isnull(saturdayPOS, 0) + isnull(sundayPOS, 0))), 0) AS TotalReportedByRetailer
							
							, 0 AS TotalByAudit
				
							
							, isnull(((isnull(mondaydraw, 0) + isnull(tuesdaydraw, 0) + isnull(wednesdaydraw, 0) + isnull(thursdaydraw, 0) + isnull(fridaydraw, 0) + isnull(saturdaydraw, 0) + isnull(sundaydraw, 0)) - (isnull(mondayPOS, 0) + isnull(tuesdayPOS, 0) + isnull(wednesdayPOS, 0) + isnull(thursdayPOS, 0) + isnull(fridayPOS, 0) + isnull(saturdayPOS, 0) + isnull(sundayPOS, 0))), 0)-(0) AS DifferenceCount
							
							, 0 AS TotalPH
							
							, isnull((isnull(mondaydraw, 0) + isnull(tuesdaydraw, 0) + isnull(wednesdaydraw, 0) + isnull(thursdaydraw, 0) + isnull(fridaydraw, 0) + isnull(saturdaydraw, 0) + isnull(sundaydraw, 0) - (isnull(mondayPOS, 0) + isnull(tuesdayPOS, 0) + isnull(wednesdayPOS, 0) + isnull(thursdayPOS, 0) + isnull(fridayPOS, 0) + isnull(saturdayPOS, 0) + isnull(sundayPOS, 0))), 0) AS TotalRet
							, convert(VARCHAR(12), SaleDateTime, 101) AS WeekEnding
							, storeidentifier AS StoreID
							, chainidentifier AS ChainID
							, supplieridentifier AS WholesalerID
							, '''' AS PublisherID
							, TitleName
							, StoreName
							, Address
							, City
							, State
							, ZipCode
							, StoreNumber
							, CostToStore
							, SuggRetail

					FROM
						##DifferenceScannedAndNonScannedFinalData
					ORDER BY
						StoreID
					, WeekEnding
					, State
					, TitleName '
		
		EXEC(@sqlQueryNew)
	   	
END
GO
