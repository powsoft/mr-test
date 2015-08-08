USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iphone_GetStoreList]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_iphone_GetStoreList]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreName varchar(50),
 @StoreNo varchar(50),
 @BannerName varchar(50),
 @City varchar(50),
 @State varchar(50),
 @ZipCode varchar(50)
 
 --exec [usp_iphone_GetStoreList] '40557', '-1', '68'
as

Begin
Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'SELECT  top 100 S.StoreName AS [Store Name], S.StoreIdentifier AS [Store Number],
				S.Custom1 AS Banner, S.Custom2 AS [SBT Number], S.StoreSize AS Size,
				(A.Address1 + '' '' + A.Address2) as [Street Address],
				 A.City, A.State, A.PostalCode as [Zip Code], Z.Latitude, Z.Longitude ,
				convert(varchar(10), S.ActiveFromDate, 101) AS [Active From Date], 
				convert(varchar(10), S.ActiveLastDate, 101) AS [Active Last Date]
				  
			FROM  Stores  S
			INNER JOIN Addresses A ON S.StoreID = A.OwnerEntityID 
			left join fcMaps_Zipcodes Z on Z.ZipCode=A.PostalCode '
			
		
		set @sqlQuery  = @sqlQuery  + ' WHERE 1=1 '

		if(@SupplierId <>'-1' )	
			set @sqlQuery = @sqlQuery + ' and S.StoreId in (select distinct StoreId from StoreSetup where Supplierid = ''' + @SupplierId + ''')'
			
		if(@ChainId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and S.ChainID = ''' + @ChainId + ''''
			
		if(@StoreName <>'') 
			set @sqlQuery  = @sqlQuery  + ' and S.StoreName like ''%' + @StoreName + '%'''
			
		if(@StoreNo <>'') 
			set @sqlQuery  = @sqlQuery  + ' and S.StoreIdentifier like ''%' + @StoreNo + '%'''
			
		if(@BannerName <>'-1') 
			set @sqlQuery  = @sqlQuery  + ' and S.Custom1 like ''%' + @BannerName + '%'''
			
		if(@City <>'') 
			set @sqlQuery  = @sqlQuery  + ' and A.City like ''%' + @City + '%'''
			
		if(@State <>'') 
			set @sqlQuery  = @sqlQuery  + ' and A.State like ''%' + @State + '%'''
			
		if(@ZipCode <>'') 
			set @sqlQuery  = @sqlQuery  + ' and A.PostalCode like ''%' + @ZipCode + '%'''
		
		execute(@sqlQuery); 

End
GO
