USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_SupplierInvoiceCostDifferences]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_SupplierInvoiceCostDifferences] 
	-- exec [usp_Report_SupplierInvoiceCostDifferences] '40393','2','All','-1','-1','','530','1900-01-01','1900-01-01'
	-- exec [usp_Report_SupplierInvoiceCostDifferences] '63612','41684','All','-1','-1','-1','0','04/01/2014','04/29/2014'
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
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat WITH(NOLOCK)  where SupplierID = @supplierID
	 else
		set @CostFormat=4
		set @CostFormat = ISNULL(@costformat,4)
	select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
	set @Query ='
					SELECT DISTINCT ' + @MaxRowsCount + ' T.ChainName as [Chain Name], 
							T.Banner, 
							T.SupplierName as [Supplier Name], 
							--B.BrandName as Brand, 
							T.ProductName as [Product Name], 
							T.UPC, 
							PD.IdentifierValue as [Supplier Product Code], 
							T.Qty, 
							''$''+ Convert(varchar(50),cast(T.[Setup Cost] as numeric(10,' + @CostFormat + '))) as [Supplier Invoice Cost], 
							''$''+ Convert(varchar(50),cast(T.[setup Promo] as numeric(10,' + @CostFormat + '))) as [Supplier Invoice Promo], 
							''$''+ Convert(varchar(50),cast(T.[Setup Net] as numeric(10,' + @CostFormat + '))) as [Supplier Invoice Net], 
							''$''+ Convert(varchar(50),cast(T.[Reported Cost] as numeric(10,' + @CostFormat + '))) as [Retailer Cost], 
							''$''+ Convert(varchar(50),cast(T.[Reported Promo] as numeric(10,' + @CostFormat + '))) as [Retailer Promo], 
							''$''+ Convert(varchar(50),cast(T.RetailerNet as numeric(10,' + @CostFormat + '))) as [Retailer Net], 
							convert(varchar(10),CAST(T.SaleDate as date),101) as [Transaction Date],
							T.RouteNumber as [Route Number], T.DriverName as [Driver Name], 
							T.SuppAccountNo as [Supplier Account No],
							T.SupplierInvoiceNumber as [Supplier Invoice Number],
							T.SBTNumber as [SBT Number],
							T.CostZoneName as [Cost Zone], 
							T.SupplierID as [Supplier ID #]
							
					FROM DataTrue_CustomResultSets.dbo.tmpCostDifferencesPDI T WITH(NOLOCK) 
					--INNER JOIN JobProcesses J with (nolock)  ON  J.ProcessId = T.ProcessID  and J.JobRunningID = 3 
					INNER JOIN ProductBrandAssignments PB WITH(NOLOCK)  on PB.ProductID=T.ProductID 
					INNER JOIN Brands B WITH(NOLOCK)  ON PB.BrandID = B.BrandID 							
					Left JOIN ProductIdentifiers PD WITH(NOLOCK)  ON T.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=T.SupplierId 
					WHERE  1 =1  '

		if @AttValue =17
			set @Query = @Query + ' and t.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and t.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
            

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and T.SupplierId=' + @SupplierId 
	  
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and T.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and T.banner like ''%' + @Banner + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  T.UPC  like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and cast(T.SaleDate as date) >= cast(dateadd(d,-' +  cast(@LastxDays as varchar) + ', cast(getdate() as date)) as date) and T.SaleDate  <= getdate() '  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and T.SaleDate >= cast(''' + @StartDate  + ''' as date)';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and T.SaleDate <= cast(''' + @EndDate  + ''' as date)';
		
	exec (@Query )

END
GO
