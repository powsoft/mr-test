USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ViewInvoiceDetailDR_New]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_ViewInvoiceDetailDR_New '265458','81651','81650',''
CREATE procedure [dbo].[usp_ViewInvoiceDetailDR_New]
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
									cast(ST.ReceivedQty as numeric(10,0)) as [Receiving Qty], 
									cast(ST.[RuleCost] as numeric(10,2)) as [Receiving Cost],
									(cast(ST.ReceivedQty as numeric(10,0)) *  cast(ST.[RuleCost] as numeric(10,2))) as [Total Receiving Cost],
									IC.InvoiceNumber as [Receiving Invoice#],
									IC.SupplierInvoiceNumber as [Delivery Invoice#]
						FROM DataTrue_main..iCAM_POMatch IC
						INNER JOIN InvoiceDetails ID ON ID.InvoiceNo  = isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) AND IC.PaymentID=ID.PaymentID
						INNER JOIN Products P ON ID.ProductID=P.ProductID
						INNER JOIN Stores S ON S.StoreID=IC.StoreID
						INNER JOIN ProductIdentifiers PI ON PI.ProductID=P.ProductID AND ProductIdentifierTypeID=2 
						left join (select ChainId, SupplierId, StoreId, ProductId, SaleDateTime, sum(Qty) as ReceivedQty , RuleCost , SupplierInvoiceNumber,PONo
										from StoreTransactions S With(NoLock) 
										where S.TransactionTypeId=32
										group by ChainId, SupplierId, StoreId, ProductId, SaleDateTime, RuleCost,SupplierInvoiceNumber,PONo
									 ) ST on IC.SupplierId=ST.SupplierId and IC.ChainId=ST.ChainId 
										and IC.StoreId=ST.StoreId and ID.ProductId=ST.ProductId 
										and IC.InvoiceDate=ST.SaleDateTime and ST.SupplierInvoiceNumber=isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber)
						Where 1=1 '
					
	IF(@InvoiceNumber<>'')
        set @sqlQuery = @sqlQuery + ' and isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) =''' + @InvoiceNumber +''''
        
    IF(@ChainID<>'-1')
        SET @sqlQuery = @sqlQuery + ' AND IC.ChainID =' + @ChainID	
        
    IF(@SupplierId<>'-1')
        SET @sqlQuery = @sqlQuery + ' AND IC.SupplierID =' + @SupplierId
       
    IF(@PaymentID<>'')
        SET @sqlQuery = @sqlQuery + ' AND IC.PaymentID =' + @PaymentID 
        
    set @sqlQuery = @sqlQuery + ' Order By  P.Productname ASC'   
	
    EXEC (@sqlQuery)
    print (@sqlQuery)
    
    SET @sqlQuery2 = ' SELECT top 1 convert(varchar(10),ID.PaymentDueDate,101) AS PaymentDueDate,
									convert(varchar(10),ID.SaleDate,101) AS SaleDate,
									S.StoreName, SP.SupplierName,
									IC.InvoiceNumber as [Receiving Invoice#],
									IC.SupplierInvoiceNumber as [Delivery Invoice#],
									Address1,
									City ,
									State ,
									PostalCode ,
									ID.PONo
						  From  DataTrue_main..iCAM_POMatch IC
								INNER JOIN InvoiceDetails ID ON ID.InvoiceNo = isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) AND IC.PaymentID=ID.PaymentID
								INNER JOIN Suppliers SP with(NOLOCK) on SP.SupplierId= IC.SupplierId
								INNER JOIN Products P ON ID.ProductID=P.ProductID
								INNER JOIN Stores S ON S.StoreID=IC.StoreID
								INNER JOIN Addresses A ON A.OwnerEntityID=S.StoreID  
								LEFT JOIN ProductIdentifiers PI ON PI.ProductID=P.ProductID AND ProductIdentifierTypeID=2
						  Where 1=1 '
	
	IF(@InvoiceNumber<>'')
        set @sqlQuery2 = @sqlQuery2 + ' and isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) =''' + @InvoiceNumber +''''
        
    IF(@ChainID<>'-1')
        SET @sqlQuery2 = @sqlQuery2 + ' AND IC.ChainID =' + @ChainID
       
    IF(@SupplierId<>'-1')
        SET @sqlQuery2 = @sqlQuery2 + ' AND IC.SupplierID =' + @SupplierId
          
    IF(@PaymentID<>'')
        SET @sqlQuery2 = @sqlQuery2 + ' AND IC.PaymentID =' + @PaymentID 
   
   PRINT( @sqlQuery2)    
    EXEC (@sqlQuery2)
		
End
GO
