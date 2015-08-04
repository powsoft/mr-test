USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawRegulationCHN_GetData_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * FROM Chains where ChainIdentifier='DQ'
--exec amb_DrawRegulationCHN_GetData_Beta 'DQ','62362','-1','MS','','08/18/2013','09/06/2013'
--Exec [amb_DrawRegulationCHN_GetData_Beta] 'BN','42493','-1','AK','','01/01/1900','01/01/2009','WholesalerName DESC',1,25,0
CREATE procedure [dbo].[amb_DrawRegulationCHN_GetData_Beta]
(
	@ChainIdentifier varchar(10),
	@ChainID varchar(10),
	@City varchar(50),
	@State varchar(40),
	@StoreNumber varchar(50),
	@StartDate varchar(20),
	@EndDate varchar(20)
)
as 
BEGIN
	declare @sqlQueryFinal varchar(8000)
	Declare @sqlQueryStoreNew varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	
	--Get the data in to tmp table for draws	
	if object_id('tempdb.dbo.##tempDrawRegulationDrawsCHN') is not null
	begin
	drop table ##tempDrawRegulationDrawsCHN;
	end
	declare @strquery varchar(8000)
	set @strquery='select distinct st.ChainID,st.SupplierID,st.storeid,
						st.ProductID,RuleCost,Qty,TransactionTypeID,
						datename(W,SaleDateTime)+ ''Draw'' as "wDay"
						
						into ##tempDrawRegulationDrawsCHN
						
						from DataTrue_Report.dbo.Storetransactions_forward st
						INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
						INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
						
						where TransactionTypeID in (29)
						and st.chainid=''' + @ChainID +'''
						and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
	if(@City<>'-1')   
	set @strquery = @strquery +' and a.City like '''+@City+''''							   

	if(@State<>'-1')    
	set @strquery = @strquery +' and	a.State like '''+@State+''''
							
	if(cast(  @StartDate as date) > cast( '1900-01-01' as date))
	set @strquery = @strquery +' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + convert(varchar, +@StartDate,101) +  ''''
	if(cast( @EndDate as date ) > cast( '1900-01-01' as date)) 
	set @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + convert(varchar, +@EndDate,101) + ''''

	EXEC(@strquery)

	--Get the data into tmp table for POS	
		
	if object_id('tempdb.dbo.##tempDrawRegulationPOSCHN') is not null
	begin
	drop table ##tempDrawRegulationPOSCHN;
	end
	set @strquery='select distinct st.ChainID,st.SupplierID,st.storeid,
		st.ProductID,RuleCost,Qty,st.TransactionTypeID,
		datename(W,SaleDateTime)+ ''POS'' as "POSDay"

		into ##tempDrawRegulationPOSCHN

		from DataTrue_Report.dbo.Storetransactions st
		inner join DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
		INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
		INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
		
		where st.chainid='''+ @ChainID +'''
		and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
							
	if(@City<>'-1')   
	set @strquery = @strquery +' and a.City like '''+@City+''''							   

	if(@State<>'-1')    
	set @strquery = @strquery +' and	a.State like '''+@State+''''
							
	if(CAST(@StartDate as DATE) > CAST('1900-01-01' as DATE))
	set @strquery = @strquery +' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + convert(varchar, +@StartDate,101) +  ''''
	if(CAST(@EndDate as DATE) > CAST('1900-01-01' as DATE)) 
	set @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + convert(varchar, +@EndDate,101) + ''''
							
	EXEC(@strquery)			

	--Get the final data into final tmp table

	if object_id('tempdb.dbo.##tempDrawRegulationCHNFinalData') is not null
	begin
	drop table ##tempDrawRegulationCHNFinalData
	end


	set @strquery='Select distinct tmpdraws.*,
			tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
			tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
			CAST(NULL as nvarchar(50)) as "WholesalerName",
			CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",
			CAST(NULL as nvarchar(50)) as "StoreName",
			CAST(NULL as nvarchar(50)) as "StoreNumber",
			CAST(NULL as nvarchar(100)) as "Address",
			CAST(NULL as nvarchar(50)) as "City",
			CAST(NULL as nvarchar(50)) as "State",
			CAST(NULL as nvarchar(50)) as "ZipCode",
			CAST(NULL as nvarchar(50)) as "BiPad",
			CAST(NULL as nvarchar(225)) as "Title",
			CAST(NULL as MONEY) as "CostToStore",
			CAST(NULL as money) as "SuggRetail",
			CAST(NULL as money) as "MonBase",
			CAST(NULL as money) as "TueBase",
			CAST(NULL as money) as "WedBase",
			CAST(NULL as money) as "ThurBase",
			CAST(NULL as money) as "FriBase",
			CAST(NULL as money) as "SatBase",
			CAST(NULL as money) as "SunBase"
		into ##tempDrawRegulationCHNFinalData 
		from
		(select * FROM 
			(SELECT * from ##tempDrawRegulationDrawsCHN ) p
			 pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) 
			 as Draw_eachday
		) tmpdraws
		left join
		( select * from 
			(SELECT * from ##tempDrawRegulationPOSCHN)p
			 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
			) as p1
		) tmpPOS 
		on tmpdraws.chainid=tmpPOS.chainid
		and tmpdraws.supplierid=tmpPOS.supplierid
		and tmpdraws.storeid=tmpPOS.storeid
		and tmpdraws.productid=tmpPOS.productid'

	exec(@strquery)


	--Update the required fields
	set @strquery='update f set 
	f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers where SupplierID=f.supplierid),
	f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
	f.StoreName=(select distinct StoreName from dbo.Stores  where StoreID=f.StoreID),
	f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
	f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
	f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
	f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
	f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID),
	f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=f.productid),
	f.title=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),
	f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
	and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
	f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
	and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
	f.MonBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
	f.TueBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
	f.WedBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
	f.ThurBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
	f.FriBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
	f.SatBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid ),
	f.SunBase=(SELECT DISTINCT  MonLimitQty  from dbo.StoreSetup where supplierid=f.supplierid and ChainID=f.chainid and storeid=f.storeid and ProductID=f.productid )
	from ##tempDrawRegulationCHNFinalData f'
	exec(@strquery)

	--Return the Data


	set @sqlQueryNew=' SELECT  (''Store Number: '' + StoreNumber + ''; Account Number: '' + 
												LegacySystemStoreIdentifier + '';/n Location: '' 
												+ storename + '', '' + address + '', '' + City + '', 
												'' + State + '', '' + zipcode ) AS StoreInfo
									 , wholesalername
									 , LegacySystemStoreIdentifier AS StoreID
									 , storename
									 , StoreNumber
									 , address
									 , City
									 , State
									 , zipcode
									 , bipad
									 , title
									 , costtostore
									 , suggretail
									 , mondaydraw AS MonDraws
									 , tuesdaydraw AS TueDraws
									 , wednesdaydraw AS WedDraws
									 , thursdaydraw AS ThurDraws
									 , fridaydraw AS FriDraws
									 , saturdaydraw AS SatDraws
									 , sundaydraw AS SunDraws
									 , mondaydraw - mondayPOS AS MonReturns
									 , tuesdaydraw - tuesdayPOS AS TueReturns
									 , wednesdaydraw - wednesdayPOS AS WedReturns
									 , thursdaydraw - thursdayPOS AS ThurReturns
									 , fridaydraw - fridayPOS AS FriReturns
									 , saturdaydraw - saturdayPOS AS SatReturns
									 , sundaydraw - sundayPOS AS SunReturns
									 , ''0'' AS MonShort
									 , ''0'' AS TueShort
									 , ''0'' AS WedShort
									 ,''0'' AS ThurShort
									 , ''0'' AS FriShort
									 , ''0'' AS SatShort
									 , ''0'' AS SunShort
									 , mondayPOS AS MonNetSales
									 , tuesdayPOS AS TueNetSales
									 , wednesdayPOS AS WedNetSales
									 , thursdayPOS AS ThurNetSales
									 , fridayPOS AS FriNetSales
									 , saturdayPOS AS SatNetSales
									 , sundayPOS AS SunNetSales
									 , sum(mondaydraw + tuesdaydraw + wednesdaydraw + thursdaydraw + fridaydraw + saturdaydraw + sundaydraw) AS [TTL Draws]
									 , sum(mondaydraw + tuesdaydraw + wednesdaydraw + thursdaydraw + fridaydraw + saturdaydraw + sundaydraw - (mondayPOS + tuesdayPOS + wednesdayPOS + thursdayPOS + fridayPOS + saturdayPOS + sundayPOS)) AS [TT Returns]
									 , 0 AS [TTL Shortages]
									 , sum(mondayPOS + tuesdayPOS + wednesdayPOS + thursdayPOS + fridayPOS + saturdayPOS + sundayPOS) AS NetSales
									 , sum((mondayPOS + tuesdayPOS + wednesdayPOS + thursdayPOS + fridayPOS + saturdayPOS + sundayPOS) * (suggretail - CostToStore)) AS Profit
									 , MonBase
									 , TueBase
									 , WedBase
									 , ThurBase
									 , FriBase
									 , SatBase
									 , SunBase
									 , mondayPOS AS AvgMonSale
									 , tuesdayPOS AS AvgTueSale
									 , wednesdayPOS AS AvgWedSale
									 , thursdayPOS AS AvgThurSale
									 , fridayPOS AS AvgFriSale
									 , saturdayPOS AS AvgSatSale
									 , sundayPOS AS AvgSunSale
									 , count(bipad) AS NoOfWeeksInRange
							FROM
								##tempDrawRegulationCHNFinalData

							GROUP BY
								wholesalername
							, LegacySystemStoreIdentifier
							, StoreNumber
							, bipad
							, title
							, costtostore
							, suggretail
							, mondaydraw
							, tuesdaydraw
							, wednesdaydraw
							, thursdaydraw
							, fridaydraw
							, saturdaydraw
							, sundaydraw
							, mondayPOS
							, tuesdayPOS
							, wednesdayPOS
							, thursdayPOS
							, fridayPOS
							, saturdayPOS
							, sundayPOS
							, MonBase
							, TueBase
							, WedBase
							, ThurBase
							, FriBase
							, SatBase
							, SunBase
							, StoreName
							, Address
							, City
							, State
							, ZipCode
				order by LegacySystemStoreIdentifier,title'
		print 	@sqlQueryNew
	EXEC(@sqlQueryNew)
		

end
GO
