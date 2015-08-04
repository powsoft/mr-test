USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewDistReturnAuditPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [amb_ViewDistReturnAuditPUB] '-1','01/01/1900','01/1/1900','-1','-1','-1','DEFAULT','0'
-- EXEC [amb_ViewDistReturnAuditPUB] '-1','01/1/1900','01/1/1900','-1','1771','-1','DOWJ','0'


CREATE procedure [dbo].[amb_ViewDistReturnAuditPUB]
(
@ChainID varchar(20),
@StartDate varchar(20),
@EndDate varchar(20),
@State varchar(10),
@WholesalerID varchar(20),
@TitleName varchar(100),
@PublisherIdentifier varchar(20),
@PublisherID varchar(20)

)

as 
BEGIN

	Declare @sqlQueryNew varchar(8000)
	Declare @strquery varchar(8000)

	--Get the data in to tmp table for draws	
	IF object_id('tempdb.dbo.##tempReturnAuditDraws') is not null
		BEGIN
		  drop table ##tempReturnAuditDraws;
		END
	
	SET @strquery='SELECT Distinct 
					  M.ManufacturerIdentifier AS PublisherID, 
					  ST.ChainID,
					  ST.SupplierID,
					  s.storeid,
					  ST.ProductID,
					  Qty,
					  ST.TransactionTypeID,
					  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
					   FROM BillingControl BC WHERE  BC.ChainID = st.ChainID AND BC.EntityIDToInvoice = st.SupplierID)  AS SaleDateTime,
					  datename(W,SaleDateTime)+ ''Draw'' as "wDay"
				
				INTO ##tempReturnAuditDraws
				
				FROM DataTrue_Report.dbo.Storetransactions_forward ST
					INNER JOIN DataTrue_Report.dbo.Brands B ON B.BrandID=st.BrandID
					INNER JOIN DataTrue_Report.dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
					INNER JOIN DataTrue_Report.dbo.Suppliers Sup ON Sup.SupplierID=ST.SupplierID
					INNER JOIN DataTrue_Report.dbo.Chains C ON ST.ChainID=C.ChainID
					INNER JOIN DataTrue_Report.dbo.Stores S ON S.StoreID=ST.StoreID
					INNER JOIN DataTrue_Report.dbo.Addresses A ON A.OwnerEntityID=ST.StoreID 
					INNER JOIN DataTrue_Report.dbo.Products P ON P.productid=ST.productid 
				
				Where TransactionTypeID in (29) and M.ManufacturerID='+@PublisherId

	IF(@ChainID<>'-1')   
		SET @strquery = @strquery +' and C.ChainIdentifier='''+@ChainID+''''
	
	IF(@WholesalerID<>'-1')   
		SET @strquery = @strquery +' and Sup.SupplierIdentifier ='''+@WholesalerID+''''								
	
	IF(@TitleName<>'-1')   
		SET @strquery = @strquery +' and P.ProductName = '''+@TitleName+''''							   
	
	IF(@State<>'-1')    
		SET @strquery = @strquery +' and A.State like '''+@State+''''
									
	IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
		SET @strquery = @strquery +' and  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  >= ''' + convert(varchar, +@StartDate,101) +  ''''
	
	IF(CAST( @EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
		SET @strquery = @strquery +' AND  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  <= ''' + convert(varchar, +@EndDate,101) + ''''
	
	EXEC(@strquery)
	
	
	--Get the data into tmp table for POS	
				
	IF object_id('tempdb.dbo.##tempReturnAuditPOS') is not null
		BEGIN
			Drop Table ##tempReturnAuditPOS
		END
	SET @strquery='select distinct 
							M.ManufacturerIdentifier AS PublisherID,
							st.ChainID,
							st.SupplierID,
							s.storeid,
						   (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
							FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
							AND BC.EntityIDToInvoice = st.SupplierID)  AS SaleDateTime,
							st.ProductID,
							Qty,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"

					INTO ##tempReturnAuditPOS

					FROM DataTrue_Report.dbo.StoreTransactions ST
						INNER JOIN DataTrue_Report.dbo.TransactionTypes TT on TT.TransactionTypeId=ST.TransactionTypeId and TT.Buckettype=1
						INNER JOIN DataTrue_Report.dbo.Brands B ON B.BrandID=st.BrandID
						INNER JOIN DataTrue_Report.dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
						INNER JOIN DataTrue_Report.dbo.Suppliers Sup ON Sup.SupplierID=ST.SupplierID
						INNER JOIN DataTrue_Report.dbo.Chains C ON ST.ChainID=C.ChainID
						INNER JOIN DataTrue_Report.dbo.Stores S ON S.StoreID=ST.StoreID
						INNER JOIN DataTrue_Report.dbo.Addresses A ON A.OwnerEntityID=ST.StoreID 
						INNER JOIN DataTrue_Report.dbo.Products P ON P.productid=ST.productid 
					
					Where ST.TransactionTypeID in (29) and M.ManufacturerID='+@PublisherId

	IF(@ChainID<>'-1')   
		SET @strquery = @strquery +' and C.ChainIdentifier='''+@ChainID+''''
	
	IF(@WholesalerID<>'-1')   
		SET @strquery = @strquery +' and Sup.SupplierIdentifier ='''+@WholesalerID+''''								
	
	IF(@TitleName<>'-1')   
		SET @strquery = @strquery +' and P.ProductName = '''+@TitleName+''''							   
	
	IF(@State<>'-1')    
		SET @strquery = @strquery +' and A.State like '''+@State+''''
									
	IF(CAST(@StartDate AS DATE) <> CAST('1900-01-01' AS DATE))
		SET @strquery = @strquery +' and  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  >= ''' + convert(varchar, +@StartDate,101) +  ''''
	
	IF(CAST( @EndDate AS DATE) <> CAST('1900-01-01' AS DATE)) 
		SET @strquery = @strquery +' AND  (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
										  FROM BillingControl BC WHERE  BC.ChainID = st.ChainID
										  AND BC.EntityIDToInvoice = st.SupplierID)  <= ''' + convert(varchar, +@EndDate,101) + ''''
	
	EXEC(@strquery)	
		
	--Get the final data into final tmp table
	
	IF object_id('tempdb.dbo.##tempReturnAuditFinalData') is not null
		BEGIN
			Drop Table ##tempReturnAuditFinalData
		END


	SET @strquery='Select Distinct tmpdraws.*,
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
						
						INTO ##tempReturnAuditFinalData 
						
					FROM
						(SELECT * FROM 
							(SELECT * FROM ##tempReturnAuditDraws ) p
							 pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) 
							 as Draw_eachday
						) tmpdraws
						join
						( SELECT * FROM 
							(SELECT * FROM ##tempReturnAuditPOS) p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						on tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid '
					
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
							from ##tempReturnAuditFinalData f'
		
	 EXEC(@strquery)

	
	/*--------Select the required fields from the temp table-----------*/
	SET @sqlQueryNew=' select distinct 0 as PhCnt,
								 mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw AS TTLDraws,
								(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-
								(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS TotalReportedByRetailer,
								(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)AS TotalByAudit,
								((mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw)-																		(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) as DifferenceCount,
								(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) as TotalPH,
								(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-																			(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS TotalRet,
								Convert(datetime,SaleDateTime,101)  as WeekEnding,
								storeidentifier as StoreID, 
								chainidentifier as ChainID,
								supplieridentifier  as WholesalerID,
								PublisherID,
								TitleName,
								StoreName,
								Address,
								City,
								State,
								ZipCode,
								StoreNumber,
								CostToStore,
								SuggRetail

					From  ##tempReturnAuditFinalData '
				

	EXEC(@sqlQueryNew)
	   
 End
GO
