USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_Promotions_5Days_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Approved_Promotions_5Days_All] 
	-- exec usp_Report_Approved_Promotions_5Days_All '-1','2','All','','-1','','0','1900-01-01','1900-01-01'
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
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat  with (nolock) where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
		End
	 else
		set @CostFormat=4
	set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	
	set @query = 'SELECT  CAST(mreq.MaintenanceRequestID AS varchar) AS [Maintenance Request ID], 
						CASE WHEN RequestTypeID = 3 THEN ''Promotion'' ELSE '''' END AS [Request Type], 
						sup.SupplierName AS [Supplier Name], mreq.Banner AS Banner,
						(SELECT CostZoneName FROM   CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name], 
						mreq.UPC, mreq.ItemDescription as [Item Description], 
						convert(varchar(10),cast(mreq.SubmitDateTime AS date),101) AS [Submit Date Time], 
						convert(varchar(10),cast(mreq.StartDateTime AS date),101) AS [Start Date Time], 
						convert(varchar(10),cast(mreq.EndDateTime AS date),101) AS [End Date Time],
						(SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1 FROM dbo.Logins 
							INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
							WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name], 
						''$''+ cast(cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')) as varchar) AS [Current Setup Cost], 
						''$''+ Convert(varchar(50), cast(mreq.Cost as numeric(10,' + @CostFormat + ')))  AS Cost, 
						''$''+ Convert(varchar(50), cast(mreq.SuggestedRetail as numeric(10,2))) AS [Suggested Retail], 
						CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 
						THEN ''CC'' ELSE '''' END AS [Promo Type], 
						''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance], 
						mreq.EmailGeneratedToSupplier as [Email Generated To Supplier], 
						convert(varchar(10),mreq.EmailGeneratedToSupplierDateTime,101) AS [Email Date Time], 
						CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, 
						convert(varchar(10),cast(mreq.ApprovalDateTime AS date),101) AS [Approved Date Time],
						(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1 FROM   dbo.Logins AS Logins_1  with (nolock) 
							INNER JOIN dbo.Persons AS Persons_1  with (nolock) ON Logins_1.OwnerEntityId = Persons_1.PersonID
							WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name],
						CAST(DealNumber as varchar) as [Deal Number], cast(TradingPartnerPromotionIdentifier as varchar) as [Trading Partner Promotion Identifier]
				FROM  MaintenanceRequests AS mreq  with (nolock) 
				INNER JOIN Suppliers AS sup  with (nolock) ON mreq.SupplierID = sup.SupplierID 
				INNER JOIN Chains AS ch  with (nolock) ON mreq.ChainID = ch.ChainID 
				INNER JOIN SupplierBanners SB  with (nolock) on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.banner 
				WHERE (approved=1) and RequestTypeId=3 and requeststatus<>999 '
				
		--if @AttValue =17
		--	set @query = @query + ' and ch.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		--else
		--	set @query = @query + ' and sup.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and mreq.ChainID in (' + @chainID +')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and mreq.banner like ''%' + @Banner + '%'''
	
		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and mreq.SupplierId in (' + @SupplierId  +')'

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  mreq.UPC like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and (mreq.StartDateTime between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() }) )'   
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and mreq.StartDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and mreq.StartDateTime <= ''' + @EndDate  + '''';
			
		set @Query = @Query + ' and datediff(day, convert(varchar,mreq.SubmitDatetime,101), convert(varchar,mreq.StartDateTime,101)) <=5'  

		exec (@Query )

END
GO
