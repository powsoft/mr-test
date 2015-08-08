USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Promotion_Reminder]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_Report_Promotion_Reminder] 
	-- exec usp_Report_Promotion_Reminder '40393','2','All','','-1','','530','1900-01-01','1900-01-01'
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

	select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
	set @query = 'SELECT  ' + @MaxRowsCount + ' sup.SupplierName AS [Supplier Name], 
           mreq.Banner, cz.CostZoneName as [Cost Zone Name], mreq.UPC, 
           mreq.ItemDescription as [Item Description], 
           convert(varchar(10),cast(mreq.SubmitDateTime as date),101) as [Submit Date], 
           convert(varchar(10),cast(mreq.StartDateTime as date),101) as [Start Date], 
           convert(varchar(10),cast(mreq.EndDateTime as date),101) as [End Date],
		  (SELECT dbo.Persons.FirstName + dbo.Persons.LastName FROM   dbo.Logins  WITH(NOLOCK) 
                INNER JOIN dbo.Persons WITH(NOLOCK)  ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
                WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name], 
           CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS [Promo Type], 
           ''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo$], 
           CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, 
           CASE WHEN MarkDeleted = 1 THEN ''Yes'' ELSE ''No'' END AS [Deleted], 
           convert(varchar(10),cast(mreq.ApprovalDateTime as date),101) AS [Approval Date],
               (SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1
                FROM   dbo.Logins AS Logins_1  WITH(NOLOCK) 
                INNER JOIN dbo.Persons AS Persons_1 WITH(NOLOCK)  ON Logins_1.OwnerEntityId = Persons_1.PersonID
                WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name],
           mreq.DealNumber as [Deal Number],mreq.TradingPartnerPromotionIdentifier as [Trading Partner Id #]
	FROM  
		   MaintenanceRequests AS mreq  WITH(NOLOCK) 
		   INNER JOIN Suppliers AS sup WITH(NOLOCK)  ON mreq.SupplierID = sup.SupplierID 
		   INNER JOIN Chains AS ch WITH(NOLOCK)  ON mreq.ChainID = ch.ChainID 
		   INNER JOIN SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = sup.SupplierID and SB.Status=''Active'' and SB.Banner=mreq.Banner
		   left join CostZones CZ WITH(NOLOCK)  on CZ.CostZoneID=mreq.CostZoneID
	WHERE (approved=1) and requeststatus<>999 and RequestTypeId=3 and mreq.StartDatetime >= getdate() and mreq.startdatetime <= dateadd(day,14,mreq.StartDatetime) '

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
		set @Query   = @Query  +  ' and  mreq.UPC  like ''%' + @ProductUPC + '%'''

	if (@LastxDays > 0)
		set @Query = @Query + ' and mreq.StartDateTime between { fn NOW() } and dateadd(d,' +  cast(@LastxDays as varchar) + ', { fn NOW() })'  
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and mreq.StartDateTime >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and mreq.StartDateTime <= ''' + @EndDate  + '''';
		
	exec (@Query )
END
GO
