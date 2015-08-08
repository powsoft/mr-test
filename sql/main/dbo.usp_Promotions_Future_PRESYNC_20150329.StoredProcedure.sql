USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Promotions_Future_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Promotions_Future_PRESYNC_20150329]
-- exec usp_Promotions_Future '-3','40393','-1','1900-01-01','1900-01-01','2','','1','','1','','-1','-1'  
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
	
 set @sqlQuery = 'SELECT dbo.CurrentPromotions_Future.ChainName as [Chain Name],dbo.CurrentPromotions_Future.SupplierID as [Supplier No], dbo.CurrentPromotions_Future.Banner,
				(SELECT  CostZoneName FROM dbo.CostZones WHERE (CostZoneId = dbo.MaintenanceRequests.CostZoneID)) AS [Cost Zone Name],
				dbo.CurrentPromotions_Future.SupplierName as [Supplier Name], dbo.CurrentPromotions_Future.ProductName as [Product Name], 
				dbo.CurrentPromotions_Future.[Store Number], dbo.CurrentPromotions_Future.[SBT Number], dbo.CurrentPromotions_Future.[Store Name],
				dbo.CurrentPromotions_Future.UPC,  
				convert(date, dbo.CurrentPromotions_Future.[Begin Date], 101)  as [Begin Date] , 
				convert(date, dbo.CurrentPromotions_Future.[End Date], 101)  as [End Date] , 
				cast(dbo.ProductPrices.UnitPrice as numeric(10, ' + @CostFormat + ')) as [Base Cost],
				cast(dbo.CurrentPromotions_Future.Allowance as numeric(10, ' + @CostFormat + ')) as [Allowance],
				cast(dbo.ProductPrices.UnitRetail as numeric(10, 2)) as [Base Retail],
				convert(date, dbo.ProductPrices.ActiveStartDate,101) as [Base Begin Date], 
				convert(date, dbo.ProductPrices.ActiveLastDate,101) as [Base End Date],
				SUV.DistributionCenter as [Dist. Center], SUV.RegionalMgr as [Regional Mgr.], SUV.SalesRep as [Sales Rep.],
				SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number], SUV.SupplierAccountNumber as [Supplier Acct #],dbo.MaintenanceRequests.DealNumber as [Deal Number]
				FROM  dbo.CurrentPromotions_Future  with(nolock)
				INNER JOIN dbo.ProductPrices  with(nolock) ON dbo.CurrentPromotions_Future.StoreID = dbo.ProductPrices.StoreID AND dbo.CurrentPromotions_Future.SupplierID = dbo.ProductPrices.SupplierID AND 
				dbo.CurrentPromotions_Future.BrandID = dbo.ProductPrices.BrandID AND dbo.CurrentPromotions_Future.ProductID = dbo.ProductPrices.ProductID
				Inner join SupplierBanners SB with(nolock) on SB.SupplierId = CurrentPromotions_Future.SupplierId and SB.Status=''Active'' and SB.Banner=CurrentPromotions_Future.Banner'

				set @sqlQuery = @sqlQuery +  '			
					LEFT OUTER JOIN
                      dbo.MaintenanceRequests  with(nolock) ON dbo.MaintenanceRequests.ChainID = dbo.CurrentPromotions_Future.ChainID AND 
                      dbo.MaintenanceRequests.SupplierID = dbo.CurrentPromotions_Future.SupplierID AND 
                      dbo.MaintenanceRequests.productid = dbo.CurrentPromotions_Future.ProductID AND 
                      dbo.MaintenanceRequests.StartDateTime = dbo.CurrentPromotions_Future.[Begin Date] AND 
                      dbo.MaintenanceRequests.EndDateTime = dbo.CurrentPromotions_Future.[End Date] AND 
                      dbo.MaintenanceRequests.PromoAllowance = dbo.CurrentPromotions_Future.Allowance AND dbo.MaintenanceRequests.RequestTypeID = 3'

				set @sqlQuery = @sqlQuery +  '					
					LEFT OUTER JOIN  dbo.StoresUniqueValues SUV with(nolock) ON dbo.CurrentPromotions_Future.SupplierID = SUV.SupplierID AND dbo.CurrentPromotions_Future.StoreID = SUV.StoreID
					WHERE (dbo.ProductPrices.ProductPriceTypeID = 3) AND (dbo.ProductPrices.ActiveStartDate <= { fn NOW() }) AND (dbo.ProductPrices.ActiveLastDate >= { fn NOW() }) '
    

	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CurrentPromotions_Future.SupplierId=' + @SupplierId

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CurrentPromotions_Future.ChainId=' + @ChainId

	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.Banner=''' + @Banner + ''''

	if( convert(date, @FromStartDate  ) > convert(date,'1900-01-01') and  convert(date, @ToStartDate ) > convert(date,'1900-01-01') ) 
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.[Begin Date] between ''' + @FromStartDate  + ''' and ''' + @ToStartDate + ''''  ;

	else if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.[Begin Date]  >= ''' + @FromStartDate  + '''';

	else if(convert(date, @ToStartDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and  CurrentPromotions_Future.[Begin Date] <=''' + @ToStartDate  + '''';
	
	--if(@ProductIdentifierType<>3)
	--		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
	--else
	--		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.ProductIdentifierTypeId = 2 '
	
	if(@ProductIdentifierType=2 or @ProductIdentifierType=3)
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.ProductIdentifierTypeId in (2,8)'
	else
		set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
			
	if(@ProductIdentifierValue<>'')
	begin

		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.UPC like ''%' + @ProductIdentifierValue + '%'''
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and CurrentPromotions_Future.ProductName like ''%' + @ProductIdentifierValue + '%'''
	end
	
	
	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions_Future.[Store Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions_Future.[SBT Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and dbo.CurrentPromotions_Future.[Store Name] like ''%' + @StoreIdentifierValue + '%'''
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
		
	set @sqlQuery = @sqlQuery + ' order by dbo.CurrentPromotions_Future.ChainName, dbo.CurrentPromotions_Future.Banner, dbo.CurrentPromotions_Future.SupplierName, dbo.CurrentPromotions_Future.ProductName, 
                dbo.CurrentPromotions_Future.[Store Number], dbo.CurrentPromotions_Future.[SBT Number], dbo.CurrentPromotions_Future.UPC, dbo.CurrentPromotions_Future.Allowance, 
               dbo.CurrentPromotions_Future.[Begin Date], dbo.CurrentPromotions_Future.[End Date], dbo.ProductPrices.UnitPrice '

				
execute(@sqlQuery); 

End
GO
