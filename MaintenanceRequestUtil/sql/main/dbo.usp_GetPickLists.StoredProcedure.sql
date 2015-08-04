USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPickLists]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetPickLists]
@SupplierId varchar(20),
@ChainId varchar(20),
@UPC varchar(50),
@DriverName varchar(50),
@RouteNumber varchar(50)
as
 
Begin
Declare @sqlQuery varchar(4000)
    set @sqlQuery = 'select P.[Upcoming Delivery Date], SUV.DriverName as [Driver Name],
                    SUV.RouteNumber as [Route Number], UPC, SUM(P.[Order Units]) as [Total PO Units]
                    from PO_PurchaseOrderData P
                    Inner join SupplierBanners SB on SB.SupplierId = P.SupplierId and SB.Status=''Active'' and SB.Banner=P.Banner 
                    left join StoresUniqueValues SUV on SUV.SupplierID=P.SupplierId and SUV.StoreID=P.StoreId
                    where P.[Upcoming Delivery Date] >= getdate() '
          
        if(@SupplierId <>'-1' )  
            set @sqlQuery = @sqlQuery + ' and P.Supplierid = ' + @SupplierId
          
        if(@ChainId <> '-1' )
            set @sqlQuery = @sqlQuery + ' and P.ChainID = ''' + @ChainId + ''''
          
        if(@UPC <>'')
            set @sqlQuery  = @sqlQuery  + ' and P.UPC like ''%' + @UPC + '%''';
       
        if(@DriverName <> 'All')
            set @sqlQuery  = @sqlQuery  + ' and SUV.DriverName = ''' + @DriverName + '''';
           
        if(@RouteNumber <> 'All')
            set @sqlQuery  = @sqlQuery  + ' and SUV.RouteNumber = ''' + @RouteNumber + '''';
           
        set @sqlQuery  = @sqlQuery  + ' group by P.[Upcoming Delivery Date], SUV.DriverName , SUV.RouteNumber, UPC '
       
        exec(@sqlQuery);
 
End

--exec [usp_GetPickLists] '40562', '-1','','',''
GO
