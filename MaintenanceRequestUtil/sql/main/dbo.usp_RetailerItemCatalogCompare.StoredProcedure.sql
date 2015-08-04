USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_RetailerItemCatalogCompare]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[usp_RetailerItemCatalogCompare]

 @ChainId varchar(10),
 @SupplierId varchar(10),
 @CategoryId varchar(10),
 @Product varchar(50),
 @UPC varchar(50),
 @State varchar(50),
 @ZipCode varchar(50),
 @BeginDate varchar(50),
 @EndDate varchar(50)

AS
BEGIN
Declare @sqlQuery varchar(6000)

 set @sqlQuery ='Select distinct S.SupplierName as [Supplier Name], PC.ProductCategoryName as [Category Name], 
	P.ProductName as [Product Name], PID.IdentifierValue as UPC, F.State, '
	
	if(@ZipCode<>'')
		set @sqlQuery = @sqlQuery +  ' F.ZipCode as [Zip Code], '
	
	set @sqlQuery = @sqlQuery +  ' convert(varchar(10), F.ActiveFrom, 101) as [Active From], 
	convert(varchar(10), F.ActiveTo, 101) as [Active To]
	FROM FullItemCatalog F 
	INNER JOIN dbo.Products P ON F.ProductID = P.ProductID 
	INNER JOIN dbo.ProductIdentifiers PID ON PID.ProductID = F.ProductID 
    INNER JOIN dbo.Suppliers S on F.SupplierID = S.SupplierID 
    Inner Join dbo.StoreSetup SS on SS.SupplierID=S.SupplierID and SS.ProductID=P.ProductId
    Inner join Stores ST on SS.StoreID=ST.StoreID and ST.ActiveStatus=''Active''
    INNER JOIN dbo.ProductCategoryAssignments PA on PA.ProductID = F.ProductID and PA.StoreBanner=ST.Custom1
    INNER JOIN dbo.ProductCategories PC ON PC.ProductCategoryID = PA.ProductCategoryID 
    inner join SupplierBanners SB on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
    Where PID.ProductIdentifierTypeID in (2,8) and F.ActiveFrom <= getDate() and F.ActiveTo >= getDate() '

	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and PC.ChainId=' + @ChainId  
		
	if(@SupplierId <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and S.SupplierId=' + @SupplierId  
		
	if(@CategoryId <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and PC.ProductCategoryID=' + @CategoryId  
	
	if (convert(date, @BeginDate) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and F.ActiveFrom >= ''' + @BeginDate + '''';

	if(convert(date, @EndDate) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and F.ActiveTo  <= ''' + @EndDate + '''';

	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and PID.IdentifierValue like ''%' + @UPC + '%''';
		
	if(@Product <>'') 
		set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @Product  + '%''';
		
	if(@State <>'') 
		set @sqlQuery = @sqlQuery + ' and F.State like ''%' + @State  + '%''';
		
	if(@ZipCode <>'') 
		set @sqlQuery = @sqlQuery + ' and F.ZipCode like ''%' + @ZipCode  + '%''';
	
	exec (@sqlQuery  )
	
END
GO
