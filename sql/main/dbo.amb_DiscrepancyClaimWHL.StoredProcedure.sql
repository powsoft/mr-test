USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DiscrepancyClaimWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_DiscrepancyClaimWHL 'BN','04/15/2012','%','ENT','24178'
--exec amb_DiscrepancyClaimWHL '-1','06-03-2012','%','KPPL','24503'
--exec amb_DiscrepancyClaimWHL 'BAM','01-01-1900','%','WR1428','24503'
--exec amb_DiscrepancyClaimWHL 'cvs','01-20-2008','','WR1428','24503'

 CREATE PROCEDURE [dbo].[amb_DiscrepancyClaimWHL]
    (
		@ChainID VARCHAR(10) ,
		@WeekEnd VARCHAR(20) ,
		@StoreNumber VARCHAR(10) ,
		@supplieridentifier varchar(10),
		@supplierid varchar(10)
    )
AS 
BEGIN

	DECLARE @sqlQueryFinal varchar(8000)
	DECLARE @sqlQueryFinal1 varchar(8000)
	DECLARE @sqlQueryFinal2 varchar(8000)
	DECLARE @strquery varchar(8000)
	DECLARE @sqlQueryStoreLegacy varchar(8000)
	DECLARE @sqlQueryStoreNew varchar(8000)
	DECLARE @sqlQueryLegacy varchar(8000)
	DECLARE @sqlQueryNew varchar(8000)
	DECLARE @sqlQueryServiceLegacy varchar(8000)
	DECLARE @sqlQueryServiceNew varchar(8000)
	DECLARE @BillingControlDay varchar(20)
	DECLARE @newStartdate varchar(20)='01/01/1900'
	DECLARE @newenddate varchar(20)='01/01/1900'
	DECLARE @EndDate DateTime='1900/01/01'
    DECLARE @StartDate DateTime='1900/01/01'
	DECLARE @TodayDayOfWeek int
	DECLARE @DBType int --0 for old database,1 from new database, 2 from mixed
	DECLARE @chain_migrated_date date
	
IF(@ChainID<>'-1')
 BEGIN
SELECT @chain_migrated_date = cast(datemigrated AS VARCHAR)
FROM
	dbo.chains_migration
WHERE
	chainid = @ChainID;
	
	IF(cast(@chain_migrated_date as date) > cast('01/01/1900' as date))
		BEGIN
			IF(cast(@WeekEnd as date) > cast('01/01/1900' as date))
				BEGIN

SELECT @BillingControlDay = BillingControlDay
FROM
	dbo.BillingControl bc
	INNER JOIN dbo.chains c
		ON c.chainid = bc.chainid
WHERE
	c.chainidentifier = @ChainID

SET @TodayDayOfWeek = datepart (dw, (@WeekEnd))
--get the last day of the previous week (last Sunday)
SET @EndDate = dateadd(dd, @BillingControlDay - (@TodayDayOfWeek), @WeekEnd)
--get the first day of the previous week (the Monday before last)
SET @StartDate = dateadd(dd, @BillingControlDay - ((@TodayDayOfWeek) + 6), @WeekEnd)

					IF(cast(@WeekEnd as date) >= cast(@chain_migrated_date as date))
						BEGIN
SET @dbType = 2
							IF(cast(@StartDate as date) >= cast(@chain_migrated_date as date))
SET @newStartdate = @StartDate
							ELSE SET @newStartdate = dateadd(dd, 1, @chain_migrated_date)
SET @newEnddate = @EndDate
						END
					ELSE IF(cast(@WeekEnd as date) < cast(@chain_migrated_date as date)) SET @dbType = 0
				END
			ELSE SET @dbType = 0
		END
	ELSE
		BEGIN
SET @dbType = 0
		END
	END
ELSE SET @DBType = 2
		
		
IF (@DBType=0 or @DBType=2)
		BEGIN
