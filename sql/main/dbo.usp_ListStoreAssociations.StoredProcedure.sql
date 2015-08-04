USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ListStoreAssociations]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ListStoreAssociations]
 @ChainId varchar(50),
 @SupplierId varchar(50),
 @StoreNumber varchar(50),
 @StoreNumberContains varchar(50),
 @SBTNumber varchar(50),
 @SBTNumberContains varchar(50),
 @BannerName varchar(50),
 @DistributionCenter Varchar(50),
 @RegionalManager Varchar(50),
 @SupplierIdentifierValue varchar(50),
 @RetailerIdentifierValue varchar(50),
 @StoreDemographic varchar(50)
as
-- exec usp_ListStoreAssociations '62348','-1','','','Walmart','','','','',''
-- exec usp_ListStoreAssociations '60624','24465','','','-1','','','','','','','',''
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'Select distinct (cast(SS.SupplierID as varchar) + '' - '' + cast(S.StoreID as varchar)) as UniqueId,
								SP.SupplierName, 
								S.Custom1 as Banner, 
								cast(S.StoreIdentifier as numeric(10,0)) as [Store Number], 
								SUV.SBTNumber,
								W.WareHouseName as DistributionCenter, 
								SUV.SalesRep, 
								SUV.RegionalMgr,
								SUV.DriverName, 
								SUV.RouteNumber, 
								SUV.SupplierAccountNumber, 
								SUV.Comments,
								AV.AttributeValue AS [Store Demographic],SP.SupplierID,C.ChainId,S.StoreID
						
                    FROM Stores S WITH(NOLOCK)
						INNER JOIN StoreSetup SS WITH(NOLOCK) on SS.StoreId=S.StoreId
						INNER JOIN Suppliers SP WITH(NOLOCK) on SP.SupplierID=SS.SupplierID
						INNER JOIN Chains C WITH(NOLOCK) on C.ChainId=SS.ChainID
						LEFT JOIN StoresUniqueValues SUV WITH(NOLOCK) on S.StoreID=SUV.StoreID  AND SUV.SupplierID=SP.SupplierID
						LEFT JOIN WareHouses W WITH(NOLOCK) on cast(W.WareHouseId as varchar) = SUV.DistributionCenter
						LEFT JOIN AttributeValues AV WITH(NOLOCK) ON AV.OwnerEntityID =S.StoreID  AND AV.AttributeID=33
						
                  WHERE 1=1 and S.ActiveStatus=''Active'' '

	if(@ChainId <>'-1')
		set @sqlQuery  = @sqlQuery  + ' and S.ChainId =' + @ChainId

	if(@SupplierId <>'-1')
		set @sqlQuery  = @sqlQuery  + ' and SP.SupplierID =' + @SupplierId
	
	if(@SupplierIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and SP.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''

   if(@RetailerIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
           
	if(@StoreNumber <>'')
	Begin
			if(@StoreNumberContains = 'Like')
				set @sqlQuery  = @sqlQuery  + ' and cast(S.StoreIdentifier as varchar) like ''%' + @StoreNumber + '%''';
			else
				set @sqlQuery  = @sqlQuery  + ' and cast(S.StoreIdentifier as varchar) = ''' + @StoreNumber + '''';
	end

	if(@SBTNumber <> '')
		Begin
			if(@SBTNumberContains = 'Like')
				set @sqlQuery = @sqlQuery + ' and cast(SUV.SBTNumber as varchar) like ''%' + @SBTNumber + '%''';
			else
				set @sqlQuery = @sqlQuery + ' and cast(SUV.SBTNumber as varchar) = ''' + @SBTNumber + '''';
		end

	if(@BannerName <>'-1')
		set @sqlQuery = @sqlQuery + ' and S.Custom1 = ''' + @BannerName + ''''

	if(@DistributionCenter <>'')
		set @sqlQuery = @sqlQuery + ' and W.WareHouseName  like ''%' + @DistributionCenter  + '%''';

	if(@RegionalManager <>'')
		set @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr  like ''%' + @RegionalManager  + '%''';
	
	if(@StoreDemographic <>'-1')
		set @sqlQuery = @sqlQuery + ' and AV.AttributeValue  = ''' + @StoreDemographic  + '''';
		 
	 set @sqlQuery = @sqlQuery + ' order by 4 '
	
	exec(@sqlQuery);
	print(@sqlQuery);

End
GO
