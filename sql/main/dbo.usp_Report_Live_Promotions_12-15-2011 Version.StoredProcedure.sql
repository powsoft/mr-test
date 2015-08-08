USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Live_Promotions_12-15-2011 Version]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[usp_Report_Live_Promotions_12-15-2011 Version] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(20),
	@PersonID int,
	@Banner varchar(20),
	@ProductUPC varchar(20),
	@SupplierId varchar(10),
	@StoreId varchar(10),
	@LastxDays int
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int

select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
 
if @AttValue =17
begin
	set @query = 'Select top 1 ''MaintenanceReqID'',''RequestType'',''SupplierName'',''Banner'',
	''CostZoneName'',''UPC'',''ItemDescription'',''SubmitDateTime'',''StartDateTime'',''EndDateTime'',''UserName'',''CurrentSetupCost'',''Cost'',''SuggestedRetail'',''PromoType'', ''PromoAllowance'', ''EmailGeneratedToSupplier'', 
	''EmailGeneratedDateTime'',''Approved'',''ApprovedDateTime'',''RetailerUserName'' from Chains union all
		SELECT CAST(mreq.MaintenanceRequestID AS varchar) AS Expr1, CASE WHEN RequestTypeID = 3 THEN ''Promotion'' ELSE '''' END AS Type, sup.SupplierName AS Name, 
               mreq.Banner AS BannerName,
                   (SELECT CostZoneName
                    FROM   dbo.CostZones
                    WHERE (CostZoneId = mreq.CostZoneID)) AS CostZoneName, mreq.UPC, mreq.ItemDescription, CAST(mreq.SubmitDateTime AS varchar) AS Expr2, 
               CAST(mreq.StartDateTime AS varchar) AS Expr3, CAST(mreq.EndDateTime AS varchar) AS Expr4,
                   (SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1
                    FROM   dbo.Logins INNER JOIN
                                   dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
                    WHERE (dbo.Logins.LoginID = mreq.SupplierLoginID)) AS SupplierUserName, CAST(mreq.CurrentSetupCost AS varchar) AS Expr5, CAST(mreq.Cost AS varchar) 
               AS Expr6, CAST(mreq.SuggestedRetail AS varchar) AS Expr7, 
               CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS PromoType, 
               CAST(mreq.PromoAllowance AS varchar) AS Expr8, mreq.EmailGeneratedToSupplier, CAST(mreq.EmailGeneratedToSupplierDateTime AS varchar) AS Expr9, 
               CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, CAST(mreq.ApprovalDateTime AS varchar) AS Expr10,
                   (SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1
                    FROM   dbo.Logins AS Logins_1 INNER JOIN
                                   dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
                    WHERE (Logins_1.LoginID = mreq.ChainLoginID)) AS RetailerUserName
FROM  dbo.PersonsAssociation INNER JOIN
               DataTrue_Report.dbo.MaintenanceRequests AS mreq INNER JOIN
               dbo.Suppliers AS sup ON mreq.SupplierID = sup.SupplierID INNER JOIN
               dbo.Chains AS ch ON mreq.ChainID = ch.ChainID ON dbo.PersonsAssociation.ChainIDOrSupplierID = ch.ChainID
WHERE (approved=1) and RequestTypeId=3 and mreq.StartDatetime <= getdate() and mreq.endDatetime >= getdate() AND dbo.PersonsAssociation.PersonID =' + CAST( @PersonID  as varchar)
end 

else
begin


	set @query = 'Select top 1 ''MaintenanceReqID'',''RequestType'',''Supplier Name'',''Banner'',
	''CostZoneName'',''UPC'',''ItemDescription'',''SubmitDateTime'',''StartDateTime'',''EndDateTime'',''UserName'',''CurrentSetupCost'',''Cost'',''SuggestedRetail'',''PromoType'', ''PromoAllowance'', ''EmailGeneratedToSupplier'', 
	''EmailGeneratedDateTime'',''Approved'',''ApprovedDateTime'',''RetailerUserName'' from Chains union all
		SELECT CAST(mreq.MaintenanceRequestID AS varchar) AS Expr1, CASE WHEN RequestTypeID = 3 THEN ''Promotion'' ELSE '''' END AS Type, sup.SupplierName AS Name, 
               mreq.Banner AS BannerName,
                   (SELECT CostZoneName
                    FROM   dbo.CostZones
                    WHERE (CostZoneId = mreq.CostZoneID)) AS CostZoneName, mreq.UPC, mreq.ItemDescription, CAST(mreq.SubmitDateTime AS varchar) AS Expr2, 
               CAST(mreq.StartDateTime AS varchar) AS Expr3, CAST(mreq.EndDateTime AS varchar) AS Expr4,
                   (SELECT dbo.Persons.FirstName + dbo.Persons.LastName AS Expr1
                    FROM   dbo.Logins INNER JOIN
                                   dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
                    WHERE (dbo.Logins.LoginID = mreq.SupplierLoginID)) AS SupplierUserName, CAST(mreq.CurrentSetupCost AS varchar) AS Expr5, CAST(mreq.Cost AS varchar) 
               AS Expr6, CAST(mreq.SuggestedRetail AS varchar) AS Expr7, 
               CASE WHEN PromoTypeID = 1 THEN ''OI'' WHEN PromoTypeID = 2 THEN ''BB'' WHEN PromoTypeID = 3 THEN ''CC'' ELSE '''' END AS PromoType, 
               CAST(mreq.PromoAllowance AS varchar) AS Expr8, mreq.EmailGeneratedToSupplier, CAST(mreq.EmailGeneratedToSupplierDateTime AS varchar) AS Expr9, 
               CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved, CAST(mreq.ApprovalDateTime AS varchar) AS Expr10,
                   (SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1
                    FROM   dbo.Logins AS Logins_1 INNER JOIN
                                   dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
                    WHERE (Logins_1.LoginID = mreq.ChainLoginID)) AS RetailerUserName
FROM  dbo.PersonsAssociation INNER JOIN
               DataTrue_Report.dbo.MaintenanceRequests AS mreq INNER JOIN
               dbo.Suppliers AS sup ON mreq.SupplierID = sup.SupplierID INNER JOIN
               dbo.Chains AS ch ON mreq.ChainID = ch.ChainID ON dbo.PersonsAssociation.ChainIDOrSupplierID = sup.SupplierID
WHERE (approved=1) and RequestTypeId=3 and mreq.StartDatetime <= getdate() and mreq.endDatetime >= getdate() AND dbo.PersonsAssociation.PersonID = ' + CAST( @PersonID  as varchar)


                      
end 

 if(@chainID  <>'-1') 
  set @Query   = @Query  +  ' and mreq.ChainID=' + @chainID 

 if(@Banner<>'All') 
  set @Query  = @Query + ' and mreq.banner =''' + @Banner + ''''

 if(@SupplierId<>'-1') 
  set @Query  = @Query  + ' and mreq.SupplierId=' + @SupplierId  
  
 
 if(@ProductUPC  <>'-1') 
 set @Query   = @Query  +  ' and  mreq.UPC=''' + @ProductUPC + ''''
 
if (@LastxDays >= 0)
set @Query = @Query + ' and (mreq.StartDateTime between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  

exec (@Query )
END
GO
