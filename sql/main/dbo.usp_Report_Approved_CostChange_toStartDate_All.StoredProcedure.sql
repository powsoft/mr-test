USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_CostChange_toStartDate_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure  [dbo].[usp_Report_Approved_CostChange_toStartDate_All] 
-- exec usp_Report_Approved_CostChange_toStartDate_all '40393','51067','Albertsons - SCAL','','-1','','530','1900-01-01','1900-01-01'
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
	
	set @query = 'SELECT  CAST(mreq.MaintenanceRequestID AS varchar) AS [Maintenance Request ID], 
					CASE WHEN RequestTypeID = 2 THEN ''Cost Change'' ELSE '''' END AS [Request Type], sup.SupplierName AS [Supplier Name], 
					mreq.Banner AS Banner,
					(SELECT CostZoneName FROM   CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name], 
					mreq.UPC,case when mreq.RequestTypeId>1 then  case when isnull(mreq.ItemDescription,'''')='''' then prod.ProductName else mreq.ItemDescription end else mreq.ItemDescription end as [Item Description], 
					convert(varchar(10),CAST(mreq.SubmitDateTime AS date),101) AS [Submit Date Time], 
					convert(varchar(10),CAST(mreq.StartDateTime AS date),101) AS [Start Date Time], 
					convert(varchar(10),CAST(mreq.EndDateTime AS date),101) AS [End Date Time],
					(SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1 FROM dbo.Logins 
						INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
						WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name],
					
					case when sup.PDITradingPartner=1 then 
							''$''+ Convert(varchar(50), cast(p.UnitPrice as numeric(10,' + @CostFormat + ')))  
						else 
							''$''+ Convert(varchar(50), cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')))  
						end as [Current Setup Cost],
						
					''$''+ Convert(varchar(50), cast(mreq.Cost as numeric(10,' + @CostFormat + ')))  AS Cost, 
					''$''+ Convert(varchar(50), cast(mreq.SuggestedRetail as numeric(10,2))) AS [Suggested Retail], 
					CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS [Promo Type], 
					''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance], 
					mreq.EmailGeneratedToSupplier as [Email Generated To Supplier], 
					CAST(mreq.EmailGeneratedToSupplierDateTime AS varchar) AS [Email Date Time], 
					CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, 
					convert(varchar(10),CAST(mreq.ApprovalDateTime AS date),101) AS [Approved Date Time],
					(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1 FROM   dbo.Logins AS Logins_1 
						INNER JOIN dbo.Persons AS Persons_1 with (nolock)  ON Logins_1.OwnerEntityId = Persons_1.PersonID
						WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]
		,case when mreq.RequestTypeId>1 then  case when isnull(mreq.VinDescription,'''')='''' then prod.VinDesc else mreq.VinDescription end else mreq.VinDescription end as [VIN Description]   
					FROM    MaintenanceRequests AS mreq with (nolock) 
					INNER JOIN   Suppliers AS sup with (nolock) ON mreq.SupplierID = sup.SupplierID 
					INNER JOIN  Chains AS ch with (nolock) ON mreq.ChainID = ch.ChainID 
					INNER JOIN   SupplierBanners SB with (nolock) on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.banner 
					left join (Select distinct IdentifierValue, ProductName, T.VIN, T.OwnerPackageDescription as VinDesc, T.SupplierID 
													from Products P WITH(NOLOCK)
													inner join ProductIdentifiers PD WITH(NOLOCK) on PD.ProductId=P.ProductId and PD.ProductIdentifierTypeId=2 and p. ProductPriceTypeID=11 
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID
												) Prod on Prod.IdentifierValue = mreq.UPC and Prod.SupplierID = mreq.SupplierID and Prod.VIN=mreq.VIN and mreq.RequestTypeId>1
					
					left JOIN (
													Select DISTINCT P.SupplierId, ChainId, PD.IdentifierValue as UPC, UnitPrice, T.VIN
													from ProductPrices P WITH (NOLOCK)
													INNER JOIN ProductIdentifiers PD WITH (NOLOCK) on PD.ProductID=P.ProductID AND PD.ProductIdentifierTypeID=2
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID and T.SupplierID=P.SupplierID 
													and T.SupplierPackageTypeID=1 --and T.SupplierPackageID=P.SupplierPackageID
and P.ProductPriceTypeID IN (3,11)
									AND getdate() BETWEEN P.ActiveStartDate AND P.ActiveLastDate
								  ) P on P.SupplierID=mreq.SupplierID and P.ChainID=mreq.ChainID AND P.UPC=mreq.UPC and P.VIN=mreq.VIN	
					WHERE (approved=1) and RequestTypeId=2 and requeststatus<>999 '


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
		set @Query = @Query + 'and (mreq.StartDateTime between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() }  )'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and mreq.StartDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and mreq.StartDateTime <= ''' + @EndDate  + '''';
	--print (@Query )
	exec (@Query )

END
GO
