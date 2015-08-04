USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeCalculationReport]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- DeFCriptiON:	<DeFCriptiON,,>
-- =============================================

-- exec [usp_iControlFeeCalculationReport] '%', '%', 02, 2015,0,0,1
CREATE PROCEDURE [dbo].[usp_iControlFeeCalculationReport]
	-- Add the parameters for the stored procedure here
	@ChainId varchar(5),
	@SupplierId varchar(5),
	@ForMonth varchar(4),
	@ForYear varchar(4),
	@ShowSBT bit,
	@ShowRegulated bit,
	@ShowDX bit
AS
BEGIN

		IF OBJECT_ID('#tmpStoreCount', 'U') IS NOT NULL
			Drop TABLE #tmpStoreCount
			
		IF OBJECT_ID('#tmpiControlFeeReport', 'U') IS NOT NULL
			Drop TABLE #tmpiControlFeeReport
			
		IF OBJECT_ID('#tmpFinalReport', 'U') IS NOT NULL
			Drop TABLE #tmpFinalReport

	--GET PERIOD START AND END DATES
		DECLARE @PeriodStartDate DATE
		DECLARE @PeriodEndDate DATE
		
		SET @PeriodStartDate = @ForYear + '-' + @ForMonth + '-01'
		SET @PeriodEndDate = DATEADD(DD, -1, DATEADD(M, 1, @PeriodStartDate))
		
		Select ChainID, count(StoreId) as StoreCount 
		into #tmpStoreCount
		from Stores S 
		where S.ActiveFromDate <= @PeriodEndDate AND S.ActiveLastDate >= @PeriodStartDate and ChainID = 60636
		group by ChainID 
					
	Select
		FC.ReportYear
		, FC.ReportMonth
		, FC.ChainName
		, FC.SupplierName
		, Case When (FC.[DX Fee/Store Supplier] is null) And (FC.[DX Fee/Store Retailer] is null) Then NULL Else FC.[DX # of Stores] End as [DX # of Stores]
		, FC.[DX Fee/Store Supplier]
		, FC.[DX Fee/Store Retailer]
		, case when FC.[DX # of Stores] is null then NULL else (isnull(FC.[DX # of Stores],0) * (isnull(FC.[DX Fee/Store Supplier],0) + isnull(FC.[DX Fee/Store Retailer],0))) end  as [iControl Dx Fees]
		
		, FC.[SBT Fees] as [SBT Fee Rate]
		, FC.[SBT Fees Mode] as [SBT Fee Mode]
		, FC.[SBT Fees Calculate On]
		
		, FC.[SBT Total Cost POS Transactions $]
		, FC.[SBT Total Retail POS Transactions $]
		
		, Cast(Case	WHEN FC.[SBT Fees Mode] LIKE '%Per Month%' THEN 
								CASE WHEN isnull(FC.[SBT Total Cost POS Transactions $],0) + isnull(FC.[SBT Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									FC.[SBT Fees]
								END
						WHEN FC.[SBT Fees Mode] = 'Per Week' THEN 
							CASE WHEN isnull(FC.[SBT Total Cost POS Transactions $],0) + isnull(FC.[SBT Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									FC.[SBT Fees] * 52 / 12
								END
						WHEN FC.[SBT Fees Mode] = 'Per Store Per Week' THEN 
							CASE WHEN isnull(FC.[SBT Total Cost POS Transactions $],0) + isnull(FC.[SBT Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									(FC.[SBT Fees] * 52 * isnull(S.StoreCount,0)) / 12
								END
						WHEN FC.[SBT Fees Mode] = '%' THEN 
								CASE WHEN FC.[SBT Fees Calculate On] = 'Retail' THEN
										FC.[SBT Total Retail POS Transactions $] * FC.[SBT Fees] / 100
								ELSE
										FC.[SBT Total Cost POS Transactions $] * FC.[SBT Fees] / 100
								END 
			END as DECIMAL(10,2)) as [iControl SBT Fees]
		
		, FC.[SBT Legacy Total Cost POS Transactions $]
		, FC.[SBT Legacy Total Retail POS Transactions $]
		
		, Cast(
				Case	WHEN FC.[SBT Fees Mode] LIKE '%Per Month%' THEN 
								CASE WHEN isnull(FC.[SBT Legacy Total Cost POS Transactions $],0) + isnull(FC.[SBT Legacy Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									FC.[SBT Fees]
								END
						WHEN FC.[SBT Fees Mode] = 'Per Week' THEN 
							CASE WHEN isnull(FC.[SBT Legacy Total Cost POS Transactions $],0) + isnull(FC.[SBT Legacy Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									FC.[SBT Fees] * 52 / 12
								END
						WHEN FC.[SBT Fees Mode] = 'Per Store Per Week' THEN 
							CASE WHEN isnull(FC.[SBT Legacy Total Cost POS Transactions $],0) + isnull(FC.[SBT Legacy Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									(FC.[SBT Fees] * 52 * isnull(S.StoreCount,0)) / 12
								END
						
						WHEN FC.[SBT Fees Mode] = '%' THEN 
								CASE WHEN FC.[SBT Fees Calculate On] = 'Retail' THEN
										FC.[SBT Legacy Total Retail POS Transactions $] * FC.[SBT Fees] / 100
								ELSE
										FC.[SBT Legacy Total Cost POS Transactions $] * FC.[SBT Fees] / 100
								END 
			END as DECIMAL(10,2)) as [iControl SBT Legacy Fees]
		, Case When (FC.[Regulated Fee/Invoice Supplier] is null) And (FC.[Regulated Fee/Invoice Retailer] is null) Then NULL Else FC.[DX # of Stores] End as [Regulated # of Stores]	
		, FC.[Regulated # of Invoices]
		, FC.[Regulated Fee/Invoice Supplier]
		, FC.[Regulated Fee/Invoice Retailer]
		, case when FC.[Regulated # of Invoices] is null then NULL else (isnull(FC.[Regulated # of Invoices],0) * (isnull(FC.[Regulated Fee/Invoice Supplier],0) + isnull(FC.[Regulated Fee/Invoice Retailer],0))) end  as [iControl Regulated Fee]
		, FC.[DateTimeCreated]
	into #tmpiControlFeeReport
	From
		DataTrue_CustomResultSets.dbo.iControlFeeCalculation FC with (nolock)
		Left Join #tmpStoreCount S on S.ChainId=FC.ChainId 
	Where 1=1
		and FC.ChainID like @ChainId 
		and isnull(FC.SupplierID,0) like @SupplierId 
		and FC.ReportYear like @ForYear
		and FC.ReportMonth like @ForMonth
	Order BY FC.ChainName
	

	Select TOP 1 * into #tmpFinalReport from #tmpiControlFeeReport where ChainName=''
	
	IF(@ShowSBT=1) 
		insert into #tmpFinalReport
		Select * from #tmpiControlFeeReport where ([iControl SBT Legacy Fees] IS NOT NULL or [iControl SBT Fees] IS NOT NULL)
	
	IF(@ShowRegulated	=1) 
		insert into #tmpFinalReport
		Select * from #tmpiControlFeeReport where [iControl Regulated Fee] IS NOT NULL and [Regulated # of Invoices] IS NOT NULL
	
	IF(@ShowDX	=1) 
		insert into #tmpFinalReport
		Select * from #tmpiControlFeeReport where [iControl Dx Fees] IS NOT NULL and [DX # of Stores] IS NOT NULL


	SELECT DISTINCT * from #tmpFinalReport order by 3, 4 
	
	
END
GO
