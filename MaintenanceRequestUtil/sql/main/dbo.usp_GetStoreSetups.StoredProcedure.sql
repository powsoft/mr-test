USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetStoreSetups]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetStoreSetups]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50),
@Banner varchar(50),
@UPC varchar(50)
as
 
Begin
Declare @sqlQuery varchar(4000)
    set @sqlQuery = 'SELECT distinct 
						SS.StoreSetupId, SP.SupplierName, C.ChainName, S.Custom1 as [Banner],
						S.StoreId, S.StoreIdentifier as [StoreNumber], 
						PD.IdentifierValue AS UPC, P.ProductName, P.ProductId,
						PO.ReplenishmentFrequency,PO.ReplenishmentType, PO.PlanogramCapacityMax, PO.PlanogramCapacityMin, PO.DateRange, PO.FillRate, PO.LeadTime
					FROM dbo.StoreSetup SS
						INNER JOIN dbo.Suppliers SP ON SS.SupplierID= SP.SupplierID
						INNER JOIN dbo.Chains C ON SS.ChainID= C.ChainId
						INNER JOIN dbo.Products P ON SS.ProductID = P.ProductID 
						INNER JOIN dbo.ProductIdentifiers PD ON PD.ProductID = SS.ProductID and PD.ProductIdentifierTypeId in (2,8)
						INNER JOIN dbo.Stores S ON S.StoreId = SS.StoreId and S.ActiveStatus=''Active''
						Inner join SupplierBanners SB on SB.SupplierId = SP.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
						Left Join dbo.PO_Criteria PO on PO.StoreSetupID=SS.StoreSetupID  
						where 1=1 '
           
        if(@SupplierId <>'-1' )   
            set @sqlQuery = @sqlQuery + ' and SS.Supplierid = ' + @SupplierId
           
        if(@ChainId <> '-1' )
            set @sqlQuery = @sqlQuery + ' and SS.ChainID = ''' + @ChainId + ''''
           
        if(@StoreNumber <>'')
            set @sqlQuery  = @sqlQuery  + ' and S.StoreIdentifier like ''%' + @StoreNumber + '%''';
 
        if(@Banner <>'-1' )
            set @sqlQuery = @sqlQuery + ' and S.custom1 = ''' + @Banner + ''''
           
        if(@UPC <>'')
            set @sqlQuery  = @sqlQuery  + ' and PD.IdentifierValue like ''%' + @UPC + '%''';
		
		set @sqlQuery  = @sqlQuery  + ' order by PO.ReplenishmentFrequency Desc'
		
        execute(@sqlQuery);
 
End
GO
