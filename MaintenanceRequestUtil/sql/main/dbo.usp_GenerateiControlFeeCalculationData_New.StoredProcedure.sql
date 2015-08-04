USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateiControlFeeCalculationData_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- DescriptiON:	<DescriptiON,,>
-- =============================================
-- exec [usp_GenerateiControlFeeCalculationData_New] '%', '%', 12, 2014
CREATE PROCEDURE [dbo].[usp_GenerateiControlFeeCalculationData_New]
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
	
	SET ANSI_WARNINGS OFF;

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
		LEFT OUTER JOIN ProductPrices AS PP WITH (NOLOCK)
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
		NULL as [LegacyRetailDollars],
	    CAST(SS.SaleDateTime AS DATE) as SaleDateTime
		into #tmpBillingSBT
		FROM StoreTransactions AS SS WITH (NOLOCK)
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
		GROUP BY SS.ChainId, SS.SupplierId, CAST(SS.SaleDateTime AS DATE)

		UNION
		------FOR SCAN BASED TRADING NEWSPAPER
		
		SELECT DISTINCT SS.ChainId AS EntityIdRetailer, NULL,
		COALESCE(SUM((SS.RuleCost*Qty) + isnull(SS.Adjustment1,0) + isnull(SS.Adjustment2,0) + isnull(SS.Adjustment3,0) + isnull(SS.Adjustment4,0) + isnull(SS.Adjustment5,0) + isnull(SS.Adjustment6,0) + isnull(SS.Adjustment7,0) + isnull(SS.Adjustment8,0)),0) AS CostDollars,
		COALESCE(SUM((SS.RuleRetail*Qty) + isnull(SS.Adjustment1,0) + isnull(SS.Adjustment2,0) + isnull(SS.Adjustment3,0) + isnull(SS.Adjustment4,0) + isnull(SS.Adjustment5,0) + isnull(SS.Adjustment6,0) + isnull(SS.Adjustment7,0) + isnull(SS.Adjustment8,0)),0) AS RetailDollars,
		NULL as [LegacyCostDollars],
		NULL as [LegacyRetailDollars],
		CAST(SS.SaleDateTime AS DATE) as SaleDateTime
		FROM dbo.StoreTransactions AS SS WITH (NOLOCK)
		INNER JOIN Chains AS C WITH (NOLOCK) ON C.ChainID = SS.ChainID
		INNER JOIN TransactionTypes AS T WITH (NOLOCK) ON T.TransactionTypeID = SS.TransactionTypeID
		WHERE 1 = 1
		AND SS.ChainId like @ChainId 
		AND (SS.SaleDateTime BETWEEN @PeriodStartDate AND @PeriodEndDate)
		AND SS.SupplierID > 0
		AND T.BucketTypeName = 'POS'
		AND SS.RecordType=2
		GROUP BY SS.ChainId,CAST(SS.SaleDateTime AS DATE)
		
		UNION
		------FOR Legacy Records
		
		SELECT C.ChainID, NULL, NULL, NULL,
		CostDollars,
		RetailDollars,
		WeekEnding
		FROM [ONR_Transactions] as O with (nolock)
		inner join Chains C with (nolock) on O.ChainId=C.ChainIdentifier
		WHERE 1=1 AND C.ChainId like @ChainId
		AND (O.WeekEnding BETWEEN @PeriodStartDate AND @PeriodEndDate)		
		
		--FOR REGULATED
		
		SELECT DISTINCT IVD.ChainId AS EntityIdRetailer, IVD.SupplierId AS EntityIdSupplier, CAST(IVD.DateTimeCreated AS DATE) as InvoiceEntryDate,
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
		GROUP BY IVD.ChainId, IVD.SupplierId, CAST(IVD.DateTimeCreated AS DATE)
		ORDER BY IVD.ChainID, IVD.SupplierId

				
		-- Creating a dataset of Chains and Suppliers to show on report
		-- For SBT- We need to show Chain/Supplier which exist in SBTServiceFees Table
		-- For Newspaper: Need not to show on Supplier Level, show data on Chain Level only
		-- For PDI: Everything from SupplierBanners where ISPDI flag is 1 for Supplier and Chain 
		-- For regulated: Everything from SupplierBanners where IsRegulated flag is 1 for Supplier and Chain
		
		Select DISTINCT SFS.ChainId, SFS.SupplierId into #tmpChainSuppliers 
		from SBTServiceFees SFS
		Inner JOIN #tmpBillingSBT T  ON SFS.ChainId=T.EntityIdRetailer and (SFS.SupplierId = T.EntityIdSupplier OR SFS.SupplierId IS NULL)
		
		Union 
		
		Select DISTINCT T.ChainId, T.SupplierID from #tmpStoreCounts T 
		inner JOIN Suppliers S on S.SupplierID=T.SupplierId and S.PDITradingPartner=1
		inner JOIN Chains C on C.ChainID = T.ChainID and C.PDITradingPartner=1
		
		Union 
		Select DISTINCT EntityIdRetailer, EntityIdSupplier from #tmpRegulatedPayment 

		-- Remove the old data from the table corresponding to the requested chain supplier month and year.
		Delete from DataTrue_CustomResultSets.dbo.iControlFeeCalculation_Test where ReportMonth=@ForMOnth and ReportYear=@ForYear and ChainId like @ChainId 
		and (SupplierId like @SupplierId OR SupplierID IS NULL)

		--Insertions into Final Table For Supplier Fees			
		Insert into DataTrue_CustomResultSets.dbo.iControlFeeCalculation_Test
		SELECT DISTINCT cast(@ForYear as int), cast(@ForMonth as int), C.ChainID, C.ChainName, S.SupplierID, S.SupplierName,
		SC.ActiveSiteCount as [DX # of Stores], 
		CASE WHEN S.PDITradingPartner = 0 THEN NULL else(SELECT [Pb,Inv Only] FROM DXServiceFees DS where (SC.ActiveSiteCount BETWEEN DS.StoreRangeFrom and DS.StoreRangeTo) AND (@PeriodStartDate>=DS.ActiveStartDate AND @PeriodEndDate<=DS.ActiveEndDate) and Type='Supplier') END as [DX Fee/Store Supplier],
		null as [DX Fee/Store Retailer],
		B.CostDollars as [SBT Total Cost POS Transactions $],
		B.RetailDollars as [SBT Total Retail POS Transactions $],
		NULL as [SBT Legacy Total Cost POS Transactions $],
		NULL as [SBT Legacy Total Retail POS Transactions $],
		B.Fees as [SBT Fees],
		B.FeeMode as  [SBT Fees Mode], 
		B.CalculateOn as [SBT Fees Calculate On],
		R.TransactionCount  as [Regulated # of Invoices],
		R.ServiceFeeFactorValue as [Regulated Fee/Invoice Supplier],
		null as [Regulated Fee/Invoice Retailer],
		getdate() as [DatetTimeCreated]
		
		from #tmpChainSuppliers SB WITH (NOLOCK)
		inner join Suppliers S WITH (NOLOCK) on S.SupplierID=SB.SupplierID
		inner join Chains C WITH (NOLOCK) on C.ChainID=SB.ChainID
		left join (SELECT EntityIdRetailer,EntityIdSupplier,sum(CostDollars) as CostDollars,sum(B.RetailDollars) as RetailDollars,
							SF.Fees, SF.FeeMode, SF.CalculateOn
						  from #tmpBillingSBT B 
						  inner join SBTServiceFees SF on B.EntityIdRetailer=SF.ChainID and B.EntityIdSupplier=SF.SupplierID
						  WHERE B.SaleDateTime BETWEEN SF.ActiveStartDate AND SF.ActiveEndDate
						  GROUP by EntityIdRetailer,EntityIdSupplier,SF.Fees, SF.FeeMode, SF.CalculateOn
							) B ON B.EntityIdRetailer=C.ChainID and B.EntityIdSupplier=S.SupplierID
		left join #tmpStoreCounts SC on SC.ChainID=C.ChainId and SC.SupplierId=S.SupplierId
		left join (Select SF.ChainID, SF.SupplierID, SF.ServiceFeeFactorValue, sum(TransactionCount)  as TransactionCount
									from #tmpRegulatedPayment R 
									inner join ServiceFees SF on R.EntityIdRetailer=SF.ChainID and R.EntityIdSupplier=SF.SupplierID
									where ServiceFeeTypeID in (2,3) and SF.ChainID<>0 and SF.SupplierId<>0
									AND R.InvoiceEntryDate BETWEEN SF.ActiveStartDate AND SF.ActiveLastDate
									group BY SF.ChainID, SF.SupplierID, SF.ServiceFeeFactorValue
							) R on R.SupplierID=S.SupplierId and R.ChainID=C.ChainID
		WHERE 1=1 And SB.SupplierId>0
		AND SB.ChainId like @ChainId 
		AND SB.SupplierId like @SupplierId 
		
		--Insertions into Final Table For Retailer Fees

			Insert into DataTrue_CustomResultSets.dbo.iControlFeeCalculation_Test
			SELECT DISTINCT cast(@ForYear as int), cast(@ForMonth as int), C.ChainID, C.ChainName, null as SupplierID, null as SupplierName,
			SC.StoreCount as [DX # of Stores] , 
			null as [DX Fee/Store Supplier],
			CASE WHEN C.PDITradingPartner = 0 THEN NULL else (SELECT [Pb,Inv Only] FROM DXServiceFees DS where (SC.StoreCount BETWEEN DS.StoreRangeFrom and DS.StoreRangeTo) and(@PeriodStartDate>=DS.ActiveStartDate AND @PeriodEndDate<=DS.ActiveEndDate) and Type='Retailer') End as [DX Fee/Store Retailer],
			B.CostDollars as [SBT Total Cost POS Transactions $],
			B.RetailDollars as [SBT Total Retail POS Transactions $], 
			B1.[LegacyCostDollars] as [SBT Legacy Total Cost POS Transactions $],
			B1.[LegacyRetailDollars] as [SBT Legacy Total Retail POS Transactions $],
			isnull(B.Fees, B1.Fees) as [SBT Fees],
			isnull(B.FeeMode, B1.FeeMode) as  [SBT Fees Mode],  
			isnull(B.CalculateOn, B1.CalculateOn) as [SBT Fees Calculate On],
			R.InvoiceCount as [Regulated # of Invoices],
			null as [Regulated Fee/Invoice Supplier],
			R.ServiceFeeFactorValue as [Regulated Fee/Invoice Retailer],
			getdate() as [DatetTimeCreated]
			
			from #tmpChainSuppliers SB WITH (NOLOCK)
			inner join Chains C WITH (NOLOCK) on C.ChainID=SB.ChainID
			LEFT JOIN (Select ChainID, sum(ActiveSiteCount) as StoreCount from #tmpStoreCounts group by ChainID) SC on SC.ChainID = SB.ChainId
			LEFT JOIN (Select EntityIdRetailer, sum(CostDollars) as CostDollars, sum(RetailDollars) as RetailDollars, SSF.Fees, SSF.FeeMode, SSF.CalculateOn
								from  #tmpBillingSBT T
								inner JOIN #tmpChainSuppliers TCS ON TCS.ChainID=T.EntityIdRetailer and TCS.SupplierId = T.EntityIdSupplier
								inner JOIN SBTServiceFees SSF ON SSF.chainID=T.EntityIdRetailer and SSF.SupplierID IS NULL
								WHERE  T.SaleDateTime BETWEEN SSF.ActiveStartDate AND SSF.ActiveEndDate
								group by EntityIdRetailer, SSF.Fees, SSF.FeeMode, SSF.CalculateOn
							 ) B on  B.EntityIdRetailer = SB.ChainID
			LEFT JOIN (Select EntityIdRetailer, sum(LegacyCostDollars) as LegacyCostDollars, sum(LegacyRetailDollars) as LegacyRetailDollars, SSF.Fees, SSF.FeeMode, SSF.CalculateOn
								from  #tmpBillingSBT T
								inner JOIN SBTServiceFees SSF ON SSF.chainID=T.EntityIdRetailer and SSF.SupplierID IS NULL
								WHERE  T.SaleDateTime BETWEEN SSF.ActiveStartDate AND SSF.ActiveEndDate and T.EntityIdSupplier IS NULL
								group by EntityIdRetailer, SSF.Fees, SSF.FeeMode, SSF.CalculateOn
							 ) B1 on  B1.EntityIdRetailer = SB.ChainID							 			
			LEFT JOIN (Select SF.ChainID, SF.ServiceFeeFactorValue, sum(TransactionCount)  as InvoiceCount
									from #tmpRegulatedPayment R 
									inner join ServiceFees SF on R.EntityIdRetailer=SF.ChainID and SF.SupplierID=0
									where ServiceFeeTypeID in (2,3) and SF.ChainID<>0
									AND R.InvoiceEntryDate BETWEEN SF.ActiveStartDate AND SF.ActiveLastDate
									group BY SF.ChainID, SF.ServiceFeeFactorValue
							) R on R.ChainID=C.ChainID
			WHERE 1=1 AND SB.ChainId like @ChainId and @SupplierId = '%'

		-- Exclude Chains/Suppliers mark for exclusion.
		Delete T 
		from DataTrue_CustomResultSets.dbo.iControlFeeCalculation_Test T 
		inner join PDIVendors P on isnull(P.SupplierId,0)=isnull(T.SupplierId,0) and P.ChainID=T.ChainID and P.IsExcluded=1
		
END
GO
