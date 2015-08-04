USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetStoreSetupId]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetStoreSetupId]
@UserId nvarchar(100),
@ChainName nvarchar(50),
@StoreNumber nvarchar(50),
@UPC nvarchar(20)

as

Begin

 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'Select distinct StoreSetupId from StoreSetup SS
					inner join Chains C on C.ChainID=SS.ChainID
					inner join Stores S on S.StoreID=SS.StoreID and C.ChainID=S.ChainID
					inner join Suppliers SP on SP.SupplierID=SS.SupplierID
					inner join PersonsAssociation PA on  SP.SupplierID=PA.ChainIDOrSupplierID 
					inner join Logins L on PA.PersonID=L.OwnerEntityId
					inner join ProductIdentifiers PD on PD.ProductID=SS.ProductID and PD.ProductIdentifierTypeId=2
                WHERE  1=1'

	if(@ChainName<>'')
		set @sqlQuery = @sqlQuery +  ' and C.ChainName=''' + @ChainName  + ''''
    
    if(@StoreNumber<>'')
		set @sqlQuery = @sqlQuery +  ' and S.StoreIdentifier=''' + @StoreNumber  + ''''
    
    if(@UPC<>'')
		set @sqlQuery = @sqlQuery +  ' and PD.IdentifierValue like ''%' + @UPC  + '%'''
 
 Exec(@sqlQuery);

End
GO
