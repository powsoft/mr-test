USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_Promotion_Reminder_WithStores_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_Approved_Promotion_Reminder_WithStores_All_PRESYNC_20150524] 
	-- exec usp_Report_Approved_Promotion_Reminder_WithStores '40393','2','All','','-1','','130','1900-01-01','1900-01-01'
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
		set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 	set @query = 'select c.ChainName as Retailer, s.Custom1  as Banner, cast(s.StoreIdentifier as varchar)  as [Store No],
		cast(s.Custom2 as varchar)  as [SBT No], p.ProductName as [Product Name],cast( pri.IdentifierValue as varchar) as UPC,
		CAST(dbo.FDatetime(pp.ActiveStartDate) AS varchar) as [Begin Date],
		CAST(dbo.FDatetime(pp.ActiveLastDate) AS varchar) as [End Date], 
		''$''+ cast(pp.UnitPrice as varchar)  as [Promo], 
		''$''+ Convert(varchar(50), cast(pp3.unitprice as numeric(10,' + @CostFormat + '))) as [Base Cost], 
		''$''+ Convert(varchar(50), cast(pp3.unitprice-pp.unitprice  as numeric(10,' + @CostFormat + ')))  as [Net Cost],
		CZ.CostZoneName as [Cost Zone Name], cast(MR.DealNumber as varchar) as [Deal Number],
		cast(MR.TradingPartnerPromotionIdentifier as varchar) as [Trading Partner Id #]
	from Productprices pp 
	inner join dbo.ProductIdentifiers PrI on PrI.ProductID=pp.ProductID and pri.ProductIdentifierTypeID=2 
	inner join dbo.Products P on P.ProductID=pp.ProductID 
	inner join dbo.stores S on s.StoreID=pp.StoreID and S.ActiveStatus=''Active'' 
	inner join dbo.chains c on c.ChainID =s.ChainID 
	INNER JOIN  SupplierBanners SB on SB.SupplierId = pp.SupplierId and SB.Status=''Active'' and SB.Banner=s.custom1 
	inner join
		(select pp2.StoreID,pp2.SupplierID ,pp2.ProductID ,pp2.UnitPrice   from ProductPrices pp2 where pp2.ProductPriceTypeID =3 and pp2.ActiveStartDate <GETDATE() and pp2.ActiveLastDate >=GETDATE()) pp3 on
		pp3.StoreID =pp.StoreID and pp3.ProductID =pp.ProductID  and pp3.SupplierID =pp.SupplierID	
	left  join datatrue_report.dbo.MaintenanceRequestMR on MR.SupplierID=pp.SupplierID
							and MR.ChainID=pp.ChainID
							and MR.Banner=S.Custom1
							and MR.UPC=pri.IdentifierValue
							and MR.RequestTypeID=3
							and MR.Approved=1
							and requeststatus<>999 
							and MR.MarkDeleted=0
	left join CostZones CZ on CZ.CostZoneID=MR.CostZoneID	
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

	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  pri.IdentifierValue  like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (pp.ActiveStartDate  > convert(date,GETDATE()) and pp.ActiveStartDate <dateadd(d,' +  cast(@LastxDays as varchar) + ', convert(date,GETDATE())))'
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and pp.ActiveStartDate >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and pp.ActiveStartDate <= ''' + @EndDate  + '''';
		
	exec (@Query )
END
GO
