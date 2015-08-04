USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Chart_Shrink_Store]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Chart_Shrink_Store]
 @AttributeValue varchar(5),
 @SupplierID varchar(5),
 @Custom1 varchar(255),
 @StoreNumber varchar(50) ,
 @OrderDirection varchar(5)
as
Begin
 Declare @sqlQuery varchar(4000)
  
 set @sqlQuery = 'select top 5 Stores.StoreName, SUM(totalcost) as Shrink 
				from InvoiceDetails  inner join Stores on
				dbo.stores.StoreId = dbo.InvoiceDetails.StoreId and dbo.Stores.ActiveStatus=''Active''
				where dbo.InvoiceDetails.chainid=''' + @AttributeValue + '''
				 and dbo.InvoiceDetails.InvoiceDetailTypeID in (3,5,9,10)'
		 
		if(@SupplierID <>'-1') 
			set @sqlQuery  = @sqlQuery +  ' and invoiceDetails.SupplierID=' + @SupplierID

		if(@custom1='') 
			set @sqlQuery= @sqlQuery + ' and invoiceDetails.Banner is Null'

		else if(@custom1<>'-1') 
			set @sqlQuery= @sqlQuery + ' and invoiceDetails.Banner=''' + @custom1 + ''''

		if(@StoreNumber<>'') 
			set @sqlQuery = @sqlQuery +  ' and Stores.StoreIdentifier like ''%' + @StoreNumber + '%'''
		
		set @sqlQuery = @sqlQuery  + ' Group By Stores.StoreName order by Shrink ' + @OrderDirection

		execute(@sqlQuery); 
		
End
GO
