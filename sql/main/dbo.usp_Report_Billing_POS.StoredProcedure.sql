USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Billing_POS]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_Billing_POS] 
	-- exec usp_Report_Billing_POS '40393','41713','All','','65590','30114','5','1900-01-01','1900-01-01'
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
Declare @Query varchar(max)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	set @Query ='SELECT DISTINCT  ' + @MaxRowsCount + ' Chains.ChainName as [Chain Name], 
						Suppliers.SupplierName as [Supplier Name], 
						InvoiceDetails.RetailerInvoiceID  as [Invoice No], 
						Stores.StoreIdentifier as [Store Number], 
						Stores.Custom1 AS Banner,
						--B.BrandName as Brand, 
						Products.Productname as [Product Name], 
						ProductIdentifiers.IdentifierValue as UPC, 
						PD.IdentifierValue as [Supplier Product Code],
						InvoiceDetails.TotalQty as Qty, 
						''$''+ Convert(varchar(50), cast(Isnull(InvoiceDetails.UnitCost,0) as numeric(10,' + @CostFormat + '))) as Cost, 
						''$''+ Convert(varchar(50), cast(InvoiceDetails.PromoAllowance as numeric(10,' + @CostFormat + '))) as Allowance, 
						''$''+ Convert(varchar(50), cast(Isnull(InvoiceDetails.TotalCost,0) as numeric(10,' + @CostFormat + '))) as [Total Cost],
						convert(varchar(10),CAST(InvoiceDetails.SaleDate as date),101) as [Transaction Date],
						isnull(StoresUniqueValues.RouteNumber,'''') as [Route Number],
						isnull(StoresUniqueValues.DriverName,'''') as [Driver Name],
						isnull(StoresUniqueValues.SupplierAccountNumber,'''') as  [Supplier Account No],
						isnull(StoresUniqueValues.SBTNumber,'''') as [SBT Number]

				 FROM		  InvoiceDetails  with(nolock)
				 INNER JOIN   Products  with (nolock)   ON InvoiceDetails.ProductID = Products.ProductID 
				 INNER JOIN ProductBrandAssignments PB  with (nolock)   on PB.ProductID=Products.ProductID 
				 INNER JOIN Brands B  with (nolock)   ON PB.BrandID = B.BrandID 
				 Inner join   ProductIdentifiers  with (nolock)   ON ProductIdentifiers.ProductID = Products.ProductID and ProductIdentifiers.ProductIdentifierTypeID = 2
				 Left JOIN    ProductIdentifiers PD  with (nolock)   ON Products.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=InvoiceDetails.SupplierId 
				 INNER JOIN   Suppliers  with (nolock)   ON Suppliers.SupplierID = InvoiceDetails.SupplierID 
				 INNER JOIN   Chains  with (nolock)   ON InvoiceDetails.ChainID = Chains.ChainID 
				 INNER JOIN   Stores  with (nolock)   ON InvoiceDetails.StoreID = Stores.StoreID  and Stores.ActiveStatus=''Active''
				 INNER JOIN   SupplierBanners SB  with (nolock)   on SB.SupplierId = Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.Custom1
				 left join    StoresUniqueValues with (nolock)   on Stores.Storeid=StoresUniqueValues.StoreID and StoresUniqueValues.SupplierID=Suppliers.SupplierID
				 WHERE     1=1'
 
	if @AttValue =17
		set @query = @query + ' and Chains.ChainID in (select attributepart from [fnGetRetailersTable](' +  cast(@PersonID as varchar) + '))'
		--set @query = @query + ' and Chains.ChainID in (select chainid from retaileraccess where personid = ' + cast(@PersonID as varchar) + ')'
	else
		set @query = @query + ' and Suppliers.SupplierID in (select attributepart from [fnGetSupplierTable](' +  cast(@PersonID as varchar) + '))'
		

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and chains.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and Suppliers.SupplierId=' + @SupplierId  

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (InvoiceDetails.SaleDate between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and InvoiceDetails.SaleDate >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and InvoiceDetails.SaleDate <= ''' + @EndDate  + '''';
			
	set @Query = @Query + ' ORDER BY 1,3,2,5  
						/*do not remove*/ option (querytraceon 8649) /*do not remove*/'
exec  (@Query )
print (@Query)
	
END
GO
