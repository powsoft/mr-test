USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateAndSendBulkOrderFile]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_GenerateAndSendBulkOrderFile]
as
begin

	Declare @SupplierId varchar(10), @SupplierName varchar(100), @ChainID varchar(10), @LeadTime int, @SQLQuery varchar(3000)
	Declare @EmailSubject varchar(100)
	Declare @EmailBody varchar(2000)
	Declare @FileName varchar(200)
	Declare @DeliveryDate varchar(10)
	Declare @Pad varchar(10) = 112
	
	DECLARE BULK_ORDER_CURSOR CURSOR FOR 
	
	select S.SupplierId, S.SupplierName, P.ChainId, P.LeadTime
	from POOrderFileSchedule P
	inner join Suppliers S on S.SupplierId=P.SupplierId
	where FileType='Bulk' and ScheduleDay=datePart(weekday,getdate()) and LastTransmissionDate < getdate()
	
	OPEN BULK_ORDER_CURSOR;
		FETCH NEXT FROM BULK_ORDER_CURSOR INTO @SupplierId, @SupplierName, @ChainId, @LeadTime
	
		while @@FETCH_STATUS = 0
			begin
				
				set @DeliveryDate=convert(varchar(10),getdate() + @Leadtime, 101)
				
				exec usp_Generate_Purchase_Data_Bulk @SupplierId, @ChainId, '', '-1', '', @DeliveryDate	
				
				Delete from PO_BulkOrderData where SupplierId=@SupplierId and ChainId=@ChainId and DueDate = @DeliveryDate
				
				set @SQLQuery = 'select distinct P.SupplierId, P.ChainId, P.ProductId, convert(date,getdate(),101), CustomerRouteNumber as RouteNo, [Upcoming Delivery Date] as DueDate,
				(select top 1 SupplierProductId from DataTrue_Edi.dbo.ProductsSuppliersItemsConversion where SupplierId=P.SupplierID and ProductId=P.ProductId) as ItemNo,
				char(39) +P.UPC as UPCcode, ceiling(((sum([order units]))/(C.CasePortion * C.ItemsPerCase)))*(C.CasePortion * C.ItemsPerCase)  as [Qty]
				from DataTrue_Main.dbo.PO_PurchaseOrderHistoryData P
				inner join DataTrue_Edi.dbo.EDI_StoreCrossReference E on E.SupplierId=P.SupplierId and E.StoreId=P.StoreId
				inner join DataTrue_Edi.dbo.ProductsSuppliersItemsConversion C on C.SupplierID=P.SupplierId and C.ProductID=P.ProductId
				where P.SupplierId= ' + @SupplierId + ' and P.ChainId= ' + @ChainId + ' and [order units] is not null and C.ItemsPerCase is not null 
				and [Upcoming Delivery Date] = ''' + @DeliveryDate + '''
				group by CustomerRouteNumber, P.SupplierId, P.ChainId, P.ProductId, P.UPC, P.[Upcoming Delivery Date],C.CasePortion, C.ItemsPerCase
				order by 9, 5, 6, 7'
				
				exec ('Insert into [PO_BulkOrderData] ' + @SQLQuery)
				
				FETCH NEXT FROM BULK_ORDER_CURSOR INTO @SupplierId, @SupplierName, @ChainId, @LeadTime
			end
	CLOSE BULK_ORDER_CURSOR;
	DEALLOCATE BULK_ORDER_CURSOR;
	
	
	---GENERATE FILE AND SEND VIA EMAIL
	
	DECLARE BULK_FILE_CURSOR CURSOR FOR 
		
	select distinct S.SupplierId, S.SupplierName, P.ChainId
	from POOrderFileSchedule P
	inner join Suppliers S on S.SupplierId=P.SupplierId
	where FileType='Bulk' and ScheduleDay=datePart(weekday,getdate()) and LastTransmissionDate < getdate()
	
	OPEN BULK_FILE_CURSOR;
		FETCH NEXT FROM BULK_FILE_CURSOR INTO @SupplierId, @SupplierName, @ChainId
	
		while @@FETCH_STATUS = 0
			begin
			
				set @SQLQuery = 'Select RouteNo, DueDate, ItemNo, UPCcode, Qty from PO_BulkOrderData where SupplierId=' + @SupplierId + ' and ChainId=' + @ChainId + ' and DateCreated=convert(date,getdate(),101)'
				exec (@SQLQuery)
				if( @@ROWCOUNT >0)
				begin
					set @EmailSubject ='Bulk Order File for ' + @SupplierName
					set @EmailBody = N'Dear Customer, <br><br>'
					set @EmailBody = @EmailBody + N'The Bulk Order File for ' + @SupplierName + ' has been processed and is attached with this email! <br><br>'
					set @EmailBody = @EmailBody + N'Thank you for your business!<br><br>'
					
					set @FileName='Bulk_OrdersFile_' + replace(convert(varchar(10),getdate(), 101),'/','') + '.csv'
					
					--exec [usp_SendOrderEmail]  @EmailSubject, @EmailBody, @SQLQuery, @FileName
				End
				
				Update P set LastTransmissionDate=getdate()
				from POOrderFileSchedule P where FileType='Bulk' and SupplierId=@SupplierId and ChainId=@ChainId and ScheduleDay=datePart(weekday,getdate()) and LastTransmissionDate < getdate()
			
			FETCH NEXT FROM BULK_FILE_CURSOR INTO @SupplierId, @SupplierName, @ChainId
			end
	CLOSE BULK_FILE_CURSOR;
	DEALLOCATE BULK_FILE_CURSOR;
	
END
GO
