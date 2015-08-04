USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Pending_Discontinue]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Pending_Discontinue] 
-- exec usp_Report_Pending_Discontinue '-1','2','All','','-1','-1','','1900-01-01','1900-01-01'
-- exec usp_Report_Pending_Discontinue '44285','50334','All','-1','44270','-1','0','1900-01-01','1900-01-01'
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
Declare @Query varchar(5000)
declare @AttValue int
declare @RoleName Varchar(50)
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat WITH(NOLOCK)  where SupplierID = @supplierID
	 else
		set @CostFormat=4	
		
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
	SELECT @RoleName= RoleName from AssignUserRoles_New A inner join UserRoles_New R on R.RoleID=A.RoleID where UserID=@PersonID
	
	set @query = 'SELECT ' + @MaxRowsCount + ' mreq.MaintenanceRequestID AS [Maintenance Request Id]
			, ''Discontinue'' AS [Request Type]
			, sup.SupplierName AS [Supplier Name]
			, mreq.Banner 
			, (SELECT CostZoneName FROM   CostZones WITH(NOLOCK)  WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name]'
	
	if( CHARINDEX('PDI', @RoleName) > 0 )
		set @query = @query +',case when InCompliance =1 then ''True'' else ''False'' end as Compliance'
		
	set @query = @query +', mreq.UPC
			, mreq.ItemDescription as [Item Description]
			, convert(varchar(10),cast(mreq.SubmitDateTime as date),101) AS [Submit Date]
			, convert(varchar(10),cast(mreq.StartDateTime as date),101) AS [Start Date]
			, convert(varchar(10),cast(mreq.EndDateTime as date),101) as [End Date]
			, (SELECT dbo.Persons.FirstName + dbo.Persons.LastName FROM   dbo.Logins  WITH(NOLOCK) 
				INNER JOIN dbo.Persons WITH(NOLOCK)  ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
				WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name]
			, ''$''+ Convert(varchar(50), CAST(mreq.CurrentSetupCost AS numeric(10,' + @CostFormat + '))) AS [Current Setup Cost]
			, ''$''+ Convert(varchar(50), CAST(mreq.Cost AS numeric(10,' + @CostFormat + '))) AS Cost
			, ''$''+ Convert(varchar(50), CAST(mreq.SuggestedRetail AS numeric(10,2))) AS [Suggested Retail]
			, CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS [Promo Type]
			, ''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance]
			, mreq.EmailGeneratedToSupplier as [Email Generated To Supplier]
			, dbo.FDatetime(mreq.EmailGeneratedToSupplierDateTime) AS [Email Date]
			, CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved
			, convert(varchar(10),cast(mreq.ApprovalDateTime as date),101) AS [Approval Date]
			, (SELECT Persons_1.FirstName + '' '' + Persons_1.LastName FROM   dbo.Logins AS Logins_1 WITH(NOLOCK)  
				INNER JOIN  dbo.Persons AS Persons_1 WITH(NOLOCK)  ON Logins_1.OwnerEntityId = Persons_1.PersonID
				WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]
	FROM	 MaintenanceRequests AS mreq  WITH(NOLOCK) 
		INNER JOIN Suppliers AS sup WITH(NOLOCK)  ON mreq.SupplierID = sup.SupplierID 
		INNER JOIN Chains AS ch WITH(NOLOCK)  ON mreq.ChainID = ch.ChainID 
		INNER JOIN SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = sup.SupplierID and SB.Status=''Active'' and SB.Banner=mreq.Banner
	WHERE (approved is null) 
		and RequestTypeId=14  
		and requeststatus<>999 
		and (MarkDeleted is null)'

	if @AttValue =17
			set @Query = @Query + ' and ch.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @Query = @Query + ' and sup.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

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
		
	set @Query = @Query +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests where RequestTypeId=1 and SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved is null)'
	print (@Query )
	exec (@Query )
END
GO
