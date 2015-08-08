USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_SupplierBilling_ItemsBilledNotInPriceBook_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_Report_SupplierBilling-ItemsBilledNotInPriceBook_All] '75130','41713','All','-1','76209','-1',0,'11/01/2014','11/30/2014'
-- exec [usp_Report_SupplierBilling_ItemsBilledNotInPriceBook_All] '79370','79652','All','-1','79651','-1',0,'1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_SupplierBilling_ItemsBilledNotInPriceBook_All] 
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(max)

IF OBJECT_ID('tempdb..#tmpVIN') IS NOT NULL  
	BEGIN
		DROP TABLE #tmpVIN
	END 
IF OBJECT_ID('tempdb..#tmpInvoiceVIN') IS NOT NULL  
	BEGIN
		DROP TABLE #tmpInvoiceVIN
	END 
	CREATE TABLE #tmpVIN(
		[ChainId] [nvarchar](50) NULL,
		[SupplierId] [nvarchar](50) NULL,
		[StoreId] [nvarchar](50) NULL,
		[VIN] [nvarchar](50) NULL)
	
	CREATE TABLE #tmpInvoiceVIN(
		[ChainId] [nvarchar](50) NULL,
		[SupplierID] [nvarchar](50) NULL,
		[StoreId] [nvarchar](50) NULL,
		[VIN] [nvarchar](50) NULL,
		[SaleDate] [date] NULL )
		
		set @query = 'Insert into #tmpVIN
						Select distinct P.ChainId, P.SupplierId, P.StoreId, SP.VIN 
							from ProductPrices P WITH (nolock)
							inner join SupplierPackages SP on SP.SupplierId=P.SupplierId and SP.ProductId=P.ProductId and SP.SupplierPackageID=P.SupplierPackageID
							where 1=1 '
							
		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and P.ChainID in (' + @chainID +')'	
		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and P.SupplierId in (' + @SupplierId  +')'					
		
		PRINT(@query);				
		exec(@query);
	
		set @query = 'Insert into #tmpInvoiceVIN
						select distinct I.ChainID, I.SupplierID, I.StoreId,  isnull(I.VIN, SP.SupplierProductID) as VIN,convert(varchar(10),I.SaleDate,101) as SaleDate
							from InvoiceDetails I WITH (nolock)
							inner join Stores ST ON ST.StoreID=I.StoreID and ST.ChainID=I.ChainID
							left JOIN DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion SP on SP.SupplierID=I.SupplierID and SP.ProductID=I.ProductId
							WHERE 1=1 ' 
							
		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and I.ChainID in (' + @chainID +')'	
			
		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and I.SupplierId in (' + @SupplierId  +')'
			
		if(@Banner<>'All') 
			set @Query  = @Query + ' and ST.Custom1 like ''%' + @Banner + '%'''	
			
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and I.SaleDate >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and I.SaleDate <= ''' + @EndDate  + '''';	
	
	PRINT(@query);						 
    exec(@query);
    
    select distinct C.ChainName as [Retailer Name], S.SupplierName as [Supplier Name],ST.Custom1 as Banner,ST.StoreIdentifier as [Store No], I.VIN, 
			convert(varchar(10),I.SaleDate,101) as SaleDate
			from #tmpInvoiceVIn I WITH (nolock)
			inner JOIN Chains C on C.ChainId=I.ChainId
			inner join Suppliers S ON S.SupplierID=I.SupplierID
			inner join Stores ST ON ST.StoreID=I.StoreID and ST.ChainID=I.ChainID
			Left JOIN #tmpVIN P ON P.ChainID=I.ChainID and P.SupplierID=I.SupplierID and P.StoreID=I.StoreID and I.VIN=P.VIN
			WHERE 1=1 and P.VIN IS null
		
END
GO
