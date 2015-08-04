USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_CostChange]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_Report_Approved_CostChange 64010,75151,'All','-1','75150','-1',0,'1/1/1900','1/1/2099',' top 250000'
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
--exec usp_Report_Approved_CostChange 64010,81710,'Lehigh Gas','-1','75150','-1',0,'1/1/1900','1/1/2099',' top 250000'
CREATE  procedure [dbo].[usp_Report_Approved_CostChange] 
	-- exec usp_Report_Approved_CostChange '40393','51067','Albertsons - SCAL','','-1','','530','1900-01-01','1900-01-01'
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), 
	@MaxRowsCount varchar(20) = ' Top 2500000 '
AS
BEGIN
Declare @Query varchar(max)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
	set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	
	set @query = 'SELECT ' + @MaxRowsCount + ' CAST(mreq.MaintenanceRequestID AS varchar) AS [Maintenance Request ID], 
					CASE WHEN RequestTypeID = 2 THEN ''Cost Change'' ELSE '''' END AS [Request Type], sup.SupplierName AS [Supplier Name], 
					mreq.Banner AS Banner,
					(SELECT CostZoneName FROM   CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name], 
					mreq.UPC,case when mreq.RequestTypeId>1 then case when isnull(mreq.ItemDescription,'''')='''' then prod.ProductName else mreq.ItemDescription end end as [Item Description], 
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
					convert(varchar(10),CAST(mreq.EmailGeneratedToSupplierDateTime AS date),101) AS [Email Date Time], 
					CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, 
					convert(varchar(10),CAST(mreq.ApprovalDateTime AS date),101) AS [Approved Date Time],
					(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1 FROM   dbo.Logins AS Logins_1 
						INNER JOIN dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
						WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]
		 ,case when mreq.RequestTypeId>1 then  case when isnull(mreq.VinDescription,'''')='''' then prod.VinDesc else mreq.VinDescription end else mreq.VinDescription end as [VIN Description]   
					into #tmp_ReportApprovedCostChange
		
					FROM    
					MaintenanceRequests AS mreq  WITH(NOLOCK) 

					INNER JOIN   Suppliers AS sup WITH (NOLOCK) ON mreq.SupplierID = sup.SupplierID 
					INNER JOIN   Chains AS ch WITH (NOLOCK) ON mreq.ChainID = ch.ChainID 
					INNER JOIN   SupplierBanners SB WITH (NOLOCK) on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.banner 
						left outer hash join  (Select distinct IdentifierValue, ProductName, T.VIN, T.OwnerPackageDescription as VinDesc, T.SupplierID 
													from Products P WITH(NOLOCK)
													inner join ProductIdentifiers PD WITH(NOLOCK) on PD.ProductId=P.ProductId and PD.ProductIdentifierTypeId=2
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID where 1=1 '
													
													if(@SupplierId<>'-1') 
															set @Query  = @Query  + ' and t.SupplierId=' + @SupplierId  
		
											set @query += '	) Prod on Prod.IdentifierValue = mreq.UPC and Prod.SupplierID = mreq.SupplierID and Prod.VIN=mreq.VIN and mreq.RequestTypeId>1
					
						left outer hash join  (
													Select DISTINCT P.SupplierId, ChainId, PD.IdentifierValue as UPC, UnitPrice, T.VIN
													from ProductPrices P WITH (NOLOCK)
													INNER JOIN ProductIdentifiers PD WITH (NOLOCK) on PD.ProductID=P.ProductID AND PD.ProductIdentifierTypeID=2 and p. ProductPriceTypeID=11 
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID and T.SupplierID=P.SupplierID 
													and T.SupplierPackageTypeID=1 --and T.SupplierPackageID=P.SupplierPackageID
and P.ProductPriceTypeID IN (3,11)
									AND getdate() BETWEEN P.ActiveStartDate AND P.ActiveLastDate
									 where 1=1 '
													if(@chainID  <>'-1') 
															set @Query   = @Query  +  ' and p.ChainID=' + @chainID 

													if(@SupplierId<>'-1') 
															set @Query  = @Query  + ' and p.SupplierId=' + @SupplierId  
		
											set @query += '
								  ) P on P.SupplierID=mreq.SupplierID and P.ChainID=mreq.ChainID AND P.UPC=mreq.UPC and P.VIN=mreq.VIN	
					WHERE (approved=1) and RequestTypeId=2 and requeststatus<>999 
					'

 
	if @AttValue =17
			set @query = @query + ' and ch.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @query = @query + ' and sup.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

	if(@chainID  <>'-1') 
		set @Query   = @Query  +  ' and mreq.ChainID=' + @chainID 

	if(@Banner<>'All') 
		set @Query  = @Query + ' and mreq.banner = ''' + @Banner + ''''

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and mreq.SupplierId=' + @SupplierId  
	
	if(@ProductUPC  <>'-1') 
		set @Query   = @Query  +  ' and  mreq.UPC like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and (mreq.StartDateTime between dateadd(d,-' +  cast(@LastxDays as varchar) + ', cast( { fn NOW() } as date)) and cast({ fn NOW() }  as date) )'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and convert(date,mreq.ApprovalDateTime) >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and convert(date,mreq.ApprovalDateTime) <= ''' + @EndDate  + '''';
	
	--set @Query = @Query + ' and  mreq.MaintenanceRequestID not in (select recordid from tmp_ReportApprovedCostChange where personid=' + cast(@PersonID as varchar(12)) + ' and ReportName=''ApprovedCostChange'');'
    set @Query = @Query + ' option (hash join,loop join)'
	
	set @Query = @Query + ';Delete FROM #tmp_ReportApprovedCostChange Where [Maintenance Request ID] IN (select recordid from tmp_ReportApprovedCostChange where personid=' + cast(@PersonID as varchar(12)) + ' and ReportName=''ApprovedCostChange'') '
	
	set @Query = @Query + ';insert into tmp_ReportApprovedCostChange(Personid,Recordid,ReportName)  select ' + cast(@PersonID as varchar(10)) + ',[Maintenance Request ID],''ApprovedCostChange'' from #tmp_ReportApprovedCostChange ;' 
	
	set @Query = @Query + ';select * from #tmp_ReportApprovedCostChange '
	--print(@Query)
	exec(@Query)

end
GO
