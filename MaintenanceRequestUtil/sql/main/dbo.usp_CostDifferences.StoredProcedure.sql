USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CostDifferences]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CostDifferences]
 
 @ChainId varchar(10),
 @supplierID varchar(10),
 @BannerId varchar(255),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(250),
 @SaleFromDate varchar(50),
 @SaleToDate varchar(50),
 @StoreIdentifierType INT,
 @StoreIdentifierValue varchar(250),
 @SupplierIdentifierValue varchar(50),
 @RetailerIdentifierValue varchar(50)
 --select * from suppliers where suppliername like 'Dakot%'
as
--exec usp_CostDifferences '40393','65590','-1','2','','1900-01-01','1900-01-01','','','',''
--exec usp_CostDifferences '60620','40557','-1','2','','1900-01-01','1900-01-01','1','=108','',''
Begin
 Declare @sqlQuery varchar(4000)

 Declare @CostFormat varchar(10)
 
	 if(@supplierID<>'-1')
		set @CostFormat = isnull((Select  Costformat from SupplierFormat where SupplierID = @supplierID),4)
	 else
		set @CostFormat=4
		
	 
	set @sqlQuery = ' SELECT  Distinct   T.ChainName as Retailer, T.SupplierName as [Supplier Name], T.[Store Number], T.SBTNumber as [SBT Number], 
					  T.Banner, T.ProductName, T.UPC, cast(T.Qty as numeric) as Qty,
					  CAST(T.[Setup Cost] AS decimal(10,' + @CostFormat + ')) AS [Supplier Cost], 
                      CAST(isnull(T.[setup Promo],0) AS  decimal(10,' + @CostFormat + ')) AS [Supplier Promo], 
                      CAST(T.[Setup Net] AS decimal(10,' + @CostFormat + ')) AS [Supplier Net], 
                      CAST(isnull(T.[Reported Cost],0) as decimal(10,' + @CostFormat + ')) AS [Retailer Cost], 
                      CAST(isnull(T.[Reported Promo],0) AS  decimal(10,' + @CostFormat + ')) AS [Retailer Promo],  
                      CAST(T.RetailerNet AS decimal(10,' + @CostFormat + ')) AS [Retailer Net], 
                      convert(varchar(10),cast(T.SaleDate AS DATETIME),101) AS SaleDate
				 FROM    DataTrue_CustomResultSets.dbo.tmpCostDifferencesByStore T 
					inner join Suppliers S on S.SupplierId = T.SupplierId
					inner join Chains C on C.ChainId = T.ChainId
					left  join ProductIdentifiers PD1  WITH(NOLOCK) on T.ProductID = PD1.ProductID and PD1.ProductIdentifierTypeId =8 
					Where 1 = 1 and ISNULL(JobRunningID,'''') <> 3 '
					
	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and T.ChainId=' + @ChainId 				

	if(@supplierID <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and T.SupplierId=' + @supplierID  
	
	if(@SupplierIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and S.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''

	if(@RetailerIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
		
	if(@BannerId='') 
		set @sqlQuery = @sqlQuery + ' and T.Banner is Null'

	else if(@BannerId<>'-1') 
		set @sqlQuery = @sqlQuery + ' and T.Banner=''' + @BannerId + ''''
	
	if (convert(date, @SaleFromDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and T.SaleDate >= cast(''' + @SaleFromDate  + ''' as date)';

	if(convert(date, @SaleToDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and T.SaleDate <= cast(''' + @SaleToDate  + ''' as date)';
		
	if(@ProductIdentifierValue<>'')
		begin
			-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number,8=bipad
			if (@ProductIdentifierType=2)
				 set @sqlQuery = @sqlQuery + ' and T.UPC ' + @ProductIdentifierValue 
         
			else if (@ProductIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and T.ProductName ' + @ProductIdentifierValue 
		
			else if (@ProductIdentifierType=8)
				set @sqlQuery = @sqlQuery + ' and PD1.Bipad ' + @ProductIdentifierValue 
		end
	
	if(@StoreIdentifierValue<>'')
	begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
			if (@StoreIdentifierType=1)
					set @sqlQuery = @sqlQuery + ' and T.[Store Number] ' + @StoreIdentifierValue 
			else if (@StoreIdentifierType=2)
					set @sqlQuery = @sqlQuery + ' and T.SBTNumber ' + @StoreIdentifierValue 
	end

	
	set @sqlQuery = @sqlQuery + ' order by SaleDate Desc'
	
	exec(@sqlQuery); 
	print (@sqlQuery);
End
GO
