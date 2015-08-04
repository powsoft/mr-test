USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ReturnAffidavitsPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[amb_ReturnAffidavitsPUB]
(
@PublisherIdentifier varchar(50),
@PublisherId varchar(50),
@WholesalerID varchar(20),
@Weekend varchar(20),
@ChainId varchar(20)
)--exec  amb_ReturnAffidavitsPUB 'Default','0','-1','11/11/2010','-1'
as 
BEGIN
Declare @sqlQueryOld varchar(4000)
Declare @strquery varchar(8000)
Declare @sqlQueryNew varchar(8000)
Declare @strqueryNewFinal varchar(8000)
Declare @BillingControlDay varchar(20)
Declare @newStartdate varchar(20)='1900-01-01'
Declare @newenddate varchar(20)='1900-01-01'
Declare @TodayDayOfWeek int
Declare @EndOfWeek varchar(20)
Declare @StartOfWeek varchar(20)
Declare @DBType int  --0 for old database,1 from new database, 2 from mixed
DECLARE @chain_migrated_date date
	
IF(@ChainID<>'-1')
	BEGIN
		SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) FROM    dbo.chains_migration WHERE   chainid = @ChainID;

		IF(CAST(@chain_migrated_date as DATE) > CAST('1900-01-01' as DATE))
			BEGIN
				SELECT @BillingControlDay=BillingControlDay 
				FROM dbo.BillingControl bc 
				INNER JOIN dbo.chains c ON c.chainid=bc.chainid
				WHERE  c.chainidentifier=@ChainID 
				
				SET @TodayDayOfWeek = datepart(dw, @WeekEnd)
				SET @EndOfWeek=DATEADD(dd,(@BillingControlDay -@TodayDayOfWeek), @WeekEnd)
				SET @StartOfWeek=DATEADD(dd, @BillingControlDay-(@TodayDayOfWeek+6), @WeekEnd)

				IF(CAST(@Weekend as DATE) >= CAST(@chain_migrated_date as DATE))
					BEGIN
						set @dbType=2
						IF(cast(@StartOfWeek as date) >= cast(@chain_migrated_date as date))
							SET @newStartdate=@StartOfWeek
						ELSE
							SET @newStartdate=DATEADD(dd,1,@chain_migrated_date)
						SET @newenddate=@EndOfWeek
					END
				ELSE IF(CAST(@Weekend as DATE) < CAST(@chain_migrated_date as DATE))
					BEGIN
						SET @DBType=0
					END
			END
		ELSE
			BEGIN
				SET @DBType=0
			END
	END
ELSE
	BEGIN
		SET @DBType=2
	END
