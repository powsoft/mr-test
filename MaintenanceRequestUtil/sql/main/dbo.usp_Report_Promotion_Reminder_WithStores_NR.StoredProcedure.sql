USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Promotion_Reminder_WithStores_NR]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Promotion_Reminder_WithStores_NR] 
	-- exec usp_Report_Promotion_Reminder_WithStores_NR '40393','2','All','-1','-1','','530','1900-01-01','1900-01-01'
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
 	
select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
 
	set @query = 'select  distinct ' + @MaxRowsCount + ' SP.SupplierName as Supplier,  c.ChainName as Retailer, s.Custom1  as Banner, 
					pp.TradingPartnerPromotionIdentifier as [Trading Partner Promotion Identifier], 
					MR.DealNumber as [Deal Number],
					s.StoreIdentifier as [Store No],
					s.Custom2 as [SBT No], p.ProductName as [Product Name], pri.IdentifierValue as UPC,
					convert(varchar(10),cast(pp.ActiveStartDate as date),101) as [Begin Date],
					convert(varchar(10),cast(pp.ActiveLastDate as date),101) as [End Date], 
					''$''+ Convert(varchar(50), cast(pp.UnitPrice as numeric(10,' + @CostFormat + ')))  as Allowance , 
					''$''+ Convert(varchar(50), CAST(pp3.unitprice as numeric(10,' + @CostFormat + '))) as Base, 
					''$''+ Convert(varchar(50), CAST(pp3.unitprice-pp.unitprice as numeric(10,' + @CostFormat + '))) as [Net Cost]

				from Productprices pp  WITH(NOLOCK) 
				inner join ProductIdentifiers PrI WITH(NOLOCK)  on PrI.ProductID=pp.ProductID and pri.ProductIdentifierTypeID=2 
				inner join Products P  WITH(NOLOCK) on P.ProductID=pp.ProductID 
				inner join Suppliers SP  WITH(NOLOCK) on SP.SupplierId=pp.SupplierId 
				inner join Stores  S  WITH(NOLOCK) on s.StoreID=pp.StoreID and S.ActiveStatus=''Active''  
				inner join Chains c  WITH(NOLOCK) on c.ChainID =s.ChainID 
				inner join SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = SP.SupplierID and SB.Status=''Active'' and SB.Banner=S.Custom1
				inner join		
				(select pp2.StoreID,pp2.SupplierID ,pp2.ProductID ,pp2.UnitPrice   from Productprices pp2 WITH(NOLOCK)  where pp2.ProductPriceTypeID =3 
				and pp2.ActiveStartDate <GETDATE() and pp2.ActiveLastDate >=GETDATE()) pp3 on
				pp3.StoreID =pp.StoreID and pp3.ProductID =pp.ProductID  and pp3.SupplierID =pp.SupplierID	

				left join MaintenanceRequests MR WITH(NOLOCK)  on MR.SupplierID=pp.SupplierID and MR.ChainID=pp.ChainID and MR.productid=pp.ProductID 
				and MR.RequestTypeID=3 and MR.StartDateTime=pp.ActiveStartDate and MR.EndDateTime=pp.ActiveLastDate and MR.requeststatus<>999
				inner join MaintenanceRequestStores MS on MR.MaintenanceRequestID=MS.MaintenanceRequestID and MS.StoreId=pp.StoreID
				where pp.ProductPriceTypeID=8 '

		if @AttValue =17
			set @Query = @Query + ' and c.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and pp.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and c.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and s.custom1 like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and pp.SupplierId=' + @SupplierId  

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  pri.IdentifierValue  like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
		begin
			set @Query = @Query + ' and ((convert(date, pp.ActiveStartDate)  > convert(date,GETDATE()) and convert(date,pp.ActiveStartDate) =dateadd(d,' +  cast(@LastxDays as varchar) + ', convert(date,GETDATE())))'
			set @Query = @Query + ' or  (dateadd(HH,24,pp.DateTimeCreated)  >= GETDATE() and convert(date,pp.ActiveStartDate) > GETDATE() and convert(date,pp.ActiveStartDate) <dateadd(d,' +  cast(@LastxDays as varchar) + ', convert(date,GETDATE()))))'  
		end
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and pp.ActiveStartDate >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and pp.ActiveStartDate <= ''' + @EndDate  + '''';

		exec (@Query )
		print (@Query)
END
GO
