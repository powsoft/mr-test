USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ViewInvoiceDetail]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_ViewInvoiceDetail] '3613464','-1','-1','02/14/2014'
CREATE procedure [dbo].[usp_ViewInvoiceDetail]
@InvoiceNumber varchar(255),
@ChainID varchar(40),
@SupplierId varchar(40),
@InvoiceProcessingDate varchar(50)

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
									isnull(ID.TotalCost,0) AS [Total Cost]
									
										
				  FROM InvoiceDetails ID with(NOLOCK) 
						INNER JOIN Products P with(NOLOCK) ON ID.ProductID=P.ProductID
						LEFT JOIN ProductIdentifiers PI with(NOLOCK) ON PI.ProductID=P.ProductID 
								   AND ProductIdentifierTypeID=2 
					  INNER JOIN InvoicesRetailer IR with(NOLOCK) ON ID.RetailerInvoiceID=IR.RetailerInvoiceID
						
				   Where 1=1 '
					
	  IF(@InvoiceNumber<>'')
        set @sqlQuery = @sqlQuery + ' AND ID.InvoiceNo =''' + @InvoiceNumber +''''
        
    IF(@InvoiceProcessingDate<>'')
        set @sqlQuery = @sqlQuery + ' AND convert(VARCHAR,IR.DatetimeCreated,101) =''' + @InvoiceProcessingDate +''''
        
    IF(@ChainID<>'-1')
        SET @sqlQuery = @sqlQuery + ' AND ID.ChainID =' + @ChainID	
        
    IF(@SupplierId<>'-1')
        SET @sqlQuery = @sqlQuery + ' AND ID.SupplierID =' + @SupplierId
        
    set @sqlQuery = @sqlQuery + ' Order By  P.Productname ASC'   
	
    EXEC (@sqlQuery)
    PRINT (@sqlQuery)
    
    
    SET @sqlQuery2 = ' SELECT top 1 convert(varchar(10),ID.PaymentDueDate,101) AS PaymentDueDate,
									convert(varchar(10),ID.SaleDate,101) AS SaleDate,
									S.StoreName,SP.SupplierName,
									InvoiceNo,
									Address1,
									City ,
									State ,
									PostalCode 
						From  InvoiceDetails ID with(NOLOCK)
								INNER JOIN Suppliers SP with(NOLOCK) on SP.SupplierId= ID.SupplierId
								INNER JOIN Products P with(NOLOCK) ON ID.ProductID=P.ProductID
								INNER JOIN Stores S with(NOLOCK) ON S.StoreID=ID.StoreID
								INNER JOIN Addresses A with(NOLOCK) ON A.OwnerEntityID=S.StoreID  
								INNER JOIN InvoicesRetailer IR with(NOLOCK) ON ID.RetailerInvoiceID=IR.RetailerInvoiceID
								LEFT JOIN ProductIdentifiers PI with(NOLOCK) ON PI.ProductID=P.ProductID AND ProductIdentifierTypeID=2
								Where 1=1 '
	
	IF(@InvoiceNumber<>'')
        SET @sqlQuery2 = @sqlQuery2 + ' AND ID.InvoiceNo =''' + @InvoiceNumber +''''
        
    IF(@InvoiceProcessingDate<>'')
        set @sqlQuery = @sqlQuery + ' AND convert(VARCHAR,IR.DatetimeCreated,101) =''' + @InvoiceProcessingDate +''''
        
    IF(@ChainID<>'-1')
        SET @sqlQuery2 = @sqlQuery2 + ' AND ID.ChainID =' + @ChainID	
        
    IF(@SupplierId<>'-1')
        SET @sqlQuery2 = @sqlQuery2 + ' AND ID.SupplierID =' + @SupplierId
    
    EXEC (@sqlQuery2)
		
End
GO
