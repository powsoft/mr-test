USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetStoreList]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetStoreList]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreNumber varchar(50),
 @SBTNumber varchar(50),
 @Banner varchar(50),
 @City Varchar(50),
 @Status varchar(10)
as

Begin
Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'SELECT  dbo.Stores.StoreId, dbo.Stores.StoreName AS [Store Name], dbo.Stores.StoreIdentifier AS [Store Number],
				dbo.Stores.Custom1 AS Banner, dbo.Stores.Custom2 AS [SBT Number],
				dbo.Stores.StoreSize AS Size, (dbo.Addresses.Address1 + '' '' + dbo.Addresses.Address2) as [Street Address],
				dbo.Addresses.City, dbo.Addresses.State, dbo.Addresses.PostalCode as [Zip Code], '

		if(@Status='Active')				
			set @sqlQuery  = @sqlQuery  + ' convert(varchar(10), dbo.Stores.ActiveFromDate, 101) AS [Active From Date], 
						convert(varchar(10), dbo.Stores.ActiveLastDate, 101) AS [Active Last Date]'
		if(@Status='TempClose')								
			set @sqlQuery  = @sqlQuery  + ' convert(varchar(10),DateofChange,101) as [Date Closed], convert(varchar(10),DateToChangeStatusBack,101) as [Reopen Date], Reason '

		if(@Status='Closed')								
			set @sqlQuery  = @sqlQuery  + ' convert(varchar(10),DateofChange,101) as [Date Closed], Reason '

		set @sqlQuery  = @sqlQuery  + ' FROM  dbo.Stores 
					INNER JOIN dbo.Addresses ON dbo.Stores.StoreID = dbo.Addresses.OwnerEntityID '
		if(@Status <> 'Active')				
			set @sqlQuery  = @sqlQuery  + 'INNER JOIN dbo.StoreStatus ON dbo.Stores.StoreID = dbo.StoreStatus.StoreID '

		set @sqlQuery  = @sqlQuery  + ' WHERE 1=1 '

		if(@SupplierId <>'-1' )	
			set @sqlQuery = @sqlQuery + ' and dbo.Stores.StoreId in (select distinct StoreId from StoreSetup where Supplierid = ''' + @SupplierId + ''')'
			
		if(@ChainId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and dbo.Stores.ChainID = ''' + @ChainId + ''''
			
		if(@StoreNumber <>'') 
			set @sqlQuery  = @sqlQuery  + ' and StoreIdentifier like ''%' + @StoreNumber + '%''';

		if(@SBTNumber <> '') 
			set @sqlQuery = @sqlQuery + ' and custom2 like ''%' + @SBTNumber + '%''';

		if(@Banner <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and custom1 = ''' + @Banner + ''''

		if(@City <>'') 
			set @sqlQuery = @sqlQuery + ' and city  like ''%' + @City  + '%''';

		if(@Status <> '') 
			set @sqlQuery = @sqlQuery + ' and Activestatus = ''' + @Status + ''''
  
		execute(@sqlQuery); 

End
GO
