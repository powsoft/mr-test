USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_CostDifferences_ByStore_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_CostDifferences_ByStore_All_PRESYNC_20150524] 
	-- usp_Report_CostDifferences_ByStore_All '-1','62331','All','-1','-1','-1','0','01/01/2013','12/31/2013'
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
 
Declare @AccessLevel varchar(20)
Declare @AccessValue varchar(20)

select @AccessLevel=AttributeName 
			,@AccessValue=AttributeValue
from AttributeDefinitions d
	inner join AttributeValues v on d.AttributeID = v.AttributeID
where OwnerEntityID = @PersonId
			and v.IsActive = 1 
			and d.AttributeID IN(9,17,23)
			
	if(@AccessLevel ='ChainAccess') 		
		Begin	
			if(@chainID<>'-1') 
				Set @chainID =@chainID + ',' +@AccessValue
			else
				Set @chainID =@AccessValue
		End
	else if(@AccessLevel ='SupplierAccess') 	
		Begin
			if(@SupplierId<>'-1') 
				Set @SupplierId = @SupplierId+ ',' +@AccessValue
			else
				Set @SupplierId=@AccessValue
		End
		
	Print(@SupplierId)	
	print(@chainID)

 if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(1000)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
 else
	set @CostFormat=4
 set @CostFormat = isnull(@costformat,4)		
 select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 set @Query =' SELECT       dbo.Chains.ChainName as [Chain Name]
						, dbo.Stores.StoreIdentifier as [Store Number]
						, dbo.Stores.Custom1 AS Banner
						, dbo.Suppliers.SupplierName as [Supplier Name]
						, B.BrandName as Brand
						, dbo.Products.ProductName as [Product Name]
						, dbo.ProductIdentifiers.IdentifierValue AS UPC
						, PD.IdentifierValue as [Supplier Product Code]
						, SUM(ST.Qty) AS Qty
						, ''$''+ Convert(varchar(50)
						, Cast(ST.SetupCost as numeric(10,' + @CostFormat + '))) AS [Setup Cost]
						, ''$''+ Convert(varchar(50)
						, Cast(ST.PromoAllowance as numeric(10,' + @CostFormat + '))) AS [Setup Promo]
						, ''$''+ Convert(varchar(50)
						, cast((ST.SetupCost - isnull(ST.PromoAllowance,0)) as numeric(10,' + @CostFormat + '))) AS [Setup Net]
						, ''$''+ Convert(varchar(50), cast((ST.ReportedCost + ST.ReportedAllowance) as numeric(10,' + @CostFormat + '))) AS [Reported Cost]
						, ''$''+ Convert(varchar(50)
						, Cast(ST.ReportedAllowance as numeric(10,' + @CostFormat + '))) AS [Reported Promo]
						, ''$''+ Convert(varchar(50)
						, Cast(ST.ReportedCost as numeric(10,' + @CostFormat + '))) as [Retailer Net]
						, dbo.FDatetime(ST.SaleDateTime) AS [Sale Date]
						, isnull(SUV.RouteNumber,'''') as [Route Number]
						, isnull(SUV.DriverName,'''') as [Driver Name]
						, isnull(SUV.SupplierAccountNumber,'''') as [Supplier Account No]
						, isnull(SUV.SBTNumber,'''') as [SBT Number], isnull(dbo.CostZones.CostZoneId,'''') as [Cost Zone] 
						, dbo.Suppliers.SupplierID as [Supplier ID #]
                      
		FROM dbo.TransactionTypes 
			INNER JOIN datatrue_report.dbo.StoreTransactions ST ON dbo.TransactionTypes.TransactionTypeID = ST.TransactionTypeID 
			INNER JOIN dbo.Suppliers ON ST.SupplierID = dbo.Suppliers.SupplierID 
			INNER JOIN dbo.Chains ON dbo.Chains.ChainID = ST.ChainID 
			INNER JOIN dbo.Stores ON ST.StoreID = dbo.Stores.StoreID and dbo.Stores.ActiveStatus=''Active''  
			INNER JOIN dbo.Products ON ST.ProductID = dbo.Products.ProductID 
			INNER JOIN ProductBrandAssignments PB on PB.ProductID=ST.ProductID 
			INNER JOIN Brands B ON PB.BrandID = B.BrandID 
			INNER JOIN SupplierBanners SB on SB.SupplierId = dbo.Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1
			INNER JOIN dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and dbo.ProductIdentifiers.ProductIdentifierTypeID = 2
			Left JOIN  dbo.ProductIdentifiers PD ON ST.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=ST.SupplierId 
			left join  dbo.StoresUniqueValues SUV on dbo.Stores.Storeid=SUV.StoreID and SUV.SupplierID=dbo.Suppliers.SupplierID
			Left Join dbo.CostZoneRelations ON dbo.CostZoneRelations.StoreID = dbo.Stores.StoreID and dbo.CostZoneRelations.SupplierID = dbo.Suppliers.SupplierID 
			Left join dbo.CostZones on dbo.CostZones.CostZoneID=dbo.CostZoneRelations.CostZoneID
		
		WHERE    (dbo.TransactionTypes.BucketTypeName = ''POS'')  
			AND (Cast(ST.SetupCost as decimal(10,4)) - isnull(cast(ST.PromoAllowance as decimal(10,4)), 0) <> cast(ST.ReportedCost as decimal(10,4))) '                     

		--if @AttValue =17
		--	set @query = @query + ' and dbo.Chains.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		--else
		--	set @query = @query + ' and dbo.Suppliers.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and dbo.Suppliers.SupplierId in ( ' + @SupplierId +')'
		     
		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and dbo.Chains.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and dbo.Stores.Custom1 like ''%' + @Banner + '%'''

		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and dbo.Stores.StoreIdentifier like ''%' + @StoreId + '%'''

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and dbo.ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''


		if (@LastxDays > 0)
			set @Query = @Query + ' and (ST.SaleDateTime >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and ST.SaleDateTime <=getdate()) '  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and ST.SaleDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and ST.SaleDateTime <= ''' + @EndDate  + '''';


		set @query = @query + ' GROUP BY dbo.Chains.ChainName
							, dbo.Stores.StoreIdentifier
							, dbo.Stores.Custom1
							, dbo.Suppliers.SupplierName
							, B.BrandName
							, dbo.Products.ProductName
							, dbo.ProductIdentifiers.IdentifierValue
							, PD.IdentifierValue
							, ST.SetupCost
							, ST.PromoAllowance
							, ST.SetupCost
							, ST.ReportedCost 
							, ST.ReportedAllowance
							, ST.ReportedCost
							, ST.SaleDateTime 
							, SUV.RouteNumber
							, SUV.DriverName
							, SUV.SupplierAccountNumber
							, SUV.SBTNumber
							, dbo.Suppliers.SupplierID
							, dbo.CostZones.CostZoneId
							
							
				HAVING      (CAST(SUM(ST.Qty) AS varchar) <> ''0'')';
    print  (@Query )
		exec  (@Query )
END
GO
