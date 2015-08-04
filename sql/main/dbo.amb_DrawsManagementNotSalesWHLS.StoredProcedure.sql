USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawsManagementNotSalesWHLS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- exec amb_DrawsManagementNotSalesWHLS 'TA','-1','-1','','WR1428','24503'
--- Exec amb_DrawsManagementNotSalesWHLS '-1','-1','-1','872','ENT','24178'
--Exec amb_DrawsManagementNotSalesWHLS 'BN','NY','NEW HARTFORD','','Wolfe','28943'
CREATE procedure [dbo].[amb_DrawsManagementNotSalesWHLS]
( 
	@ChainIdentifier NVARCHAR(100) ,
	@State varchar(10),
	@City varchar(20),
	@StoreNumber varchar(10),
	@supplieridentifier varchar(10),
	@supplierid varchar(10)
)
as 

BEGIN
	DECLARE @sqlQueryStoreLegacy VARCHAR(8000)
	DECLARE @sqlQueryStorenewDB VARCHAR(8000)
	DECLARE @sqlQueryLegacy VARCHAR(8000)
	DECLARE @sqlQuerynewDB VARCHAR(8000)
	
	SET @sqlQueryStoreLegacy='SELECT distinct SL.StoreNumber, SL.StoreID, SL.StoreName,SL.Address, SL.City, SL.State, SL.ZipCode
								 FROM [IC-HQSQL2].iControl.dbo.BaseOrder B 
						     INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON B.ChainID = SL.ChainID AND B.StoreID = SL.StoreID
						     INNER JOIN [IC-HQSQL2].iControl.dbo.ProductsPrices PP ON B.ChainID = PP.ChainID AND B.WholesalerID = PP.WholesalerID AND B.Bipad = PP.Bipad 
						     INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON B.Bipad = P.Bipad 
						     LEFT JOIN [IC-HQSQL2].iControl.dbo.ProductsWhlsUniqueBipads PWB ON PP.Bipad = PWB.iControlBipad AND PP.WholesalerID = PWB.WholesalerID
						     LEFT JOIN [IC-HQSQL2].iControl.dbo.ServiceFees  SF ON B.WholesalerID = SF.WholesalerID AND B.StoreID = SF.StoreID 
						     WHERE 1=1  and B.ChainID not in (Select chainid from chains_migration) 
						     AND B.WholesalerID='''+@supplieridentifier+''' AND B.Stopped=0 AND ([mon]+[tue]+[wed]+[thur]+[fri]+[sat]+[sun])>=0  '

	if(@StoreNumber<>'')
			SET @sqlQueryStoreLegacy= @sqlQueryStoreLegacy+ ' AND SL.StoreNumber like ''%' + @StoreNumber+'%'''
			
	if(@City<>'-1')
			SET @sqlQueryStoreLegacy= @sqlQueryStoreLegacy+ ' AND SL.City = '''+@City+''''
			
	if(@State<>'-1')
			SET @sqlQueryStoreLegacy= @sqlQueryStoreLegacy+ ' AND SL.State = '''+@State+'''' 
			
	if(@ChainIdentifier<>'-1')
			SET @sqlQueryStoreLegacy= @sqlQueryStoreLegacy+ ' AND SL.ChainID = '''+@ChainIdentifier+''''
			
			
	SET @sqlQueryLegacy='SELECT  distinct ('' Store #: '' + SL.StoreID + '','' + SL.StoreNumber + '',	'' + SL.StoreName + '' /n	Location: '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,SL.StoreNumber,SL.StoreID ,SL.StoreName,
									SL.Address, SL.City, SL.State, SL.ZipCode,SL.ChainID,B.Bipad,
									 B.Mon, B.Tue, B.Wed, B.Thur, B.Fri, B.Sat, B.Sun, 
									PP.CostToStore,PP.CostToStore4Wholesaler, PP.CostToWholesaler, PP.SuggRetail, P.AbbrvName AS Title, B.Stopped, 
									SF.WHLS_StoreID, PWB.WholesaerBipad, B.NonReturn, B.Hol
									FROM [IC-HQSQL2].iControl.dbo.BaseOrder B 
									INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON B.ChainID = SL.ChainID AND B.StoreID = SL.StoreID
									INNER JOIN [IC-HQSQL2].iControl.dbo.ProductsPrices PP ON B.ChainID = PP.ChainID AND 
									B.WholesalerID = PP.WholesalerID AND B.Bipad = PP.Bipad 
									INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON B.Bipad = P.Bipad 
									LEFT JOIN [IC-HQSQL2].iControl.dbo.ProductsWhlsUniqueBipads PWB ON PP.Bipad = PWB.iControlBipad
									 AND PP.WholesalerID = PWB.WholesalerID
									LEFT JOIN [IC-HQSQL2].iControl.dbo.ServiceFees  SF ON B.WholesalerID = SF.WholesalerID AND 
									B.StoreID = SF.StoreID 
									WHERE 1=1  and B.ChainID not in (Select chainid from chains_migration) 
									AND B.WholesalerID='''+@supplieridentifier+''' AND B.Stopped=0 
									AND ([mon]+[tue]+[wed]+[thur]+[fri]+[sat]+[sun])>=0  '

	if(@StoreNumber<>'')
			SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.StoreNumber like ''%' + @StoreNumber+'%'''
			
	if(@City<>'-1')
			SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.City = '''+@City+''''
			
	if(@State<>'-1')
			SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.State = '''+@State+'''' 
			
	if(@ChainIdentifier<>'-1')
			SET @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.ChainID = '''+@ChainIdentifier+''''
			
			
			
	SET @sqlQueryStorenewDB='SELECT distinct S.StoreIdentifier as StoreNumber, S.LegacySystemStoreIdentifier as StoreId,
							S.StoreName, A.Address1 as Address, A.City, A.State, A.PostalCode as ZipCode
							FROM dbo.storesetup ss
							inner join dbo.chains c on c.chainid=ss.chainid
							INNER JOIN dbo.stores S ON ss.ChainID = S.ChainID AND ss.StoreID = S.StoreID
							INNER JOIN dbo.ProductPrices pp ON ss.ChainID = pp.ChainID AND ss.supplierid = pp.supplierid	
							AND ss.productid = pp.productid AND ProductPriceTypeID=3 
							INNER JOIN dbo.Products p ON ss.productid = p.productid
							inner join dbo.Addresses a on S.StoreID =a.OwnerEntityID  
							inner join dbo.productidentifiers pi on p.productid=pi.productid and PI.ProductIdentifierTypeID=8
							LEFT JOIN dbo.ServiceFees  SF ON ss.supplierid = SF.supplierid 
							WHERE 1=1 AND c.ChainIdentifier in (Select chainid from chains_migration) 
							AND ss.supplierid ='''+@supplierid+'''  
							AND (([MonLimitQty]+[tueLimitQty]+[wedLimitQty]+[thuLimitQty]+[friLimitQty]+[satLimitQty]+[sunLimitQty])>=0) '
							
			if(@StoreNumber<>'')
					SET @sqlQueryStorenewDB= @sqlQueryStorenewDB+ ' AND S.LegacySystemStoreIdentifier like ''%' + @StoreNumber+'%'''
			
			if(@City<>'-1')
					SET @sqlQueryStorenewDB= @sqlQueryStorenewDB+ ' AND A.City = '''+@City+''''
			
			if(@State<>'-1')
					SET @sqlQueryStorenewDB= @sqlQueryStorenewDB+ ' AND A.State = '''+@State+'''' 
			
			if(@ChainIdentifier<>'-1')
					SET @sqlQueryStorenewDB= @sqlQueryStorenewDB+ ' AND c.ChainIDentifier = '''+@ChainIdentifier+''''

	SET @sqlQuerynewDB='SELECT distinct (''Store #: '' + S.LegacySystemStoreIdentifier + '','' 
						+ S.StoreIdentifier + '','' + S.StoreName + '' /n Location: '' + A.Address1+ '', 
						'' + A.City + '','' + A.State + '', '' + A.PostalCode) as StoreInfo,
						S.StoreIdentifier as StoreNumber,S.LegacySystemStoreIdentifier as StoreId,S.StoreName,
						 A.Address1 as Address, A.City, A.State, A.PostalCode as ZipCode,C.chainidentifier AS chainid,
						 PI.Bipad, ss.MonLimitQty as Mon, 
						ss.TueLimitQty as Tue,ss.WedLimitQty as Wed,  ss.ThuLimitQty as Thur ,  ss.FriLimitQty as Fri,ss.SatLimitQty as Sat, 
						ss.SunLimitQty as Sun, PP.unitprice as CostToStore,0 as CostToStore4Wholesaler,0 AS CostToWholesaler,
						PP.unitretail as SuggRetail, 
						P.productname AS Title, 0 as Stopped, S.LegacySystemStoreIdentifier as WHLS_StoreID, PI.bipad as WholesaerBipad,
						0 as  NonReturn, 0 as Hol
						FROM dbo.storesetup ss
						inner join dbo.chains c on c.chainid=ss.chainid
						INNER JOIN dbo.stores S ON ss.ChainID = S.ChainID AND ss.StoreID = S.StoreID
						INNER JOIN dbo.ProductPrices pp ON ss.ChainID = pp.ChainID AND ss.supplierid = pp.supplierid	
						AND ss.productid = pp.productid AND ProductPriceTypeID=3 
						INNER JOIN dbo.Products p ON ss.productid = p.productid
						inner join dbo.Addresses a on S.StoreID =a.OwnerEntityID  
						inner join dbo.productidentifiers pi on p.productid=pi.productid and PI.ProductIdentifierTypeID=8
						LEFT JOIN dbo.ServiceFees  SF ON ss.supplierid = SF.supplierid 
						WHERE 1=1 AND c.ChainIdentifier in (Select chainid from chains_migration) 
						AND ss.supplierid ='''+@supplierid+'''  
						AND (([MonLimitQty]+[tueLimitQty]+[wedLimitQty]+[thuLimitQty]+[friLimitQty]+[satLimitQty]+[sunLimitQty])>=0) 
					'
			if(@StoreNumber<>'')
					SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND S.LegacySystemStoreIdentifier like ''%' + @StoreNumber+'%'''
			
			if(@City<>'-1')
					SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND A.City = '''+@City+''''
			
			if(@State<>'-1')
					SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND A.State = '''+@State+'''' 
			
			if(@ChainIdentifier<>'-1')
					SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND c.ChainIDentifier = '''+@ChainIdentifier+''''
			
	--Exec(@sqlQueryStoreLegacy + ' union ' + @sqlQueryStorenewDB)	
	print (@sqlQueryLegacy + ' union ' + @sqlQuerynewDB)
	Exec(@sqlQueryLegacy + ' union ' + @sqlQuerynewDB)
	
End
GO
