USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetWeekending]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[amb_GetWeekending]
@SupplierIdentifier varchar(10),
@SupplierId varchar(20),
@ChainID varchar(10),
@StoreNumber varchar(10)
AS
--exec amb_GetWeekending 'CLL','24164','DQ',''
BEGIN
	DECLARE @sqlQueryOld VARCHAR(8000)
	DECLARE @sqlQueryNew VARCHAR(8000)
	declare @strQueryNew varchar(4000)
	DECLARE @sqlQueryBoth VARCHAR(8000)
	Declare @DBType int --0 for old database, 1 from mixed
	DECLARE @chain_migrated_date date	
	DECLARE @BillingControlDay INT
	DECLARE @TodayDayOfWeek INT
	DECLARE @EndOfPrevWeek DateTime
	DECLARE @EndOfPrevWeek1 DateTime
	DECLARE @StartOfPrevWeek DateTime
	DECLARE @CurrentDate DateTime =Getdate()+14

SELECT @chain_migrated_date = cast(datemigrated AS VARCHAR)
FROM
	dbo.chains_migration
WHERE
	chainid = @chainID;
			IF ( @chain_migrated_date IS NULL )
SET @dbtype = 0
			else SET @dbtype = 1
		
			/* (STEP 1) GET DATA FROM THE OLD DATBASE (icontrol)*/
			IF (@dbtype=0 or @dbtype=1)
				BEGIN
SET @sqlQueryOld = 'SELECT OnR.WeekEnding 
													FROM ([IC-HQSQL2].iControl.dbo.BaseOrder 
													INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList ON BaseOrder.ChainID = StoresList.ChainID)
													INNER JOIN  [IC-HQSQL2].iControl.dbo.OnR ON (OnR.StoreID = StoresList.StoreID) 
													AND (OnR.ChainID = StoresList.ChainID)		
													AND (BaseOrder.WholesalerID = OnR.WholesalerID) AND (BaseOrder.Bipad = OnR.Bipad)
													Where 1=1 and BaseOrder.WholesalerID=''' + @supplieridentifier + ''''
SET @sqlQueryOld += ' and  BaseOrder.ChainID =''' + @ChainID + ''''						
														  
				IF ( @StoreNumber <> '' )
SET @sqlQueryOld += ' AND StoresList.StoreNumber Like ''%' + @StoreNumber + '%'''
SET @sqlQueryOld += ' GROUP BY OnR.WeekEnding '      
			
				END
			/* (STEP 2) GET DATA FROM THE NEW DATABASE (DataTrue_Main)*/		
				if(@dbtype=1)
				BEGIN
--Declare @SupplierID int=24164; Declare @ChainID int =62362



SELECT @BillingControlDay = BillingControlDay
FROM
	BillingControl BC
	INNER JOIN Chains C
		ON C.ChainID = BC.ChainID
WHERE
	C.ChainIdentifier = @ChainID
	AND EntityIDToInvoice = @SupplierID

				/*
					select * from BillingControl
					where ChainID=35541 and EntityIDToInvoice=37803
					*/
				--Please Remove below 
				--set @BillingControlDay=2;


				--get number of a current day (1-Sunday,2-Monday, 3-Tuesday... 7-Saturday)
				SET @TodayDayOfWeek = datepart (dw, @CurrentDate)
				--get the last day of the previous week (last Sunday)
				SET @EndOfPrevWeek = dateadd(dd, @BillingControlDay - @TodayDayOfWeek, @CurrentDate)
				--get the first day of the previous week (the Monday before last)
				--SET @StartOfPrevWeek = dateadd(dd, @BillingControlDay - (@TodayDayOfWeek + 7), @CurrentDate)
				
				SET @EndOfPrevWeek1 = DATEADD(dd, -7, @EndOfPrevWeek)
				print isnull(object_id('tempdb.dbo.##temp_weekEnding'),'0')
				IF isnull(object_id('tempdb.dbo.##temp_weekEnding'),'0')!='0'
				BEGIN
				print 'drop'
				--Declare  @@weekending Table (dt varchar(12))
				DROP TABLE ##temp_weekEnding;
				END
				--set @strQueryNew='SELECT '''+ cast (@EndOfPrevWeek as varchar)+''' INTO ##temp_weekEnding; SELECT '''+ cast(@StartOfPrevWeek as VARCHAR)+''' INTO ##temp_weekEnding;'
				set @strQueryNew='SELECT '''+ cast (@EndOfPrevWeek as varchar)+''' as dt INTO ##temp_weekEnding; insert into ##temp_weekEnding(dt) values( '''+ cast(@EndOfPrevWeek1 as VARCHAR)+''');'

				exec(@strQueryNew) 
				set @sqlQueryNew ='SELECT * FROM ##temp_weekEnding'

					
				--	@sqlQueryNew='selet * from '
				--		--print @EndOfPrevWeek
				--		--print @StartOfPrevWeek
																							
				END				
			
				if(@dbtype=0)
						Begin
							Exec('select TOP 2 * from ('+@sqlQueryOld+') a  Order BY WeekEnding Desc')				
						End
				IF(@dbtype=1)	
				Begin			
					Exec( 'select TOP 2 * from ('+@sqlQueryOld + ' union  ' + @sqlQueryNew +' ) a Order BY WeekEnding Desc') 
				End
		END
GO