SET @sqlQueryStoreLegacy = 'SELECT Distinct SL.StoreNumber,SL.StoreID,SL.StoreName,
									SL.Address,SL.State,SL.City,SL.ZipCode 
									FROM  [IC-HQSQL2].iControl.dbo.Products P
									INNER JOIN 
									(  [IC-HQSQL2].iControl.dbo.OnR OnR 
									 INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID)
									ON P.Bipad = OnR.Bipad 
									where 1=1 AND SL.StoreID not in(''se*'') '
									
				if (@supplieridentifier<>'-1')
					SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + '	and OnR.WholesalerID =''' + @supplieridentifier + '''' 
        
        IF ( @ChainID <> '-1' )
					SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + ' AND OnR.ChainID =''' + @ChainID + ''''  

        IF(CAST( @WeekEnd AS DATE) <> CAST( '1900-01-01' AS DATE))
					SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + ' AND OnR.WeekEnding = ''' + convert(VARCHAR, +@WeekEnd, 101) + ''''  
            
        IF ( @StoreNumber <> '' )
					SET @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + ' AND SL.StoreNumber like ''%' + @StoreNumber + '%'''

			SET @sqlQueryLegacy = 'SELECT distinct (''Store # : '' + SL.StoreNumber + '', '' + SL.StoreName + ''/n Location:  '' + SL.Address + '', '' + SL.City + '','' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,SL.ChainID,SL.StoreID,SL.StoreNumber,SL.StoreName,
									SL.Address,SL.State,SL.City,SL.ZipCode, OnR.Bipad,P.TitleName as TitleName,Convert(varchar(12),OnR.WeekEnding,101) as WeekEnding, 
							  OnR.MonPh, OnR.TuePh,OnR.WedPh,OnR.ThurPh,OnR.FriPh,OnR.SatPh,OnR.SunPh,
							  OnR.PhysicalCount,
							  OnR.Mon,OnR.Tue,OnR.Wed,OnR.Thur,OnR.Fri,OnR.Sat,OnR.Sun,OnR.CostToStore,0 AS DbType  
							  FROM  [IC-HQSQL2].iControl.dbo.Products P
							  INNER JOIN 
							  (  [IC-HQSQL2].iControl.dbo.OnR OnR  
							  INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID)
							  INNER JOIN   [IC-HQSQL2].iControl.dbo.Invoices I ON SL.StoreID = I.StoreID 
							  ON P.Bipad = OnR.Bipad '
					SET @sqlQueryLegacy = @sqlQueryLegacy + ' where 1=1 AND SL.StoreID not in(''se*'')'
					
					if (@supplieridentifier<>'-1')
						SET @sqlQueryLegacy = @sqlQueryLegacy + ' and OnR.WholesalerID =''' + @supplieridentifier + '''  '

					IF ( @ChainID <> '-1' )
						SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND OnR.ChainID =''' + @ChainID + ''''  
	                
					IF(CAST( @WeekEnd AS DATE) <> CAST( '1900-01-01' AS DATE))
						SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND OnR.WeekEnding =''' + convert(VARCHAR, +@WeekEnd, 101) + ''''  
	            
					IF ( @StoreNumber <> '' )
						SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND SL.StoreNumber like ''%' + @StoreNumber + '%'''



