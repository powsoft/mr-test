USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DeauthorizedStoreAssociation]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_DeauthorizedStoreAssociation]
(
 @ChainId varchar(50),
 @SupplierId varchar(50),
 @StoreNumber varchar(50),
 @StoreNumberContains varchar(50),
 @BannerName varchar(50)
 )
as
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'Select distinct (cast(SS.SupplierID as varchar) + '' - '' + cast(S.StoreID as varchar)) as UniqueId,
								SP.SupplierName, 
								S.Custom1 as Banner, 
								cast(S.StoreIdentifier as numeric(10,0)) as StoreNumber, 
								SP.SupplierID,C.ChainId,S.StoreID,C.ChainName
						
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
	
	
	if(@StoreNumber <>'')
	Begin
			if(@StoreNumberContains = 'Like')
				set @sqlQuery  = @sqlQuery  + ' and cast(S.StoreIdentifier as varchar) like ''%' + @StoreNumber + '%''';
			else
				set @sqlQuery  = @sqlQuery  + ' and cast(S.StoreIdentifier as varchar) = ''' + @StoreNumber + '''';
	end

	

	if(@BannerName <>'-1')
		set @sqlQuery = @sqlQuery + ' and S.Custom1 = ''' + @BannerName + ''''

		 
	 set @sqlQuery = @sqlQuery + ' order by 4 '
	
	exec(@sqlQuery);
	print(@sqlQuery);

End
GO
