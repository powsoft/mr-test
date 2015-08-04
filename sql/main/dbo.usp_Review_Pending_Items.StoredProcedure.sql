USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Review_Pending_Items]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE	 PROCEDURE [dbo].[usp_Review_Pending_Items] 
	-- exec [usp_Review_Pending_Items] '40559', '40393','-1','1900-01-01','1900-01-01','2','','-1','-1','1',''
	@SupplierId varchar(10),
	@ChainID varchar(20),
	@Banner varchar(50),
	@FromStartDate varchar(20),
	@ToStartDate varchar(20),
	@ProductIdentifierType varchar(20),
	@ProductIdentifierValue varchar(20),
	@DealNumber varchar(20),
	@CostZoneId varchar(20),
	@RequestTypeId varchar(3),
	@Compliance varchar(3)
	
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else
		set @CostFormat=4	
 	
	set @query = 'SELECT mreq.MaintenanceRequestID AS [Maintenance Request Id]
					,  Mt.RequestTypeDescription As  [Request Type]
					, sup.SupplierName AS [Supplier Name]
					, mreq.Banner
					, (SELECT CostZoneName FROM   dbo.CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name]
					, mreq.UPC, mreq.ItemDescription as [Item Description]
					, Convert(varchar(20),dbo.FDatetime(mreq.SubmitDateTime),101) AS [Submit Date]
					, Convert(varchar(20),dbo.FDatetime(mreq.StartDateTime),101) AS [Start Date]
					, Convert(varchar(20),dbo.FDatetime(mreq.EndDateTime),101) as [End Date]
					, (SELECT dbo.Persons.FirstName + dbo.Persons.LastName FROM   dbo.Logins 
						INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
						WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name]
					, ''$''+ Convert(varchar(50), CAST(mreq.CurrentSetupCost AS numeric(10,' + @CostFormat + '))) AS [Current Setup Cost]
					, ''$''+ Convert(varchar(50), CAST(mreq.Cost AS numeric(10,' + @CostFormat + '))) AS Cost
					, ''$''+ Convert(varchar(50), CAST(mreq.SuggestedRetail AS numeric(10,2))) AS [Suggested Retail]
					, CASE 
							WHEN PromoTypeID = 1 THEN ''OI'' 
							WHEN PromoTypeID = 2 THEN ''BB'' 
							WHEN PromoTypeID = 3 THEN ''CC'' 
							ELSE '''' 
							END AS [Promo Type]
					, ''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance]
					, mreq.EmailGeneratedToSupplier as [Email Generated To Supplier]
					, dbo.FDatetime(mreq.EmailGeneratedToSupplierDateTime) AS [Email Date]
					, CASE WHEN Approved = 1 THEN ''Yes'' WHEN Approved = 0 THEN ''No'' ELSE ''Pending'' END AS Approved
					, dbo.FDatetime(mreq.ApprovalDateTime) AS [Approval Date]
					, (SELECT Persons_1.FirstName + '' '' + Persons_1.LastName FROM   dbo.Logins AS Logins_1 
						INNER JOIN  dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
						WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]
					, case when InCompliance =1 then ''True'' else ''False'' end as [Lead Time Compliance]
				FROM	 dbo.MaintenanceRequests AS mreq 
				INNER JOIN MaintananceRequestsTypes Mt ON mreq.RequestTypeID=Mt.RequestType
				INNER JOIN dbo.Suppliers AS sup ON mreq.SupplierID = sup.SupplierID 
				INNER JOIN dbo.Chains AS ch ON mreq.ChainID = ch.ChainID 
				INNER JOIN SupplierBanners SB on SB.SupplierId = sup.SupplierID and SB.Status=''Active'' and SB.Banner=mreq.Banner
				WHERE (approved is null) and requeststatus<>999 and (MarkDeleted is null)'

	if(@RequestTypeId  <>'-1') 
		set @Query   = @Query  +  ' and mreq.RequestTypeId=' + @RequestTypeId 

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and mreq.SupplierId=' + @SupplierId  
		
	if(@ChainID  <>'-1') 
		set @Query   = @Query  +  ' and mreq.ChainID=' + @ChainID 

	if(@Banner<>'-1') 
		set @Query  = @Query + ' and mreq.banner like ''%' + @Banner + '%'''

	if (convert(date, @FromStartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and mreq.StartDateTime >= ''' + @FromStartDate  + '''';

	if(convert(date, @ToStartDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and mreq.StartDateTime <= ''' + @ToStartDate  + '''';
	
    if(@ProductIdentifierValue<>'')
		begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				 set @Query = @Query + ' and mreq.UPC  like ''%' + @ProductIdentifierValue + '%'''
		         
			else if (@ProductIdentifierType=3)
				set @Query = @Query + ' and mreq.ItemDescription like ''%' + @ProductIdentifierValue + '%'''
		end

	if(@DealNumber<>'-1')
		set @Query = @Query +  ' and mreq.DealNumber = ''' + @DealNumber + ''''
		
	if(@CostZoneId<>'-1')
		set @Query = @Query +  ' and mreq.CostZoneId = ''' + @CostZoneId + ''''
	
	if(@Compliance<>'-1')
		set @Query = @Query +  ' and mreq.InCompliance = ''' + @Compliance  + ''''					
		
	exec (@Query )
END
GO
