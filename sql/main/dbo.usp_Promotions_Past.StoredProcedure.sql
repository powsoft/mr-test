USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Promotions_Past]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Promotions_Past]
 
 @SupplierId varchar(10),
 @ChainId varchar(10),
 @Banner varchar(255),
 @FromStartDate varchar(50),
 @ToStartDate varchar(50),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @OtherOption int,
 @Others varchar(50),
 @DealNumber varchar(50),
 @CostZoneId varchar(50)
as
-- exec usp_Promotions_Past '-3','40393','-1','1900-01-01','1900-01-01','2','','1','','1','','-1','-1' 
Begin
 Declare @sqlQuery varchar(4000)
 Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1' and @SupplierId<>'-3')
	Select @CostFormat = Costformat from SupplierFormat with(nolock) where SupplierID = @supplierID
 else
	set @CostFormat=4
	
 set @sqlQuery = 'SELECT dbo.CurrentPromotions_Past.ChainName as [Chain Name],dbo.CurrentPromotions_Past.SupplierID as [Supplier No],  dbo.CurrentPromotions_Past.Banner,
				(SELECT  CostZoneName FROM dbo.CostZones WHERE (CostZoneId = dbo.MaintenanceRequests.CostZoneID)) AS [Cost Zone Name],
				dbo.CurrentPromotions_Past.SupplierName as [Supplier Name], dbo.CurrentPromotions_Past.ProductName as [Product Name], 
				dbo.CurrentPromotions_Past.[Store Number], dbo.CurrentPromotions_Past.[SBT Number], dbo.CurrentPromotions_Past.[Store Name],
				dbo.CurrentPromotions_Past.UPC, 
				convert(date, dbo.CurrentPromotions_Past.[Begin Date], 101)  as [Begin Date] , 
				convert(date, dbo.CurrentPromotions_Past.[End Date], 101)  as [End Date] , 
				cast(dbo.ProductPrices.UnitPrice as numeric(10, ' + @CostFormat + ')) as [Base Cost],
				cast(dbo.CurrentPromotions_Past.Allowance as numeric(10, ' + @CostFormat + ')) as [Allowance],
				cast(dbo.ProductPrices.UnitRetail as numeric(10, 2)) as [Base Retail],
				convert(date, dbo.ProductPrices.ActiveStartDate,101) as [Base Begin Date], 
				convert(date, dbo.ProductPrices.ActiveLastDate,101) as [Base End Date],
				SUV.DistributionCenter as [Dist. Center], SUV.RegionalMgr as [Regional Mgr.], SUV.SalesRep as [Sales Rep.],
				SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number], SUV.SupplierAccountNumber as [Supplier Acct #],dbo.MaintenanceRequests.DealNumber as [Deal Number]
				FROM  dbo.CurrentPromotions_Past 
				INNER JOIN dbo.ProductPrices with(nolock) ON dbo.CurrentPromotions_Past.StoreID = dbo.ProductPrices.StoreID AND dbo.CurrentPromotions_Past.SupplierID = dbo.ProductPrices.SupplierID AND 
				dbo.CurrentPromotions_Past.BrandID = dbo.ProductPrices.BrandID AND dbo.CurrentPromotions_Past.ProductID = dbo.ProductPrices.ProductID
				Inner join SupplierBanners SB with(nolock) on SB.SupplierId = CurrentPromotions_Past.SupplierId and SB.Status=''Active'' and SB.Banner=CurrentPromotions_Past.Banner'

				set @sqlQuery = @sqlQuery +  '			
					LEFT OUTER JOIN
                      dbo.MaintenanceRequests with(nolock) ON dbo.MaintenanceRequests.ChainID = dbo.CurrentPromotions_Past.ChainID AND 
                      dbo.MaintenanceRequests.SupplierID = dbo.CurrentPromotions_Past.SupplierID AND 
                      dbo.MaintenanceRequests.productid = dbo.CurrentPromotions_Past.ProductID AND 
                      dbo.MaintenanceRequests.StartDateTime = dbo.CurrentPromotions_Past.[Begin Date] AND 
                      dbo.MaintenanceRequests.EndDateTime = dbo.CurrentPromotions_Past.[End Date] AND 
                      dbo.MaintenanceRequests.PromoAllowance = dbo.CurrentPromotions_Past.Allowance AND dbo.MaintenanceRequests.RequestTypeID = 3'

				set @sqlQuery = @sqlQuery +  '					
					
					LEFT OUTER JOIN  dbo.StoresUniqueValues SUV with(nolock) ON dbo.CurrentPromotions_Past.SupplierID = SUV.SupplierID AND dbo.CurrentPromotions_Past.StoreID = SUV.StoreID
					WHERE (dbo.ProductPrices.ProductPriceTypeID = 3) AND (dbo.ProductPrices.ActiveStartDate <= { fn NOW() }) AND (dbo.ProductPrices.ActiveLastDate >= { fn NOW() }) '
    

	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CurrentPromotions_Past.SupplierId=' + @SupplierId

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CurrentPromotions_Past.ChainId=' + @ChainId

	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.Banner=''' + @Banner + ''''

	if( convert(date, @FromStartDate  ) > convert(date,'1900-01-01') and  convert(date, @ToStartDate ) > convert(date,'1900-01-01') ) 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.[Begin Date] between ''' + @FromStartDate  + ''' and ''' + @ToStartDate + ''''  ;

	else if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.[Begin Date]  >= ''' + @FromStartDate  + '''';

	else if(convert(date, @ToStartDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and  CurrentPromotions_Past.[Begin Date] <=''' + @ToStartDate  + '''';
	
	--if(@ProductIdentifierType<>3)
	--		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
	--else
	--		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.ProductIdentifierTypeId = 2 '
	
	if(@ProductIdentifierType=2 or @ProductIdentifierType=3)
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.ProductIdentifierTypeId in (2,8)'
	else
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
	
			
	if(@ProductIdentifierValue<>'')
	begin

		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.UPC like ''%' + @ProductIdentifierValue + '%'''
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Past.ProductName like ''%' + @ProductIdentifierValue + '%'''
	end

	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions_Past.[Store Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions_Past.[SBT Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions_Past.[Store Name] like ''%' + @StoreIdentifierValue + '%'''
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
	
	if(@DealNumber<>'-1')
		set @sqlQuery = @sqlQuery +  ' and dbo.MaintenanceRequests.DealNumber = ''' + @DealNumber + ''''

	if(@CostZoneId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and dbo.MaintenanceRequests.CostZoneId = ''' + @CostZoneId + ''''
		
	set @sqlQuery = @sqlQuery + ' order by dbo.CurrentPromotions_Past.ChainName, dbo.CurrentPromotions_Past.Banner, dbo.CurrentPromotions_Past.SupplierName, dbo.CurrentPromotions_Past.ProductName, 
                dbo.CurrentPromotions_Past.[Store Number], dbo.CurrentPromotions_Past.[SBT Number], dbo.CurrentPromotions_Past.UPC, dbo.CurrentPromotions_Past.Allowance, 
               dbo.CurrentPromotions_Past.[Begin Date], dbo.CurrentPromotions_Past.[End Date], dbo.ProductPrices.UnitPrice '

				
execute(@sqlQuery); 

End
GO
