USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Ending_Promotion_Reminder_WithStores_NR_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Ending_Promotion_Reminder_WithStores_NR_All] 
	-- exec usp_Report_Ending_Promotion_Reminder_WithStores_NR '40393','2','All','','-1','','530','1900-01-01','1900-01-01'
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(max)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4
		set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	set @query = ' select c.ChainName as Retailer, s.Custom1  as Banner, 
						TradingPartnerPromotionIdentifier as [Trading Partner Promotion Identifier],
						s.StoreIdentifier as [Store No],
						s.Custom2 as [SBT No], p.ProductName as Product, pri.IdentifierValue as UPC,
						convert(varchar(10),cast(pp.ActiveStartDate as date),101) as [Begin Date],
						convert(varchar(10),cast(pp.ActiveLastDate as date),101) as [End Date], 
						''$''+ Convert(varchar(50), cast(pp.UnitPrice as numeric(10,' + @CostFormat + '))) as Allowance ,
						''$''+ Convert(varchar(50), (select cast (unitprice as numeric(10,' + @CostFormat + ')) 
						from Productprices where ProductId=pp.ProductId 
						and SupplierID=pp.SupplierID and ChainID=pp.ChainID and StoreId=pp.StoreID 
						and ActiveStartDate<=pp.ActiveStartDate and ActiveLastDate>=pp.ActiveLastDate
						and ProductPriceTypeId=3 )) as [Default Cost],
						''$''+ Convert(varchar(50), (select cast((unitprice-pp.unitprice) as numeric(10,' + @CostFormat + ')) from Productprices 
						where ProductId=pp.ProductId and SupplierID=pp.SupplierID and ChainID=pp.ChainID and StoreId=pp.StoreID 
						and ActiveStartDate<=pp.ActiveStartDate and ActiveLastDate>=pp.ActiveLastDate
						and ProductPriceTypeId=3 ))  as [Net Cost] 

					from Productprices pp  WITH(NOLOCK) 
					inner join ProductIdentifiers PrI WITH(NOLOCK)  on PrI.ProductID=pp.ProductID and pri.ProductIdentifierTypeID=2 
					inner join Products P WITH(NOLOCK)  on P.ProductID=pp.ProductID 
					inner join Stores  S WITH(NOLOCK)  on s.StoreID=pp.StoreID and S.ActiveStatus=''Active'' 
					inner join Chains c WITH(NOLOCK)  on c.ChainID =s.ChainID 
					inner join SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = pp.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
					where pp.ProductPriceTypeID=8 '
	
		--if @AttValue =17
		--	set @query = @query + ' and C.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		--else
		--	set @query = @query + ' and pp.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and c.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and s.custom1 like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and pp.SupplierId in (' + @SupplierId  +')'

		if(@StoreId<>'-1') 
			set @Query  = @Query  + ' and s.StoreIdentifier like ''%' + @StoreId  + '%'''

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  pri.IdentifierValue  like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
		begin
			set @Query = @Query + ' and ((pp.ActiveLastDate  > convert(date,GETDATE()) and pp.ActiveLastDate =dateadd(d,' +  cast(@LastxDays as varchar) + ', convert(date,GETDATE())))'
			set @Query = @Query + ' or  (pp.DateTimeCreated  = convert(date,GETDATE()) and pp.ActiveLastDate <dateadd(d,' +  cast(@LastxDays as varchar) + ', convert(date,GETDATE()))))'  
		end
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and pp.ActiveLastDate >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and pp.ActiveLastDate <= ''' + @EndDate  + '''';
		
		exec (@Query )
END
GO
