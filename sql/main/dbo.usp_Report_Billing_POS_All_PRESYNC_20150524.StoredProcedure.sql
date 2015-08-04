USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Billing_POS_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_Billing_POS_All_PRESYNC_20150524] 
	-- exec usp_Report_Billing_POS '40393','41544','All','','40561','','5','1900-01-01','1900-01-01'
	@chainID varchar(1000),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(1000),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(1000)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4
set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @Query ='SELECT dbo.Chains.ChainName as [Chain Name], dbo.Suppliers.SupplierName as [Supplier Name], 
						dbo.InvoiceDetails.RetailerInvoiceID  as [Invoice No], dbo.Stores.StoreIdentifier as [Store Number], 
						dbo.Stores.Custom1 AS Banner,B.BrandName as Brand, dbo.Products.Productname as [Product Name], dbo.ProductIdentifiers.IdentifierValue as UPC, 
						PD.IdentifierValue as [Supplier Product Code],
						dbo.InvoiceDetails.TotalQty as Qty, 
						''$''+ Convert(varchar(50), cast(dbo.InvoiceDetails.UnitCost as numeric(10,' + @CostFormat + '))) as Cost, 
						''$''+ Convert(varchar(50), cast(dbo.InvoiceDetails.PromoAllowance as numeric(10,' + @CostFormat + '))) as Allowance, 
						''$''+ Convert(varchar(50), cast(dbo.InvoiceDetails.TotalCost as numeric(10,' + @CostFormat + '))) as [Total Cost],
						dbo.FDatetime(dbo.InvoiceDetails.SaleDate) as [Transaction Date],
						isnull(dbo.StoresUniqueValues.RouteNumber,'''') as [Route Number],
						isnull(dbo.StoresUniqueValues.DriverName,'''') as [Driver Name],
						isnull(dbo.StoresUniqueValues.SupplierAccountNumber,'''') as  [Supplier Account No],
						isnull(dbo.StoresUniqueValues.SBTNumber,'''') as [SBT Number]

				 FROM		  dbo.InvoiceDetails 
				 INNER JOIN   dbo.Products ON dbo.InvoiceDetails.ProductID = dbo.Products.ProductID 
				 INNER JOIN ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID 
				 INNER JOIN Brands B ON PB.BrandID = B.BrandID 
				 Inner join   dbo.ProductIdentifiers ON dbo.ProductIdentifiers.ProductID = dbo.Products.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID = 2
				 Left JOIN    dbo.ProductIdentifiers PD ON dbo.Products.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=dbo.InvoiceDetails.SupplierId 
				 INNER JOIN   dbo.Suppliers ON dbo.Suppliers.SupplierID = dbo.InvoiceDetails.SupplierID 
				 INNER JOIN   dbo.Chains ON dbo.InvoiceDetails.ChainID = dbo.Chains.ChainID 
				 INNER JOIN   dbo.Stores ON dbo.InvoiceDetails.StoreID = dbo.Stores.StoreID  and dbo.Stores.ActiveStatus=''Active''
				 INNER JOIN   SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1
				 left join    dbo.StoresUniqueValues on dbo.Stores.Storeid=dbo.StoresUniqueValues.StoreID and dbo.StoresUniqueValues.SupplierID=dbo.Suppliers.SupplierID
				 WHERE     1=1'
 
	--if @AttValue =17
	--	set @query = @query + ' and dbo.Chains.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and dbo.Suppliers.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and dbo.chains.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and dbo.Suppliers.SupplierId in (' + @SupplierId  +')'

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (dbo.InvoiceDetails.SaleDate between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and dbo.InvoiceDetails.SaleDate >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and dbo.InvoiceDetails.SaleDate <= ''' + @EndDate  + '''';
			
	set @Query = @Query + ' ORDER BY 1,3,2,5 '

	exec  (@Query )
END
GO
