USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Chart_Shrink_City]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Chart_Shrink_City]
 @AttributeValue varchar(5),
 @SupplierID varchar(5),
 @Custom1 varchar(255),
 @StoreNumber varchar(50) ,
 @StateID varchar(5)
as
Begin
 Declare @sqlQuery varchar(4000)
  
 set @sqlQuery = 'select FC.EntityID , SUM(totalcost) as Shrink, FC.ShortName as City
                      from InvoiceDetails  
                      inner join Stores on dbo.InvoiceDetails.StoreID=Stores.StoreId
                      inner join vStoreLookupByAddress on 
                      dbo.InvoiceDetails.ChainID=dbo.vStoreLookupByAddress.ChainID 
                      and dbo.InvoiceDetails.StoreID=dbo.vStoreLookupByAddress.StoreID  
                      inner join fcMap_Cities FC on FC.LongName=vStoreLookupByAddress.CountyName
                      and FC.StateName=vStoreLookupByAddress.State
                      and dbo.InvoiceDetails.chainid=''' + @AttributeValue + '''
					  and dbo.InvoiceDetails.InvoiceDetailTypeID in (3,5,9,10)	'
					  
		if(@SupplierID <>'-1') 
			set @sqlQuery  = @sqlQuery +  ' and invoiceDetails.SupplierID=' + @SupplierID

		if(@custom1='') 
			set @sqlQuery= @sqlQuery + ' and invoiceDetails.Banner is Null'

		else if(@custom1<>'-1') 
			set @sqlQuery= @sqlQuery + ' and invoiceDetails.Banner=''' + @custom1 + ''''

		if(@StoreNumber<>'') 
			set @sqlQuery = @sqlQuery +  ' and Stores.StoreIdentifier like ''%' + @StoreNumber + '%'''
		
		if(@StateID<>'') 
			set @sqlQuery = @sqlQuery +  ' and vStoreLookupByAddress.State = ''' + @StateID + ''''
		
		set @sqlQuery = @sqlQuery  + ' Group By FC.EntityID, FC.ShortName'

		execute(@sqlQuery); 

End
GO
