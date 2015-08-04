USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_PDI_TEST_StoreTransactions_Create]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vince Moore
-- Create date: 05/07/2013
-- Description:	Creates records in table PDI_Test_StoreTramsactions in the Import database for the
-- chain and supplier specified. It will create records for all products for the supplier in every store, with a random 
-- quantity between 5 and 50, for every day in the date range specified.
-- If we get rid of the hard-coded table name this could be a fairly generic transaction generator
-- =============================================
CREATE PROCEDURE [dbo].[prUtil_PDI_TEST_StoreTransactions_Create] 
	@ChainID int,
	@SupplierID int,
	@StartDate date,
	@EndDate date
AS
BEGIN
	SET NOCOUNT ON;

	--Declare @ChainID int
	--Declare @StoreID int
	--Declare @ProductID int
	--Declare @SupplierID int
	--Declare @StartDate date
	--Declare @EndDate date

	--Select @StartDate = '2013-04-01', 
	--@EndDate = '2013-05-06',
	--@ChainID = 44285,
	--@supplierid = 50725 

	;With 
	DateSequence(SaleDate) as(    
		Select @StartDate as SaleDate
		union all    
		Select dateadd(day, 1, SaleDate)       
		from DateSequence        
		where SaleDate <= @EndDate
	),
	ChainStoreProductSup(chainID, storeid,productid,supplierid) as (	
		select distinct chainID, storeid,productid,supplierid 
		from datatrue_main.dbo.storesetup
		where chainid=@ChainID
		and supplierid = @supplierid
		and storeid > 0
		and productid > 0
	)
	Insert Into Import.dbo.PDI_TEST_StoreTransactions
	(
	ChainID,
	StoreID,
	ProductID,
	SupplierID,
	TransactionTypeID,
	BrandID,
	Qty,
	SaleDateTime,
	UPC,
	ReportedCost,
	ReportedRetail,
	CostMisMatch,
	RetailMismatch,
	TransactionStatus,
	Reversed,
	SourceID,
	DateTimeCreated,
	DateTimeLastUpdate,
	WorkingTransactionID
	)		
	Select p.ChainID, 
	p.StoreID, 
	p.ProductID, 
	p.Supplierid, 
	2 TransactionTypeID, 
	0 BrandID, 
	CONVERT(INT, 45*RAND(checksum(newid()))+5) as Qty, 
	d.SaleDate SaleDateTime,   
	IdentifierValue UPC,
	pp.UnitPrice ReportedCost,
	pp.UnitRetail ReportedRetail,
	0 CostMismatch,
	0 RetailMismatch,
	811 TransactionStatus,
	0 Reversed,
	23254 SourceID,
	GETDATE() DateTimeCreated,
	getdate() DateTimeLastUpdate,
	0 WorkingTransactionID
	From DateSequence d
	cross join ChainStoreProductSup p
	inner join datatrue_main.dbo.ProductIdentifiers pid on pid.ProductID = p.ProductID
	inner join datatrue_main.dbo.ProductPrices pp on pp.ChainID = p.chainID 
		and pp.SupplierID = p.SupplierID 
		and pp.StoreID = p.storeid
		and pp.ProductID = p.ProductID
		and ProductPriceTypeID = 3


    
END
GO
