USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GTIN_Report]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GTIN_Report 'Test123'
CREATE procedure [dbo].[usp_GTIN_Report]

 @GTIN varchar(50)
 
as
Begin
 Declare @sqlQuery varchar(5000)
 
	set @sqlQuery = 'select P1.IdentifierValue as GTIN, P2.IdentifierValue as UPC, P3.IdentifierValue as [UniqueEntityProductId], ProductIdentifierTypeName as ProductIdType,
						EntityName as [Entity Name], EntityType as  [Entity Type]
						from ProductIdentifiers  p1
						inner join ProductIdentifiers P2 on P2.ProductIdentifierTypeID=2 and P2.ProductID=P1.ProductId
						left join (select productid, IdentifierValue, T.ProductIdentifierTypeName, isnull(SupplierName, ISNULL(chainname,ManufacturerName)) as EntityName,
									CASE WHEN E.EntityTypeID=2 THEN ''Retailer'' when E.EntityTypeID=5 then ''Supplier'' when E.EntityTypeID=11 then ''Manufacturer'' end as EntityType
									from ProductIdentifiers P
									inner join ProductIdentifierTypes T on T.ProductIdentifierTypeID=P.ProductIdentifierTypeID
									INNER JOIN SystemEntities E ON E.EntityId=P.OwnerEntityId
									left JOIN Suppliers S on S.SupplierID=P.OwnerEntityId
									left JOIN Chains C on C.ChainID=P.OwnerEntityId
									left JOIN Manufacturers M on M.ManufacturerID=P.OwnerEntityId
									where P.ProductIdentifierTypeID not in (2,12)) p3 on p3.productid =p1.ProductID 
						where P1.ProductIdentifierTypeID =12 '
             
   if(@GTIN <>'')
     set @sqlQuery = @sqlQuery +  ' and P1.IdentifierValue LIKE ''%' + @GTIN + '%'''
                
	EXEC (@sqlQuery);
   
End
GO
