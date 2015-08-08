USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawsManagementNotSalesWHLS_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- exec amb_DrawsManagementNotSalesWHLS 'TA','-1','-1','','WR1428','24503'
--- Exec amb_DrawsManagementNotSalesWHLS '-1','-1','-1','872','ENT','24178'
-- Exec amb_DrawsManagementNotSalesWHLS_Beta 'DQ','-1','-1','','CLL','24164'
-- Exec amb_DrawsManagementNotSalesWHLS_Beta 'LG','-1','-1','','WR1687','24643'
-- Exec amb_DrawsManagementNotSalesWHLS_Beta 'HIS','-1','-1','','WR362','27637'

CREATE procedure [dbo].[amb_DrawsManagementNotSalesWHLS_Beta]
( 
	@ChainIdentifier NVARCHAR(100) ,
	@State varchar(10),
	@City varchar(20),
	@StoreNumber varchar(20),
	@supplieridentifier varchar(20),
	@supplierid varchar(20)
)
as 

BEGIN
	DECLARE @sqlQuerynewDB VARCHAR(8000)
	

	SET @sqlQuerynewDB='SELECT  Distinct  ( isnull(S.LegacySystemStoreIdentifier,''N.A'') + '', Site # '' + S.StoreIdentifier + '' /n Location: '' + A.Address1+ '', '' + A.City + '','' + A.State + '', '' + A.PostalCode) as StoreInfo,
						 S.StoreIdentifier as StoreNumber,
						 S.LegacySystemStoreIdentifier as StoreId,
						 S.StoreName,
						 A.Address1 as Address, 
						 A.City, 
						 A.State, 
						 A.PostalCode as ZipCode,
						 C.chainidentifier AS ChainID,
						 PI.Bipad, 
						 ISNULL(ss.MonLimitQty,0) as Mon, 
						 ISNULL(ss.TueLimitQty,0) as Tue,
						 ISNULL(ss.WedLimitQty,0) as Wed,  
						 ISNULL(ss.ThuLimitQty,0) as Thur ,  
						 ISNULL(ss.FriLimitQty,0) as Fri,
						 ISNULL(ss.SatLimitQty,0) as Sat, 
						 ISNULL(ss.SunLimitQty,0) as Sun, 
						 Convert(money,ISNULL(PP.unitprice,0)) as CostToStore,
						 Convert(money, PP.unitprice) as CostToStore4Wholesaler,
						 Convert(money,PP.unitprice) AS CostToWholesaler,
						 Convert(money,ISNULL(PP.unitretail,0)) as SuggRetail, 
						 P.productname AS Title, 
						 Convert(bit,0) as Stopped, 
						 --S.LegacySystemStoreIdentifier as WHLS_StoreID, 
						 PI.bipad as WholesaerBipad,
						 Convert(bit,0) as  NonReturn, 
						 Convert(int,0) as Hol
						
						FROM dbo.storesetup ss with (nolock) 
							inner join dbo.chains c  with (nolock) on c.chainid=ss.chainid
							INNER JOIN dbo.stores S  with (nolock) ON ss.ChainID = S.ChainID AND ss.StoreID = S.StoreID
							INNER JOIN dbo.ProductPrices pp  with (nolock) ON ss.ChainID = pp.ChainID AND ss.supplierid = pp.supplierid	
							AND ss.productid = pp.productid AND SS.StoreID = PP.StoreID AND ProductPriceTypeID=3 
							INNER JOIN dbo.Products p  with (nolock) ON ss.productid = p.productid
							inner join dbo.Addresses a with (nolock)  on S.StoreID =a.OwnerEntityID  
							inner join dbo.productidentifiers pi with (nolock)  on p.productid=pi.productid and PI.ProductIdentifierTypeID=8
							LEFT JOIN dbo.ServiceFees  SF with (nolock)  ON ss.supplierid = SF.supplierid 
						
					   WHERE 1=1 AND c.ChainIdentifier in (Select chainid from chains_migration) 
							AND ss.supplierid ='''+@supplierid+''' and ss.ActiveLastDate> getdate()'
							--AND ((ISNULL([MonLimitQty],0)+ISNULL([tueLimitQty],0)+ISNULL([wedLimitQty],0)+ISNULL([thuLimitQty],0)+ISNULL([friLimitQty],0)+ISNULL([satLimitQty],0)+ISNULL([sunLimitQty],0))>=0) 
					
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
	print(@sqlQuerynewDB)
	
End
GO
