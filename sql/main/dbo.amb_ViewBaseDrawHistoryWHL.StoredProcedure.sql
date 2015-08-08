USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewBaseDrawHistoryWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_ViewBaseDrawHistoryWHL 'TA','PA','-1','','WR1428','24503'
--exec amb_ViewBaseDrawHistoryWHL 'BN','-1','-1','','ENT','24178'
--exec amb_ViewBaseDrawHistoryWHL 'TA','-1','-1','','WR1428','24503'
CREATE PROCEDURE [dbo].[amb_ViewBaseDrawHistoryWHL]
(
	@ChainID VARCHAR(10) ,
	@State VARCHAR(10) ,
	@Title VARCHAR(50) ,
	@StoreNumber VARCHAR(10) ,
	@supplieridentifier varchar(10),
	@supplierid varchar(10)
)
AS 
BEGIN
 
	DECLARE @sqlQueryLegacy VARCHAR(8000)
	DECLARE @sqlQuerynewDB VARCHAR(8000)
	
	
		
	SET @sqlQueryLegacy = 'SELECT  (''Store Number: '' + SL.StoreNumber + ''; Account Number: '' + 
										SL.StoreId + '';/n Location: '' + SL.StoreName + '', '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,BO.StoreID as StoreID,
						  SL.ChainID,P.AbbrvName AS Title, P.TitleName,P.Bipad, 
						  BO.WholesalerID,	 PP.CostToStore, PP.SuggRetail,BO.Mon, 
						  BO.Tue,BO.Wed, BO.Thur, BO.Fri, BO.Sat, BO.Sun, 
						  '''' CostStartDate,'''' CostEndDate,'''' ProductStartDate,'''' ProductEndDate
	                  
						 FROM  [IC-HQSQL2].iControl.dbo.BaseOrder BO
						 INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON BO.Bipad = P.Bipad
						 INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON BO.StoreID = SL.StoreID AND BO.ChainID = SL.ChainID
						 INNER JOIN  [IC-HQSQL2].iControl.dbo.ProductsPrices PP ON BO.WholesalerID =  PP.WholesalerID
						 AND BO.ChainID =  PP.ChainID AND P.Bipad =  PP.Bipad
						 WHERE BO.Stopped=0 AND SL.Active=1  AND P.Active=1
						 and BO.ChainID not in (Select chainid from chains_migration)
						 and BO.WholesalerID =''' +@supplieridentifier + ''''
			
	IF ( @State <> '-1' ) 
		SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND SL.State = '''+ @State + ''''

	IF ( @StoreNumber <> '' ) 
		SET @sqlQueryLegacy = @sqlQueryLegacy+ '  AND SL.storeid LIKE ''%' + @StoreNumber+ '%'''

	IF ( @Title <> '-1' ) 
		SET @sqlQueryLegacy = @sqlQueryLegacy+ '  AND P.AbbrvName = ''' + @Title + ''''

	IF ( @ChainID <> '-1' ) 
		SET @sqlQueryLegacy = @sqlQueryLegacy + ' AND SL.ChainID = '''+ @ChainID + '''' 	

	
		
	
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
                            
							From dbo.StoreSetup SS 
							INNER JOIN dbo.Products p on p.ProductID=ss.ProductID
							INNER JOIN dbo.stores s on s.StoreID=ss.StoreID AND s.ChainID=ss.ChainID
							INNER JOIN dbo.ProductPrices pp on pp.SupplierID=SS.SupplierID 
							AND pp.ChainID=SS.ChainID 
							AND pp.ProductID=p.ProductID
							INNER JOIN dbo.Suppliers sup on sup.SupplierID=ss.SupplierID
							INNER JOIN dbo.Chains c on ss.ChainID=c.ChainID 
							INNER JOIN dbo.ProductIdentifiers pid on pid.ProductID=p.ProductID 
							INNER JOIN dbo.ProductPriceTypes ppt on pp.ProductPriceTypeID=ppt.ProductPriceTypeID 
							INNER JOIN  dbo.Addresses a on s.StoreID =a.OwnerEntityID 
							
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
	
	
	print(@sqlQueryLegacy + ' union ' + @sqlQuerynewDB)
	exec(@sqlQueryLegacy + ' union ' + @sqlQuerynewDB)
			
END
GO