print @DBType
/* (STEP 1)----GET DATA FROM THE OLD DATABASE (iControl)-------*/
IF (@DBType=0 or @DBType=2)
	BEGIN
			SET @sqlQueryOld='SELECT Distinct  P.PublisherID, OnR.WholesalerID, P.Bipad,
							 P.TitleName,Sum(OnR.MonR) AS MonReturns, Sum(OnR.TueR) AS TueReturns,
							 Sum(OnR.WedR) AS WedReturns,Sum(OnR.ThurR) AS ThurReturns, Sum(OnR.FriR) AS FriReturns,									
							 Sum(OnR.SatR) AS SatReturns,Sum(OnR.SunR) AS SunReturns, 
							 Sum([monR]+[TueR]+[WedR]+[ThurR]+[FriR]+[SatR]+[SunR]) AS TotalReturns,
						   Convert(varchar,OnR.WeekEndingCreditIssued,101) AS [Credit Week],
						   Convert(varchar,OnR.WeekEnding,101) AS [Credit are For Delivery Week], OnR.CostToWholesaler 
						  
								FROM  [IC-HQSQL2].iControl.dbo.OnR OnR   
								INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad  Where 1=1 '
								
		IF(@WholesalerID<>'-1')
			SET @sqlQueryOld += ' AND OnR.WholesalerID = ''' + @WholesalerID+''' '
			
		IF(@ChainId<>'-1')
			SET @sqlQueryOld += ' AND OnR.ChainID = ''' + @ChainId+''' '	
			
		IF(CAST(@WeekEnd AS DATE) <> CAST('1900-01-01' AS DATE))
			SET @sqlQueryOld += ' AND OnR.WeekEndingCreditIssued = ''' +Convert(Varchar, +@WeekEnd,101)+''' '
			
		SET @sqlQueryOld += ' GROUP BY P.PublisherID, OnR.WholesalerID, P.Bipad, 
			P.TitleName,OnR.WeekEndingCreditIssued, OnR.WeekEnding, OnR.CostToWholesaler'
	
		SET @sqlQueryOld += ' HAVING P.PublisherID=''' + @PublisherIdentifier + ''' '

	
End

/* (STEP 2)----GET DATA FROM THE NEW DATABASE (DataTrue_Main)-------*/
IF (@DBType=1 or @DBType=2)

BEGIN 
		IF object_id('tempdb.dbo.##tempReturnAffidavitsDraw') is not null
			BEGIN
				Drop Table ##tempReturnAffidavitsDraw;
			END
			SET @strquery='select distinct st.ChainID,st.SupplierID,St.Storeid,M.ManufacturerIdentifier,
							st.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempReturnAffidavitsDraw
							from dbo.Storetransactions_forward st
							INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN dbo.Suppliers sup  ON st.SupplierId=Sup.SupplierId
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							
							where TransactionTypeID in (29)							
							and M.ManufacturerID=' + @PublisherId
							
							
		IF(@WholesalerID<>'-1')					
				SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''			
							
		IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
				
		IF(CAST(@newStartdate as DATE) <> CAST('1900-01-01' as DATE))
			SET @strquery += ' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''

		IF(CAST(@newEnddate as DATE ) <> CAST('1900-01-01' as DATE)) 
			SET @strquery += ' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
			
		EXEC(@strquery)
		
		/* Get the data into tmp table for POS */
			IF object_id('tempdb.dbo.##tempReturnAffidavitsPOS') is not null
				BEGIN
				   drop table ##tempReturnAffidavitsPOS
				END		
			SET @strquery=' Select distinct st.ChainID,st.SupplierID,St.Storeid,M.ManufacturerIdentifier,										
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"
							
							into ##tempReturnAffidavitsPOS
							
							from dbo.Storetransactions st
							inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid 
							and tt.buckettype=1
							INNER JOIN dbo.Brands B ON st.BrandID=B.BrandID
							INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN dbo.Suppliers sup  ON st.SupplierId=Sup.SupplierId
							inner JOIN dbo.Chains c on st.ChainID=c.ChainID
							
							where 1 = 1						
							and M.ManufacturerID=' + @PublisherId
							
		IF(@WholesalerID<>'-1')					
				SET @strquery = @strquery +' and sup.SupplierIdentifier='''+@WholesalerID+''''			
							
		IF(@ChainID<>'-1')					
				SET @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
				
		IF(CAST(@newStartdate as DATE) <> CAST('1900-01-01' as DATE))
			SET @strquery += ' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''

		IF(CAST(@newEnddate as DATE ) <> CAST('1900-01-01' as DATE)) 
			SET @strquery += ' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
			
		exec(@strquery)			
				--Get the final data into final tmp table

		IF object_id('tempdb.dbo.##tempReturnAffidavitsFinalData') is not null
		BEGIN
				    DROP Table ##tempReturnAffidavitsFinalData
		END	
		
				SET @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) AS WeekEnding,
							CAST(NULL as nvarchar(50)) as "BiPad",
							CAST(NULL as nvarchar(225)) as "Title",
							CAST(NULL as nvarchar(50)) as "supplieridentifier"
							into ##tempReturnAffidavitsFinalData
						from
						(select * FROM 
							(SELECT * from ##tempReturnAffidavitsDraw ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws	
						join
						( select * from 
							(SELECT * from ##tempReturnAffidavitsPOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
							 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						on  tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'
						
						EXEC(@strquery)
			--Update the required fields
			SET @strquery='update f set
			f.supplieridentifier=(select distinct supplieridentifier from dbo.suppliers  
				where supplierid=f.supplierid),
			f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers 
				where ProductID=f.productid),
			f.title=(SELECT DISTINCT  ProductName  from dbo.Products 
				where ProductID=f.productid),
			f.WeekEnding=(select distinct top 1 Saledatetime from dbo.Storetransactions_forward 
							where supplierid=F.supplierid and ChainId=f.ChainId and StoreID=F.StoreID and 
							ProductId=F.ProductId and TransactionTypeID in (29))
			from ##tempReturnAffidavitsFinalData f'
			EXEC(@strquery)
		--Return the Data
			SET @sqlQueryNew='Select Distinct ManufacturerIdentifier as PublisherID,
								supplieridentifier as WholesalerID,
								Bipad,title as TitleName,
								sum(mondaydraw-mondayPOS) as MonReturns,
								sum(tuesdaydraw-tuesdayPOS) as TueReturns,
								sum(wednesdaydraw-wednesdayPOS) as WedReturns,
								sum(thursdaydraw-thursdayPOS) as ThurReturns,
								sum(fridaydraw-fridayPOS) as FriReturns,
								sum(saturdaydraw-saturdayPOS) as SatReturns,
								sum(sundaydraw-sundayPOS) as SunReturns,	
								Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+
								sundaydraw-(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+
								saturdayPOS+sundayPOS)) AS [TotalReturns],
								Convert(Varchar,(Convert(datetime,WeekEnding)),101) as [Credit Week],
								Convert(Varchar,(Convert(datetime,WeekEnding)),101) as [Credit are For Delivery Week],
								0 as CostToWholesaler
								From 
								##tempReturnAffidavitsFinalData
								group by chainid,supplieridentifier,StoreID,productid,bipad,title,mondaydraw,tuesdaydraw,wednesdaydraw,thursdaydraw,fridaydraw,
								saturdaydraw,sundaydraw ,mondayPOS ,tuesdayPOS ,wednesdayPOS,thursdayPOS ,fridayPOS,saturdayPOS,sundayPOS,WeekEnding,
								ManufacturerIdentifier  
								;'
								
END
	IF(@DBType=2)
		BEGIN
			SET @strqueryNewFinal=@sqlQueryOld + ' UNION ' + @sqlQueryNew
			EXEC(@strqueryNewFinal)
		END
	ELSE IF(@DBType=1)
		BEGIN
			EXEC(@sqlQueryNew)
		END
	ELSE IF(@DBType=0)
		BEGIN
			EXEC(@sqlQueryOld)
		END				
END
GO
