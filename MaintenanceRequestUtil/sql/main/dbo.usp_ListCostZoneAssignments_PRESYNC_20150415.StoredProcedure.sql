USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ListCostZoneAssignments_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ListCostZoneAssignments_PRESYNC_20150415]
 
 @SupplierId varchar(50),
 @ChainId varchar(50),
 @StoreNumber varchar(50),
 @StoreNumberContains varchar(50),
 @SBTNumber varchar(50),
 @SBTNumberContains varchar(50),
 @BannerId varchar(50),
 @CostZoneId varchar(50)
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'SELECT SP.SupplierName as [Supplier Name], 
						  C.ChainName as [Chain Name], 
						  S.StoreName as [Store Name], 
						  S.StoreIdentifier as [Store Number], 
						  S.SBTNumber as [SBT Number], 
						  S.Custom1 as Banner, 
						  CZ.CostZoneName as [Cost Zone Name], 
						  CZ.CostZoneDescription as [Cost Zone Description],
						  CZ.OwnerMarketID [Owner Market ID],
						  A.City, 
						  A.State, 
						  A.PostalCode as [Zip Code],
						  CZR.CostZoneRelationID,
						  CZ.CostZoneID as [MR Template Cost Zone]
				  FROM CostZoneRelations CZR WITH(NOLOCK)
				  INNER JOIN Stores S WITH(NOLOCK) ON CZR.StoreID = S.StoreID 
				  INNER JOIN Chains C WITH(NOLOCK) ON S.ChainID = C.ChainID 
				  INNER JOIN Suppliers SP WITH(NOLOCK) ON SP.SupplierId = CZR.SupplierId
				  INNER JOIN Addresses A WITH(NOLOCK) ON A.OwnerEntityID = S.StoreID 
				  INNER JOIN CostZones CZ WITH(NOLOCK) ON CZR.CostZoneID = CZ.CostZoneId
				  WHERE 1=1 and S.Activestatus =''Active'' '
				  
				if(@SupplierId <>'-1') 
				  set @sqlQuery  = @sqlQuery  + '  AND CZR.SupplierID =' + @SupplierId 
				 
				if(@ChainId <>'-1') 
				  set @sqlQuery  = @sqlQuery  + '  AND C.ChainId =' + @ChainId 

				if(@StoreNumber <>'') 
				begin
					if(@StoreNumberContains = 'Like')
						set @sqlQuery  = @sqlQuery  + ' AND S.StoreIdentifier like ''%' + @StoreNumber + '%''';
					else
						set @sqlQuery  = @sqlQuery  + ' AND S.StoreIdentifier = ''' + @StoreNumber + '''';
				end

				if(@SBTNumber <> '') 
				Begin
					if(@SBTNumberContains = 'Like')
						set @sqlQuery = @sqlQuery + ' AND S.SBTNumber like ''%' + @SBTNumber + '%''';
					else
						set @sqlQuery = @sqlQuery + ' AND S.SBTNumber = ''' + @SBTNumber + '''';
				end

				if(@BannerId='') 
					set @sqlQuery = @sqlQuery + ' AND S.custom1 is Null'

				else if(@BannerId<>'-1') 
					set @sqlQuery = @sqlQuery + ' AND S.custom1=''' + @BannerId + ''''
 
				if(@CostZoneId<>'-1') 
					set @sqlQuery = @sqlQuery +  ' and CZ.CostZoneID=' + @CostZoneId
			
		EXEC(@sqlQuery); 
End
GO
