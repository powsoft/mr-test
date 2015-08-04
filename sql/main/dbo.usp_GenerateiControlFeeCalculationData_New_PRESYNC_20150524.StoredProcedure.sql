USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateiControlFeeCalculationData_New_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- DescriptiON:	<DescriptiON,,>
-- =============================================
-- exec [usp_GenerateiControlFeeCalculationData_NEw] '%', '%', 11, 2014
CREATE PROCEDURE [dbo].[usp_GenerateiControlFeeCalculationData_New_PRESYNC_20150524]
	-- Add the parameters for the stored procedure here
	@ChainId varchar(5),
	@SupplierId varchar(5),
	@ForMonth varchar(4),
	@ForYear varchar(4)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SET ANSI_WARNINGS ON;

	BEGIN TRY
		BEGIN TRANSACTION
			
			IF OBJECT_ID('#tmpStoreCounts', 'U') IS NOT NULL
				DROP TABLE #tmpStoreCounts
			
			IF OBJECT_ID('#tmpBillingSBT', 'U') IS NOT NULL
				DROP TABLE #tmpBillingSBT
			
			IF OBJECT_ID('#tmpRegulatedPayment', 'U') IS NOT NULL
				DROP TABLE #tmpRegulatedPayment
				
			--GET PERIOD START AND END DATES
			DECLARE @PeriodStartDate DATE
			DECLARE @PeriodEndDate DATE
			
			SET @PeriodStartDate = @ForYear + '-' + @ForMonth + '-01'
			SET @PeriodEndDate = DATEADD(DD, -1, DATEADD(M, 1, @PeriodStartDate))
			
			;WITH SitesCalcsTable AS
			(
			SELECT DISTINCT OverallCalcs.ChainID, ActiveCalcs.SupplierID, OverallCalcs.OverallSiteCount, ActiveCalcs.ActiveSiteCount
			FROM
			(
				SELECT DISTINCT C.ChainId, ISNULL(COALESCE(COUNT(S.StoreID), 0), 0) AS OverallSiteCount
				--INTO #tmpSiteCount
				FROM dbo.Stores AS S WITH (NOLOCK)
				INNER JOIN dbo.Chains AS C WITH (NOLOCK)
				ON 1 = 1
				AND C.ChainId = S.ChainID
				AND (S.ActiveFromDate <= @PeriodEndDate AND S.ActiveLastDate >= @PeriodStartDate)
				WHERE 1=1 
				AND C.ChainId like @ChainId
				AND C.PDITradingPartner=1
				GROUP BY C.ChainID
			) AS OverallCalcs
			OUTER APPLY
			(
				SELECT DISTINCT SS.ChainID, SS.SupplierID, ISNULL(COALESCE(COUNT(DISTINCT SS.StoreID), 0), 0) AS ActiveSiteCount
				FROM dbo.StoreSetup AS SS WITH (NOLOCK)
				INNER JOIN dbo.Chains AS C WITH (NOLOCK)ON 1 = 1 AND C.ChainId = SS.ChainID
				INNER JOIN dbo.Suppliers AS S WITH (NOLOCK)ON 1 = 1 AND S.SupplierId= SS.SupplierId
				WHERE 1 = 1
				AND SS.ChainId like @ChainId 
				AND SS.SupplierId like @SupplierId 
				AND C.PDITradingPartner=1
				AND S.PDITradingPartner=1
				AND SS.ChainID = OverallCalcs.ChainID
				AND SS.StoreID <> 0
				AND (SS.ActiveStartDate <= @PeriodEndDate AND SS.ActiveLastDate >= @PeriodStartDate)
				GROUP BY SS.ChainID, SS.SupplierID
			) AS ActiveCalcs
			WHERE ActiveCalcs.SupplierID IS NOT NULL
			)

			SELECT DISTINCT SitesCalcsTable.ChainID, 
			SitesCalcsTable.SupplierID, 
			MAX(SitesCalcsTable.OverallSiteCount) AS OverallSiteCount, 
			MAX(SitesCalcsTable.ActiveSiteCount) AS ActiveSiteCount, 
			COALESCE(COUNT(PP.ProductID), 0) AS [Sum of All SKU]
			into #tmpStoreCounts
			FROM SitesCalcsTable
			LEFT OUTER JOIN DataTrue_Main.dbo.ProductPrices AS PP WITH (NOLOCK)
			ON 1 = 1
			AND PP.ChainID = SitesCalcsTable.ChainID
			AND PP.SupplierID = SitesCalcsTable.SupplierID
			AND PP.SupplierID > 0
			AND (PP.ActiveStartDate <= @PeriodEndDate AND PP.ActiveLastDate >= @PeriodStartDate)
			WHERE PP.ChainId like @ChainId 
			AND PP.SupplierId like @SupplierId 
			GROUP BY SitesCalcsTable.ChainID, SitesCalcsTable.SupplierID
			ORDER BY SitesCalcsTable.ChainID, SitesCalcsTable.SupplierID

			------FOR SCAN BASED TRADING NON-NEWSPAPER
			
			SELECT DISTINCT SS.ChainId AS EntityIdRetailer, SS.SupplierId AS EntityIdSupplier,
			COALESCE(SUM((SS.RuleCost*Qty) + isnull(SS.Adjustment1,0) + isnull(SS.Adjustment2,0) + isnull(SS.Adjustment3,0) + isnull(SS.Adjustment4,0) + isnull(SS.Adjustment5,0) + isnull(SS.Adjustment6,0) + isnull(SS.Adjustment7,0) + isnull(SS.Adjustment8,0)),0) AS CostDollars,
			COALESCE(SUM((SS.RuleRetail*Qty) + isnull(SS.Adjustment1,0) + isnull(SS.Adjustment2,0) + isnull(SS.Adjustment3,0) + isnull(SS.Adjustment4,0) + isnull(SS.Adjustment5,0) + isnull(SS.Adjustment6,0) + isnull(SS.Adjustment7,0) + isnull(SS.Adjustment8,0)),0) AS RetailDollars,
			NULL as [LegacyCostDollars],
			NULL as [LegacyRetailDollars]
			into #tmpBillingSBT
			FROM DataTrue_Main.dbo.StoreTransactions AS SS WITH (NOLOCK)
			INNER JOIN Chains AS C WITH (NOLOCK) ON C.ChainID = SS.ChainID
			INNER JOIN TransactionTypes AS T WITH (NOLOCK) ON T.TransactionTypeID = SS.TransactionTypeID
			INNER JOIN Suppliers AS S WITH (NOLOCK) ON S.SupplierID = SS.SupplierID
			WHERE 1 = 1
			AND SS.ChainId like @ChainId 
			AND SS.SupplierId like @SupplierId 
			AND (SS.SaleDateTime BETWEEN @PeriodStartDate AND @PeriodEndDate)
			AND SS.SupplierID > 0
			AND T.BucketTypeName = 'POS'
			AND S.IsRegulated = 0
			AND isnull(SS.RecordType,0)<>2
			GROUP BY SS.ChainId, SS.SupplierId

			UNION
			------FOR SCAN BASED TRADING NEWSPAPER
			
			SELECT DISTINCT SS.ChainId AS EntityIdRetailer, NULL,
			COALESCE(SUM((SS.RuleCost*Qty) + isnull(SS.Adjustment1,0) + isnull(SS.Adjustment2,0) + isnull(SS.Adjustment3,0) + isnull(SS.Adjustment4,0) + isnull(SS.Adjustment5,0) + isnull(SS.Adjustment6,0) + isnull(SS.Adjustment7,0) + isnull(SS.Adjustment8,0)),0) AS CostDollars,
			COALESCE(SUM((SS.RuleRetail*Qty) + isnull(SS.Adjustment1,0) + isnull(SS.Adjustment2,0) + isnull(SS.Adjustment3,0) + isnull(SS.Adjustment4,0) + isnull(SS.Adjustment5,0) + isnull(SS.Adjustment6,0) + isnull(SS.Adjustment7,0) + isnull(SS.Adjustment8,0)),0) AS RetailDollars,
			NULL as [LegacyCostDollars],
			NULL as [LegacyRetailDollars]
			FROM dbo.StoreTransactions AS SS WITH (NOLOCK)
			INNER JOIN Chains AS C WITH (NOLOCK) ON C.ChainID = SS.ChainID
			INNER JOIN TransactionTypes AS T WITH (NOLOCK) ON T.TransactionTypeID = SS.TransactionTypeID
			WHERE 1 = 1
			AND SS.ChainId like @ChainId 
			AND (SS.SaleDateTime BETWEEN @PeriodStartDate AND @PeriodEndDate)
			AND SS.SupplierID > 0
			AND T.BucketTypeName = 'POS'
			AND SS.RecordType=2
			GROUP BY SS.ChainId
			
			UNION
			------FOR Legacy Records
			
			SELECT C.ChainID, NULL, NULL, NULL,
			SUM(([monsl]+[tuesl]+[wedsl]+[thursl]+[frisl]+[satsl]+[sunsl])*[CostToWholeSaler]) AS CostDollars,
			SUM(([monsl]+[tuesl]+[wedsl]+[thursl]+[frisl]+[satsl]+[sunsl])*[suggretail]) AS RetailDollars
			FROM [IC-HQSQL2].[icontrol].dbo.[OnR] as O with (nolock)
			inner join Chains C with (nolock) on O.ChainId=C.ChainIdentifier
			WHERE 1=1
			AND (O.WeekEnding BETWEEN @PeriodStartDate AND @PeriodEndDate)
			GROUP BY C.ChainID
			having SUM(([monsl]+[tuesl]+[wedsl]+[thursl]+[frisl]+[satsl]+[sunsl])*[suggretail])>0

			--FOR REGULATED
			
			SELECT DISTINCT IVD.ChainId AS EntityIdRetailer, IVD.SupplierId AS EntityIdSupplier,
			COALESCE(COUNT(DISTINCT RetailerInvoiceID),0) AS TransactionCount
			into #tmpRegulatedPayment
			FROM Invoicedetails AS IVD WITH (NOLOCK)
			INNER JOIN Chains AS C WITH (NOLOCK) ON C.ChainID = IVD.ChainID
			INNER JOIN Suppliers AS S WITH (NOLOCK) ON S.SupplierID = IVD.SupplierID
			WHERE 1 = 1
			AND IVD.ChainId like @ChainId 
			AND IVD.SupplierId like @SupplierId 
			AND CAST(IVD.DateTimeCreated AS DATE) BETWEEN @PeriodStartDate AND @PeriodEndDate
			AND IVD.SupplierID > 0 
			AND IVD.InvoiceDetailTypeID = 2 
			AND ABS(TotalCost) > .01
			AND S.IsRegulated = 1
			GROUP BY IVD.ChainId, IVD.SupplierId
			ORDER BY IVD.ChainID, IVD.SupplierId

			-- Creating a dataset of Chains and Suppliers to show on report
			-- For SBT- We need to show Chain/Supplier which exist in SBTServiceFees Table
			-- For Newspaper: Need not to show on Supplier Level, show data on Chain Level only
			-- For PDI: Everything from SupplierBanners where ISPDi flag is 1 for Supplier and Chain
			-- For regulated: Everything from SupplierBanners where IsRegulated flag is 1 for Supplier and Chain
			
			Select DISTINCT EntityIdRetailer as ChainId, EntityIdSupplier as SupplierId into #tmpChainSuppliers from #tmpBillingSBT 
			Union 
			Select DISTINCT T.ChainId, T.SupplierID from #tmpStoreCounts T 
			inner JOIN Suppliers S on S.SupplierID=T.SupplierId and S.PDITradingPartner=1
			inner JOIN Chains C on C.ChainID = T.ChainID and C.PDITradingPartner=1
			Union 
			Select DISTINCT EntityIdRetailer, EntityIdSupplier from #tmpRegulatedPayment 

			-- Remove the old data from the table corresponding to the requested chain supplier month and year.
			Delete from dbo.iControlFeeCalculation_Test where ReportMonth=@ForMOnth and ReportYear=@ForYear and ChainId like @ChainId and SupplierId like @SupplierId

			--Insertions into Final Table For Supplier Fees			
			Insert into dbo.iControlFeeCalculation_Test
			SELECT DISTINCT cast(@ForYear as int), cast(@ForMonth as int), C.ChainID, C.ChainName, S.SupplierID, S.SupplierName,
			SC.ActiveSiteCount as [DX # of Stores], 
			CASE WHEN S.PDITradingPartner = 0 THEN NULL else(SELECT [Pb,Inv Only] FROM DXServiceFees DS where (SC.ActiveSiteCount BETWEEN DS.StoreRangeFrom and DS.StoreRangeTo) AND (@PeriodStartDate>=DS.ActiveStartDate AND @PeriodEndDate<=DS.ActiveEndDate) and Type='Supplier') END as [DX Fee/Store Supplier],
			null as [DX Fee/Store Retailer],
			B.CostDollars as [SBT Total Cost POS Transactions $],
			B.RetailDollars as [SBT Total Retail POS Transactions $],
			B.[LegacyCostDollars] as [SBT Legacy Total Cost POS Transactions $],
			B.[LegacyRetailDollars] as [SBT Legacy Total Retail POS Transactions $],
			RF.Fees as [SBT Fees],
			RF.FeeMode as  [SBT Fees Mode], 
			R.TransactionCount  as [Regulated # of Invoices],
			SF.ServiceFeeFactorValue as [Regulated Fee/Invoice Supplier],
			null as [Regulated Fee/Invoice Retailer],
			getdate() as [DatetTimeCreated]
			
			from #tmpChainSuppliers SB WITH (NOLOCK)
			inner join Suppliers S WITH (NOLOCK) on S.SupplierID=SB.SupplierID
			inner join Chains C WITH (NOLOCK) on C.ChainID=SB.ChainID
			left join #tmpBillingSBT B on B.EntityIdRetailer=C.ChainID and B.EntityIdSupplier=S.SupplierID
			left join #tmpStoreCounts SC on SC.ChainID=C.ChainId and SC.SupplierId=S.SupplierId
			left join #tmpRegulatedPayment R on R.EntityIdRetailer=C.ChainID and R.EntityIdSupplier=S.SupplierID
			LEFT JOIN SBTServiceFees RF ON RF.ChainId=C.ChainID and RF.SupplierId=S.SupplierId and (@PeriodStartDate>=RF.ActiveStartDate AND @PeriodEndDate<=RF.ActiveEndDate)
			LEFT JOIN (select SF.ChainID, SF.SupplierID, SF.ServiceFeeFactorValue 
							from ServiceFees SF
							where ServiceFeeTypeID in (2,3) and SF.ChainID<>0 and SF.SupplierId<>0
							and (@PeriodStartDate>=SF.ActiveStartDate AND @PeriodEndDate<=SF.ActiveLastDate)
					   ) as SF on SF.ChainId=C.ChainID and SF.SupplierId=SB.SupplierId
			WHERE 1=1 And SB.SupplierId>0
			AND SB.ChainId like @ChainId 
			AND SB.SupplierId like @SupplierId 
			
			
			--Insertions into Final Table For Retailer Fees
			Insert into dbo.iControlFeeCalculation_Test_Test
			SELECT DISTINCT cast(@ForYear as int), cast(@ForMonth as int), C.ChainID, C.ChainName, null as SupplierID, null as SupplierName,
			SC.StoreCount as [DX # of Stores] , 
			null as [DX Fee/Store Supplier],
			CASE WHEN C.PDITradingPartner = 0 THEN NULL else (SELECT [Pb,Inv Only] FROM DXServiceFees DS where (SC.StoreCount BETWEEN DS.StoreRangeFrom and DS.StoreRangeTo) and(@PeriodStartDate>=DS.ActiveStartDate AND @PeriodEndDate<=DS.ActiveEndDate) and Type='Retailer') End as [DX Fee/Store Retailer],
			B.CostDollars as [SBT Total Cost POS Transactions $],
			B.RetailDollars as [SBT Total Retail POS Transactions $], 
			B.[LegacyCostDollars] as [SBT Legacy Total Cost POS Transactions $],
			B.[LegacyRetailDollars] as [SBT Legacy Total Retail POS Transactions $],
			RF.Fees as [SBT Fees],
			RF.FeeMode as  [SBT Fees Mode],  
			R.InvoiceCount as [Regulated # of Invoices],
			null as [Regulated Fee/Invoice Supplier],
			SF.ServiceFeeFactorValue as [Regulated Fee/Invoice Retailer],
			getdate() as [DatetTimeCreated]
			
			from #tmpChainSuppliers SB WITH (NOLOCK)
			inner join Chains C WITH (NOLOCK) on C.ChainID=SB.ChainID
			LEFT JOIN SBTServiceFees RF ON RF.ChainId=C.ChainID and RF.SupplierId is null and (@PeriodStartDate>=RF.ActiveStartDate AND @PeriodEndDate<=RF.ActiveEndDate)
			Left JOin (Select ChainID, sum(ActiveSiteCount) as StoreCount from #tmpStoreCounts group by ChainID) SC on SC.ChainID = SB.ChainId
			LEFT JOIN (Select EntityIdRetailer, sum(CostDollars) as CostDollars, sum(RetailDollars) as RetailDollars 
									from  #tmpBillingSBT T
									inner JOIN SBTServiceFees SSF ON SSF.chainID=T.EntityIdRetailer and SSF.SupplierId=T.EntityIdSupplier
									group by EntityIdRetailer
								 ) B on  B.EntityIdRetailer = SB.ChainID
			LEFT JOIN (Select EntityIdRetailer, sum(TransactionCount) as InvoiceCount from #tmpRegulatedPayment group by EntityIdRetailer) R on R.EntityIdRetailer=SB.ChainID
			LEFT JOIN (select SF.ChainID, SF.ServiceFeeFactorValue 
							from ServiceFees SF
							where ServiceFeeTypeID in (2,3) and SF.ChainID<>0 and SupplierId=0
							and (@PeriodStartDate>=SF.ActiveStartDate AND @PeriodEndDate<=SF.ActiveLastDate)
					   ) as SF on SF.ChainId=C.ChainID 
			WHERE 1=1 And SB.SupplierId>0 AND SB.ChainId like @ChainId and @SupplierId = '%'
			
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorEmailBody NVARCHAR(MAX);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			
		SELECT @ErrorEmailBody = 'An exception was encountered in usp_PDI_UpdateAPISyncTables.  Message: ' + @ErrorMessage
			
		--EXEC dbo.prSendEmailNotification_PassEmailAddresses 'ERROR in job PDI_UpdateAPIBillingComponents'
		--	,@ErrorEmailBody
		--	,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
			
		RAISERROR (@ErrorMessage,
				   @ErrorSeverity,
				   @ErrorState
				   );
	END CATCH
	
END
GO