/* Get The Delivery Fee */
SET @sqlQueryServiceLegacy = 'SELECT Distinct I.DeliveryFee AS ServiceFeeDaily,SL.StoreNumber 		
										FROM  [IC-HQSQL2].iControl.dbo.StoresList  SL
										INNER JOIN   [IC-HQSQL2].iControl.dbo.Invoices I ON SL.StoreID = I.StoreID 
										WHERE I.DeliveryFee<>0 AND I.InvType=''pos'' '
		if (@supplieridentifier<>'-1')
				SET @sqlQueryServiceLegacy = @sqlQueryServiceLegacy + ' AND I.WholesalerID=''' + @supplieridentifier + ''''
										
		IF ( @ChainID <> '-1' )
				SET @sqlQueryServiceLegacy += ' AND SL.ChainID=''' + @ChainID + '''' 
          
    IF ( @StoreNumber <> '' )
				SET @sqlQueryServiceLegacy += ' AND SL.StoreNumber like ''%' + @StoreNumber + '%'''
            
    IF(CAST( @WeekEnd AS DATE) <> CAST( '1900-01-01' AS DATE))
			SET @sqlQueryServiceLegacy += ' AND I.WeekEnding =''' + convert(VARCHAR, +@WeekEnd, 101) + ''''    
            
		End				
        

	IF (@DBType=1 or  @DBType=2) 
			BEGIN
			--Get the data in to tmp table for draws
			
				IF object_id('tempdb.dbo.##tempDiscrepancyClaimDraws') is not null
					BEGIN
DROP TABLE ##tempDiscrepancyClaimDraws;
					END
SET @strquery = 'select distinct st.ChainID,st.SupplierID,s.storeid,
								st.ProductID,Qty,TransactionTypeID,
								datename(W,SaleDateTime)+ ''Draw'' as "wDay"
								into ##tempDiscrepancyClaimDraws
								from dbo.Storetransactions_forward st
								inner JOIN dbo.Chains c on st.ChainID=c.ChainID
								INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
								INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
								where TransactionTypeID in (29) 
								and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%''' 
								
			IF(@SupplierID<>'-1')
				SET @strquery = @strquery + '  and st.supplierid=' + @SupplierID 
			IF(@ChainID<>'-1')
				SET @strquery = @strquery + ' and c.ChainIdentifier=''' + @ChainID + ''''
			
			IF(@StoreNumber<>'')
				SET @strquery = @strquery + ' and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
									
			IF(CAST(@newStartdate AS DATE ) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery + ' and SaleDateTime >= ''' + convert(VARCHAR, +@newStartdate, 101) + ''''
		
			IF(CAST(@newEnddate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery + ' AND SaleDateTime <= ''' + convert(VARCHAR, +@newEnddate, 101) + ''''
			
			EXEC (@strquery)	
			
			
			--Get the data into tmp table for POS
			
			IF object_id('tempdb.dbo.##tempDiscrepancyClaimPOS') is not null
				BEGIN
DROP TABLE ##tempDiscrepancyClaimPOS
				END
SET @strquery = 'select distinct st.ChainID,st.SupplierID,
							s.storeid,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempDiscrepancyClaimPOS
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID											
							INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 										
							where 1=1 and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
			IF(@SupplierID<>'-1')
				SET @strquery = @strquery + ' and st.supplierid=' + @SupplierID + ''

			IF(@ChainID<>'-1')
					SET @strquery = @strquery + ' and c.ChainIdentifier=''' + @ChainID + ''''							
			
			IF(@StoreNumber<>'')
				SET @strquery = @strquery + ' and s.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
										
			IF(CAST(@newStartdate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery + ' and SaleDateTime >= ''' + convert(VARCHAR, +@newStartdate, 101) + ''''
				
			IF(CAST(@newEnddate AS DATE) <> CAST('1900-01-01' AS DATE))
				SET @strquery = @strquery + ' AND SaleDateTime <= ''' + convert(VARCHAR, +@newEnddate, 101) + ''''
			
			EXEC (@strquery)	
			
			IF object_id('tempdb.dbo.##tempDiscrepancyClaimWHLFinalData') is not null
				BEGIN
DROP TABLE ##tempDiscrepancyClaimWHLFinalData	
			    END
SET @strquery = 'Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,
							tmpPOS.TuesdayPOS,
							tmpPOS.WednesdayPOS,
							tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,
							tmpPOS.SaturdayPOS,
							tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "chainidentifier",
							CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",	
							CAST(NULL as nvarchar(50)) as "StoreNumber",
							CAST(NULL as nvarchar(50)) as "StoreName",
							CAST(NULL as nvarchar(100)) as "Address",
							CAST(NULL as nvarchar(50)) as "City",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "ZipCode",
							CAST(NULL as nvarchar(225)) as "TitleName",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as nvarchar(50)) as "BiPad"
							into ##tempDiscrepancyClaimWHLFinalData 
						from
						(select * FROM 
							(SELECT * from ##tempDiscrepancyClaimDraws ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
							(SELECT * from ##tempDiscrepancyClaimPOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
							 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						on tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'
EXEC (@strquery)

--Update the required fields
SET @strquery = 'update f set
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
							f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
							where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
							AND SupplierID=f.supplierid and ProductPriceTypeID=3),
							f.TitleName=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid),	
							f.Bipad=(SELECT DISTINCT  Bipad  from dbo.ProductIdentifiers where ProductID=f.productid),	
							f.chainidentifier=(SELECT DISTINCT chainidentifier from dbo.chains where chainid=f.chainid)			
							from ##tempDiscrepancyClaimWHLFinalData f'
EXEC (@strquery)
SET @sqlQueryStoreNew = 'SELECT distinct StoreNumber,LegacySystemStoreIdentifier AS StoreID,StoreName,Address,State,City,ZipCode 
										 FROM ##tempDiscrepancyClaimWHLFinalData'
SET @sqlQueryNew = ' SELECT distinct  ( ''Store Number: '' + StoreNumber + '','' + StoreName  + ''/n Location: '' + address + '', '' + City + '','' + State + '', '' + zipcode ) as StoreInfo,chainidentifier as ChainID,LegacySystemStoreIdentifier AS StoreID,StoreNumber,StoreName,Address,State,City,ZipCode , Bipad,TitleName,
									Convert(varchar(12),''' + @newEnddate + ''',101) as WeekEnding, 
									MondayDraw-MondayPOS as MonPh, 
									TuesdayDraw-TuesdayPOS as TuePh,
									WednesdayDraw-WednesdayPOS as WedPh,
									ThursdayDraw-ThursdayPOS as ThurPh,
									FridayDraw-FridayPOS as FriPh,
									SaturdayDraw-SaturdayPOS as SatPh,
									SundayDraw-SundayPOS as SunPh,
									0 as PhysicalCount,
									MondayDraw as Mon,
									TuesdayDraw as Tue,
									WednesdayDraw as Wed,
									ThursdayDraw as Thur,
									FridayDraw as Fri,
									SaturdayDraw as Sat,
									SundayDraw as Sun,
									CostToStore,
									1 AS DbType
									FROM ##tempDiscrepancyClaimWHLFinalData'
SET @sqlQueryServiceNew = 'SELECT Distinct ServiceFeeFactorValue AS ServiceFeeDaily,S.StoreIdentifier as StoreNumber 		
										FROM dbo.ServiceFees  SF
										inner JOIN dbo.suppliers Sup on SF.supplierid=Sup.SupplierID 
										INNER JOIN dbo.Stores S ON S.StoreID=SF.StoreID
										and SF.supplierid=''' + @SupplierID + ''''
			IF(@StoreNumber<>'')
SET @sqlQueryServiceNew += ' and S.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
					
	End
	
				
/*Final Query Execution*/			
	IF(@DBType=2)
		BEGIN
--SET @sqlQueryFinal= @sqlQueryStoreLegacy +' UNION ' + @sqlQueryStoreNew
--EXEC(@sqlQueryFinal)

SET @sqlQueryFinal = @sqlQueryLegacy + ' UNION ' + @sqlQueryNew
EXEC (@sqlQueryFinal)
SET @sqlQueryFinal = @sqlQueryServiceLegacy + ' UNION ' + @sqlQueryServiceNew
EXEC (@sqlQueryFinal)
		END
	 ELSE IF(@DBType=1)
		BEGIN
--EXEC(@sqlQueryStoreNew)
EXEC (@sqlQueryNew)
EXEC (@sqlQueryServiceNew)
		END
	ELSE IF(@DBType=0)
		BEGIN
--EXEC(@sqlQueryStoreLegacy)
EXEC (@sqlQueryLegacy)
EXEC (@sqlQueryServiceLegacy)
		END	
   END
GO
