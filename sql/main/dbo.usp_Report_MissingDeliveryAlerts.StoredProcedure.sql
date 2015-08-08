USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_MissingDeliveryAlerts]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_Report_MissingDeliveryAlerts] 
	-- exec [usp_Report_MissingDeliveryAlerts] '40393','2','All','-1','-1','','530','1900-01-01','1900-01-01'
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat with(nolock) where SupplierID = @supplierID
	 else
		set @CostFormat=4
		set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues with(nolock) where OwnerEntityID=@PersonID and AttributeID=17

	set @query = '		
		select c. ChainName as [Chain],st.StoreIdentifier  as [Store Number], s.SupplierName  as [Supplier],[Avg No Of Day Between Deliveries],[Days Since Last Delivery Records]
		      ,convert(varchar(10),cast([LastDeliveryDate] as date),101) as [LastDeliveryDate]

			from [Sensor_PotentialMissingDeliveries] a  with(nolock)

			inner join Suppliers s with(nolock) on s.SupplierID =a.supplierid
			inner join stores st with(nolock) on st.StoreID=a.storeid
			inner join Chains c with(nolock) on c.ChainID = st.ChainID 

			where 1=1 
		
		'
	
	
	if @AttValue =17
		set @query = @query + ' and c.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	else
		set @query = @query + ' and s.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

	if(@chainID  <>'-1') 
		set @Query = @Query  +  ' and c.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and st.custom1 like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and s.SupplierId=' + @SupplierId  

	--if(@ProductUPC  <>'-1' and @ProductUPC is not null) 
	--	set @Query   = @Query  +  ' and  CP.UPC like ''%' + @ProductUPC + '%'''

	--if (@LastxDays > 0)
	--	set @Query = @Query + ' and (CP.[Begin Date] between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() }) )'  
	
	--if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
	--	set @Query = @Query + ' and CP.[Begin Date] >= ''' + @StartDate  + '''';

	--if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
	--	set @Query = @Query + ' and CP.[Begin Date] <= ''' + @EndDate  + '''';
 	
 		set @Query = @Query + ' 
 		order by 3,1'
 	
	exec (@Query )
--	print (@Query )
END
GO
