USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetWeekendings_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[amb_GetWeekendings_PRESYNC_20150415]
@SupplierIdentifier varchar(10),
@SupplierId varchar(20),
@ChainID varchar(10),
@StoreNumber varchar(10)
AS
--exec amb_GetWeekendings 'CLL','24164','DQ',''
--exec amb_GetWeekendings 'WR281','25194','SV',''
BEGIN
	DECLARE @sqlQueryNew VARCHAR(8000)
	declare @strQueryNew varchar(4000)
	DECLARE @sqlQueryBoth VARCHAR(8000)
	DECLARE @chain_migrated_date date	
	DECLARE @BillingControlDay INT
	DECLARE @TodayDayOfWeek INT
	DECLARE @EndOfPrevWeek DateTime
	DECLARE @EndOfPrevWeek1 DateTime
	DECLARE @StartOfPrevWeek DateTime
	DECLARE @CurrentDate DateTime =Getdate()+7

		
	SELECT @BillingControlDay = BillingControlDay
	FROM BillingControl BC
	INNER JOIN Chains C ON C.ChainID = BC.ChainID
	WHERE C.ChainIdentifier = @ChainID AND EntityIDToInvoice = @SupplierID

	--get number of a current day (1-Sunday,2-Monday, 3-Tuesday... 7-Saturday)
	SET @TodayDayOfWeek = datepart (dw, @CurrentDate)
	--get the last day of the previous week (last Sunday)
	SET @EndOfPrevWeek = dateadd(dd, @BillingControlDay - @TodayDayOfWeek, @CurrentDate)
	--get the first day of the previous week (the Monday before last)

	SET @EndOfPrevWeek1 = DATEADD(dd, -7, @EndOfPrevWeek)
	
	IF isnull(object_id('tempdb.dbo.##temp_weekEnding'),'0')!='0'
		BEGIN
			DROP TABLE ##temp_weekEnding;
		END
	SET @strQueryNew='SELECT '''+ cast (@EndOfPrevWeek as varchar)+''' as WeekEnding INTO ##temp_weekEnding; 
	insert into ##temp_weekEnding(WeekEnding) values( '''+ cast(@EndOfPrevWeek1 as VARCHAR)+''');'

	EXEC(@strQueryNew);
	PRINT(@strQueryNew);
	
	SET @sqlQueryNew ='SELECT * FROM ##temp_weekEnding '
	EXEC('select TOP 2 CAST(WeekEnding AS DATE) AS WeekEnding from ('+@sqlQueryNew+ ') a  Order BY WeekEnding Desc')
END
GO
