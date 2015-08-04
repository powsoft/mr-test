USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewBaseDrawHistoryWHL_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_ViewBaseDrawHistoryWHL 'TA','PA','-1','','WR1428','24503'
--exec amb_ViewBaseDrawHistoryWHL 'BN','-1','-1','','ENT','24178'
--exec amb_ViewBaseDrawHistoryWHL 'TA','-1','-1','','WR1428','24503'
CREATE PROCEDURE [dbo].[amb_ViewBaseDrawHistoryWHL_Beta]
(
	@ChainID VARCHAR(10) ,
	@State VARCHAR(10) ,
	@Title VARCHAR(50) ,
	@StoreNumber VARCHAR(10) ,
	@supplieridentifier varchar(10),
	@supplierid varchar(10)
	/*@OrderBy varchar(100),
	@StartIndex int,
	@PageSize int,
	@DisplayMode int*/
)
AS 
BEGIN

	DECLARE @sqlQuerynewDB VARCHAR(8000)
	
	SET @sqlQuerynewDB =  ' Select  (''Store Number: '' + S.StoreIdentifier + ''; Account Number: '' + 
							S.LegacySystemStoreIdentifier + '';/n Location: '' + S.StoreName + '', '' + A.Address1 + '', '' + 
							A.City + '', '' + A.State + '', '' + A.PostalCode ) as StoreInfo, S.LegacySystemStoreIdentifier as StoreID,
							c.ChainIdentifier as chainid ,p.ProductName AS Title,p.ProductName AS TitleName,pid.Bipad, 
							sup.SupplierIdentifier as wholesalerid ,pp.unitprice as CostToStore,pp.UnitRetail AS SuggRetail,  
							ss.MonLimitQty as Mon ,	ss.TueLimitQty as Tue,ss.WedLimitQty as Wed, ss.ThuLimitQty as Thur , 
							ss.FriLimitQty as Fri ,	ss.SatLimitQty as Sat,ss.SunLimitQty as Sun,Convert(Varchar(12),
							pp.ActiveStartDate,101) as  CostStartDate,Convert(Varchar(12),pp.ActiveLastDate,101) as CostEndDate,
							Convert(Varchar(12),SS.ActiveStartDate,101) as ProductStartDate,Convert(Varchar(12),
							SS.ActiveLastDate,101) as ProductEndDate 
                            
							From DataTrue_Report.dbo.StoreSetup SS 
							INNER JOIN DataTrue_Report.dbo.Products p on p.ProductID=ss.ProductID
							INNER JOIN DataTrue_Report.dbo.stores s on s.StoreID=ss.StoreID AND s.ChainID=ss.ChainID
							INNER JOIN DataTrue_Report.dbo.ProductPrices pp on pp.SupplierID=SS.SupplierID 
							AND pp.ChainID=SS.ChainID 
							AND pp.ProductID=p.ProductID
							INNER JOIN DataTrue_Report.dbo.Suppliers sup on sup.SupplierID=ss.SupplierID
							INNER JOIN DataTrue_Report.dbo.Chains c on ss.ChainID=c.ChainID 
							INNER JOIN DataTrue_Report.dbo.ProductIdentifiers pid on pid.ProductID=p.ProductID 
							INNER JOIN DataTrue_Report.dbo.ProductPriceTypes ppt on pp.ProductPriceTypeID=ppt.ProductPriceTypeID 
							INNER JOIN DataTrue_Report.dbo.Addresses a on s.StoreID =a.OwnerEntityID 
							
							WHERE c.ChainIdentifier in (Select chainid from chains_migration) 
							and sup.SupplierId = ' + @supplierid 

	IF ( @State <> '-1' ) 
		SET @sqlQuerynewDB = @sqlQuerynewDB + ' AND a.State = ''' + @State+ ''''

	IF ( @StoreNumber <> '' ) 
		SET @sqlQuerynewDB = @sqlQuerynewDB+ '  AND s.LegacySystemStoreIdentifier LIKE ''%'+ @StoreNumber + '%'''

	IF ( @Title <> '-1' ) 
		SET @sqlQuerynewDB = @sqlQuerynewDB + '  AND p.ProductName = '''+ @Title + ''''

	IF ( @ChainID <> '-1' ) 
		SET @sqlQuerynewDB = @sqlQuerynewDB + ' AND c.ChainIdentifier = '''+ @ChainID + '''' 
		
	SET @sqlQuerynewDB = @sqlQuerynewDB + ' Order By S.LegacySystemStoreIdentifier,p.ProductName '
	exec(@sqlQuerynewDB)
			
END
GO
