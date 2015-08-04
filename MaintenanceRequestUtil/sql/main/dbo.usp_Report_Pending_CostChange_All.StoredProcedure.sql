USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Pending_CostChange_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Pending_CostChange_All] 
	-- exec usp_Report_Pending_CostChange_All '40393,44199','40384','All','-1','40561,40567,41464,40562,40557,40558,41440,40560','-1','0','1900-01-01','1900-01-01'
	-- exec usp_Report_Pending_CostChange_All '44285','50334','All','-1','44270','-1','0','1900-01-01','1900-01-01'
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
declare @RoleName Varchar(50)
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
	Begin
		DECLARE @sqlCommand nvarchar(max)
		declare @counts int
		SET @sqlCommand = 'SELECT @cnt=Max(Costformat) FROM SupplierFormat WITH(NOLOCK)  where SupplierID in ('+ @supplierID+' )'
		EXECUTE sp_executesql @sqlCommand, N'@cnt int OUTPUT',   @cnt=@CostFormat OUTPUT
	End
	 else
		set @CostFormat=4	
		set @CostFormat = ISNULL(@CostFormat , 4)
		select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 	SELECT @RoleName= RoleName from AssignUserRoles_New A inner join UserRoles_New R on R.RoleID=A.RoleID where UserID=@PersonID
 	set @query = 'SELECT   mreq.MaintenanceRequestID AS MaintenanceReqID
			, CASE 
				WHEN RequestTypeID = 2 
					THEN ''Cost Change'' 
				ELSE '''' 
				END AS [Request Type]
			, sup.SupplierName AS [Supplier Name]
			, mreq.Banner
			, (SELECT CostZoneName
				FROM   dbo.CostZones
				WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name]'
		if( CHARINDEX('PDI', @RoleName) > 0 )
			set @query = @query +',case when InCompliance =1 then ''True'' else ''False'' end as [Lead Time Compliance]'
		set @query = @query +', mreq.UPC,case when mreq.RequestTypeId>1 then  case when isnull(mreq.ItemDescription,'''')='''' then prod.ProductName else mreq.ItemDescription end else mreq.ItemDescription end as [Item Description]
			, convert(varchar(10),CAST(mreq.SubmitDateTime as date),101) AS [Submit Date]
			, convert(varchar(10),CAST(mreq.StartDateTime as date),101) AS [Start Date], 
			  convert(varchar(10),CAST(mreq.EndDateTime as date),101) AS [End Date]
			, (SELECT dbo.Persons.FirstName + dbo.Persons.LastName FROM   dbo.Logins 
				INNER JOIN  dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
				WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name],
			case when sup.PDITradingPartner=1 then 
							''$''+ Convert(varchar(50), cast(p.UnitPrice as numeric(10,' + @CostFormat + ')))  
						else 
							''$''+ Convert(varchar(50), cast(mreq.CurrentSetupCost as numeric(10,' + @CostFormat + ')))  
						end as [Current Setup Cost]
			, ''$''+ Convert(varchar(50), CAST(mreq.Cost AS numeric(10,' + @CostFormat + '))) AS Cost
			, mreq.EmailGeneratedToSupplier as [Email Generated To Supplier]
			, mreq.EmailGeneratedToSupplierDateTime as [Email Date]
			, CASE 
				WHEN Approved = 1 
					THEN ''Yes'' 
				WHEN Approved = 0 
					THEN ''No'' 
				ELSE ''Pending'' 
				END AS Approved
			, convert(varchar(10),CAST(mreq.ApprovalDateTime as date),101) AS [Approval Date]
			, (SELECT Persons_1.FirstName + '' '' + Persons_1.LastName FROM   dbo.Logins AS Logins_1  WITH(NOLOCK) 
				INNER JOIN  dbo.Persons AS Persons_1 WITH(NOLOCK)  ON Logins_1.OwnerEntityId = Persons_1.PersonID
				WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]
				,case when mreq.RequestTypeId>1 then  case when isnull(mreq.VinDescription,'''')='''' then prod.VinDesc else mreq.VinDescription end else mreq.VinDescription end as [VIN Description]   
		FROM  MaintenanceRequests AS mreq  WITH(NOLOCK) 
			INNER JOIN     Suppliers AS sup WITH(NOLOCK)  ON mreq.SupplierID = sup.SupplierID 
			INNER JOIN    Chains AS ch WITH(NOLOCK)  ON mreq.ChainID = ch.ChainID 
			INNER JOIN SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = sup.SupplierID and SB.Status=''Active'' and SB.Banner=mreq.Banner
			left join (Select distinct IdentifierValue, ProductName, T.VIN, T.OwnerPackageDescription as VinDesc, T.SupplierID 
													from Products P WITH(NOLOCK)
													inner join ProductIdentifiers PD WITH(NOLOCK) on PD.ProductId=P.ProductId and PD.ProductIdentifierTypeId=2
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID
												) Prod on Prod.IdentifierValue = mreq.UPC and Prod.SupplierID = mreq.SupplierID and Prod.VIN=mreq.VIN and mreq.RequestTypeId>1
					
					left JOIN (
													Select DISTINCT P.SupplierId, ChainId, PD.IdentifierValue as UPC, UnitPrice, T.VIN
													from ProductPrices P WITH (NOLOCK)
													INNER JOIN ProductIdentifiers PD WITH (NOLOCK) on PD.ProductID=P.ProductID AND PD.ProductIdentifierTypeID=2 and p. ProductPriceTypeID=11 
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID and T.SupplierID=P.SupplierID 
													and T.SupplierPackageTypeID=1 --and T.SupplierPackageID=P.SupplierPackageID
and P.ProductPriceTypeID IN (3,11)
									AND getdate() BETWEEN P.ActiveStartDate AND P.ActiveLastDate
								  ) P on P.SupplierID=mreq.SupplierID and P.ChainID=mreq.ChainID AND P.UPC=mreq.UPC and P.VIN=mreq.VIN
		WHERE (approved is null)
		 and RequestTypeId=2  
		 and requeststatus<>999 
		 and (MarkDeleted is null)'
		
		--if @AttValue =17
		--	set @query = @query + ' and ch.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
		--else
		--	set @query = @query + ' and sup.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'

		if(@chainID  <>'-1') 
			set @Query   = @Query  +  ' and mreq.ChainID in (' + @chainID + ')'

		if(@Banner<>'All') 
			set @Query  = @Query + ' and mreq.banner like ''%' + @Banner + '%'''

		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and mreq.SupplierId in (' + @SupplierId  +')'

		if(@ProductUPC  <>'-1') 
			set @Query   = @Query  +  ' and  mreq.UPC like ''%' + @ProductUPC + '%'''

		if (@LastxDays > 0)
			set @Query = @Query + ' and (mreq.StartDateTime between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and  { fn NOW() }  )'  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and mreq.StartDateTime >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and mreq.StartDateTime <= ''' + @EndDate  + '''';
		
		set @Query = @Query +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests where RequestTypeId=2 and SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved is null)'
		
		exec (@Query )
END
GO
