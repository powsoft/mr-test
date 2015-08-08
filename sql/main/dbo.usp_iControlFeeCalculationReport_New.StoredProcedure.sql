USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeCalculationReport_New]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- DeFCriptiON:	<DeFCriptiON,,>
-- =============================================

-- exec [usp_iControlFeeCalculationReport] '%', '%', 11, 2014
Create PROCEDURE [dbo].[usp_iControlFeeCalculationReport_New]
	-- Add the parameters for the stored procedure here
	@ChainId varchar(5),
	@SupplierId varchar(5),
	@ForMonth varchar(4),
	@ForYear varchar(4)
	
AS
BEGIN
	
	Select
		FC.ReportYear
		, FC.ReportMonth
		, FC.ChainName
		, FC.SupplierName
		, FC.[DX # of Stores]
		, FC.[DX Fee/Store Supplier]
		, FC.[DX Fee/Store Retailer]
		, case when FC.[DX # of Stores] is null then NULL else (isnull(FC.[DX # of Stores],0) * (isnull(FC.[DX Fee/Store Supplier],0) + isnull(FC.[DX Fee/Store Retailer],0))) end  as [iControl Dx Fees]
		
		, FC.[SBT Total Cost POS Transactions $]
		, FC.[SBT Total Retail POS Transactions $]
		
		, FC.[SBT Legacy Total Cost POS Transactions $]
		, FC.[SBT Legacy Total Retail POS Transactions $]
		
		, FC.[SBT Fees] as [SBT Fee Rate]
		, FC.[SBT Fees Mode] as [SBT Fee Mode]
		, FC.[SBT Fees Calculate On]
		, Cast(Case	WHEN FC.[SBT Fees Mode] LIKE '%Per Month%' THEN 
								CASE WHEN isnull(FC.[SBT Total Cost POS Transactions $],0) + isnull(FC.[SBT Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									FC.[SBT Fees]
								END
						WHEN FC.[SBT Fees Mode] = '%' THEN 
								CASE WHEN FC.[SBT Fees Calculate On] = 'Retail' THEN
										FC.[SBT Total Retail POS Transactions $] * FC.[SBT Fees] / 100
								ELSE
										FC.[SBT Total Cost POS Transactions $] * FC.[SBT Fees] / 100
								END 
			END as DECIMAL(10,2)) as [iControl SBT Fees]
		, Cast(Case	WHEN FC.[SBT Fees Mode] LIKE '%Per Month%' THEN 
								CASE WHEN isnull(FC.[SBT Legacy Total Cost POS Transactions $],0) + isnull(FC.[SBT Legacy Total Retail POS Transactions $],0) =0 THEN
									NULL
								ELSE
									FC.[SBT Fees]
								END
						WHEN FC.[SBT Fees Mode] = '%' THEN 
								CASE WHEN FC.[SBT Fees Calculate On] = 'Retail' THEN
										FC.[SBT Legacy Total Retail POS Transactions $] * FC.[SBT Fees] / 100
								ELSE
										FC.[SBT Legacy Total Cost POS Transactions $] * FC.[SBT Fees] / 100
								END 
			END as DECIMAL(10,2)) as [iControl SBT Legacy Fees]
		, FC.[Regulated # of Invoices]
		, FC.[Regulated Fee/Invoice Supplier]
		, FC.[Regulated Fee/Invoice Retailer]
		, case when FC.[Regulated # of Invoices] is null then NULL else (isnull(FC.[Regulated # of Invoices],0) * (isnull(FC.[Regulated Fee/Invoice Supplier],0) + isnull(FC.[Regulated Fee/Invoice Retailer],0))) end  as [iControl Regulated Fee]
		, FC.[DateTimeCreated]
	From
		DataTrue_CustomResultSets.dbo.iControlFeeCalculation_Test FC
	Where 1=1
		and FC.ChainID like @ChainId 
		and isnull(FC.SupplierID,0) like @SupplierId 
		and FC.ReportYear like @ForYear
		and FC.ReportMonth like @ForMonth
	Order BY
		FC.ChainName
	
END
GO
