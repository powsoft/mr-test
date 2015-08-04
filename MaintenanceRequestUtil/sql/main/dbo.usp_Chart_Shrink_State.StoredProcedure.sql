USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Chart_Shrink_State]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Chart_Shrink_State]
 @AttributeValue varchar(5),
 @SupplierID varchar(5),
 @Custom1 varchar(255),
 @StoreNumber varchar(50) ,
 @OrderDirection varchar(5)
as
Begin
 Declare @sqlQuery varchar(4000)
  
 set @sqlQuery = 'select vStoreLookupByAddress.State, SUM(totalcost) as Shrink 
                      from InvoiceDetails  
                      inner join Stores on dbo.InvoiceDetails.StoreID=Stores.StoreId
                      inner join vStoreLookupByAddress on 
                      
                      dbo.InvoiceDetails.ChainID=dbo.vStoreLookupByAddress.ChainID 
                      and dbo.InvoiceDetails.StoreID=dbo.vStoreLookupByAddress.StoreID  
                      and dbo.InvoiceDetails.chainid=''' + @AttributeValue + '''
					    and dbo.InvoiceDetails.InvoiceDetailTypeID in (3,5,9,10)'	
					  
		if(@SupplierID <>'-1') 
			set @sqlQuery  = @sqlQuery +  ' and invoiceDetails.SupplierID=' + @SupplierID

		if(@custom1='') 
			set @sqlQuery= @sqlQuery + ' and invoiceDetails.Banner is Null'

		else if(@custom1<>'-1') 
			set @sqlQuery= @sqlQuery + ' and invoiceDetails.Banner=''' + @custom1 + ''''

		if(@StoreNumber<>'') 
			set @sqlQuery = @sqlQuery +  ' and Stores.StoreIdentifier like ''%' + @StoreNumber + '%'''
		
		set @sqlQuery = @sqlQuery + 'where vStoreLookupByAddress.State != '''' '
		
		set @sqlQuery = @sqlQuery  + ' Group By vStoreLookupByAddress.State'

		execute(@sqlQuery); 
		
End
GO
