USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Rejected_Delete]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Rejected_Delete] 
	-- exec usp_Report_Rejected_Delete '40393','2','All','','-1','','0','1900-01-01','1900-01-01'
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
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat WITH(NOLOCK)  where SupplierID = @supplierID
	 else
		set @CostFormat=4	
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
	select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = 'SELECT ' + @MaxRowsCount + ' mreq.MaintenanceRequestID AS [Maintenance Request Id] 
						  , ''Delete/Deauthorized'' AS [Request Type]
							, sup.SupplierName AS [Supplier Name], mreq.Banner 
							, (SELECT CostZoneName FROM   CostZones WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone Name]
							, mreq.UPC, mreq.ItemDescription as [Item Description]
							, convert(varchar(10),cast(mreq.SubmitDateTime as date),101) AS [Submit Date]
							, convert(varchar(10),cast(mreq.StartDateTime as date),101) AS [Start Date]
							, convert(varchar(10),cast(mreq.EndDateTime as date),101) as [End Date]
							, (SELECT dbo.Persons.FirstName + dbo.Persons.LastName FROM   dbo.Logins 
                    INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
                    WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Supplier User Name]
              , ''$''+ Convert(varchar(50), CAST(mreq.CurrentSetupCost AS numeric(10,' + @CostFormat + '))) AS [Current Setup Cost]
              , ''$''+ Convert(varchar(50), CAST(mreq.Cost AS numeric(10,' + @CostFormat + '))) AS Cost
              , ''$''+ Convert(varchar(50), CAST(mreq.SuggestedRetail AS numeric(10,2))) AS [Suggested Retail]
              , CASE 
									WHEN PromoTypeID = 1 
										THEN ''OI'' 
									WHEN PromoTypeID = 2 
										THEN ''BB'' 
									WHEN PromoTypeID = 3 
										THEN ''CC'' 
									ELSE '''' END AS [Promo Type]
							, ''$''+ CAST(mreq.PromoAllowance AS varchar) AS [Promo Allowance]
							, mreq.EmailGeneratedToSupplier as [Email Generated To Supplier]
							, convert(varchar(10),cast(mreq.EmailGeneratedToSupplierDateTime as date),101) AS [Email Date]
							, CASE 
									 WHEN markDeleted = 1 THEN
										 ''Yes''
									 WHEN markDeleted = 0 THEN
										 ''No''
									 ELSE
										 ''Pending'' END AS Deleted
							, mreq.DeleteReason as [Delete Reason] 
							, convert(varchar(10),cast(mreq.DeleteDateTime as date),101) AS [Approval Date]
							, (SELECT Persons_1.FirstName + '' '' + Persons_1.LastName FROM   dbo.Logins AS Logins_1 
                   INNER JOIN  dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
                    WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer User Name]
						
						INTO #tmp_ReportRejectedDelete
						
						FROM	 MaintenanceRequests AS mreq  WITH(NOLOCK) 
							INNER JOIN Suppliers AS sup WITH(NOLOCK)  ON mreq.SupplierID = sup.SupplierID 
							INNER JOIN Chains AS ch WITH(NOLOCK)  ON mreq.ChainID = ch.ChainID 
							INNER JOIN SupplierBanners SB WITH(NOLOCK)  on SB.SupplierId = sup.SupplierID and SB.Status=''Active'' and SB.Banner=mreq.Banner
						WHERE (approved=0) 
							and RequestTypeId=9  
							and requeststatus<>999 
							and (MarkDeleted =1)'

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
		
	set @Query = @Query +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests WITH(NOLOCK)  where RequestTypeId=1 and SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved=0)'
	
	set @Query = @Query + ' option (hash join,loop join)'
		
	set @Query = @Query + '; DELETE From  #tmp_ReportRejectedDelete WHERE [Maintenance Request ID]  IN (Select RecordID FROM [DataTrue_CustomResultSets].dbo.tmp_ReportRejectedDelete WHERE PersonID=' + CAST(@PersonID AS VARCHAR(12)) + ' AND ReportName=''RejectedDelete'');'
	
	set @Query = @Query + ';INSERT INTO [DataTrue_CustomResultSets].dbo.tmp_ReportRejectedDelete with (tablockx) (PersonID,RecordID,ReportName,Datetime) Select ' + CAST(@PersonID AS VARCHAR(10)) + ',[Maintenance Request Id],''RejectedDelete'',getdate() from #tmp_ReportRejectedDelete ;' 
	
	set @Query = @Query + ';Select * From #tmp_ReportRejectedDelete '
	
	exec (@Query )
END
GO
