USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeCalculationReport_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
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
CREATE PROCEDURE [dbo].[usp_iControlFeeCalculationReport_PRESYNC_20150524]
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
		, FC.[SBT Total Cost POS Transactions $]
		, FC.[SBT Total Retail POS Transactions $]
		, FC.[SBT Fees]
		, FC.[Regulated # of Invoices]
		, FC.[Regulated Fee/Invoice Supplier]
		, FC.[Regulated Fee/Invoice Retailer]
		, FC.[DateTimeCreated]
	From
		iControlFeeCalculation FC
	Where
		FC.ChainID like @ChainId 
		and isnull(FC.SupplierID,0) like @SupplierId 
		and FC.ReportYear like @ForYear
		and FC.ReportMonth like @ForMonth
	
END
GO
