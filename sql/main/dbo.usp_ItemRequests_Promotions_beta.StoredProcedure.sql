USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ItemRequests_Promotions_beta]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ItemRequests_Promotions_beta]
 
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
	 @CostZoneId varchar(50),
	 @RequestStatus varchar(10)
as
-- [usp_ItemRequests_Promotions_beta] '-1','40393','-1','05/11/2013','09/09/2013',2,'',1,'',1,'','-1','-1','Past'
Begin
	 Declare @sqlQuery varchar(4000)
	 Declare @sqlDateCheck varchar(4000)
	 Declare @sqlTableName varchar(4000)
	 Declare @CostFormat varchar(10)='4'
 
	 if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
	set @CostFormat=isnull(@CostFormat, 4)
	
    if(@RequestStatus ='Future')	
		set @sqlTableName = '_Future'
	else if(@RequestStatus ='Past')	
		set @sqlTableName = '_Past'
	else if(@RequestStatus ='All')	
		set @sqlTableName = '_ViewALL'	
	else
		set @sqlTableName = ''
		
	 set @sqlQuery = 'SELECT CP.ChainName as [Chain Name],CP.SupplierID as [Supplier No], 
					CP.Banner,
					(SELECT  CostZoneName FROM dbo.CostZones WHERE (CostZoneId = dbo.MaintenanceRequests.CostZoneID)) AS [Cost Zone Name],
					CP.SupplierName as [Supplier Name], CP.ProductName as [Product Name], 
					CP.[Store Number], CP.[SBT Number], CP.[Store Name],
					CP.UPC, 
					convert(varchar(10), CP.[Begin Date], 101)  as [Begin Date] , 
					convert(varchar(10), CP.[End Date], 101)  as [End Date] , 
					cast(dbo.ProductPrices.UnitPrice as numeric(10, ' + @CostFormat + ')) as [Base Cost],
					cast(CP.Allowance as numeric(10, ' + @CostFormat + ')) as [Allowance],
					cast(dbo.ProductPrices.UnitRetail as numeric(10,2)) as [Base Retail],
					convert(varchar(10), dbo.ProductPrices.ActiveStartDate,101) as [Base Begin Date], 
					convert(varchar(10), dbo.ProductPrices.ActiveLastDate,101) as [Base End Date],
					SUV.DistributionCenter as [Dist. Center], SUV.RegionalMgr as [Regional Mgr.], SUV.SalesRep as [Sales Rep.],
					SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number], SUV.SupplierAccountNumber as [Supplier Acct #],
					dbo.MaintenanceRequests.DealNumber as [Deal Number]
				FROM  dbo.CurrentPromotions' + @sqlTableName + ' CP 
				INNER JOIN	dbo.ProductPrices ON CP.StoreID = dbo.ProductPrices.StoreID AND CP.SupplierID = dbo.ProductPrices.SupplierID AND 
					CP.BrandID = dbo.ProductPrices.BrandID AND CP.ProductID = dbo.ProductPrices.ProductID
				Inner join SupplierBanners SB on SB.SupplierId = CP.SupplierId and SB.Status=''Active'' and SB.Banner=CP.Banner
				LEFT OUTER JOIN
					dbo.MaintenanceRequests ON dbo.MaintenanceRequests.ChainID = CP.ChainID AND 
					dbo.MaintenanceRequests.SupplierID = CP.SupplierID AND 
					dbo.MaintenanceRequests.productid = CP.ProductID AND 
					dbo.MaintenanceRequests.StartDateTime = CP.[Begin Date] AND 
					dbo.MaintenanceRequests.EndDateTime = CP.[End Date] AND 
                      dbo.MaintenanceRequests.PromoAllowance = CP.Allowance AND dbo.MaintenanceRequests.RequestTypeID = 3			
				LEFT OUTER JOIN  dbo.StoresUniqueValues SUV ON CP.SupplierID = SUV.SupplierID AND CP.StoreID = SUV.StoreID
				WHERE (dbo.ProductPrices.ProductPriceTypeID = 3) '
	
	if(@RequestStatus ='Current')	
		set @sqlDateCheck = ' and (dbo.ProductPrices.ActiveStartDate <= { fn NOW() }) AND (dbo.ProductPrices.ActiveLastDate >= { fn NOW() }) '

	else if(@RequestStatus ='Future')	
		set @sqlDateCheck = ' and dbo.ProductPrices.ActiveStartDate > { fn NOW() }  '

	else if(@RequestStatus ='Past')	
		set @sqlDateCheck = ' and dbo.ProductPrices.ActiveLastDate < { fn NOW() } '
	else
		set @sqlDateCheck = ''
	
	set @sqlQuery = @sqlQuery + @sqlDateCheck
		
	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CP.SupplierId=' + @SupplierId

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and CP.ChainId=' + @ChainId

	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and CP.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and CP.Banner=''' + @Banner + ''''

	if( convert(date, @FromStartDate  ) > convert(date,'1900-01-01') and  convert(date, @ToStartDate ) > convert(date,'1900-01-01') ) 
		set @sqlQuery = @sqlQuery + ' and CP.[Begin Date] between ''' + @FromStartDate  + ''' and ''' + @ToStartDate + ''''  ;

	else if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and CP.[Begin Date]  >= ''' + @FromStartDate  + '''';

	else if(convert(date, @ToStartDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and  CP.[Begin Date] <=''' + @ToStartDate  + '''';
	
	if(@ProductIdentifierType<>3)
			set @sqlQuery = @sqlQuery + ' and CP.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
	else
			set @sqlQuery = @sqlQuery + ' and CP.ProductIdentifierTypeId in (2,8) '
			
	if(@ProductIdentifierValue<>'')
	begin

		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and CP.UPC like ''%' + @ProductIdentifierValue + '%'''
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and CP.ProductName like ''%' + @ProductIdentifierValue + '%'''
	end
	
	
	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and CP.[Store Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and CP.[SBT Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and CP.[Store Name] like ''%' + @StoreIdentifierValue + '%'''
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
		
	--set @sqlQuery = @sqlQuery + ' and ProductPrices.ActiveStartDate = (Select max(ActiveStartDate) from ProductPrices P1 
	--	where dbo.ProductPrices.ProductPriceTypeID = P1.ProductPriceTypeID
	--	and dbo.ProductPrices.SupplierID =P1.SupplierID
	--	and dbo.ProductPrices.ChainID =P1.ChainID
	--	and dbo.ProductPrices.StoreID =P1.StoreID
	--	and dbo.ProductPrices.ProductID =P1.ProductID ' + @sqlDateCheck + ')'
	set @sqlQuery = @sqlQuery + ' order by CP.ChainName, CP.Banner, CP.SupplierName, 
								  CP.ProductName, CP.[Store Number], CP.[SBT Number], 
								  CP.UPC, CP.Allowance, CP.[Begin Date], CP.[End Date], 
								  dbo.ProductPrices.UnitPrice, dbo.ProductPrices.UnitRetail'
							  
	exec(@sqlQuery); 
	print 	(@sqlQuery); 
End
GO
