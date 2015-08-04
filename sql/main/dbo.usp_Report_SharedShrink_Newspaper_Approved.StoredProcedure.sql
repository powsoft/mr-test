USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_SharedShrink_Newspaper_Approved]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_SharedShrink_Newspaper_Approved]
-- exec [usp_Report_SharedShrink_Newspaper_Approved] '-1','-1','All','-1','-1','-1','100','1900-01-01','1900-01-01'
-- exec [usp_Report_SharedShrink_Newspaper_Approved] '-1','-1','All','-1','-1','-1','125','1900-01-01','1900-01-01'
-- exec [usp_Report_SharedShrink_Newspaper_Approved] '64010','-1','All','-1','27155','-1','125','1900-01-01','1900-01-01'
(
	@ChainID varchar(20), --
	@PersonID int, -- 
	@Banner varchar(50), -- 
	@ProductUPC varchar(20), --?
	@SupplierId varchar(10),--
	@StoreId varchar(10),--
	@LastxDays int, --
	@StartDate varchar(20), --
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
	--, --
	--@Status varchar(10) --0 =Pending; 1=Approved;2=In Settlement;3=Rejected;
)
AS
Begin
	 DECLARE @sqlQuery VARCHAR(4000);
	 Declare @AttValue int;
	 Declare @CostFormat varchar(10);
	 
	 if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat WITH(NOLOCK)  where SupplierID = @supplierID
	 else
		SET @CostFormat=4			
		
	SET @CostFormat = ISNULL(@CostFormat , 4)
 	
	select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
	
	
	 SET @sqlQuery = 'Select Distinct ' + @MaxRowsCount + ' sup.SupplierIdentifier,
							 sup.SupplierName AS [Wholesaler Name],
                             c.ChainIdentifier,
                             c.ChainName AS [Chain Name],
                             s.LegacySystemStoreIdentifier,
                             sh.ChainID,
                             sh.Supplierid,
                             pi.BIPAD,
							 p.ProductName,
							 p.DESCRIPTION,
							 SUM(sh.ShrinkUnits) as ShrinkUnits,
							 SUM(sh.Shrink$) as Shrink$,
							 sh.Unitcost as Unitcost,
							 SUM(sh.OriginalPOS) as OriginalPOS,
							 SUM(sh.OriginalDeliveries) as OriginalDeliveries,
							 SUM(sh.OriginalPickups) as OriginalPickups,
							 Convert(varchar(12),sh.SaleDateTime,101) AS SaleDateTime,
							  Convert(varchar(12),MAX(sh.DateTimecreated),101) as DateTimecreated,
							 sh.status,
							 (case when sh.PODReceived = 1 then ''Yes'' else ''No'' end ) as POD, 
							 sh.PODReceived, 
							 Convert(varchar(12),MAX(sh.DateTimecreated),101) as DateTimecreatedNew
					from dbo.InventoryReport_Newspaper_Shrink_Facts sh WITH(NOLOCK) 
					inner join dbo.chains c WITH(NOLOCK)  on c.ChainID=sh.ChainID
					inner join dbo.stores s WITH(NOLOCK)  on s.storeid=sh.storeid 
					inner join dbo.Suppliers sup WITH(NOLOCK)  on sup.SupplierID=sh.SupplierID
					inner join dbo.Products p WITH(NOLOCK)  on p.productid=sh.productid
					inner join dbo.ProductIdentifiers pi WITH(NOLOCK)  on p.productid=pi.productid
					INNER JOIN SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = sup.SupplierID and SB.Status=''Active'' 
					where 1=1 and sh.status=1  '

	if(@chainID  <>'-1') 
		set @sqlQuery   = @sqlQuery  +  ' AND C.chainid = ''' + @ChainID + ''''

	if(@Banner<>'All') 
		set @sqlQuery  = @sqlQuery + ' and SB.Banner like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @sqlQuery  = @sqlQuery  + ' and sh.SupplierId=' + @SupplierId  
		
	if(@StoreId<>'-1') 
		set @sqlQuery  = @sqlQuery  + ' and sh.StoreId=' + @StoreId  

	if(@ProductUPC  <>'-1' ) 
		set @sqlQuery   = @sqlQuery  +  ' and  pi.UPC like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @sqlQuery = @sqlQuery + ' and (sh.SaleDateTime between  dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() } )'   
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and sh.SaleDateTime  >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and sh.SaleDateTime  <= ''' + @EndDate  + '''';
	
	--if(@Status <>'') 
	--	set @sqlQuery = @sqlQuery + ' and sh.Status = ''' + @Status  + '''';
								  
	set @sqlQuery=@sqlQuery+ ' Group by sup.SupplierIdentifier,
										sup.SupplierName,
										c.ChainIdentifier,c.ChainName,
										s.LegacySystemStoreIdentifier,
										sh.ChainID,
										sh.Supplierid,
										pi.bipad,
										p.ProductName,
										p.DESCRIPTION, 
										sh.Unitcost,
										sh.status,
										sh.PODReceived,
										sh.SaleDateTime,
										sh.DateTimecreated
								order by sup.SupplierIdentifier '
								
				exec (@sqlQuery)	
				print(@sqlQuery)					  
	
End

--Select top 1 * from  dbo.InventoryReport_Newspaper_Shrink_Facts sh
--Select top 100 banner,* FROM	 MaintenanceRequests AS mreq 

--Select top 1 *  from Products
--select top 1 * from SupplierBanners

--SELECT top 100 IdentifierValue, * FROM ProductIdentifiers
GO
