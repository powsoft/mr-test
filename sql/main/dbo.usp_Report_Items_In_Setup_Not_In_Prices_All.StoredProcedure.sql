USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Items_In_Setup_Not_In_Prices_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Items_In_Setup_Not_In_Prices_All] 
	-- exec usp_Report_Items_In_Setup_Not_In_Prices '40393','2','All','','-1','','10','1900-01-01','1900-01-01'
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(150),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int

	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=9
 
	set @query = 'SELECT C.ChainName as [Retailer], S.SupplierName as [Supplier], ST.StoreName as [Store Name],
						ST.Custom1 as Banner, ST.StoreIdentifier AS [Store No], P.ProductName as [Product], 
						PD.IdentifierValue AS UPC, isnull(SUV.RouteNumber,'''') as [Route Number],
						isnull(SUV.DriverName,'''') as [Driver Name],
						isnull(SUV.SupplierAccountNumber,'''') as [SupplierAccount#],
						isnull(SUV.SBTNumber,'''') as [SBT Number]
					
					FROM  dbo.StoreSetup SS  with(nolock)
							INNER JOIN Stores  ST  with(nolock) ON SS.StoreID = ST.StoreID and ST.ActiveStatus =''Active'' 
							INNER JOIN Products P with(nolock) ON SS.ProductID = P.ProductID 
							INNER JOIN ProductIdentifiers PD with(nolock) ON PD.ProductID = P.ProductID  and PD.ProductIdentifierTypeID=2 
							INNER JOIN Suppliers S with(nolock) ON S.SupplierID = SS.SupplierID 
							INNER JOIN Chains C with(nolock) ON C.ChainID = SS.ChainID 
							inner join SupplierBanners SB with(nolock) on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
							LEFT JOIN StoresUniqueValues  SUV with(nolock) on SUV.Storeid=ST.StoreID and SUV.SupplierID=S.SupplierID
							LEFT JOIN Productprices PP with(nolock) on PP.SupplierID=S.SupplierID and PP.StoreID=ST.StoreID 
							and PP.ProductID=P.ProductID and PP.ChainID=C.ChainID
					WHERE   PP.ProductPriceTypeID in (3,11)
							and PP.ProductID is null '

	--if @AttValue = 9
	--	set @query = @query + ' and S.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
	--else
	--	set @query = @query + ' and C.ChainId in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	 
	
	if(@SupplierId<>'-1') 
		set @Query  = @Query  +  ' and S.SupplierID in (' + @SupplierId  +')'
	  
	if(@chainID  <>'-1') 
		set @Query  = @Query  +  ' and C.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query  +  ' and ST.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query  = @Query  +  ' and ST.StoreIdentifier like ''%' + @StoreId + '%''' 

	if(@ProductUPC  <>'-1') 
		set @Query  = @Query  +  ' and PD.IdentifierValue like ''%' + @ProductUPC + '%'''

	exec  (@Query )
	
END
GO
