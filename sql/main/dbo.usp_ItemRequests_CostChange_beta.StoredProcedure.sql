USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ItemRequests_CostChange_beta]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ItemRequests_CostChange_beta]
 
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

Begin
 Declare @sqlQuery varchar(4000)
 Declare @CostFormat varchar(10)='4'
 if(@supplierID<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
 else
	set @CostFormat=4
	
 set @sqlQuery = 'SELECT C.ChainName as [Chain Name],C.SupplierID as [Supplier No], C.Banner,
						(SELECT  CostZoneName FROM dbo.CostZones WHERE (CostZoneId = dbo.MaintenanceRequests.CostZoneID)) AS [Cost Zone Name],
						C.SupplierName as [Supplier Name], C.ProductName as [Product Name], 
						C.[Store Number], C.[SBT Number], C.[Store Name],C.UPC, 
						convert(varchar(10), C.[Begin Date], 101) as [Begin Date], 
						convert(varchar(10), C.[End Date], 101) as [End Date], 
						cast(C.UnitPrice as numeric(10, ' + @CostFormat + ')) as [Base Cost], 
						cast(C.UnitRetail as numeric(10,2)) as [Base Retail],
						SUV.DistributionCenter as [Dist. Center], SUV.RegionalMgr as [Regional Mgr.], SUV.SalesRep as [Sales Rep.],
						SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number], SUV.SupplierAccountNumber as [Supplier Acct #]
					FROM  dbo.vwCurrentCosts C 
					INNER JOIN SupplierBanners SB on SB.SupplierId = C.SupplierId and SB.Status=''Active'' and SB.Banner=C.Banner
					LEFT OUTER JOIN
                      dbo.MaintenanceRequests ON dbo.MaintenanceRequests.ChainID = C.ChainID AND 
                      dbo.MaintenanceRequests.SupplierID = C.SupplierID AND 
                      dbo.MaintenanceRequests.productid = C.ProductID AND 
                      dbo.MaintenanceRequests.StartDateTime = C.[Begin Date] AND 
                      dbo.MaintenanceRequests.EndDateTime = C.[End Date] AND 
                      dbo.MaintenanceRequests.Cost = C.UnitPrice AND dbo.MaintenanceRequests.RequestTypeID = 2
					LEFT OUTER JOIN  dbo.StoresUniqueValues SUV ON C.SupplierID = SUV.SupplierID AND C.StoreID = SUV.StoreID 
					WHERE 1=1'
					
	if(@RequestStatus ='Current')	
		set @sqlQuery = @sqlQuery +  ' and	(C.[Begin Date] <= { fn NOW() }) AND (C.[End Date] >= { fn NOW() }) '

	else if(@RequestStatus ='Future')	
		set @sqlQuery = @sqlQuery +  ' and	C.[Begin Date] > { fn NOW() }  '

	else if(@RequestStatus ='Past')	
		set @sqlQuery = @sqlQuery +  ' and	C.[End Date] < { fn NOW() } '
		
	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and C.SupplierId=' + @SupplierId

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and C.ChainId=' + @ChainId
	  
	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and C.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and C.Banner=''' + @Banner + ''''

	if( convert(date, @FromStartDate  ) > convert(date,'1900-01-01') and  convert(date, @ToStartDate ) > convert(date,'1900-01-01') ) 
		set @sqlQuery = @sqlQuery + ' and C.[Begin Date] between ''' + @FromStartDate  + ''' and ''' + @ToStartDate + ''''  ;

	else if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and C.[Begin Date]  >= ''' + @FromStartDate  + '''';

	else if(convert(date, @ToStartDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and  C.[Begin Date] <=''' + @ToStartDate  + '''';
		
		
	if(@ProductIdentifierType=2)
		set @sqlQuery = @sqlQuery + ' and C.ProductIdentifierTypeId in (2,8)'
	else if(@ProductIdentifierType<>3)
		set @sqlQuery = @sqlQuery + ' and C.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
		
		
	if(@ProductIdentifierValue<>'')
	begin

		--if(@ProductIdentifierType<>3)
		--	set @sqlQuery = @sqlQuery + ' and C.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
		
		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and C.UPC like ''%' + @ProductIdentifierValue + '%'''
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and C.ProductName like ''%' + @ProductIdentifierValue + '%'''
	end
	
	
	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and C.[Store Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and C.[SBT Number] like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and C.[Store Name] like ''%' + @StoreIdentifierValue + '%'''
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
	
	set @sqlQuery = @sqlQuery + ' order by C.ChainName, C.SupplierName, C.Banner, C.[Store Number], C.[SBT Number],
										   C.ProductName, C.UPC, C.UnitPrice, C.[Begin Date], C.[End Date]'
	
	exec(@sqlQuery); 

End
GO
