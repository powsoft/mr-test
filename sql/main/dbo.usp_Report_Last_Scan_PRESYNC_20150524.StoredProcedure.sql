USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Last_Scan_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: <Create Date,,>12/12/2011
-- Description:	<Description,,> ADDED FIELD LastScanDate
-- =============================================
--[usp_Report_Last_Scan]  '40393','41409','-1','-1','-1','-1',10
CREATE procedure [dbo].[usp_Report_Last_Scan_PRESYNC_20150524] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20) 
AS
BEGIN
declare @AttValue int

 select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 
Declare @Query varchar(8000)

set @Query = ' 	SELECT        dbo.TransactionTypes.BucketTypeName, dbo.Chains.ChainName as [Chain Name],
				dbo.Stores.StoreIdentifier AS [Store Number], dbo.Stores.Custom1 AS Banner, 
                dbo.Suppliers.SupplierName as [Supplier Name], B.BrandName as Brand, dbo.Products.ProductName as [Product Name],
                dbo.ProductIdentifiers.IdentifierValue AS UPC, PD.IdentifierValue as [Supplier Product Code],
                SUM(S.Qty * dbo.TransactionTypes.QtySign) AS Qty,  
                dbo.FDatetime(SaleDateTime) as [Last Scan Date],isnull(dbo.StoresUniqueValues.RouteNumber,'''') as [Route Number],
                isnull(dbo.StoresUniqueValues.DriverName,'''') as [Driver Name],isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'''') as [SupplierAccount#],
                isnull(dbo.StoresUniqueValues.SBTNumber,'''') as [SBT Number]
				FROM  datatrue_report.dbo.StoreTransactions S
				INNER JOIN dbo.TransactionTypes ON S.TransactionTypeID = dbo.TransactionTypes.TransactionTypeID 
                INNER JOIN dbo.Stores ON S.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active''  
                INNER JOIN dbo.Suppliers ON S.SupplierID = dbo.Suppliers.SupplierID 
                INNER JOIN dbo.Products ON S.ProductID = dbo.Products.ProductID 
				INNER JOIN ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID 
				INNER JOIN Brands B ON PB.BrandID = B.BrandID 
                INNER JOIN dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID = 2
                Left JOIN  dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=dbo.Suppliers.SupplierId 
                INNER JOIN dbo.Chains ON S.ChainID = dbo.Chains.ChainID  
                INNER JOIN SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1
                left join  dbo.StoresUniqueValues on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
				WHERE     1=1 '
	
	if @AttValue =17
		set @query = @query + ' and dbo.Chains.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	else
		set @query = @query + ' and dbo.Suppliers.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
                  
	if(@chainID  <>'-1') 
		set @Query  = @Query  +  ' and dbo.Chains.ChainID=' + @chainID 

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and dbo.Suppliers.SupplierId=' + @SupplierId  

	if(@Banner<>'All') 
		set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and S.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
		
	set @Query = @Query + ' GROUP BY dbo.TransactionTypes.BucketTypeName, dbo.Stores.StoreIdentifier, dbo.Stores.Custom1, dbo.Suppliers.SupplierName,B.BrandName, dbo.Products.ProductName, 
									dbo.ProductIdentifiers.IdentifierValue, PD.IdentifierValue, dbo.Chains.ChainName, SaleDateTime,dbo.StoresUniqueValues.RouteNumber,dbo.StoresUniqueValues.DriverName,dbo.StoresUniqueValues.SupplierAccountNumber,dbo.StoresUniqueValues.SBTNumber
							HAVING  (dbo.TransactionTypes.BucketTypeName =''POS'')'

	exec (@Query )
	
END
GO
