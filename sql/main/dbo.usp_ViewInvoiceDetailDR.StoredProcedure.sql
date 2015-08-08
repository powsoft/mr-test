USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ViewInvoiceDetailDR]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_ViewInvoiceDetailDR '5306008','81651','-1','61620'
CREATE procedure [dbo].[usp_ViewInvoiceDetailDR]
@InvoiceNumber varchar(255),
@ChainID varchar(40),
@SupplierId varchar(40),
@PaymentID Varchar(20)

AS
Begin

DECLARE @sqlQuery varchar(4000)
DECLARE @sqlQuery2 varchar(4000)

	SET @sqlQuery = 'SELECT Distinct ID.ProductID,
									P.ProductName AS [Product Name],
									PI.IdentifierValue AS UPC,
									ID.VIN ,
									ID.TotalQty AS [Total Qty],
									isnull(ID.UnitCost,0) AS [Unit Cost],
									(ID.TotalQty *  isnull(ID.UnitCost,0)) AS [Total],
									isnull(ID.Adjustment1,0) AS Adjustment,
									isnull(ID.TotalCost,0) AS [Total Cost],
									ID.RetailerInvoiceID as InvoiceNo,
									ID.InvoiceNo as SupplierInvoiceNo
				  FROM InvoiceDetails ID
						INNER JOIN Products P ON ID.ProductID=P.ProductID
						INNER JOIN Stores S ON S.StoreID=ID.StoreID
						LEFT JOIN ProductIdentifiers PI ON PI.ProductID=P.ProductID AND ProductIdentifierTypeID=2 
					Where 1=1 '
					
	IF(@InvoiceNumber<>'')
        set @sqlQuery = @sqlQuery + ' AND ID.RetailerInvoiceID =''' + @InvoiceNumber +''''
        
    IF(@ChainID<>'-1')
        SET @sqlQuery = @sqlQuery + ' AND ID.ChainID =' + @ChainID	
        
    IF(@SupplierId<>'-1')
        SET @sqlQuery = @sqlQuery + ' AND ID.SupplierID =' + @SupplierId
       
    IF(@PaymentID<>'')
        SET @sqlQuery = @sqlQuery + ' AND ID.PaymentID =' + @PaymentID 
        
    set @sqlQuery = @sqlQuery + ' Order By  P.Productname ASC'   
	
    EXEC (@sqlQuery)
    print (@sqlQuery)
    
    SET @sqlQuery2 = ' SELECT top 1 convert(varchar(10),ID.PaymentDueDate,101) AS PaymentDueDate,
									convert(varchar(10),ID.SaleDate,101) AS SaleDate,
									S.StoreName, SP.SupplierName,
									ID.RetailerInvoiceID as InvoiceNo,
									ID.InvoiceNo as SupplierInvoiceNo,
									Address1,
									City ,
									State ,
									PostalCode ,
									ID.PONo
						From  InvoiceDetails ID
								INNER JOIN Suppliers SP with(NOLOCK) on SP.SupplierId= ID.SupplierId
								INNER JOIN Products P ON ID.ProductID=P.ProductID
								INNER JOIN Stores S ON S.StoreID=ID.StoreID
								INNER JOIN Addresses A ON A.OwnerEntityID=S.StoreID  
								LEFT JOIN ProductIdentifiers PI ON PI.ProductID=P.ProductID AND ProductIdentifierTypeID=2
						Where 1=1 '
	
	IF(@InvoiceNumber<>'')
        set @sqlQuery2 = @sqlQuery2 + ' AND ID.RetailerInvoiceID =''' + @InvoiceNumber +''''
        
    IF(@ChainID<>'-1')
        SET @sqlQuery2 = @sqlQuery2 + ' AND ID.ChainID =' + @ChainID
       
    IF(@SupplierId<>'-1')
        SET @sqlQuery2 = @sqlQuery2 + ' AND ID.SupplierID =' + @SupplierId
          
    IF(@PaymentID<>'')
        SET @sqlQuery2 = @sqlQuery2 + ' AND ID.PaymentID =' + @PaymentID 
   
   PRINT( @sqlQuery2)    
    EXEC (@sqlQuery2)
		
End
GO
