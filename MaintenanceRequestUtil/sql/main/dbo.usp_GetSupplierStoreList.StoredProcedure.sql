USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSupplierStoreList]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetSupplierStoreList]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreNumber varchar(50),
 @StoreNumberContains varchar(50),
 @SBTNumber varchar(50),
 @SBTNumberContains varchar(50),
 @Banner varchar(50),
 @City Varchar(50),
 @Status varchar(10),
 @SupplierIdentifierValue varchar(20),
 @RetailerIdentifierValue varchar(20),
 @StoreDemographic Varchar(50)
as
--exec [usp_GetSupplierStoreList] '-1', 60627, '','Like' ,'','Like', '-1','','Active','','','-1'
Begin
Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'SELECT distinct dbo.Stores.StoreID ,C.ChainName as [Retailer Name], S.SupplierName as [Supplier Name],dbo.Stores.StoreName AS [Store Name], 
									dbo.Stores.StoreIdentifier AS [Store Number],
									dbo.Stores.Custom1 AS Banner, dbo.Stores.Custom2 AS [SBT Number],
									dbo.StoresUniqueValues.SupplierAccountNumber as [Supplier Acct No], dbo.StoresUniqueValues.DriverName as [Driver Name], 
									dbo.StoresUniqueValues.RouteNumber as [Route], 
									dbo.Stores.StoreSize AS Size, (dbo.Addresses.Address1 + '' '' + dbo.Addresses.Address2) as [Street Address],
									dbo.Addresses.City, dbo.Addresses.State, dbo.Addresses.PostalCode as [Zip Code], 
									(select top 1 CostZoneName from dbo.CostZones cz, dbo.costZoneRelations czr 
									where cz.SupplierId=sb.SupplierId and cz.CostZoneID= czr.CostZoneID
									and czr.StoreId=Stores.StoreId and czr.SupplierId=cz.SupplierId) as [Cost Zone],
									(select top 1 cz.CostZoneId from dbo.CostZones cz, dbo.costZoneRelations czr 
									where cz.SupplierId=sb.SupplierId and cz.CostZoneID= czr.CostZoneID
									and czr.StoreId=Stores.StoreId and czr.SupplierId=cz.SupplierId) as [Cost Zone Number],
									AV.AttributeValue AS [Store Demographic],
									(select top 1 cz.OwnerMarketId from dbo.CostZones cz, dbo.costZoneRelations czr 
									where cz.SupplierId=sb.SupplierId and cz.CostZoneID= czr.CostZoneID
									and czr.StoreId=Stores.StoreId and czr.SupplierId=cz.SupplierId) as [Owner Market ID] '

		if(@Status='Active')				
			set @sqlQuery  = @sqlQuery  + ' , convert(varchar(10), dbo.Stores.ActiveFromDate, 101) AS [Active From Date], 
						convert(varchar(10), dbo.Stores.ActiveLastDate, 101) AS [Active Last Date]'
		if(@Status='TempClose')								
			set @sqlQuery  = @sqlQuery  + ' , convert(varchar(10),DateofChange,101) as [Date Closed], convert(varchar(10),DateToChangeStatusBack,101) as [Reopen Date], Cast(Reason AS VARCHAR) AS Reason '

		if(@Status='Closed')								
			set @sqlQuery  = @sqlQuery  + ' , convert(varchar(10),DateofChange,101) as [Date Closed] , Cast(Reason AS VARCHAR) AS Reason '

		set @sqlQuery  = @sqlQuery  + ' FROM  dbo.Stores with(NOLOCK)
										Inner join SupplierBanners SB  with(NOLOCK) on  SB.Status=''Active'' and SB.Banner=dbo.Stores.Custom1 and SB.ChainId=Stores.ChainId
										Inner Join StoreSetup SS  WITH (NOLOCK)   on SS.StoreId=Stores.StoreId and SS.SupplierId=SB.SupplierId and SS.ChainId=SB.ChainId
										Inner Join Suppliers S  with(NOLOCK) on S.SupplierId = SB.SupplierId 
										Inner join Chains C  with(NOLOCK) on C.ChainId = dbo.Stores.ChainId
										Left JOIN dbo.Addresses  with(NOLOCK) ON dbo.Stores.StoreID = dbo.Addresses.OwnerEntityID 
										LEFT OUTER JOIN dbo.StoresUniqueValues  with(NOLOCK) ON dbo.Stores.StoreID = dbo.StoresUniqueValues.StoreID and s.Supplierid=dbo.StoresUniqueValues.Supplierid
										LEFT JOIN AttributeValues AV WITH (NOLOCK) ON AV.OwnerEntityID=Stores.StoreID AND AttributeID=33 '
										
										if(@SupplierId <>'-1' )
											set @sqlQuery  = @sqlQuery  + '	and dbo.StoresUniqueValues.SupplierId=' + @SupplierId + ''
										
		if(@Status <> 'Active')				
			set @sqlQuery  = @sqlQuery  + 'Left JOIN dbo.StoreStatus  with(NOLOCK) ON dbo.Stores.StoreID = dbo.StoreStatus.StoreID '

		set @sqlQuery  = @sqlQuery  + ' WHERE dbo.Stores.ActiveStatus=''Active'' '

		if(@SupplierId <>'-1' )
			set @sqlQuery  = @sqlQuery  + ' and S.SupplierId =' + @SupplierId 
				
		if(@ChainId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and dbo.Stores.ChainID = ' + @ChainId 
			
		if(@StoreNumber <>'') 
		Begin
			if(@StoreNumberContains = 'Like')
				set @sqlQuery  = @sqlQuery  + ' and StoreIdentifier like ''%' + @StoreNumber + '%''';
			else
				set @sqlQuery  = @sqlQuery  + ' and StoreIdentifier = ''' + @StoreNumber + '''';
		End

		if(@SBTNumber <> '') 
		Begin
			if(@SBTNumberContains = 'Like')
				set @sqlQuery = @sqlQuery + ' and custom2 like ''%' + @SBTNumber + '%''';
			else
				set @sqlQuery = @sqlQuery + ' and custom2 = ''' + @SBTNumber + '''';
		End

		if(@Banner <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and custom1 = ''' + @Banner + ''''

		if(@City <>'') 
			set @sqlQuery = @sqlQuery + ' and city  like ''%' + @City  + '%''';

		if(@Status <> '') 
			set @sqlQuery = @sqlQuery + ' and Activestatus = ''' + @Status + ''''
  
		if(@SupplierIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and S.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
			
		if(@RetailerIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
			
		if(@StoreDemographic<>'-1' and @StoreDemographic<>'')
			set @sqlQuery = @sqlQuery + ' and AV.AttributeValue = ''' + @StoreDemographic + ''''
			
		exec(@sqlQuery); 
		print @sqlQuery

End
GO
