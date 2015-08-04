USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateAndSendDetailedOrderFile]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_GenerateAndSendDetailedOrderFile]
as
begin

	Declare @SupplierId varchar(10), @SupplierName varchar(100), @ChainID varchar(10), @LeadTime int, @SQLQuery varchar(3000)
	Declare @EmailSubject varchar(100)
	Declare @EmailBody varchar(2000)
	Declare @DeliveryDate varchar(10)
	Declare @FileName varchar(200)
	DECLARE DETAIL_ORDER_CURSOR CURSOR FOR 
	
	
	select S.SupplierId, S.SupplierName, P.ChainId, LeadTime
	from POOrderFileSchedule P
	inner join Suppliers S on S.SupplierId=P.SupplierId
	where FileType='Detail' and ScheduleDay=datePart(weekday,getdate()) and LastTransmissionDate < getdate()
		
	OPEN DETAIL_ORDER_CURSOR;
		FETCH NEXT FROM DETAIL_ORDER_CURSOR INTO @SupplierId, @SupplierName, @ChainId, @LeadTime
	
		while @@FETCH_STATUS = 0
			begin
				
				set @DeliveryDate=convert(varchar(10),getdate() + @Leadtime, 101)
				
				exec [usp_Generate_Purchase_Data_Detailed] @SupplierId, @ChainId, '', '-1', '', @DeliveryDate, 1
				
				set @SQLQuery = 'select distinct CustomerRouteNumber as RouteNo, [Upcoming Delivery Date] as DueDate,''Dollar General # '' + P.StoreIdentifier as CustName, 
				(select top 1 SupplierProductId from DataTrue_Edi.dbo.ProductsSuppliersItemsConversion where SupplierId=P.SupplierID and ProductId=P.ProductId) as ItemNo,
				char(39) +P.UPC as UPCcode, ([order units]) as Qty, 
				POGenerationDate as TransDate, P.StoreIdentifier as DGStoreNumber, 
				CustomerStoreNumber as  CustomerNumber
				from DataTrue_Main.dbo.PO_PurchaseOrderHistoryDataDetailed P
				inner join DataTrue_Edi.dbo.EDI_StoreCrossReference E on E.SupplierId=P.SupplierId and E.StoreId=P.StoreId
				where P.SupplierId= ' + @SupplierId + ' and P.ChainId= ' + @ChainId + ' and isnull([order units],0) >0 and [Upcoming Delivery Date] = ''' + @DeliveryDate + '''
				order by POGenerationDate, [Upcoming Delivery Date], P.StoreIdentifier '
				exec (@SQLQuery)
				
				if( @@ROWCOUNT >0)
				begin
					set @EmailSubject ='Detailed Order File for ' + @SupplierName
					set @EmailBody = N'Dear Customer, <br><br>'
					set @EmailBody = @EmailBody + N'The Detailed Order File for ' + @SupplierName + ' has been processed and is attached with this email! <br><br>'
					set @EmailBody = @EmailBody + N'Thank you for your business!<br><br>'
					
					set @FileName='Detailed_OrdersFile_' + replace(convert(varchar(10),@DeliveryDate, 101),'/','') + '.csv'
					
					--exec [usp_SendOrderEmail]  @EmailSubject, @EmailBody, @SQLQuery, @FileName
				End
				
				Update P set LastTransmissionDate=getdate()
				from POOrderFileSchedule P where FileType='Detail' and SupplierId=@SupplierId and ChainId=@ChainId and ScheduleDay=datePart(weekday,getdate()) and LastTransmissionDate < getdate()
				
				FETCH NEXT FROM DETAIL_ORDER_CURSOR INTO @SupplierId, @SupplierName, @ChainId, @LeadTime
			end
	CLOSE DETAIL_ORDER_CURSOR;
	DEALLOCATE DETAIL_ORDER_CURSOR;
	
END
GO
