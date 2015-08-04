USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewBaseDrawHistoryCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Exec amb_ViewBaseDrawHistoryCHN 'BN','42493','-1','-1','0',''
CREATE
 procedure [dbo].[amb_ViewBaseDrawHistoryCHN]
(
      @ChainIdentifier NVARCHAR(100) ,
      @ChainID NVARCHAR(100) ,
      @StateName NVARCHAR(100) ,
      @ProductName NVARCHAR(250),
      @ChainMigrated VARCHAR(1), --0 for Old DB, 1 for New DB, 2 for Both
      @StoreNumber varchar(250)
)

as 
BEGIN

	Declare @sqlQuery varchar(4000)

	IF (@ChainMigrated=0) 
		BEGIN

SET @sqlQuery = 'SELECT distinct (''Store Number: '' + SL.StoreNumber + ''; Account Number: '' + 
										SL.StoreId + '';/n Location: '' + SL.StoreName + '', '' + SL.Address + '', '' + SL.City + '', 
										'' + SL.State + '', '' + SL.ZipCode ) as StoreInfo,
										P.AbbrvName AS Title, B.WholesalerID as wholesalerid, P.Bipad, 
										PP.CostToStore, PP.SuggRetail, B.Mon, B.Tue, B.Wed, B.Thur, B.Fri, B.Sat, 
										B.Sun, ''''  CostStartDate,    '''' CostEndDate, ''''  ProductStartDate, ''''  ProductEndDate 					
										FROM [IC-HQSQL2].iControl.dbo.BaseOrder B
										INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON B.Bipad = P.Bipad
										INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON B.StoreID = SL.StoreID
										 AND B.ChainID = SL.ChainID
										INNER JOIN [IC-HQSQL2].iControl.dbo.ProductsPrices PP ON B.WholesalerID = PP.WholesalerID AND
										B.ChainID = PP.ChainID AND P.Bipad = PP.Bipad 
										WHERE B.Stopped=0 AND SL.Active=1 AND P.Active=1 
							      And SL.ChainID= ''' + @ChainIdentifier + '''' 

		   if(@StateName<>'-1')
SET @sqlQuery = @sqlQuery + ' AND SL.State = ''' + @StateName + ''''
		      
		   if(@ProductName<>'-1')
SET @sqlQuery = @sqlQuery + '  AND P.AbbrvName = ''' + @ProductName + ''''
				
		  if(@StoreNumber<>'')
SET @sqlQuery = @sqlQuery + '  AND SL.StoreID like ''%' + @StoreNumber + '%'''
SET @sqlQuery = @sqlQuery + '  Order BY StoreInfo,B.WholesalerID,P.AbbrvName'
EXEC (@sqlQuery);            		  
		END
		
	ELSE IF(@ChainMigrated=1)
		BEGIN
SET @sqlQuery = ' SELECT distinct (''Store Number: '' + S.StoreIdentifier + ''; Account Number: '' + 
		   S.LegacySystemStoreIdentifier + '';/n Location: '' + S.StoreName + '', '' + A.Address1 + '', '' + 
		   A.City + '', '' + A.State + '', '' + A.PostalCode ) as StoreInfo,
		   p.ProductName AS Title,  sup.SupplierIdentifier as wholesalerid, 
		   pp.unitprice as CostToStore, pp.UnitRetail AS SuggRetail,  
			 ss.MonLimitQty as Mon , ss.TueLimitQty as Tue, ss.WedLimitQty as Wed,
		   ss.ThuLimitQty as Thur ,  ss.FriLimitQty as Fri, 
			 ss.SatLimitQty as Sat,  ss.SunLimitQty as Sun, 
			 Convert(Varchar(12),pp.ActiveStartDate,101) as  CostStartDate,
			 Convert(Varchar(12),pp.ActiveLastDate,101) as CostEndDate,
			 Convert(Varchar(12),SS.ActiveStartDate,101) as ProductStartDate,
			 Convert(Varchar(12),SS.ActiveLastDate,101) as ProductEndDate
			            
			From dbo.storesetup SS 
			inner join dbo.Suppliers sup on sup.SupplierID=ss.SupplierID
			inner join dbo.Chains c on ss.ChainID=c.ChainID 
			inner join dbo.stores s on s.StoreID=ss.StoreID
			inner join dbo.Products p on p.ProductID=ss.ProductID
			inner join dbo.ProductIdentifiers pid 
			on pid.ProductID=p.ProductID and pid.productidentifiertypeid=8
			inner join dbo.ProductPrices pp on pp.productid=p.productid 
			and pp.SupplierID=ss.SupplierID and pp.chainid=ss.chainid and pp.StoreID=ss.StoreId
			inner join dbo.ProductPriceTypes ppt on pp.ProductPriceTypeID=ppt.ProductPriceTypeID 
			inner join dbo.Addresses a on s.StoreID =a.OwnerEntityID  
			WHERE  pp.ProductPriceTypeID=3  and c.ChainId = ' + @ChainID
			
			if(@StateName<>'-1')
SET @sqlQuery = @sqlQuery + ' AND a.State = ''' + @StateName + ''''
				
			if(@ProductName<>'-1')
SET @sqlQuery = @sqlQuery + '  AND p.ProductName = ''' + @ProductName + ''''
				
			if(@StoreNumber<>'')
SET @sqlQuery = @sqlQuery + ' AND S.LegacySystemStoreIdentifier like ''%' + @StoreNumber + '%'''
SET @sqlQuery = @sqlQuery + '  Order BY StoreInfo,sup.SupplierIdentifier,p.ProductName'
EXEC (@sqlQuery);
		END
END
GO
