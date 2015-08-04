USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ShrinkSettlementPODStatus]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================

--exec amb_ShrinkSettlementPODStatus 'KNG','Florida Times-Union','WR501','Chain','2','','1900-01-01','1900-01-01'
CREATE PROCEDURE [dbo].[amb_ShrinkSettlementPODStatus]
    @ChainID VARCHAR(10) ,
    @StoreID VARCHAR(50) ,
    @WholesalerID VARCHAR(20) ,
    @ViewLevel VARCHAR(20),
    @Status VARCHAR(20),
    @Bipad VARCHAR(20),
    @StartDate VARCHAR(30),
    @EndDate VARCHAR(30)
AS 
    BEGIN
        DECLARE @sqlQuery VARCHAR(4000)
        
        SET @sqlQuery = 'Select sup.SupplierIdentifier AS WholesalerID, c.ChainIdentifier AS ChainID,
							  s.LegacySystemStoreIdentifier AS StoreID,Convert(varchar(12),POD.SaleDate,101) as								  SaleDate,Convert(varchar(12),POD.PODReceivedDate,101) as PODReceivedDate 
         
                          FROM dbo.PODHistory POD
							   INNER JOIN dbo.InventoryReport_Newspaper_Shrink_Facts SH                                          ON SH.ChainID=POD.ChainID AND SH.Supplierid=POD.SupplierID AND SH.StoreID=POD.								   StoreID AND SH.SaleDateTime=POD.SaleDate
						       INNER JOIN  dbo.chains c ON c.ChainID=POD.ChainID 
							   INNER JOIN  dbo.Suppliers sup ON sup.SupplierID=POD.SupplierID  
							   INNER JOIN dbo.stores s  ON s.storeid=POD.StoreID  
							   
					     WHERE 1=1 AND SH.PODReceived=''True'' AND SH.Status='''+@Status+''' '
							   
    IF ( convert(varchar, @StartDate,101) = convert(varchar, @EndDate,101) ) 
        BEGIN
            SET @sqlQuery += ' and ((sh.datetimecreated) >= ''' + convert(varchar, @StartDate,101) +''')'
        END
    ELSE 
        BEGIN
            SET @sqlQuery +=  ' and ((sh.datetimecreated) Between '''+ @StartDate + ''' AND  '''+ @EndDate+''')'
        END   
	    
        IF ( @ChainID <> '-1' ) 
            SET @sqlQuery +=' AND c.ChainIdentifier = '''+ @ChainID +''''
            
        IF ( @StoreID <> '' AND @ViewLevel != 'chain') 
            SET @sqlQuery +=' AND ((s.LegacySystemStoreIdentifier) like ''%' + @StoreID+ '%'') '
            
        IF ( @WholesalerID <> '-1' ) 
            SET @sqlQuery +=' AND sup.SupplierIdentifier = '''+ @WholesalerID +''''
            
        IF ( @Bipad <> '-1') 
            SET @sqlQuery = @sqlQuery + ' AND ((sh.productid) = ''' + @Bipad+ ''') '    
            			  
        SET @sqlQuery +='  order by sup.SupplierIdentifier '
        
        print @sqlQuery
        EXEC(@sqlQuery);
    END
GO
