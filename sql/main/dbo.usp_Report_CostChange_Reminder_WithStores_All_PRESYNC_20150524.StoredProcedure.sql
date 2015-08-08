USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_CostChange_Reminder_WithStores_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_CostChange_Reminder_WithStores_All_PRESYNC_20150524] 
	-- exec usp_Report_CostChange_Reminder_WithStores '40393','2','All','018200006524','-1','','530','1900-01-01','1900-01-01'
	@chainID varchar(1000),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(1000),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(7000)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Begin
		DECLARE @sqlCommand nvarchar(1000)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4
    set @CostFormat = isnull(@costformat,4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
  
	set @query = 'select c.ChainName as Retailer, s.Custom1  as Banner, cast(s.StoreIdentifier as varchar)  as [Store No],
					cast(s.Custom2 as varchar)  as [SBT No], p.ProductName as [Product Name],
					cast( pri.IdentifierValue as varchar) as UPC,
					cast(convert(varchar,pp.ActiveStartDate,101) as varchar) as [Begin Date],
					cast(convert(varchar,pp.ActiveLastDate,101)as varchar) as [End Date], 
					''$''+ Convert(varchar(50), cast(pp.UnitPrice as numeric(10,' + @CostFormat + '))) as [New Cost],
					''$''+ Convert(varchar(50), cast(cc.UnitPrice as numeric(10,' + @CostFormat + '))) as [Old Cost], 
					dbo.FDatetime(cc.ActiveStartDate) as [Old Cost Begin], 
					dbo.FDatetime(cc.ActiveLastDate) as [Old Cost End], 
					''$''+ cast(p8.UnitPrice as varchar) as [Promo], 
					cast(convert(varchar,p8.ActiveStartDate,101) as varchar) as [Promo Begin], 
					cast(convert(varchar,p8.ActiveLastDate,101) as varchar) as [Promo End]

					from Productprices pp 
					inner join	dbo.ProductIdentifiers PrI on PrI.ProductID=pp.ProductID and pri.ProductIdentifierTypeID=2 
					inner join dbo.Products P on P.ProductID=pp.ProductID 
					inner join dbo.stores S on s.StoreID=pp.StoreID and S.ActiveStatus=''Active''
					inner join dbo.chains c on c.ChainID =pp.ChainID 
					INNER JOIN SupplierBanners SB on SB.SupplierId = pp.SupplierId and SB.Status=''Active'' and SB.Banner=s.Custom1
					left join

						(select distinct p.SupplierID, p.unitprice,p.StoreID,p.ProductID,p.ActiveLastDate ,p.ActiveStartDate  
							from ProductPrices p 
							where p.ProductPriceTypeID =3 and p.ActiveLastDate >GETDATE() and p.ActiveStartDate <=GETDATE()
						) CC on cc.ProductID =pp.ProductID and cc.StoreID=pp.StoreID and cc.Supplierid=pp.SupplierID and
							cc.ActiveStartDate < pp.ActiveStartDate and cc.ActiveLastDate >=pp.ActiveStartDate 

					left join
						(select distinct p.SupplierID, p.unitprice,p.StoreID,p.ProductID,p.ActiveLastDate ,p.ActiveStartDate  from ProductPrices p 
							where p.ProductPriceTypeID =8 and p.ActiveLastDate >GETDATE()  and p.ActiveStartDate <=GETDATE()
						) P8 on P8.ProductID =pp.ProductID and P8.StoreID=pp.StoreID and p8.Supplierid=pp.SupplierID and
							p8.ActiveStartDate <= pp.ActiveStartDate and p8.ActiveLastDate >=pp.ActiveStartDate 

					where pp.ProductPriceTypeID=3 '
		
		--if @AttValue =17
		--	set @query = @query + ' and c.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		--else
		--	set @query = @query + ' and pp.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and c.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and s.custom1 like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and pp.SupplierId in (' + @SupplierId  +')'
			
		if(@StoreId <>'-1') 
			set @Query   = @Query  +  ' and S.StoreIdentifier like ''%' + @StoreId + '%'''

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  pri.IdentifierValue  like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and pp.ActiveStartDate > { fn NOW() } and pp.ActiveStartDate < dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() })'  			
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and pp.ActiveStartDate >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and pp.ActiveStartDate <= ''' + @EndDate  + '''';
			
		exec (@Query )
END
GO
