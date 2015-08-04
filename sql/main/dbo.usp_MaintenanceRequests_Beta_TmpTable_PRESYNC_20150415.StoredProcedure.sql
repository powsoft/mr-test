USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_MaintenanceRequests_Beta_TmpTable_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [usp_MaintenanceRequests_Beta_TmpTable] 'Chain',40393,40559,'072554110573','1900-01-01','1900-01-01','2','1','SHOPPERS FOOD AND PHARMACY','0','','-1','-1','41713','-1','-1','False','-1','0','','','',''

--EXEC [usp_MaintenanceRequests_Beta] 'Chain',63612,63866,'','1900-01-01','1900-01-01','-1','1','Mile High Shoppes','0','','-1','-1','41684','-1','-1','False','-1','0','','','',''

--EXEC [usp_MaintenanceRequests_Beta] 'Chain',80502,80639,'','1900-01-01','1900-01-01','-1','-1','Sunrise Stores','0','','-1','-1','80504','-1','-1','True','-1','0','','','',''

-- EXEC [usp_MaintenanceRequests_Beta] 'Chain',75221,'80253','','1900-01-01','1900-01-01','-1','-1','Maverik','0','','-1','-1','75227','-1','-1','True','-1','0','','','',''


--EXEC [usp_MaintenanceRequests_Beta_TmpTable] 'Chain',40393,'65590','','2015-01-01','1900-01-01','-1','-1','Cub Foods','0','','-1','-1','75227','-1','-1','False','-1','0','','','','','-1'

CREATE procedure [dbo].[usp_MaintenanceRequests_Beta_TmpTable_PRESYNC_20150415]
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
 @CostZoneId varchar(20),
 @UserId varchar(10), 
 @ProductCategoryIDLevel2 varchar(10),
 @ProductCategoryIDLevel3 varchar(10),
 @isPDIUSer varchar(5),
 @Compliance varchar(4),
 @AllRqstStatus varchar(10),
 @SupplierIdentifierValue varchar(20),
 @RetailerIdentifierValue varchar(20),
 @Bipad varchar(100),
 @OwnerMarketID varchar(100),
 @Category varchar(10)
