USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_VIN_Exception_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- exec usp_Report_VIN_Exception_All '40393,44199',40384,'All','-1','40558,41440,44246','-1',0,'05/01/2013','05/01/2013'
CREATE  procedure  [dbo].[usp_Report_VIN_Exception_All] 
	-- exec [usp_Report_VIN_Exception_all] '40393','41544','All','','40561','','5','1900-01-01','1900-01-01'
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
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(max)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat  with(nolock) where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4
set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	
	set @query = 'select C.ChainName as [Retailer Name], SP.SupplierName as [Supplier Name], ST.Custom1 as Banner,ST.StoreIdentifier as [Store Number], PD.IdentifierValue as UPC, P.ProductName as Product, 
						PID.IdentifierValue as [Vendor Item Number], S.Qty as [Total Qty], convert(varchar(10), D.DateTimeCreated, 101) as [Invoice Date], 
						''$''+ Convert(varchar(50), cast(ISNULL(D.TotalCost,0) as numeric(10,' + @CostFormat + ')))  as [Total Cost]
						from StoreTransactions S  with(nolock) 
						inner join Chains C  with(nolock) on C.ChainId=S.ChainId
						inner join Suppliers SP  with(nolock) on SP.SupplierId=S.SupplierId
						inner join Stores ST  with(nolock)  on ST.StoreId=S.StoreId and ST.ChainId=S.ChainId
						inner join Products P  with(nolock) on P.ProductId=S.ProductId
						inner join ProductIdentifiers PD  with(nolock) on PD.ProductId=S.ProductId and PD.ProductIdentifierTypeId=2
						inner join InvoiceDetails D  with(nolock) on D.SupplierId=S.SupplierID and D.ChainId=S.ChainId and D.StoreId=S.StoreId and D.ProductId=S.ProductId and D.SaleDate=S.SaleDateTime
						Left JOIN  ProductIdentifiers PID  with(nolock) ON PID.ProductID = P.ProductID and PID.ProductIdentifierTypeId = 3 and PID.OwnerEntityId=SP.SupplierID 
						WHERE  1=1 
						 and S.UnAuthorizedAssignment = 1   '
						
	--if @AttValue =17
	--	set @query = @query + ' and C.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	--else
	--	set @query = @query + ' and SP.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and C.ChainID in (' + @chainID +')'

	if(@Banner<>'All') 
		set @Query  = @Query + ' and ST.Custom1 like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and SP.SupplierId in (' + @SupplierId  +')'

	if(@StoreId <>'-1') 
		set @Query   = @Query  +  ' and ST.StoreIdentifier like ''%' + @StoreId + '%'''

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and PD.IdentifierValue like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (D.DateTimeCreated between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and D.DateTimeCreated >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and D.DateTimeCreated <= ''' + @EndDate  + '''';
			
	set @Query = @Query + ' ORDER BY 1,3,2,5 '
print (@Query)
	exec  (@Query )
END
GO
