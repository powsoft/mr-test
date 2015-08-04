USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Last_Scan]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean
-- Create date: <Create Date,,>12/12/2011
-- Description:	<Description,,> ADDED FIELD LastScanDate
-- =============================================
--[usp_Report_Last_Scan]  '40393','41409','All','','-1','-1','10','1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_Last_Scan] 
	-- Add the parameters for the stored procedure here
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
declare @AttValue int

 select @attvalue = AttributeID  from AttributeValues with(nolock) where OwnerEntityID=@PersonID and AttributeID=17
 
 
Declare @Query varchar(8000)

set @Query = ' 	SELECT        TransactionTypes.BucketTypeName, Chains.ChainName as [Chain Name],
				Stores.StoreIdentifier AS [Store Number], Stores.Custom1 AS Banner, 
                Suppliers.SupplierName as [Supplier Name], B.BrandName as Brand, Products.ProductName as [Product Name],
                ProductIdentifiers.IdentifierValue AS UPC, PD.IdentifierValue as [Supplier Product Code],
                SUM(S.Qty * TransactionTypes.QtySign) AS Qty,  
                convert(varchar(20),cast(SaleDateTime as date),101) as [Last Scan Date],
                isnull(StoresUniqueValues.RouteNumber,'''') as [Route Number],
                isnull(StoresUniqueValues.DriverName,'''') as [Driver Name],isnull(StoresUniqueValues.SupplierAccountNumber,'''') as [SupplierAccount#],
                isnull(StoresUniqueValues.SBTNumber,'''') as [SBT Number]
				FROM  StoreTransactions S with(nolock)
				INNER JOIN TransactionTypes ON S.TransactionTypeID = TransactionTypes.TransactionTypeID 
                INNER JOIN Stores with(nolock)  ON S.StoreID = Stores.StoreID and Stores.ActiveStatus=''Active''  
                INNER JOIN Suppliers with(nolock) ON S.SupplierID = Suppliers.SupplierID 
                INNER JOIN Products with(nolock) ON S.ProductID = Products.ProductID 
				INNER JOIN ProductBrandAssignments PB with(nolock) on PB.ProductID=Products.ProductID 
				INNER JOIN Brands B with(nolock) ON PB.BrandID = B.BrandID 
                INNER JOIN ProductIdentifiers with(nolock) ON Products.ProductID = ProductIdentifiers.ProductID and ProductIdentifiers.ProductIdentifierTypeID = 2
                Left JOIN  ProductIdentifiers PD with(nolock) ON Products.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=Suppliers.SupplierId 
                INNER JOIN Chains with(nolock) ON S.ChainID = Chains.ChainID  
                INNER JOIN SupplierBanners SB with(nolock) on SB.SupplierId = Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.Custom1
                left join  StoresUniqueValues with(nolock)  on Stores.Storeid=StoresUniqueValues.StoreID and StoresUniqueValues.SupplierID=Suppliers.SupplierID
				WHERE     1=1 '
	
if @AttValue =17
			set @Query = @Query + ' and chains.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and suppliers.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
       
	if(@chainID  <>'-1') 
		set @Query  = @Query  +  ' and Chains.ChainID=' + @chainID 

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and Suppliers.SupplierId=' + @SupplierId  

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (S.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and S.SaleDateTime <=getdate()) '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and S.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and S.SaleDateTime <= ''' + @EndDate  + '''';
		
	set @Query = @Query + ' GROUP BY TransactionTypes.BucketTypeName, Stores.StoreIdentifier, Stores.Custom1, Suppliers.SupplierName,B.BrandName, Products.ProductName, 
									ProductIdentifiers.IdentifierValue, PD.IdentifierValue, Chains.ChainName, SaleDateTime,StoresUniqueValues.RouteNumber,StoresUniqueValues.DriverName,StoresUniqueValues.SupplierAccountNumber,StoresUniqueValues.SBTNumber
							HAVING  (TransactionTypes.BucketTypeName =''POS'')'

	exec (@Query )
	
END
GO
