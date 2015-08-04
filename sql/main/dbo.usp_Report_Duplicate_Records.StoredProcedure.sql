USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Duplicate_Records]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Duplicate_Records] 
	-- exec [usp_Report_Duplicate_Records] '40393','41713','All','','-1','-1','0','1900-01-01','1900-01-01'
	
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
declare @RoleName Varchar(50)
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
		
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	SELECT @RoleName= RoleName from AssignUserRoles_New A inner join UserRoles_New R on R.RoleID=A.RoleID where UserID=@PersonID

	set @query = 'SELECT ' + @MaxRowsCount + ' ch.ChainName AS [Retailer Name]
					 , sup.SupplierName AS [Supplier Name]
					 , ST.Banner
					 , S.StoreName AS [Store Name]
					 , S.StoreIdentifier  AS [Store Number]
					 , P.ProductName AS [Product Name]
					 , ST.UPC
					 , Qty AS [Qty]
					 , ''$'' + convert(VARCHAR(50), cast(ST.SetupCost AS NUMERIC(10, '+ @CostFormat +'))) AS [Setup Cost]
					 , ''$'' + convert(VARCHAR(50), cast(ST.SetupRetail AS NUMERIC(10, '+ @CostFormat +'))) AS [Setup Retail]
					 , ''$'' + convert(VARCHAR(50), cast(ST.RuleCost AS NUMERIC(10, '+ @CostFormat +'))) AS [Rule Cost]
					 , ''$'' + convert(VARCHAR(50), cast(ST.RuleRetail AS NUMERIC(10, '+ @CostFormat +'))) AS [Rule Retail]
					 ,SourceIdentifier  AS [File Name]
					 , CASE
						   WHEN WorkingSource = ''INV'' THEN
							   ''Inventory Count''
						   WHEN WorkingSource = ''SUP-S'' THEN
							   ''Delivery Pickups''
						   WHEN WorkingSource = ''SUP-U'' THEN
							   ''Delivery Pickups''
						   ELSE
							   ''''
					   END AS [Working Source]
					 , convert(varchar(10),cast(ST.SaleDateTime as date),101) AS [Transaction Date]
					 , convert(varchar(10),cast(ST.DateTimeCreated as date),101) AS [Date Time Created]
					
							
				FROM
					dbo.StoreTransactions_Working AS ST WITH (NOLOCK)
					INNER JOIN dbo.Suppliers AS sup WITH (NOLOCK)
						ON ST.SupplierID = sup.SupplierID
					INNER JOIN dbo.Chains AS ch WITH (NOLOCK)
						ON ST.ChainID = ch.ChainID
					INNER JOIN Stores S
						ON S.StoreID = ST.StoreID
					INNER JOIN dbo.SupplierBanners SB WITH (NOLOCK)
						ON SB.SupplierId = sup.SupplierID AND SB.Status = ''Active'' AND SB.Banner = ST.Banner
					INNER JOIN Products P
						ON P.ProductID = ST.ProductID 
				WHERE
					1 = 1
					AND ST.WorkingStatus IN (-6, -10) '

		if @AttValue =17
			set @Query = @Query + ' and ch.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and sup.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and ST.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and ST.banner like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and ST.SupplierId=' + @SupplierId  

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  ST.UPC like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (ST.SaleDateTime between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() }) )'   
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and ST.SaleDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and ST.SaleDateTime <= ''' + @EndDate  + '''';

	exec (@Query )
END
GO
