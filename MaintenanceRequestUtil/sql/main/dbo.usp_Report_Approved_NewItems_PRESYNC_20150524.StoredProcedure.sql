USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Approved_NewItems_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_Approved_NewItems_PRESYNC_20150524] 
	-- exec usp_Report_Approved_NewItems '40393','2','All','','-1','','530','1900-01-01','1900-01-01'
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4
	set @CostFormat = ISNULL(@CostFormat , 4)
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 	
	set @query = 'SELECT  CAST(mreq.MaintenanceRequestID AS varchar) AS [Maintenance Request ID], 
					CASE WHEN RequestTypeID = 1 THEN ''New Item'' ELSE '''' END AS [Request Type], 
					sup.SupplierName AS [Supplier Name], mreq.Banner AS Banner,
					(SELECT CostZoneName FROM   dbo.CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name], 
					mreq.UPC, mreq.ItemDescription as [Item Description], 
					dbo.FDatetime(mreq.SubmitDateTime) AS [Submit Date Time], 
					dbo.FDatetime(mreq.StartDateTime) AS [Start Date Time], 
					dbo.FDatetime(mreq.EndDateTime) AS [End Date Time],
					(SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1 FROM dbo.Logins 
						INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
						WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name], 
					''$''+ Convert(varchar(50), cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')))  AS [Current Setup Cost], 
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
			WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]
			FROM  DataTrue_Report.dbo.MaintenanceRequests AS mreq 
			INNER JOIN dbo.Suppliers AS sup ON mreq.SupplierID = sup.SupplierID 
			INNER JOIN dbo.Chains AS ch ON mreq.ChainID = ch.ChainID 
			INNER JOIN SupplierBanners SB on SB.SupplierId = sup.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.banner 
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
			set @Query = @Query + ' and mreq.StartDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and mreq.StartDateTime <= ''' + @EndDate  + '''';
		
		exec (@Query )
END
GO
