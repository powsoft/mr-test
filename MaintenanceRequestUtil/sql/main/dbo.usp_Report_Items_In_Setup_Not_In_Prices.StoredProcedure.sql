USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Items_In_Setup_Not_In_Prices]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Items_In_Setup_Not_In_Prices] 
	-- exec [usp_Report_Items_In_Setup_Not_In_Prices] '-1','2','All','','-1','','0','1900-01-01','1900-01-01'
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int

	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=9
 
	set @query = 'SELECT ' + @MaxRowsCount + ' C.ChainName as [Retailer], S.SupplierName as [Supplier], ST.StoreName as [Store Name],
						ST.Custom1 as Banner, ST.StoreIdentifier AS [Store No], P.ProductName as [Product], 
						PD.IdentifierValue AS UPC, isnull(SUV.RouteNumber,'''') as [Route Number],
						isnull(SUV.DriverName,'''') as [Driver Name],
						isnull(SUV.SupplierAccountNumber,'''') as [SupplierAccount#],
						isnull(SUV.SBTNumber,'''') as [SBT Number]
					
					FROM  StoreSetup SS  with(nolock)
							INNER JOIN Stores  ST  with(nolock) ON SS.StoreID = ST.StoreID and ST.ActiveStatus =''Active'' 
							INNER JOIN Products P  with(nolock) ON SS.ProductID = P.ProductID 
							INNER JOIN ProductIdentifiers PD  with(nolock) ON PD.ProductID = P.ProductID  and PD.ProductIdentifierTypeID=2 
							INNER JOIN Suppliers S  with(nolock) ON S.SupplierID = SS.SupplierID 
							INNER JOIN Chains C  with(nolock) ON C.ChainID = SS.ChainID 
							inner join SupplierBanners SB  with(nolock) on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
							LEFT JOIN StoresUniqueValues  SUV  with(nolock) on SUV.Storeid=ST.StoreID and SUV.SupplierID=S.SupplierID
							LEFT JOIN Productprices PP  with(nolock) on PP.SupplierID=S.SupplierID and PP.StoreID=ST.StoreID 
							and PP.ProductID=P.ProductID and PP.ChainID=C.ChainID
					WHERE   PP.ProductPriceTypeID in (3 ,11)
							and PP.ProductID is null '

	if @AttValue =17
			set @Query = @Query + ' and c.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and s.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

	
	if(@SupplierId<>'-1') 
		set @Query  = @Query  +  ' and S.SupplierID=' + @SupplierId  
	  
	if(@chainID  <>'-1') 
		set @Query  = @Query  +  ' and C.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query  +  ' and ST.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query  = @Query  +  ' and ST.StoreIdentifier like ''%' + @StoreId + '%''' 

	if(@ProductUPC  <>'-1') 
		set @Query  = @Query  +  ' and PD.IdentifierValue like ''%' + @ProductUPC + '%'''
		
	PRINT (@Query )
	exec  (@Query )
	
END
GO
