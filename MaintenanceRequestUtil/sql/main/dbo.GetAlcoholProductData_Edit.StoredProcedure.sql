USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[GetAlcoholProductData_Edit]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from DataTrue_EDI.dbo.InboundInventory_Web 
--[GetAlcoholProductData_edit] '101', 42255, '54321',''

CREATE proc [dbo].[GetAlcoholProductData_Edit]
@StoreID varchar(50), 
@SupplierID varchar(50), 
@InvoiceNo varchar(max),
@UPC varchar(50)
as
 
Begin
declare @sqlQuery varchar(max)

	SET @sqlQuery = 'SELECT IW.DataTrueProductID as ProductID,IW.ProductIdentifier as SKU,IW.ProductIdentifier as UPC,IW.ProductName,
	IW.UnitMeasure as UOM ,CONVERT(DECIMAL(10,2),IW.Cost) AS Cost, 
	(select sum(qty) from [DataTrue_EDI].[dbo].[InboundInventory_Web] where ReferenceIdentification=''' + @InvoiceNo + ''' and PurposeCode=''DB'' AND PRODUCTIDENTIFIER=IW.pRODUCTIDENTIFIER and DataTrueSupplierID=' + @SupplierID +') as QtyDB,
	(select sum(Adjustment1) from [DataTrue_EDI].[dbo].[InboundInventory_Web] where ReferenceIdentification=''' + @InvoiceNo + ''' and PurposeCode=''DB'' AND PRODUCTIDENTIFIER=IW.pRODUCTIDENTIFIER and DataTrueSupplierID=' + @SupplierID +') 
	 as Discount ,
	ISNULL((select sum(qty) from [DataTrue_EDI].[dbo].[InboundInventory_Web] where ReferenceIdentification=''' + @InvoiceNo + ''' and PurposeCode=''CR'' AND PRODUCTIDENTIFIER=IW.pRODUCTIDENTIFIER and DataTrueSupplierID=' + @SupplierID +' ),0) as QtyCR,
	(select sum(Adjustment2) from [DataTrue_EDI].[dbo].[InboundInventory_Web] where ReferenceIdentification=''' + @InvoiceNo + ''' and PurposeCode=''DB'' AND PRODUCTIDENTIFIER=IW.pRODUCTIDENTIFIER and DataTrueSupplierID=' + @SupplierID +') 
	 as Adjustments ,
	(select sum(PPC)  from [DataTrue_EDI].[dbo].[InboundInventory_Web] where ReferenceIdentification=''' + @InvoiceNo + ''' and PurposeCode=''DB'' AND PRODUCTIDENTIFIER=IW.pRODUCTIDENTIFIER and DataTrueSupplierID=' + @SupplierID +') as PPC, 
	 IW.RecordStatus,IW.Retail as Price

	FROM [DataTrue_EDI].[dbo].[InboundInventory_Web] IW 
	left join Stores S on S.StoreId=IW.DataTrueStoreID
	where 1=1  and IW.DataTrueSupplierID=' + @Supplierid 

	if len(@upc) > 0
		set @sqlQuery = @sqlQuery + ' and IW.ProductIdentifier=''' + @UPC + ''''
		
	if len(@StoreID) > 0
		set @sqlQuery = @sqlQuery + ' and IW.StoreIdentifier=''' + @StoreID + ''''	
	set @sqlQuery = @sqlQuery + ' and ReferenceIdentification=''' + @InvoiceNo + ''' and purposecode=''DB'''
	 EXEC(@sqlQuery)
	 PRINT(@sqlQuery)
End
GO
