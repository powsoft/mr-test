USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawsManagementNotSalesWHLS_Beta_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- exec amb_DrawsManagementNotSalesWHLS 'TA','-1','-1','','WR1428','24503'
--- Exec amb_DrawsManagementNotSalesWHLS '-1','-1','-1','872','ENT','24178'
--Exec amb_DrawsManagementNotSalesWHLS_Beta 'BN','-1','-1','','Wolfe','28943','StoreNumber ASC',1,25,0
CREATE procedure [dbo].[amb_DrawsManagementNotSalesWHLS_Beta_PRESYNC_20150415]
( 
	@ChainIdentifier NVARCHAR(100) ,
	@State varchar(10),
	@City varchar(20),
	@StoreNumber varchar(10),
	@supplieridentifier varchar(10),
	@supplierid varchar(10)
	/*@OrderBy varchar(100),
	@StartIndex int,
	@PageSize int,
	@DisplayMode int*/
)
as 

BEGIN
	DECLARE @sqlQuerynewDB VARCHAR(8000)
	

	SET @sqlQuerynewDB='SELECT  Distinct  (''Store #: '' + S.LegacySystemStoreIdentifier + '','' 
						+ S.StoreIdentifier + '','' + S.StoreName + '' /n Location: '' + A.Address1+ '', 
						'' + A.City + '','' + A.State + '', '' + A.PostalCode) as StoreInfo,
						 S.StoreIdentifier as StoreNumber,
						 S.LegacySystemStoreIdentifier as StoreId,
						 S.StoreName,
						 A.Address1 as Address, 
						 A.City, 
						 A.State, 
						 A.PostalCode as ZipCode,
						 C.chainidentifier AS chainid,
						 PI.Bipad, 
						 ISNULL(ss.MonLimitQty,0) as Mon, 
						 ISNULL(ss.TueLimitQty,0) as Tue,
						 ISNULL(ss.WedLimitQty,0) as Wed,  
						 ISNULL(ss.ThuLimitQty,0) as Thur ,  
						 ISNULL(ss.FriLimitQty,0) as Fri,
						 ISNULL(ss.SatLimitQty,0) as Sat, 
						 ISNULL(ss.SunLimitQty,0) as Sun, 
						 Convert(money,ISNULL(PP.unitprice,0)) as CostToStore,
						 Convert(money, 0) as CostToStore4Wholesaler,
						 Convert(money,0) AS CostToWholesaler,
						 Convert(money,ISNULL(PP.unitretail,0)) as SuggRetail, 
						 P.productname AS Title, 
						 Convert(bit,0) as Stopped, 
						 S.LegacySystemStoreIdentifier as WHLS_StoreID, 
						 PI.bipad as WholesaerBipad,
						 Convert(bit,0) as  NonReturn, 
						 Convert(int,0) as Hol
						
						FROM DataTrue_Report.dbo.storesetup ss
							inner join DataTrue_Report.dbo.chains c on c.chainid=ss.chainid
							INNER JOIN DataTrue_Report.dbo.stores S ON ss.ChainID = S.ChainID AND ss.StoreID = S.StoreID
							INNER JOIN DataTrue_Report.dbo.ProductPrices pp ON ss.ChainID = pp.ChainID AND ss.supplierid = pp.supplierid	
							AND ss.productid = pp.productid AND ProductPriceTypeID=3 
							INNER JOIN DataTrue_Report.dbo.Products p ON ss.productid = p.productid
							inner join DataTrue_Report.dbo.Addresses a on S.StoreID =a.OwnerEntityID  
							inner join DataTrue_Report.dbo.productidentifiers pi on p.productid=pi.productid and PI.ProductIdentifierTypeID=8
							LEFT JOIN dbo.ServiceFees  SF ON ss.supplierid = SF.supplierid 
						
					   WHERE 1=1 AND c.ChainIdentifier in (Select chainid from chains_migration) 
							AND ss.supplierid ='''+@supplierid+'''  
							AND ((ISNULL([MonLimitQty],0)+ISNULL([tueLimitQty],0)+ISNULL([wedLimitQty],0)+ISNULL([thuLimitQty],0)+ISNULL([friLimitQty],0)+ISNULL([satLimitQty],0)+ISNULL([sunLimitQty],0))>=0) 
					'
	if(@StoreNumber<>'')
			SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND S.LegacySystemStoreIdentifier like ''%' + @StoreNumber+'%'''
	
	if(@City<>'-1')
			SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND A.City = '''+@City+''''
	
	if(@State<>'-1')
			SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND A.State = '''+@State+'''' 
	
	if(@ChainIdentifier<>'-1')
	    SET @sqlQuerynewDB= @sqlQuerynewDB+ ' AND c.ChainIDentifier = '''+@ChainIdentifier+''''
	    
	 SET @sqlQuerynewDB= @sqlQuerynewDB+ ' Order By S.LegacySystemStoreIdentifier,P.productname '
	EXEC(@sqlQuerynewDB)
	/*SET @sqlQueryFinal = [dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  ( ' + @sqlQuerynewDB+ '	) as temp ', @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)

	EXEC(@sqlQueryFinal)*/
	
	
End
GO
