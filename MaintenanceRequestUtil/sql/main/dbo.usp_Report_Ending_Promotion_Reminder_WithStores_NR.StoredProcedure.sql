USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Ending_Promotion_Reminder_WithStores_NR]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Ending_Promotion_Reminder_WithStores_NR] 
	-- exec [usp_Report_Ending_Promotion_Reminder_WithStores_NR] '40393','2','All','','-1','-1','','1900-01-01','1900-01-01'
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
Declare @Query varchar(7000)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
		set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	set @query = ' select ' + @MaxRowsCount + ' c.ChainName as Retailer, s.Custom1  as Banner, 
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

					from Productprices pp  with (nolock)  
					inner join ProductIdentifiers PrI with (nolock)   on PrI.ProductID=pp.ProductID and pri.ProductIdentifierTypeID=2 
					inner join Products P with (nolock)   on P.ProductID=pp.ProductID 
					inner join Stores  S with (nolock)   on s.StoreID=pp.StoreID and S.ActiveStatus=''Active'' 
					inner join Chains c with (nolock)   on c.ChainID =s.ChainID 
					inner join SupplierBanners SB  with (nolock)  on SB.SupplierId = pp.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
					where pp.ProductPriceTypeID=8 '
	
		if @AttValue =17
			set @query = @query + ' and c.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @query = @query + ' and pp.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and c.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and s.custom1 like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and pp.SupplierId=' + @SupplierId  

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
