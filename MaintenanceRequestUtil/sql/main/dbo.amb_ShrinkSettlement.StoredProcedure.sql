USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ShrinkSettlement]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_ShrinkSettlement '-1','','30219','2','-1','11/11/2011','11/11/2011','item'
CREATE PROCEDURE [dbo].[amb_ShrinkSettlement]
    @ChainID VARCHAR(10) ,
    @StoreID VARCHAR(50) ,
    @Bipad VARCHAR(20) ,
    @SettlementStatus VARCHAR(20) ,
    @WholesalerID VARCHAR(20) ,
    @StartDate VARCHAR(50) ,
    @EndDate VARCHAR(50) ,
    @ViewLevel VARCHAR(50)
AS 
    BEGIN
    DECLARE @sqlQuery VARCHAR(4000)
    DECLARE @strGroupBy VARCHAR(2000)
    SET @sqlQuery = ' select '
    IF ( @ViewLevel = 'item' ) 
        BEGIN
            SET @sqlQuery = @sqlQuery + ' Distinct sup.SupplierIdentifier,sup.SupplierName AS [Wholesaler Name],
                                          c.ChainIdentifier,c.ChainName AS [Chain Name],
                                          s.LegacySystemStoreIdentifier,sh.ChainID,sh.Supplierid,pi.bipad,
										  p.ProductName,p.DESCRIPTION,sh.ShrinkFactsID,sh.ShrinkUnits,
										  sh.Shrink$,sh.Unitcost,sh.OriginalPOS,sh.OriginalDeliveries, 
										  sh.OriginalPickups,sh.SaleDateTime,sh.DateTimecreated,sh.status,
										  (case when sh.PODReceived = 1 then ''Yes'' else ''No'' end ) as POD,
										   sh.PODReceived '
            SET @strGroupBy = ''
        END
    ELSE 
        IF ( @ViewLevel = 'store' ) 
            BEGIN
			SET @sqlQuery = @sqlQuery + ' distinct sup.SupplierIdentifier,sup.SupplierName AS																								[Wholesaler Name],c.ChainIdentifier,c.ChainName AS [Chain Name],
										s.LegacySystemStoreIdentifier,sh.ChainID,sh.StoreID,sh.Supplierid,
										SUM(sh.ShrinkUnits) AS ShrinkUnits,SUM(sh.Shrink$) AS Shrink$,
										SUM(sh.OriginalDeliveries) AS OriginalDeliveries,																								    SUM(sh.OriginalPickups) AS OriginalPickups, 
										SUM(sh.OriginalPOS) AS OriginalPOS ,sh.SaleDateTime,
										MAX(sh.DateTimecreated) AS DateTimecreated,sh.status,
										(case when sh.PODReceived = 1 then ''Yes''
										else ''No''  end ) as POD,sh.PODReceived ' 
                    
			SET @strGroupBy=' GROUP BY sh.ChainID,sh.StoreID,sh.Supplierid,
								c.ChainIdentifier,c.ChainName,
								s.LegacySystemStoreIdentifier,s.storeidentifier,sup.SupplierIdentifier,
								sup.SupplierName,sh.status,sh.SaleDateTime,sh.DateTimecreated,
								sh.PODReceived  '							
            END
        ELSE 
            IF ( @ViewLevel = 'chain' ) 
                BEGIN
			SET @sqlQuery = @sqlQuery + ' DISTINCT sup.SupplierIdentifier,sup.SupplierName AS [Wholesaler Name],
											c.ChainIdentifier,c.ChainName AS [Chain Name],
											sh.ChainID,sh.Supplierid,SUM(sh.ShrinkUnits) AS ShrinkUnits,
											SUM (sh.Shrink$) AS Shrink$ ,SUM(sh.OriginalDeliveries) AS OriginalDeliveries,
											SUM(sh.OriginalPickups) AS OriginalPickups, 
											SUM(sh.OriginalPOS) AS OriginalPOS ,sh.SaleDateTime,
											MAX(sh.DateTimecreated) AS DateTimecreated,sh.status,
											(case when sh.PODReceived = 1 then ''Yes''
											else ''No'' end ) as POD,sh.PODReceived '
						                            
					SET @strGroupBy=' GROUP BY sh.ChainID,sh.Supplierid,c.ChainIdentifier,c.ChainName,
										sup.SupplierIdentifier,sup.SupplierName,sh.status,sh.SaleDateTime,
										sh.DateTimecreated,sh.PODReceived '
                END
		
    SET @sqlQuery = @sqlQuery + ' from dbo.InventoryReport_Newspaper_Shrink_Facts sh
								 inner join dbo.chains c on c.ChainID=sh.ChainID 
								 inner join dbo.Suppliers sup on sup.SupplierID=sh.SupplierID'
				      
    IF ( @ViewLevel != 'chain' ) 
        SET @sqlQuery = @sqlQuery + '  inner join dbo.stores s on s.storeid=sh.storeid  '
    IF ( @ViewLevel = 'item' ) 
        SET @sqlQuery = @sqlQuery + '  inner join dbo.Products p on p.productid=sh.productid
									   inner join dbo.ProductIdentifiers pi on p.productid=pi.										   productid 
									   Where 1=1  '


    IF ( CAST(@StartDate as DATE) = CAST(@EndDate as DATE) ) 
        BEGIN
            SET @sqlQuery = @sqlQuery + ' and sh.DateTimecreated >= ''' + convert(varchar, @StartDate,101)+''''
        END
    ELSE 
        BEGIN
            SET @sqlQuery = @sqlQuery + ' and sh.DateTimecreated 
                                          Between '''+ convert(varchar,@StartDate,101) + ''' AND  ''' + convert(varchar,@EndDate,101) + ''''
        END

    IF ( @ChainID <> '-1' ) 
        SET @sqlQuery = @sqlQuery + ' AND C.ChainIdentifier = ''' + @ChainID +''''
         
    IF ( @StoreID <> '' AND @ViewLevel != 'chain') 
        SET @sqlQuery = @sqlQuery + ' AND s.LegacySystemStoreIdentifier like ''%' + @StoreID+ '%'''
        
    IF ( @Bipad <> '-1' AND @ViewLevel = 'item') 
        SET @sqlQuery = @sqlQuery + ' AND sh.productid = ''' + @Bipad+ ''''
        
    IF ( @SettlementStatus <> '-1' ) 
        SET @sqlQuery = @sqlQuery + ' AND sh.status = '''+ @SettlementStatus + ''' '
        
    IF ( @WholesalerID <> '-1' ) 
        SET @sqlQuery = @sqlQuery + ' AND sup.SupplierIdentifier = '''+@WholesalerID +''''
      
    SET @sqlQuery = @sqlQuery + @strGroupBy
    
    SET @sqlQuery = @sqlQuery + '  order by sup.SupplierIdentifier '
  
    EXEC(@sqlQuery);
   
  END
GO
