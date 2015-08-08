USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[GetSupplierActionable_Edit]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from DataTrue_EDI.dbo.Inbound846Inventory_ACH           
--[GetSupplierActionable_Edit] '65138', '82726', '50964','11/11/2014 12:00:00 AM' ,'20141119_103444_000065138_000073521_iControl.TXT'   
          
CREATE  proc [dbo].[GetSupplierActionable_Edit]                 
@SupplierID varchar(50),           
@InvoiceNo varchar(max),       
@ChainID varchar(50),         
@EffectiveDate datetime,
@FileName Varchar(120)  
as          
           
Begin          
declare @sqlQuery varchar(max)

SELECT  RecordID
			  , IW.DataTrueProductID AS ProductID
			  , rtrim(IW.ItemNumber) AS SKU
			  , CASE When (rtrim(isnull(IW.ProductIdentifier,''))= '')
					 THEN rtrim(IW.RawProductIdentifier)
					 ELSE rtrim(IW.ProductIdentifier) END AS UPC
			  , IW.ProductName
			  , IW.UnitMeasure AS UOM
			  , IW.Cost Cost
			  , CAST(AlllowanceChargeAmount1 AS Decimal(18,2))  AS Adjustment1
			  , CAST(AlllowanceChargeAmount2 AS Decimal(18,2))  AS Adjustment2
			  , CAST(AlllowanceChargeAmount3 AS Decimal(18,2))  AS Adjustment3
			  , CAST(AlllowanceChargeAmount4 AS Decimal(18,2))  AS Adjustment4
			  , CAST(AlllowanceChargeAmount5 AS Decimal(18,2))  AS Adjustment5
			  , CAST(AlllowanceChargeAmount6 AS Decimal(18,2)) AS Adjustment6
			  , CAST(AlllowanceChargeAmount7 AS Decimal(18,2)) AS Adjustment7
			  , CAST(AlllowanceChargeAmount8 AS Decimal(18,2)) AS Adjustment8
			  , PacksPerCase AS PPC
			  , IW.RecordStatus
			  , IW.Retail AS Price
			  , IW.ChainName
			  , s.SupplierIdentifier
			  , Qty
			  , PurposeCode
			  , DataTrue_EDI.dbo.fnIsValidUPC(IW.ProductIdentifier) AS IsValidUPC
FROM
	[DataTrue_EDI].[dbo].[Inbound846Inventory_ACH] IW
	INNER JOIN Chains C
		ON C.ChainIdentifier = IW.ChainName
	INNER JOIN Suppliers S
		ON S.EDIName = IW.SupplierIdentifier

WHERE
	1 = 1
	AND RecordStatus = 255
	AND ReferenceIdentification = @InvoiceNo
	AND C.ChainId = @ChainID
	AND s.SupplierId = @SupplierID
	AND IW.[FileName] = @FileName
	AND IW.EffectiveDate IN  (
								SELECT Distinct EffectiveDate AS EffectiveDate  
								FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH]
									INNER JOIN Chains C ON C.ChainIdentifier = IW.ChainName
									INNER JOIN Suppliers S ON S.EDIName = IW.SupplierIdentifier  
								 WHERE ReferenceIDentification=@InvoiceNo 
									AND c.ChainID =@ChainID 
									AND s.SupplierID =@SupplierID  
									AND [FileName]=@FileName 
							  )
	   
End
GO
