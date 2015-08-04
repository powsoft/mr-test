USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewMyPublicationCostWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_ViewMyPublicationCostWHL 'CLL','24164','BAM','CLARION-LEDGER SUNDAY'
CREATE PROCEDURE [dbo].[amb_ViewMyPublicationCostWHL]
    (
      @supplieridentifier varchar(10),
	    @supplierid varchar(10),
      @ChainID VARCHAR(10),
      @Title VARCHAR(200)
    )
AS 
BEGIN

	
	DECLARE @sqlQuerynewDB VARCHAR(8000)

SET @sqlQuerynewDB = ' SELECT DISTINCT C.ChainIdentifier AS ChainID,S.SupplierIdentifier AS WholesalerID,P.ProductName AS TitleName,
									PP.UnitPrice AS CostToStore,PP.UnitRetail AS SuggRetail,(PP.UnitRetail-PP.UnitPrice)as  ProfitperUnit,
									convert(varchar,PP.activestartdate,101) as Startdate,convert(varchar,PP.activelastdate,101) as Enddate
									FROM DataTrue_Report.dbo.ProductPrices PP 
									INNER JOIN  DataTrue_Report.dbo.Products P ON P.ProductID=PP.ProductID
									INNER JOIN DataTrue_Report.dbo.Chains C ON C.ChainID=PP.ChainID
									INNER JOIN  DataTrue_Report.dbo.Suppliers S ON S.SupplierID=PP.SupplierID 
									WHERE  1=1 and  C.ChainIdentifier in (Select chainid from chains_migration)'
SET @sqlQuerynewDB = @sqlQuerynewDB + ' AND  S.SupplierIdentifier=''' + @supplieridentifier + ''''
			
IF ( @ChainID <> '-1' )
SET @sqlQuerynewDB = @sqlQuerynewDB + ' AND  C.ChainIdentifier = ''' + @ChainID + ''''
				
IF ( @Title <> '-1' )
SET @sqlQuerynewDB = @sqlQuerynewDB + ' AND P.ProductName = ''' + @Title + ''''

EXEC (@sqlQuerynewDB)
		
END
GO
