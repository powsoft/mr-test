USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iphone_GetInvoiceList]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_iphone_GetInvoiceList]
@SupplierID nvarchar(20),
@ChainID nvarchar(20),
@StoreNo nvarchar(20),
@UPC nvarchar(20),
@SaleFromDate varchar(20),
@SaleToDate varchar(20),
@RecordCount nvarchar(20)

as


Begin
	Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'SELECT distinct top ' + @RecordCount + ' R.RetailerInvoiceID as [Invoice No], cast(dbo.FDateTime(R.InvoiceDate) as varchar) as [Sale Date], 
					  R.OriginalAmount as [Total Cost]
					  FROM InvoicesRetailer R 
					  left outer join InvoiceDetails ID on ID.RetailerInvoiceID=R.RetailerInvoiceID
					  Inner join dbo.Stores on dbo.Stores.StoreID = ID.StoreID 
					  Inner join dbo.ProductIdentifiers on dbo.ProductIdentifiers.ProductID = ID.ProductID 
                      WHERE 1=1 '

	if(@supplierID<>'-1')
		set @sqlQuery = @sqlQuery +  ' and ID.SupplierID=' + @supplierID

	if(@ChainID<>'-1')
		set @sqlQuery = @sqlQuery +  ' and ID.ChainId=' + @ChainID

	if(@StoreNo<>'')
		set @sqlQuery = @sqlQuery + ' and  Stores.StoreIdentifier like ''%' + @StoreNo + '%''';

	if(@UPC<>'')
		set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @UPC + '%''';

	if convert(date, @SaleFromDate ) > convert(date,'1900-01-01')
		set @sqlQuery = @sqlQuery + ' and R.InvoiceDate >= ''' + @SaleFromDate + '''' 

	else if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and R.InvoiceDate <= ''' + @SaleToDate + '''';

	
	--set @sqlQuery = @sqlQuery + ' Order by R.RetailerInvoiceID , R.InvoiceDate '
 
 execute(@sqlQuery);

End
GO
