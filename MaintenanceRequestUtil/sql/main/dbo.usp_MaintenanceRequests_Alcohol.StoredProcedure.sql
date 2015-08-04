USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_MaintenanceRequests_Alcohol]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_MaintenanceRequests_Alcohol]
 @AccessLevel varchar(20),
 @ChainId varchar(10),
 @SupplierId varchar(10),
 @UPC varchar(100),
 @FromDate varchar(15),
 @ToDate varchar(15),
 @RequestTypeId varchar(2),
 @Status varchar(50),
 @BannerName varchar(250),
 @ShowStore varchar(1),
 @StoreNumber varchar(20),
 @DealNumber varchar(50),
 @CostZoneId varchar(20)
as
--exec usp_MaintenanceRequests_Alcohol 'Chain','40393','-1','','1900-01-01','1900-01-01','1','1','All','0','','-1','-1'
Begin
Declare @sqlQuery varchar(4000)
	begin try
		   Drop Table [@tmpMaintenanceRequestAlcohol]
	end try
	begin catch
	end catch

	if(@AccessLevel = 'Supplier') 
		begin
				set @sqlQuery = 'SELECT mreq.MaintenanceRequestID, 
					 Mt.RequestTypeDescription  AS RequestType, ch.ChainName as Name, ';
		end
	else
		begin
				set @sqlQuery = 'SELECT distinct mreq.MaintenanceRequestID, mreq.SupplierId, mreq.ChainId, mreq.CostZoneId,mreq.RequestTypeID,
					 Mt.RequestTypeDescription  AS RequestType, sup.SupplierName as Name, ';
		end

	if(@ShowStore='1')
		set @sqlQuery = @sqlQuery + ' MRS.StoreIdentifier as AllStores, '
	else 
		set @sqlQuery = @sqlQuery + 'CASE WHEN AllStores = 1 THEN ''All'' 
										  ELSE ''Multiple'' END AS AllStores, '
	

	set @sqlQuery = @sqlQuery +  'mreq.Banner AS BannerName, 

									(SELECT  CostZoneName FROM dbo.CostZones
									   WHERE (CostZoneId = mreq.CostZoneID)) AS CostZoneName,
									   
									mreq.UPC, mreq.ItemDescription, mreq.DealNumber, isnull(dc.filename,'''') as filename,
									convert(varchar(10), mreq.SubmitDateTime, 101) as SubmitDateTime, 
									convert(varchar(10), mreq.StartDateTime, 101) as StartDateTime, 
									convert(varchar(10), mreq.EndDateTime, 101) as EndDateTime, 
													(SELECT  dbo.Persons.FirstName + '' '' + dbo.Persons.LastName AS Expr1
														FROM dbo.Logins INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
														WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS SupplierUserName, 
								                        
														(SELECT  dbo.Logins.Login
														FROM dbo.Logins 
														WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS SupplierEmailId, 
														cast(mreq.CurrentSetupCost as numeric(10,3)) as CurrentSetupCost, 
														cast(mreq.Cost as numeric(10,3)) as Cost, 
														cast(mreq.SuggestedRetail as numeric(10,2)) as SuggestedRetail, 
								                        
								CASE WHEN PromoTypeID = 1 THEN ''OI'' 
								WHEN PromoTypeID = 2 THEN ''BB'' 
								WHEN PromoTypeID = 3 THEN ''CC'' 
								ELSE '''' END AS PromoType, 

								mreq.PromoAllowance, 
								mreq.EmailGeneratedToSupplier, mreq.EmailGeneratedToSupplierDateTime, 
								                  
								CASE WHEN MarkDeleted = 1 THEN ''Deleted''
								WHEN Approved = 1 THEN ''Approved'' 
								WHEN Approved = 0 THEN ''Rejected'' '

	if(@AccessLevel = 'Supplier') 
		set @sqlQuery = @sqlQuery + ' WHEN FromWebInterface=1 Then ''Pending'' ELSE ''Pending '' END AS Approved,'
	else
		set @sqlQuery = @sqlQuery + ' ELSE ''Pending'' END AS Approved,'

	if(@AccessLevel = 'Chain') 
		set @sqlQuery = @sqlQuery + '''False'' AS ShowEditColumn,'	
	else if(@SupplierId='-1') 
		set @sqlQuery = @sqlQuery + '''False'' AS ShowEditColumn,'
	else if(@Status>'1') 
		set @sqlQuery = @sqlQuery + '''False'' AS ShowEditColumn,'	
	else
		set @sqlQuery = @sqlQuery + '''True'' AS ShowEditColumn,'	
		 
	set @sqlQuery = @sqlQuery + ' CASE WHEN MarkDeleted = 1 THEN 0
									WHEN mreq.Banner like ''%Shop N Save%'' and mreq.StartDateTime > GetDate() and convert(varchar(10), StartDateTime, 101) <= convert(varchar(10),dateadd(d,3, GETDATE()), 101) THEN 0
									else 1 
									END
									As Deletable,
									mreq.ApprovalDateTime, mreq.DenialReason, 
									(mreq.DeleteReason + '' ('' + convert(varchar(10), mreq.DeleteDateTime, 101) + '') ''  ) as DeleteReason,
									                    
									(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1
										FROM dbo.Logins AS Logins_1 INNER JOIN dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
										WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS RetailerUserName

									into [@tmpMaintenanceRequestAlcohol]              
									FROM  dbo.MaintenanceRequests AS mreq 
										INNER JOIN MaintananceRequestsTypes Mt ON mreq.RequestTypeID=Mt.RequestType
									INNER JOIN dbo.Suppliers AS sup ON mreq.SupplierId = sup.SupplierId 
									INNER JOIN dbo.Chains AS ch ON mreq.ChainId = ch.ChainId 
									Inner join SupplierBanners SB on SB.SupplierId = mreq.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.Banner
									Left Join DealContracts dc on dc.DealNumber=mreq.DealNumber and dc.SupplierId = mreq.SupplierId '
									
		

	if(@ShowStore='1')
		set @sqlQuery = @sqlQuery + ' Left JOIN DataTrue_CustomResultSets.dbo.tmpMaintenanceRequestStores MRS ON MRS.MaintenanceRequestId= mreq.MaintenanceRequestId'


	set @sqlQuery = @sqlQuery + ' WHERE mreq.RequestStatus not in (999, 17, 18, 15, 16, -30, -333) '
	 
	 if(@RequestTypeId <> '-1') 
			set @sqlQuery = @sqlQuery + ' and  mt.RequestType='+@RequestTypeId
	 
	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.ChainId=' + @ChainId

	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.SupplierId=' + @SupplierId

	if(@CostZoneId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.CostZoneId=' + @CostZoneId
	 
	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and UPC like ''%' + @UPC + '%''';
	 
	if(@FromDate<>'1900-01-01') 
		set @sqlQuery = @sqlQuery + ' and StartDateTime  >= ''' + @FromDate + '''';

	if(@ToDate<>'1900-01-01') 
		set @sqlQuery = @sqlQuery + ' and StartDateTime  <= ''' + @ToDate  + '''';

	if(@Status = 1) 
	Begin
		set @sqlQuery = @sqlQuery +  ' and mreq.Approved is Null '
	End

	if(@Status = 2) 
		set @sqlQuery = @sqlQuery +  ' and mreq.Approved = 1 and mreq.requeststatus in (0, 5)'

	if(@Status = 3) 
		set @sqlQuery = @sqlQuery +  ' and mreq.Approved = 0'

	if(@Status = 4) 
		set @sqlQuery = @sqlQuery +  ' and mreq.MarkDeleted = 1'

	else if(@Status != -1) 
		set @sqlQuery = @sqlQuery +  ' and (MarkDeleted is null or MarkDeleted=0)' 
		
	if(@BannerName<>'All' and @BannerName<>'') 
		set @sqlQuery = @sqlQuery +  ' and mreq.Banner=''' + @BannerName + ''''

	if(@ShowStore='1' and @StoreNumber<>'')
		set @sqlQuery = @sqlQuery +  ' and MRS.StoreIdentifier like ''%' + @StoreNumber + '%'''

	if(@DealNumber<>'-1')
		set @sqlQuery = @sqlQuery +  ' and mreq.DealNumber = ''' + @DealNumber + ''''

	--Special case for Gopher
	set @sqlQuery = @sqlQuery +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests where SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved is null)'

	if(@ShowStore='1')	
		set @sqlquery =@sqlQuery + ' order by MRS.StoreIdentifier'
		
		
	PRINT 	@sqlQuery
	exec (@sqlQuery); 

	Select M1.MaintenanceRequestID  as NewItemId, M2.MaintenanceRequestID as CostChangeId 
	into #tmpDuplicateRecords
	from MaintenanceRequests M1	
	inner join MaintenanceRequests M2 on M1.SupplierID=M2.SupplierID and M1.ChainID=M2.ChainID 
	and M1.AllStores=M2.AllStores and M1.UPC=M2.UPC
	where M1.RequestTypeID=1 and M1.RequestStatus<>999 and M1.Approved is null and M1.Cost=0
	and M2.RequestTypeID=2 and M2.RequestStatus<>999 and M2.Approved is null 

	Delete from [@tmpMaintenanceRequestAlcohol] 
	where MaintenanceRequestId in (Select distinct NewItemId from #tmpDuplicateRecords)

	Update [@tmpMaintenanceRequestAlcohol] set RequestType='ADD NEW ITEM'  
	where MaintenanceRequestId in (Select distinct CostChangeId from #tmpDuplicateRecords)
	
		Select * from [@tmpMaintenanceRequestAlcohol] 

	begin try
		   Drop Table [@tmpMaintenanceRequestAlcohol]
	end try
	begin catch
	end catch
	
End
GO
