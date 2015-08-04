USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InventoryReview_beta]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_InventoryReview_beta '-1','41440','-1','-1',2,'',1,'','1','','1','Banner ASC',1,25,1
CREATE procedure [dbo].[usp_InventoryReview_beta]

@ChainId varchar(10),
@SupplierId varchar(10),
@custom1 varchar(255),
@BrandId varchar(10),
@ProductIdentifierType int,
@ProductIdentifierValue varchar(50),
@StoreIdentifierType int,
@StoreIdentifierValue varchar(50),
@OtherOption int,
@Others varchar(50),
@AggregateByDist varchar(12),
@OrderBy varchar(100),
@StartIndex int,
@PageSize int,
@DisplayMode int

as

Begin
Declare @sqlQuery varchar(4000)

Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
 else
	set @CostFormat=4
	
set @sqlQuery = 'SELECT  dbo.Chains.ChainName as [Retailer Name],
					suppliers.suppliername as [Supplier Name],
					stores.Custom1 as Banner ,
					dbo.Stores.StoreIdentifier as [Store No], dbo.Brands.BrandName as Brand,
					dbo.Products.ProductName as [Product], dbo.ProductIdentifiers.IdentifierValue as [UPC], PD.IdentifierValue 
					as [Supplier Product Code],
					cast(InventoryPerpetual.Cost as numeric(10, ' + @CostFormat + ')) as Cost, InventoryPerpetual.CurrentOnHandQty  AS [Qty Available],'
					
if(@AggregateByDist='1')
	 begin					
		 set @sqlQuery = @sqlQuery + ' SUV.DistributionCenter as [Dist. Center]'
	end 
else	
    begin	 
		 set @sqlQuery = @sqlQuery + ' SUV.DistributionCenter as [Dist. Center],SUV.RegionalMgr as [Regional Mgr.], 
									   SUV.SalesRep as [Sales Rep.],SUV.DriverName as [Driver Name],
									   SUV.RouteNumber as [Route Number], SUV.SupplierAccountNumber as [Supplier Acct #]'	
	end							      
	 set @sqlQuery = @sqlQuery + '  FROM  InventoryPerpetual
									INNER JOIN  dbo.Products ON dbo.InventoryPerpetual.ProductID = dbo.Products.ProductID
									INNER JOIN  dbo.Stores ON InventoryPerpetual.StoreID = dbo.Stores.StoreID AND dbo.Stores.ActiveStatus = ''Active''
									INNER JOIN  dbo.Chains ON dbo.Chains.ChainID = dbo.Stores.ChainID
									INNER JOIN  dbo.Brands ON InventoryPerpetual.BrandID = dbo.Brands.BrandID
									LEFT JOIN   dbo. storesetup s on s.StoreID =InventoryPerpetual.StoreID and s.ProductID =InventoryPerpetual.ProductID
									LEFT JOIN    StoresUniqueValues SUV on SUV.SupplierID = s.SupplierID and SUV.StoreID=Stores.StoreID 
									Inner join  SupplierBanners SB on SB.SupplierId = s.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.custom1									INNER JOIN  dbo.ProductIdentifiers ON InventoryPerpetual.ProductID = dbo.ProductIdentifiers.ProductID 
									AND ProductIdentifiers.ProductIdentifierTypeID in (2,8)
									inner join dbo.suppliers on suppliers.supplierid=s.supplierid 
									Left JOIN  dbo.ProductIdentifiers PD ON InventoryPerpetual.ProductID = PD.ProductID AND
								    PD.ProductIdentifierTypeID =3 
									and PD.OwnerEntityId=S.SupplierId
									WHERE  1=1'

if(@SupplierId<>'-1')
    set @sqlQuery = @sqlQuery + ' and s.supplierid =' + @SupplierId

if(@ChainId<>'-1')
    set @sqlQuery = @sqlQuery + ' and sb.ChainId=' + @ChainId

if(@custom1='')
    set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'

else if(@custom1<>'-1')
    set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''

if(@BrandId<>'-1')
    set @sqlQuery = @sqlQuery + ' and Brands.BrandId= ' + @BrandId

		
if(@ProductIdentifierValue<>'')
begin

    -- 2 = UPC, 3 = Product Name , 7 = Supplier Product Code
    if (@ProductIdentifierType=2)
         set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
         
    else if (@ProductIdentifierType=3)
        set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @ProductIdentifierValue + '%'''
        
    else if (@ProductIdentifierType=7)
		 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
end

if(@StoreIdentifierValue<>'')
begin
    -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
    if (@StoreIdentifierType=1)
        set @sqlQuery = @sqlQuery + ' and stores.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
    else if (@StoreIdentifierType=2)
        set @sqlQuery = @sqlQuery + ' and stores.Custom2 like ''%' + @StoreIdentifierValue + '%'''
    else if (@StoreIdentifierType=3)
        set @sqlQuery = @sqlQuery + ' and stores.StoreName like ''%' + @StoreIdentifierValue + '%'''
end

if(@Others<>'')
begin
    -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
    -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                         
    if (@OtherOption=1)
        set @sqlQuery = @sqlQuery + ' and SUV.DistributionCenter like ''%' + @Others + '%'''
    else if (@OtherOption=2)
        set @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr like ''%' + @Others + '%'''
    else if (@OtherOption=3)
        set @sqlQuery = @sqlQuery + ' and SUV.SalesRep like ''%' + @Others + '%'''
    else if (@OtherOption=4)
        set @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber like ''%' + @Others + '%'''
    else if (@OtherOption=5)
        set @sqlQuery = @sqlQuery + ' and SUV.DriverName like ''%' + @Others + '%'''
    else if (@OtherOption=6)
        set @sqlQuery = @sqlQuery + ' and SUV.RouteNumber like ''%' + @Others + '%'''
end

if(@AggregateByDist='1')

	set @sqlQuery=@sqlQuery + ' group by SUV.DistributionCenter, dbo.Chains.ChainName,suppliers.suppliername,stores.Custom1,
								 dbo.Stores.StoreIdentifier,dbo.Brands.BrandName,dbo.Products.ProductName, dbo.ProductIdentifiers.IdentifierValue,
								 PD.IdentifierValue,
								 InventoryPerpetual.Cost,InventoryPerpetual.CurrentOnHandQty '	   
print (@sqlQuery)          
set @sqlQuery = [dbo].GetPagingQuery_new(@sqlQuery, @orderby, @StartIndex ,@PageSize ,@DisplayMode)
print (@sqlQuery)
exec (@sqlQuery);

End
GO
