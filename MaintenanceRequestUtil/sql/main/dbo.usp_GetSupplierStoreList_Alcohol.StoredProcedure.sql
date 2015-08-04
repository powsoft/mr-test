USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSupplierStoreList_Alcohol]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_GetSupplierStoreList_Alcohol] 50729, '-1','','','-1','','TempClose','','','',''
CREATE procedure [dbo].[usp_GetSupplierStoreList_Alcohol]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @StoreNumber varchar(50),
 @State varchar(50),
 @Banner varchar(50),
 @City Varchar(50),
 @Status varchar(10),
 @ZipCode varchar(50),
 @CostZone varchar(50),
 @DriverName varchar(50),
 @Route varchar(50)
as

Begin
Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'SELECT distinct SP.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], S.StoreName AS [Store Name], S.StoreIdentifier AS [Store Number],
				S.Custom1 AS Banner, S.StoreSize AS Cluster, (A.Address1 + '' '' + A.Address2) as [Street Address],
				A.City, A.State, A.PostalCode as [Zip Code], 
				cz.CostZoneName as [Cost Zone]'

		if(@Status='Active')				
			set @sqlQuery  = @sqlQuery  + ' , convert(varchar(10), S.ActiveFromDate, 101) AS [Active From Date], 
											  convert(varchar(10), S.ActiveLastDate, 101) AS [Active Last Date]'
		if(@Status='TempClose')								
			set @sqlQuery  = @sqlQuery  + ' , convert(varchar(10),DateofChange,101) as [Date Closed], 
											  convert(varchar(10),DateToChangeStatusBack,101) as [Reopen Date], Convert(nvarchar(MAX),Reason) '

		if(@Status='Closed')								
			set @sqlQuery  = @sqlQuery  + ' , convert(varchar(10),DateofChange,101) as [Date Closed], Convert(nvarchar(MAX),Reason) '

		set @sqlQuery  = @sqlQuery  + ',SUV.SupplierAccountNumber as [Customer Number], 
										SUV.DriverName as [Driver Name], 
										SUV.RouteNumber as [Route]
										FROM  dbo.Stores S
										Inner join SupplierBanners SB on  SB.Status=''Active'' and SB.Banner=S.Custom1 and isnull(SB.Banner,'''') <>''''
										Inner Join StoreSetup SS on SS.StoreId=S.StoreId and SS.SupplierId=SB.SupplierId and SS.ChainId=SB.ChainId
										Inner Join Suppliers SP on SP.SupplierId=SB.SupplierId
										Inner Join Chains C on C.ChainId=SB.ChainId and C.ChainId=SS.ChainId
										Left Join costZoneRelations czr on czr.StoreId=S.StoreId and czr.SupplierId=SP.SupplierId
										Left join CostZones cz on cz.CostZoneID= czr.CostZoneID'
		
		if(@SupplierId <>'-1' )
			set @sqlQuery  = @sqlQuery  + ' and SB.SupplierId =' + @SupplierId 
                    
		set @sqlQuery  = @sqlQuery  + ' LEFT JOIN dbo.StoresUniqueValues SUV ON S.StoreID = SUV.StoreID and SUV.SupplierId=' + @SupplierId + '
										Left JOIN dbo.Addresses A ON S.StoreID = A.OwnerEntityID '
		if(@Status <> 'Active')				
			set @sqlQuery  = @sqlQuery  + 'Left JOIN dbo.StoreStatus SSs ON S.StoreID = SSs.StoreID '

		set @sqlQuery  = @sqlQuery  + ' WHERE 1=1 '

		if(@SupplierId <>'-1' )	
			set @sqlQuery = @sqlQuery + ' and SP.Supplierid = ''' + @SupplierId + ''''
			
		if(@ChainId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and S.ChainID = ''' + @ChainId + ''''
			
		if(@StoreNumber <>'') 
			set @sqlQuery  = @sqlQuery  + ' and S.StoreIdentifier like ''%' + @StoreNumber + '%''';

		if(@State <> '') 
			set @sqlQuery = @sqlQuery + ' and A.State like ''%' + @State + '%''';

		if(@ZipCode <> '') 
			set @sqlQuery = @sqlQuery + ' and A.PostalCode like ''%' + @ZipCode + '%''';
		
		if(@CostZone <> '') 
			set @sqlQuery = @sqlQuery + ' and cz.CostZoneName like ''%' + @CostZone + '%''';
			
		if(@DriverName <> '') 
			set @sqlQuery = @sqlQuery + ' and SUV.DriverName like ''%' + @DriverName + '%''';
			
		if(@Route <> '') 
			set @sqlQuery = @sqlQuery + ' and SUV.RouteNumber like ''%' + @Route + '%''';
			
		if(@Banner <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and custom1 = ''' + @Banner + ''''

		if(@City <>'') 
			set @sqlQuery = @sqlQuery + ' and city  like ''%' + @City  + '%''';

		if(@Status <> '') 
			set @sqlQuery = @sqlQuery + ' and Activestatus = ''' + @Status + ''''
			
  --print(@sqlQuery); 
  		exec(@sqlQuery); 

End
GO
