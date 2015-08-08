USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iphone_GetSalesForUPC]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_iphone_GetSalesForUPC]
@SupplierID nvarchar(20),
@ChainID nvarchar(20),
@StoreNo nvarchar(20),
@UPC nvarchar(20),
@InvoiceDate nvarchar(20)
as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'SELECT  P.IdentifierValue as [UPC],Stores.StoreIdentifier as [Store Number],  sum(ID.TotalQty) as [Qty]
					  FROM InvoicesRetailer R 
					  left outer join InvoiceDetails ID on ID.RetailerInvoiceID=R.RetailerInvoiceID
					  Inner join dbo.Stores on dbo.Stores.StoreID = ID.StoreID 
					  Inner join dbo.ProductIdentifiers P on P.ProductID = ID.ProductID 
                      WHERE  1=1'

 if(@supplierID<>'-1')
    set @sqlQuery = @sqlQuery +  ' and ID.SupplierID=' + @supplierID
 
 if(@ChainID<>'-1')
    set @sqlQuery = @sqlQuery +  ' and ID.ChainId=' + @ChainID

 if(@StoreNo<>'')
    set @sqlQuery = @sqlQuery + ' and  Stores.StoreIdentifier like ''%' + @StoreNo + '%''';
 
 if(@UPC<>'')
    set @sqlQuery = @sqlQuery + ' and P.IdentifierValue like ''%' + @UPC + '%''';

 if(@InvoiceDate<>'')
    set @sqlQuery = @sqlQuery +  ' and convert(date, R.InvoiceDate) =''' + @InvoiceDate + ''''
 
 set @sqlQuery = @sqlQuery + ' group by P.IdentifierValue, Stores.StoreIdentifier '
   
 set @sqlQuery = @sqlQuery + ' Order by P.IdentifierValue, Stores.StoreIdentifier '
 
 execute(@sqlQuery);

End
GO
