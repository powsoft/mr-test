USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_MaintenanceRequests_Alcohol_PDI_Beta]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_MaintenanceRequests_Alcohol_PDI_Beta]
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
 @ProductCategoryIDLevel1 varchar(10), 
 @ProductCategoryIDLevel2 varchar(10),
 @ProductCategoryIDLevel3 varchar(10)
 
as
-- exec [usp_MaintenanceRequests_Alcohol_PDI_Beta] 'Supplier',44285, '44270','','1900-01-01','1900-01-01','-1','-1','All',0,'','-1','-1',50334,'1627','-1','-1'
Begin
Declare @sqlQuery varchar(8000)
begin try
	IF OBJECT_ID('@tmpMaintenanceRequest') IS NOT NULL 
	begin 
		Drop Table [@tmpMaintenanceRequest]
	end
	IF OBJECT_ID('@tmpDuplicateRecords') IS NOT NULL 
	begin
		Drop Table [@tmpDuplicateRecords]
	end
	if(@AccessLevel = 'Supplier') 
		begin
				set @sqlQuery = 'SELECT mreq.MaintenanceRequestID, 
					CASE WHEN RequestTypeID = 1 THEN ''New Item'' 
					WHEN RequestTypeID = 2 THEN ''Cost Change'' 
					WHEN RequestTypeID = 3 THEN ''Promo'' 
					WHEN RequestTypeID = 6 THEN ''Substitute''
					ELSE '''' END AS Activity, ch.ChainName  as Client, ';
		end
	else
		begin
				set @sqlQuery = 'SELECT distinct mreq.MaintenanceRequestID, mreq.SupplierId, mreq.ChainId, mreq.CostZoneId,mreq.RequestTypeID,
					CASE WHEN RequestTypeID = 1 THEN ''New Item'' 
					WHEN RequestTypeID = 2 THEN ''Cost Change'' 
					WHEN RequestTypeID = 3 THEN ''Promo'' 
					WHEN RequestTypeID = 6 THEN ''Substitute''
					ELSE '''' END  as Activity, sup.SupplierName  as Client, ';
		end

	if(@ShowStore='1')
		set @sqlQuery = @sqlQuery + ' MRS.StoreIdentifier as [Store#], '
	else 
		set @sqlQuery = @sqlQuery + 'CASE WHEN AllStores = 1 THEN ''All'' 
										  ELSE ''Multiple'' END AS Store#, '
	

	set @sqlQuery = @sqlQuery +  'mreq.Banner as Division, 

	(SELECT  CostZoneName AS [Cost Zone]  FROM dbo.CostZones
	   WHERE (CostZoneId = mreq.CostZoneID)) AS [Cost Zone],
	   
	mreq.UPC, mreq.ItemDescription as Item, mreq.DealNumber, isnull(dc.filename,'''') as filename,
	convert(varchar(10), mreq.SubmitDateTime, 101) as [Date Submitted], 
	convert(varchar(10), mreq.StartDateTime, 101) as [Start Date], 
	convert(varchar(10), mreq.EndDateTime, 101) as [End Date], 
                    (SELECT  dbo.Persons.FirstName + '' '' + dbo.Persons.LastName AS Expr1
                        FROM dbo.Logins INNER JOIN dbo.Persons ON dbo.Logins.OwnerEntityId = dbo.Persons.PersonID
                        WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS [Submitted By], 
                        
                        (SELECT  dbo.Logins.Login
                        FROM dbo.Logins 
                        WHERE (dbo.Logins.OwnerEntityId = mreq.SupplierLoginID)) AS SupplierEmailId, 
                        cast(mreq.CurrentSetupCost as numeric(10,3)) as [Current Cost], 
                        cast(mreq.Cost as numeric(10,3)) as [New Cost], 
                        cast(mreq.SuggestedRetail as numeric(10,2)) as MSRP, 
                        
CASE WHEN PromoTypeID = 1 THEN ''OI'' 
WHEN PromoTypeID = 2 THEN ''BB'' 
WHEN PromoTypeID = 3 THEN ''CC'' 
ELSE '''' END AS [Promo Type], 

mreq.PromoAllowance as [Promo Allowance], 
mreq.EmailGeneratedToSupplier as [Confirmation Email], convert(varchar(10),mreq.EmailGeneratedToSupplierDateTime, 101) as [Confirmation Date], 
                  
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
         as [Primary Sellable Pkg Qty],mreq.VIN,mreq.VINDescription as [VIN Description],
         mreq.PurchPackDescription as [Purchase Pack Description],mreq.PurchPackQty as [Purchase Pack Qty],
         mreq.AltSellPackage1 as [Alt Sell Package1],mreq.AltSellPackage1UPC as [Alt Sell Package1 UPC],
         mreq.AltSellPackage1Qty as [Alt Sell Package1 Qty],mreq.AltSellPackage1Retail as [Alt Sell Package1 Retail],p1.ProductCategoryName as [Category Level1],p2.ProductCategoryName as [Category Level2],pc3.ProductCategoryName  as [Category Level3], '
         
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
convert(varchar(10), mreq.ApprovalDateTime, 101) as [Date Approved], mreq.DenialReason as [Denial/Delete Reason], 
(mreq.DeleteReason + '' ('' + convert(varchar(10), mreq.DeleteDateTime, 101) + '') ''  ) as DeleteReason,
                    
(SELECT Persons_1.FirstName + '' '' + Persons_1.LastName AS Expr1
	FROM dbo.Logins AS Logins_1 INNER JOIN dbo.Persons AS Persons_1 ON Logins_1.OwnerEntityId = Persons_1.PersonID
	WHERE (Logins_1.OwnerEntityId = mreq.ChainLoginID)) AS [Retailer Recipient]

into [@tmpMaintenanceRequest]              
FROM  dbo.MaintenanceRequests AS mreq 
INNER JOIN dbo.Suppliers AS sup ON mreq.SupplierId = sup.SupplierId 
INNER JOIN dbo.Chains AS ch ON mreq.ChainId = ch.ChainId 
Inner join SupplierBanners SB on SB.SupplierId = mreq.SupplierId and SB.Status=''Active'' and SB.Banner=mreq.Banner
Left Join DealContracts dc on dc.DealNumber=mreq.DealNumber and dc.SupplierId = mreq.SupplierId 
Left Join ProductCategories pc3 on pc3.ProductCategoryID=mreq.ProductCategoryID
JOIN ProductCategories P2 ON P2.ProductCategoryID=pc3.ProductCategoryParentID
JOIN ProductCategories p1 ON p1.ProductCategoryID=P2.ProductCategoryParentID
'

if(@ShowStore='1')
	set @sqlQuery = @sqlQuery + ' Left JOIN DataTrue_CustomResultSets.dbo.tmpMaintenanceRequestStores MRS ON MRS.MaintenanceRequestId= mreq.MaintenanceRequestId'


set @sqlQuery = @sqlQuery + ' WHERE mreq.RequestStatus not in (999, 17, 18, 15, 16, -30, -333)'
 
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

else if(@Status <> -1) 
	set @sqlQuery = @sqlQuery +  ' and (MarkDeleted is null or MarkDeleted=0)' 
	
if(@BannerName<>'All' and @BannerName<>'') 
	set @sqlQuery = @sqlQuery +  ' and mreq.Banner=''' + @BannerName + ''''

if(@ShowStore='1' and @StoreNumber<>'')
	set @sqlQuery = @sqlQuery +  ' and MRS.StoreIdentifier like ''%' + @StoreNumber + '%'''

if(@DealNumber<>'-1')
	set @sqlQuery = @sqlQuery +  ' and mreq.DealNumber = ''' + @DealNumber + ''''

if(@ProductCategoryIDLevel3<>'-1')
	set @sqlQuery = @sqlQuery +  ' and mreq.ProductCategoryID = ''' + @ProductCategoryIDLevel3 + ''''
if(@ProductCategoryIDLevel3='-1' and @ProductCategoryIDLevel2<>'-1')
	set @sqlQuery = @sqlQuery +  ' and P2.ProductCategoryID = ''' + @ProductCategoryIDLevel2 + ''''
if(@ProductCategoryIDLevel3='-1' and @ProductCategoryIDLevel2 = '-1' and @ProductCategoryIDLevel1<>'-1')
	set @sqlQuery = @sqlQuery +  ' and P1.ProductCategoryID = ''' + @ProductCategoryIDLevel1 + ''''
	
--Special case for Gopher
set @sqlQuery = @sqlQuery +  ' and mreq.MaintenanceRequestID not in (Select MaintenanceRequestID from MaintenanceRequests where SupplierID=40558 and  SkipPopulating879_889Records = 0 and Approved is null)'

if(@ShowStore='1')	
	set @sqlquery =@sqlQuery + ' order by MRS.StoreIdentifier'
PRINT @sqlQuery;
exec (@sqlQuery);

Select M1.MaintenanceRequestID  as NewItemId, M2.MaintenanceRequestID as CostChangeId 
into [@tmpDuplicateRecords]
from MaintenanceRequests M1	
inner join MaintenanceRequests M2 on M1.SupplierID=M2.SupplierID and M1.ChainID=M2.ChainID 
and M1.AllStores=M2.AllStores and M1.UPC=M2.UPC
where M1.RequestTypeID=1 and M1.RequestStatus<>999 and M1.Approved is null and M1.Cost=0
and M2.RequestTypeID=2 and M2.RequestStatus<>999 and M2.Approved is null 

Delete from [@tmpMaintenanceRequest] 
where MaintenanceRequestId in (Select distinct NewItemId from [@tmpDuplicateRecords])

Update [@tmpMaintenanceRequest] set Activity='New Item' 
where MaintenanceRequestId in (Select distinct CostChangeId from [@tmpDuplicateRecords])

	declare @UserColumns varchar(1000)
	Select @UserColumns=replace(isnull(C.ColumnNames, ',' + D.Columns),',','],[') from CustomColumnsDefine D
	left join CustomColumns C on C.FormName=D.FormID and C.PersonID=@UserId
	where FormID=45 
	
	
	if(@UserColumns='' or @UserColumns is null)
		set @UserColumns='*'
	else
		set @UserColumns= RIGHT(@UserColumns,len(@UserColumns)-2) + '], MaintenanceRequestID,SupplierEmailId, filename ' 
	print @UserColumns;
	set @sqlQuery='	Select ' + @UserColumns + ' from [@tmpMaintenanceRequest]  where 1=1 '

	if (@RequestTypeId = '1')
		set @sqlQuery+= ' and Activity = ''New Item'''

	else if (@RequestTypeId = '2')
		set @sqlQuery+= ' and  Activity = ''Cost Change'''

	else if (@RequestTypeId = '3')
		set @sqlQuery+= ' and Activity = ''Promo'''

	else if (@RequestTypeId = '6')
		set @sqlQuery+= ' and Activity = ''Substitute'''
	
	print @sqlQuery
	exec(@sqlQuery)
	
	
      IF OBJECT_ID('@tmpMaintenanceRequest') IS NOT NULL 
			begin 
				Drop Table [@tmpMaintenanceRequest]
			end
		IF OBJECT_ID('@tmpDuplicateRecords') IS NOT NULL 
		begin
			Drop Table [@tmpDuplicateRecords]
		end
	end try

	begin catch
		
		IF OBJECT_ID('@tmpMaintenanceRequest') IS NOT NULL 
			begin 
				Drop Table [@tmpMaintenanceRequest]
			end
		IF OBJECT_ID('tempdb.@tmpDuplicateRecords') IS NOT NULL 
		begin
			Drop Table [@tmpDuplicateRecords]
		end
	end catch

End
GO
