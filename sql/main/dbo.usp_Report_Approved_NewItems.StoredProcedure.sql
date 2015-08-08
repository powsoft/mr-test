USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_NewItems]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Approved_NewItems] 
	-- exec usp_Report_Approved_NewItems 65726,75125,'All','-1','75124','-1',0,'08/25/2014','12/31/2099'
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
		Select @CostFormat = Costformat from SupplierFormat WITH (NOLOCK) where SupplierID = @supplierID
	 else
		set @CostFormat=4
	set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 	
	set @query = 'SELECT ' + @MaxRowsCount + ' CAST(mreq.MaintenanceRequestID AS varchar) AS [Maintenance Request ID], 
					CASE WHEN RequestTypeID = 1 THEN ''New Item'' ELSE '''' END AS [Request Type], 
					sup.SupplierName AS [Supplier Name], mreq.Banner AS Banner,
					(SELECT CostZoneName FROM   CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name], 
					mreq.UPC, mreq.ItemDescription as [Item Description], 
					convert(varchar(10),cast(mreq.SubmitDateTime as date),101) AS [Submit Date Time], 
					convert(varchar(10),cast(mreq.StartDateTime as date),101) AS [Start Date Time], 
					convert(varchar(10),cast(mreq.EndDateTime as date),101) AS [End Date Time],
					(SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1 FROM dbo.Logins  WITH (NOLOCK) 
						INNER JOIN dbo.Persons  WITH (NOLOCK) ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
						WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name], 
					''$''+ Convert(varchar(50), cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')))  AS [Current Setup Cost], 
					''$''+ Convert(varchar(50), cast(mreq.Cost as numeric(10,' + @CostFormat + ')))  AS Cost, 
					''$''+ Convert(varchar(50), cast(mreq.SuggestedRetail as numeric(10,2))) AS [Suggested Retail], 
					CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS [Promo Type], 
					''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance], 
					mreq.EmailGeneratedToSupplier as [Email Generated To Supplier], 
					convert(varchar(10),CAST(mreq.EmailGeneratedToSupplierDateTime AS date),101) AS [Email Date Time], 
					CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, 
					convert(varchar(10),CAST(mreq.ApprovalDateTime AS date),101) AS [Approved Date Time],
					(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1 
					
					FROM   dbo.Logins AS Logins_1  WITH (NOLOCK) 
						INNER JOIN dbo.Persons AS Persons_1 WITH (NOLOCK)  ON Logins_1.OwnerEntityId = Persons_1.PersonID
			WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]

into #tmp_ReportApprovedNewItems

			FROM  MaintenanceRequests AS mreq  WITH (NOLOCK) 
			INNER JOIN Suppliers AS sup WITH (NOLOCK) ON mreq.SupplierID = sup.SupplierID 
			INNER JOIN Chains AS ch WITH (NOLOCK) ON mreq.ChainID = ch.ChainID 
			INNER JOIN SupplierBanners SB WITH (NOLOCK) on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.banner 
			WHERE (approved=1) and RequestTypeId=1 and requeststatus<>999 '

		if @AttValue =17
			set @query = @query + ' and ch.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		else
			set @query = @query + ' and sup.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

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
			set @Query = @Query + ' and convert(date,mreq.ApprovalDateTime) >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and convert(date,mreq.ApprovalDateTime) <= ''' + @EndDate  + '''';
			
			 set @Query = @Query + ' option (hash join,loop join)'
	set @Query = @Query + ';Delete FROM #tmp_ReportApprovedNewItems Where [Maintenance Request ID] IN (select recordid from DataTrue_CustomResultSets.dbo.tmp_ReportApprovedNewItems where personid=' + cast(@PersonID as varchar(12)) + ' and ReportName=''ApprovedNewItems'') '
	
	set @Query = @Query + ';insert into DataTrue_CustomResultSets.dbo.tmp_ReportApprovedNewItems with (tablockx) (Personid,Recordid,ReportName)  select ' + cast(@PersonID as varchar(10)) + ',[Maintenance Request ID],''ApprovedNewItems'' from #tmp_ReportApprovedNewItems ;' 
	
	set @Query = @Query + ';select * from #tmp_ReportApprovedNewItems '
	
		print (@query)
		exec (@Query )
END
GO
