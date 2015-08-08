USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateDetailedOrderFile]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_GenerateDetailedOrderFile] 44246,44199,'06/26/2013',0,1
CREATE Procedure [dbo].[usp_GenerateDetailedOrderFile]

@SupplierId varchar(10), 
@ChainId varchar(10), 
@DeliveryDate varchar(10),
@ExportFlag varchar(1),
@OverWriteOrder varchar(1)
as
begin

	Declare @SQLQuery varchar(3000)
	
	if(@ExportFlag=0)
		exec [usp_Generate_Purchase_Data_Detailed] @SupplierId, @ChainId, '', '-1', '', @DeliveryDate, @OverWriteOrder

	set @SQLQuery = 'select distinct CustomerRouteNumber as RouteNo, [Upcoming Delivery Date] as DueDate,
						''Dollar General # '' + P.StoreIdentifier as CustName, 
						(select top 1 SupplierProductId from DataTrue_Edi.dbo.ProductsSuppliersItemsConversion where SupplierId=P.SupplierID 
						and ProductId=P.ProductId) as ItemNo,
						char(39) +P.UPC as UPCcode, ([order units]) as Qty, 
						POGenerationDate as TransDate, P.StoreIdentifier as DGStoreNumber, 
						CustomerStoreNumber as  CustomerNumber
					from DataTrue_Main.dbo.PO_PurchaseOrderHistoryDataDetailed P
					inner join DataTrue_Edi.dbo.EDI_StoreCrossReference E on E.SupplierId=P.SupplierId and E.StoreId=P.StoreId
					where P.SupplierId= ' + @SupplierId + ' and P.ChainId= ' + @ChainId + ' and [order units] is not null 
					and [Upcoming Delivery Date] = ''' + @DeliveryDate + '''
					and P.DeleteFlag=' + case when @OverWriteOrder='1' then '0' else '2' end + '
					order by POGenerationDate, [Upcoming Delivery Date], P.StoreIdentifier '
	
	exec (@SQLQuery)
	
	if(@OverWriteOrder != '1')
		Delete from DataTrue_Main.dbo.PO_PurchaseOrderHistoryDataDetailed where SupplierId=@SupplierId and ChainId=@ChainId and DeleteFlag=2				

END
GO
