USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_Promotions_toStartDate]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_Report_Approved_Promotions_toStartDate] 
	-- exec usp_Report_Approved_Promotions '40393','2','All','','-1','','530','1900-01-01','1900-01-01'
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
Declare @Query varchar(max)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
	set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	
	set @query = 'SELECT ' + @MaxRowsCount + '  CAST(mreq.MaintenanceRequestID AS varchar) AS [Maintenance Request ID], 
						CASE WHEN RequestTypeID = 3 THEN ''Promotion'' ELSE '''' END AS [Request Type], 
						sup.SupplierName AS [Supplier Name], mreq.Banner AS Banner,
						(SELECT CostZoneName FROM   CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name], 
						mreq.UPC, mreq.ItemDescription as [Item Description], 
						CAST(dbo.FDatetime(mreq.SubmitDateTime) AS varchar) AS [Submit Date Time], 
						CAST(dbo.FDatetime(mreq.StartDateTime) AS varchar) AS [Start Date Time], 
						CAST(dbo.FDatetime(mreq.EndDateTime) AS varchar) AS [End Date Time],
						(SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1 FROM dbo.Logins 
							INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
							WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name], 
						''$''+ Convert(varchar(50),cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + '))) AS [Current Setup Cost], 
						''$''+ Convert(varchar(50), cast(mreq.Cost as numeric(10,' + @CostFormat + ')))  AS Cost, 
						''$''+ Convert(varchar(50), cast(mreq.SuggestedRetail as numeric(10,2))) AS [Suggested Retail], 
						CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS [Promo Type], 
						''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance], 
						mreq.EmailGeneratedToSupplier as [Email Generated To Supplier], 
						CAST(mreq.EmailGeneratedToSupplierDateTime AS varchar) AS [Email Date Time], 
						CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, 
						CAST(dbo.FDatetime(mreq.ApprovalDateTime) AS varchar) AS [Approved Date Time],
						(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1 FROM   dbo.Logins AS Logins_1 
							INNER JOIN dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
							WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name],
						CAST(DealNumber as varchar) as [Deal Number], cast(TradingPartnerPromotionIdentifier as varchar) as [Trading Partner Promotion Identifier]
				into #tmp_ReportApprovedPromotions
				FROM  MaintenanceRequests AS mreq  with (nolock)  
				INNER JOIN Suppliers AS sup  with (nolock)  ON mreq.SupplierID = sup.SupplierID 
				INNER JOIN Chains AS ch with (nolock) ON mreq.ChainID = ch.ChainID 
				INNER JOIN SupplierBanners SB  with (nolock) on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.banner 
				WHERE (approved=1) and RequestTypeId=3 and RequestStatus not in (999, 17, 18, 15, 16, -30, -333) '
				
		if @AttValue =17
			set @query = @query + ' and ch.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @query = @query + ' and sup.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and mreq.ChainID=' + @chainID 

		if(@Banner<>'All') 
			set @Query  = @Query + ' and mreq.banner like ''%' + @Banner + '%'''
	
		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and mreq.SupplierId=' + @SupplierId  

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  mreq.UPC like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and (mreq.StartDateTime between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() }) )'  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and mreq.StartDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and mreq.StartDateTime <= ''' + @EndDate  + '''';
			
	set @Query = @Query + ' option (hash join,loop join)'
	set @Query = @Query + ';Delete FROM #tmp_ReportApprovedPromotions Where [Maintenance Request ID] IN (select recordid from DataTrue_CustomResultSets.dbo.tmp_ReportApprovedPromotions where personid=' + cast(@PersonID as varchar(12)) + ' and ReportName=''ApprovedPromotions_toStartDate'') '
	
	set @Query = @Query + ';insert into DataTrue_CustomResultSets.dbo.tmp_ReportApprovedPromotions with (tablockx) (Personid,Recordid,ReportName)  select ' + cast(@PersonID as varchar(10)) + ',[Maintenance Request ID],''ApprovedPromotions_toStartDate'' from #tmp_ReportApprovedPromotions ;' 
	
	set @Query = @Query + ';select * from #tmp_ReportApprovedPromotions '
		print (@Query )	
		exec (@Query )

END
GO
