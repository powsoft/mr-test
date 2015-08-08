USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Promotions_Current]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Promotions_Current]
 -- exec usp_Promotions_Current '-3','40393','-1','1900-01-01','1900-01-01','2','','1','','1','','-1','-1' 
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

Begin
 Declare @sqlQuery varchar(4000)
 Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1' and @SupplierId<>'-3')
	Select @CostFormat = Costformat from SupplierFormat with(nolock) where SupplierID = @supplierID
 else
	set @CostFormat=4
	
 set @sqlQuery = 'SELECT dbo.CurrentPromotions.ChainName as [Chain Name],dbo.CurrentPromotions.SupplierID as [Supplier No], dbo.CurrentPromotions.Banner,
					(SELECT  CostZoneName FROM dbo.CostZones WHERE (CostZoneId = dbo.MaintenanceRequests.CostZoneID)) AS [Cost Zone Name],
					dbo.CurrentPromotions.SupplierName as [Supplier Name], dbo.CurrentPromotions.ProductName as [Product Name], 
					dbo.CurrentPromotions.[Store Number], dbo.CurrentPromotions.[SBT Number], dbo.CurrentPromotions.[Store Name],
					dbo.CurrentPromotions.UPC, 
					convert(date, dbo.CurrentPromotions.[Begin Date], 101)  as [Begin Date] , 
					convert(date, dbo.CurrentPromotions.[End Date], 101)  as [End Date] , 
					cast(dbo.ProductPrices.UnitPrice as numeric(10, ' + @CostFormat + ')) as [Base Cost],
					cast(dbo.CurrentPromotions.Allowance as numeric(10, ' + @CostFormat + ')) as [Allowance],
					cast(dbo.ProductPrices.UnitRetail as numeric(10,2)) as [Base Retail],
					convert(date, dbo.ProductPrices.ActiveStartDate,101) as [Base Begin Date], 
					convert(date, dbo.ProductPrices.ActiveLastDate,101) as [Base End Date],
					SUV.DistributionCenter as [Dist. Center], SUV.RegionalMgr as [Regional Mgr.], SUV.SalesRep as [Sales Rep.],
					SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number], SUV.SupplierAccountNumber as [Supplier Acct #],
					dbo.MaintenanceRequests.DealNumber as [Deal Number]
					FROM  dbo.CurrentPromotions  with(nolock)
					INNER JOIN	dbo.ProductPrices ON dbo.CurrentPromotions.StoreID = dbo.ProductPrices.StoreID AND dbo.CurrentPromotions.SupplierID = dbo.ProductPrices.SupplierID AND 
					dbo.CurrentPromotions.BrandID = dbo.ProductPrices.BrandID AND dbo.CurrentPromotions.ProductID = dbo.ProductPrices.ProductID
					Inner join SupplierBanners SB on SB.SupplierId = CurrentPromotions.SupplierId and SB.Status=''Active'' and SB.Banner=CurrentPromotions.Banner'

			set @sqlQuery = @sqlQuery +  '	
				LEFT OUTER JOIN
                      dbo.MaintenanceRequests with(nolock) ON dbo.MaintenanceRequests.ChainID = dbo.CurrentPromotions.ChainID AND 
                      dbo.MaintenanceRequests.SupplierID = dbo.CurrentPromotions.SupplierID AND 
                      dbo.MaintenanceRequests.productid = dbo.CurrentPromotions.ProductID AND 
                      dbo.MaintenanceRequests.StartDateTime = dbo.CurrentPromotions.[Begin Date] AND 
                      dbo.MaintenanceRequests.EndDateTime = dbo.CurrentPromotions.[End Date] AND 
                      dbo.MaintenanceRequests.PromoAllowance = dbo.CurrentPromotions.Allowance AND dbo.MaintenanceRequests.RequestTypeID = 3'

			set @sqlQuery = @sqlQuery +  '				
				LEFT OUTER JOIN  dbo.StoresUniqueValues SUV with(nolock) ON dbo.CurrentPromotions.SupplierID = SUV.SupplierID AND dbo.CurrentPromotions.StoreID = SUV.StoreID
				WHERE (dbo.ProductPrices.ProductPriceTypeID = 3) AND (dbo.ProductPrices.ActiveStartDate <= { fn NOW() }) AND (dbo.ProductPrices.ActiveLastDate >= { fn NOW() }) '

	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CurrentPromotions.SupplierId=' + @SupplierId

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CurrentPromotions.ChainId=' + @ChainId

	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.Banner=''' + @Banner + ''''

	if( convert(date, @FromStartDate  ) > convert(date,'1900-01-01') and  convert(date, @ToStartDate ) > convert(date,'1900-01-01') ) 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.[Begin Date] between ''' + @FromStartDate  + ''' and ''' + @ToStartDate + ''''  ;

	else if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.[Begin Date]  >= ''' + @FromStartDate  + '''';

	else if(convert(date, @ToStartDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and  CurrentPromotions.[Begin Date] <=''' + @ToStartDate  + '''';
	
	--if(@ProductIdentifierType<>3)
	--		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
	--else
	--		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.ProductIdentifierTypeId = 2 '
	
	if(@ProductIdentifierType=2 or @ProductIdentifierType=3)
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.ProductIdentifierTypeId in (2,8)'
	else
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
	
			
	if(@ProductIdentifierValue<>'')
	begin

		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and CurrentPromotions.UPC like ''%' + @ProductIdentifierValue + '%'''
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and CurrentPromotions.ProductName like ''%' + @ProductIdentifierValue + '%'''
	end
	
	
	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions.[Store Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions.[SBT Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions.[Store Name] like ''%' + @StoreIdentifierValue + '%'''
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
		
	set @sqlQuery = @sqlQuery + ' and ProductPrices.ActiveStartDate = (Select max(ActiveStartDate) from ProductPrices P1 
		where dbo.ProductPrices.ProductPriceTypeID = P1.ProductPriceTypeID
		and dbo.ProductPrices.SupplierID =P1.SupplierID
		and dbo.ProductPrices.ChainID =P1.ChainID
		and dbo.ProductPrices.StoreID =P1.StoreID
		and dbo.ProductPrices.ProductID =P1.ProductID
		AND dbo.ProductPrices.ActiveStartDate <= { fn NOW() } 
		AND dbo.ProductPrices.ActiveLastDate >= { fn NOW() })'
		
	set @sqlQuery = @sqlQuery + ' order by dbo.CurrentPromotions.ChainName, dbo.CurrentPromotions.Banner, dbo.CurrentPromotions.SupplierName, dbo.CurrentPromotions.ProductName, 
                dbo.CurrentPromotions.[Store Number], dbo.CurrentPromotions.[SBT Number], dbo.CurrentPromotions.UPC, dbo.CurrentPromotions.Allowance, 
               dbo.CurrentPromotions.[Begin Date], dbo.CurrentPromotions.[End Date], dbo.ProductPrices.UnitPrice, dbo.ProductPrices.UnitRetail'
 execute(@sqlQuery); 

End
GO
