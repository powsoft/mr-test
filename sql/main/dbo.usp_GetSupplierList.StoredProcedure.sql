USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSupplierList]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [usp_GetSupplierList] '44285','','','','',''
CREATE  procedure [dbo].[usp_GetSupplierList]
 @ChainId varchar(20),
 @Name varchar(20),
 @City varchar(20),
 @State varchar(50),
 @Zip varchar(50),
 @ChainSupplierIdentifier varchar(50)
 
as

Begin
		Declare @sqlQuery varchar(4000)
		SELECT SupplierID AS ID
			 , SupplierName  AS [Name]
			 , isnull(Address1, '') AS Address1
			 , isnull(Address2, '') AS Address2
			 , isnull(City, '') AS City
			 , isnull(CountyName, '') AS [County Name]
			 , isnull(State, '') AS State
			 , isnull(PostalCode, '') AS [Postal Code]
			 , isnull(Country, '') AS Country
			 , 'Supplier' AS AddressType

		FROM Suppliers S WITH (NOLOCK)
		LEFT JOIN Addresses A WITH (NOLOCK) ON A.OwnerEntityID = S.SupplierID 
			AND City LIKE '%' + @City + '%'
			AND State LIKE '%' + @State + '%'
			AND [PostalCode] LIKE '%' + @Zip + '%'
		WHERE
			S.SupplierID IN (SELECT DISTINCT SupplierId FROM SupplierBanners WITH (NOLOCK)
							 WHERE ChainId = @ChainId and SupplierID>0)
			AND SupplierName LIKE '%' + @Name + '%'
			AND SupplierIdentifier LIKE '%' + @ChainSupplierIdentifier + '%'

		UNION
				
		SELECT C.ChainID AS ID
			 , C.ChainName  AS [Name]
			 , isnull(Address1, '') AS Address1
			 , isnull(Address2, '') AS Address2
			 , isnull(City, '') AS City
			 , isnull(CountyName, '') AS [County Name]
			 , isnull(State, '') AS State
			 , isnull(PostalCode, '') AS [Postal Code]
			 , isnull(Country, '') AS Country
			 , 'Chain' AS AddressType

		FROM
			Chains C WITH (NOLOCK)
			LEFT JOIN Addresses A WITH (NOLOCK) ON A.OwnerEntityID = C.ChainID
			AND City LIKE '%' + @City + '%'
			AND State LIKE '%' + @State + '%'
			AND [PostalCode] LIKE '%' + @Zip + '%'
		WHERE
			C.ChainID = @ChainId
			AND ChainName LIKE '%' + @Name + '%'
			AND ChainIdentifier LIKE '%' + @ChainSupplierIdentifier + '%'
		Order by 10,2			
End
GO