as
Begin
Declare @sqlQuery varchar(8000)
begin try
	IF OBJECT_ID('#tmpMaintenanceRequest','U') IS NOT NULL 
	begin 
		Drop Table [#tmpMaintenanceRequest]
	end
	IF OBJECT_ID('#tmpDuplicateRecords','U') IS NOT NULL 
	begin
		Drop Table [#tmpDuplicateRecords]
	end
	
	--update m set m.incompliance= case when RequiredLeadTime is null then 1 when datediff(d, SubmitDateTime, StartDateTime)<RequiredLeadTime then 0 else 1 end 
	--from MaintenanceRequests M 
	--left join MaintenanceRules R on M.SupplierId=R.SupplierId and M.ChainId=R.ChainId and M.RequestTypeId=R.RequestTypeId


	if(@AccessLevel = 'Supplier') 
		begin
				set @sqlQuery = 'SELECT mreq.MaintenanceRequestID, 
					Mt.RequestTypeDescription AS Activity, ch.ChainName  as Client,ch.ChainIdentifier as ClientIdentifier, ';
		end
	else
		begin
				set @sqlQuery = 'SELECT distinct mreq.MaintenanceRequestID, mreq.SupplierId, mreq.ChainId, mreq.CostZoneId,mreq.RequestTypeID,
					Mt.RequestTypeDescription  as Activity, sup.SupplierName  as Client,sup.SupplierIdentifier as ClientIdentifier, ';
		end

	if(@ShowStore='1')
		set @sqlQuery = @sqlQuery + ' MRS.StoreIdentifier as [Store#], '
	else 
		set @sqlQuery = @sqlQuery + 'CASE WHEN AllStores = 1 THEN ''All'' 
										  ELSE ''Multiple'' END AS Store#, '
	

	set @sqlQuery = @sqlQuery +  'mreq.Banner as Division, 

									(SELECT  CostZoneName AS [Cost Zone]  FROM dbo.CostZones with(nolock) 
									   WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone],   
									mreq.UPC, case when isnull(mreq.ItemDescription,'''')='''' then prod.ProductName else mreq.ItemDescription end  as Item, 
									mreq.DealNumber, isnull(dc.filename,'''') as filename,
									convert(DATE, mreq.SubmitDateTime, 101) as [Date Submitted], 
									convert(DATE, mreq.StartDateTime, 101) as [Start Date], 
									convert(DATE, mreq.EndDateTime, 101) as [End Date], prn.Firstname + '' '' + prn.lastname AS [Submitted By],
													--(SELECT  dbo.Persons.FirstName + '' '' + dbo.Persons.LastName AS Expr1
													--	FROM dbo.Logins INNER JOIN dbo.Persons with(nolock)  ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
													--	WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Submitted By], 
								                        
														--(SELECT  dbo.Logins.Login
													--	FROM dbo.Logins 
													--	WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID))
														
														lgn.login AS SupplierEmailId, 
														cast(mreq.CurrentSetupCost as numeric(10,3)) as [Current Cost], 
														cast(mreq.Cost as numeric(10,3)) as [New Cost], 
														cast(mreq.SuggestedRetail as numeric(10,2)) as MSRP, 
								                        
								CASE WHEN PromoTypeID = 1 THEN ''OI'' 
								WHEN PromoTypeID = 2 THEN ''BB'' 
								WHEN PromoTypeID = 3 THEN ''CC'' 
								ELSE '''' END AS [Promo Type], 

								mreq.PromoAllowance as [Promo Allowance], 
								mreq.EmailGeneratedToSupplier as [Confirmation Email], convert(Date,mreq.EmailGeneratedToSupplierDateTime, 101) as [Confirmation Date], 
								                  
								CASE WHEN MarkDeleted = 1 THEN ''Deleted''
								WHEN Approved = 1 THEN ''Approved'' 
								WHEN Approved = 0 THEN ''Rejected'' '

		if(@AccessLevel = 'Supplier') 
			set @sqlQuery = @sqlQuery + ' WHEN FromWebInterface=1 Then ''Pending'' ELSE ''Pending '' END AS Status,'
		else
			set @sqlQuery = @sqlQuery + ' ELSE ''Pending'' END AS Approved,'

		set @sqlQuery = @sqlQuery + 'mreq.PrimaryGroupLevel as [Primary Group Level],mreq.AlternateGroupLevel as [Alternate Group Level],
				 mreq.ItemGroup as [Item Group],mreq.AlternateItemGroup as [Alternate Item Group],mreq.Size,
				 mreq.BrandIdentifier as [Brand Identifier],mreq.ManufacturerIdentifier as [Manufacturer Identifier],
				 mreq.SellPkgVINAllowReorder as [Sell Pkg VIN Allow Reorder],mreq.SellPkgVINAllowReClaim as [Sell Pkg VIN Allow ReClaim],
				 mreq.PrimarySellablePkgIdentifier as [Primary Sellable Pkg Identifier],mreq.PrimarySellablePkgQty 
				 as [Primary Sellable Pkg Qty],mreq.VIN, 
				 case when isnull(mreq.VINDescription,'''')='''' then prod.VinDesc else mreq.VINDescription end  as [VIN Description],
				 mreq.PurchPackDescription as [Purchase Pack Description],mreq.PurchPackQty as [Purchase Pack Qty],
				 mreq.AltSellPackage1 as [Alt Sell Package1],mreq.AltSellPackage1UPC as [Alt Sell Package1 UPC],
				 mreq.AltSellPackage1Qty as [Alt Sell Package1 Qty],mreq.AltSellPackage1Retail as [Alt Sell Package1 Retail],
				 cast((mreq.Cost - mreq.PromoAllowance) AS Numeric(10,2)) AS [Net Cost],
				 cast(cast(CASE WHEN (mreq.SuggestedRetail > 0) THEN
						   ((mreq.SuggestedRetail - (mreq.Cost - mreq.PromoAllowance)) / mreq.SuggestedRetail * 100) 
					   ELSE 0 END AS NUMERIC(10, 2)) as varchar(10)) + ''%''  AS [Margin %],'
		 
		 IF(@isPDIUSer='True')
			 set @sqlQuery = @sqlQuery + ' p2.ProductCategoryName as [Category], '
         else 
			set @sqlQuery = @sqlQuery + ' '''' as [Category], '

		 set @sqlQuery = @sqlQuery + ' pc3.ProductCategoryName  as [Sub Category], '
         
		if(@AccessLevel = 'Chain') 
			set @sqlQuery = @sqlQuery + '''False'' AS ShowEditColumn,'	
			
		else if(@SupplierId='-1') 
			set @sqlQuery = @sqlQuery + '''False'' AS ShowEditColumn,'
			
		else if(@Status>'1') 
			set @sqlQuery = @sqlQuery + '''False'' AS ShowEditColumn,'	
			
		else
			set @sqlQuery = @sqlQuery + '''True'' AS ShowEditColumn,'	
	 
		set @sqlQuery = @sqlQuery + ' CASE WHEN MarkDeleted = 1 THEN 0 WHEN mreq.Banner like ''%Shop N Save%'' and mreq.StartDateTime > GetDate() and convert(varchar(10), StartDateTime, 101) <= convert(varchar(10),dateadd(d,3, GETDATE()), 101) THEN 0
										else 1  END As Deletable,
										convert(Date, mreq.ApprovalDateTime, 101) as [Date Approved], 
										--mreq.DenialReason as [Denial/Delete Reason], 
										--(mreq.DeleteReason + '' ('' + convert(varchar(10), mreq.DeleteDateTime, 101) + '') ''  ) as DeleteReason,
										prnc.FirstName + '' '' + prnc.LastName as [Retailer Recipient] ,
										InCompliance,mreq.OwnerMarketID ,
										cast(P.UnitPrice as numeric(10,3)) as [Harmony Current Cost] '
	if(@AllRqstStatus = '1')
		  set @sqlQuery = @sqlQuery +' ,Mt.RequestTypeDescription as [Request Description],s.StatusDescription as [Denial/Delete Reason],(s.StatusDescription + '' ('' + convert(varchar(10), mreq.DeleteDateTime, 101) + '') ''  ) as DeleteReason '
	else
		  set @sqlQuery = @sqlQuery +' ,mreq.DenialReason as [Denial/Delete Reason],(mreq.DeleteReason + '' ('' + convert(varchar(10), mreq.DeleteDateTime, 101) + '') ''  ) as DeleteReason '		
		  
		  set @sqlQuery = @sqlQuery +' into [#tmpMaintenanceRequest]              
									FROM  dbo.MaintenanceRequests AS mreq with(nolock) 
									INNER JOIN MaintananceRequestsTypes Mt  with(nolock)  ON mreq.RequestTypeID=Mt.RequestType
									INNER JOIN dbo.Suppliers AS sup  with(nolock)  ON mreq.SupplierId = sup.SupplierId 
									INNER JOIN dbo.Chains AS ch with(nolock)  ON mreq.ChainId = ch.ChainId 
									Inner join SupplierBanners SB with(nolock)  on SB.SupplierId = mreq.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.Banner '
		if(@AllRqstStatus = '1')
			 set @sqlQuery = @sqlQuery +' inner join Statuses s on mreq.requeststatus=s.StatusIntValue and s.StatusTypeID=20 '

			set @sqlQuery = @sqlQuery +' Left Join DealContracts dc with(nolock)  on dc.DealNumber=mreq.DealNumber and dc.SupplierId = mreq.SupplierId 
									Left Join ProductCategories pc3 with(nolock)  on pc3.ProductCategoryID=mreq.ProductCategoryID
									left join logins lgn with(nolock) on lgn.OwnerEntityId = mreq.SupplierLoginID
									left join persons prn with(nolock) on prn.Personid = lgn.OwnerEntityID
									left join persons prnc with(nolock) on prnc.Personid = mreq.ChainLoginID '
			
			set @sqlQuery = @sqlQuery +'left join (Select distinct IdentifierValue, ProductName, T.VIN, T.OwnerPackageDescription as VinDesc, T.SupplierID 
													from Products P WITH(NOLOCK)
													inner join ProductIdentifiers PD WITH(NOLOCK) on PD.ProductId=P.ProductId and PD.ProductIdentifierTypeId=2
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID
												) Prod on Prod.IdentifierValue = mreq.UPC and Prod.SupplierID = mreq.SupplierID and Prod.VIN=mreq.VIN and mreq.RequestTypeId>1'
		
			set @sqlQuery = @sqlQuery +' left JOIN (
													Select DISTINCT P.SupplierId, ChainId, PD.IdentifierValue as UPC, UnitPrice, T.VIN
													from ProductPrices P WITH (NOLOCK)
													INNER JOIN ProductIdentifiers PD WITH (NOLOCK) on PD.ProductID=P.ProductID AND PD.ProductIdentifierTypeID=2
													left join SupplierPackages T WITH(NOLOCK) on T.ProductID=P.ProductID and T.SupplierID=P.SupplierID 
													and T.SupplierPackageTypeID=1 --and T.SupplierPackageID=P.SupplierPackageID
													where 1=1 '
			if (@SupplierId<>'-1')
				set @sqlQuery = @sqlQuery + ' and P.SupplierID='+ @SupplierId 
	
			if (@ChainId<>'-1')
				set @sqlQuery = @sqlQuery + ' and P.ChainId='+ @ChainId
			
			set @sqlQuery = @sqlQuery + ' and P.ProductPriceTypeID =11
									AND getdate() BETWEEN P.ActiveStartDate AND P.ActiveLastDate
								  ) P on P.SupplierID=mreq.SupplierID and P.ChainID=mreq.ChainID AND P.UPC=mreq.UPC and P.VIN=mreq.VIN'
			
			IF(@isPDIUSer='True')
			Begin
				set @sqlQuery = @sqlQuery + ' Left JOIN ProductCategories P2 with(nolock)  ON P2.ProductCategoryID=pc3.ProductCategoryParentID '
											 
			END

	if(@ShowStore='1')
		set @sqlQuery = @sqlQuery + ' Left JOIN tmpMaintenanceRequestStores MRS with(nolock)  ON MRS.MaintenanceRequestId= mreq.MaintenanceRequestId'
		
	if(@AllRqstStatus <> '1')
	   Begin
		  set @sqlQuery = @sqlQuery + ' WHERE mreq.RequestStatus not in (999, 17, 18, 15, 16, -30, -333)'
	   end
	else
	    Begin
		  set @sqlQuery = @sqlQuery + ' WHERE mreq.RequestStatus in (999, 17, 18, 15, 16, -30, -333)'
	   end 

	 
	 if(@RequestTypeId <> '-1') 
			set @sqlQuery = @sqlQuery + ' and  mt.RequestType=' + @RequestTypeId
			
	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.ChainId=' + @ChainId

	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.SupplierId=' + @SupplierId

	if(@CostZoneId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and mreq.CostZoneId=' + @CostZoneId
	 
	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and mreq.UPC ' + @UPC 
		
	if(@Bipad<>'') 
		set @sqlQuery = @sqlQuery + ' and mreq.Bipad like ''%' + @Bipad + '%''';
		
	if(@OwnerMarketID <> '') 
		set @sqlQuery = @sqlQuery + ' and mreq.OwnerMarketID like ''%' + @OwnerMarketID + '%''';	
	 
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

	else if(@Status <> -1) 
		set @sqlQuery = @sqlQuery +  ' and (MarkDeleted is null or MarkDeleted=0)' 
		
	--else if(@Status = -1) 
	--	set @sqlQuery = @sqlQuery +  ' and mreq.requeststatus in (0, 5) ' 
		
	if(@BannerName<>'All' and @BannerName<>'') 
		set @sqlQuery = @sqlQuery +  ' and mreq.Banner=''' + @BannerName + ''''

	if(@ShowStore='1' and @StoreNumber<>'')
		set @sqlQuery = @sqlQuery +  ' and MRS.StoreIdentifier ' + @StoreNumber 

	if(@DealNumber<>'-1')
		set @sqlQuery = @sqlQuery +  ' and mreq.DealNumber = ''' + @DealNumber + ''''

	if(@ProductCategoryIDLevel3<>'-1')
		set @sqlQuery = @sqlQuery +  ' and P2.ProductCategoryID = ''' + @ProductCategoryIDLevel3 + ''''
	
	if(@Compliance<>'-1')
		set @sqlQuery = @sqlQuery +  ' and mreq.InCompliance = ''' + @Compliance + ''''		
		
	if(@SupplierIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and sup.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
			
	if(@RetailerIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and ch.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
		
	if(@Category='1')
		set @sqlQuery = @sqlQuery +  ' and (isnull(mreq.Bipad,'''') <> '''')'
	
	else if(@Category='2')
		set @sqlQuery = @sqlQuery +  ' and (isnull(mreq.Bipad,'''') = '''')'	

		
	--Special case for Gopher
	set @sqlQuery = @sqlQuery +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests  with(nolock)  
								   where SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved is null)'	

	if(@ShowStore='1')	
		set @sqlquery =@sqlQuery + ' order by MRS.StoreIdentifier'
	
	--PRINT (@sqlquery);
	--exec (@sqlquery);

Declare @sqlQuery2 varchar(8000)
Declare @UserColumns varchar(1000)

set @sqlQuery2 ='  Select M1.MaintenanceRequestID  as NewItemId, M2.MaintenanceRequestID as CostChangeId 
	into [#tmpDuplicateRecords]
	from MaintenanceRequests M1	 with(nolock) 
	inner join MaintenanceRequests M2 with(nolock)  on M1.SupplierID=M2.SupplierID and M1.ChainID=M2.ChainID 
	and M1.AllStores=M2.AllStores and M1.UPC=M2.UPC and M1.Banner=M2.Banner and M1.StartDateTime=M2.StartDateTime
	where M1.RequestTypeID=1 and M1.RequestStatus<>999  and M1.Cost=0 and (M1.Approved is NULL or M1.Approved = 1) 
	and M2.RequestTypeID=2 and M2.RequestStatus<>999  

	Delete from [#tmpMaintenanceRequest] 
	where MaintenanceRequestId in (Select distinct NewItemId from [#tmpDuplicateRecords])

	Update [#tmpMaintenanceRequest] set Activity=''ADD NEW ITEM'' 
	where MaintenanceRequestId in (Select distinct CostChangeId from [#tmpDuplicateRecords])'

	Select @UserColumns=replace(isnull(C.ColumnNames, ',' + D.Columns + ',' + D.SpecialColumns),',','],[') from CustomColumnsDefine D
	left join CustomColumns C on C.FormName=D.FormID and C.PersonID= @UserId
	where FormID=45 
	
	if(@UserColumns='' or @UserColumns is null)
		set @UserColumns='*'
	else
		set @UserColumns= RIGHT(@UserColumns,len(@UserColumns)-2) + '], MaintenanceRequestID,SupplierEmailId, filename '
	
	set @sqlQuery2 += 'Select distinct  ' + @UserColumns + ', case when InCompliance =1 then ''True'' else ''False'' end as [Lead Time Compliance] '
		
	if(@AllRqstStatus = '1')
		set @sqlQuery2 += ' ,[Request Description] '
	
	set @sqlQuery2 += ' from [#tmpMaintenanceRequest]  where 1=1 '
		
	print (@sqlQuery)
	print (@sqlQuery2)	
	exec (@sqlQuery + @sqlQuery2)
 
	end try

	begin catch
	
			IF OBJECT_ID('#tmpMaintenanceRequest','U') IS NOT NULL 
				begin 
					Drop Table [#tmpMaintenanceRequest]
				end
			IF OBJECT_ID('tempdb.#tmpDuplicateRecords','U') IS NOT NULL 
				begin
					Drop Table [#tmpDuplicateRecords]
				end
	end catch
END
GO
