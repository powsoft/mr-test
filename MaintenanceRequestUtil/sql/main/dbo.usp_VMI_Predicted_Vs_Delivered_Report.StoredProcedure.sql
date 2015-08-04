USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_VMI_Predicted_Vs_Delivered_Report]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_VMI_Predicted_Vs_Delivered_Report]
@SupplierId varchar(20),
@ChainId varchar(20),
@StoreNumber varchar(50),
@UPC varchar(50),
@FromDeliveryDate varchar(50),
@ToDeliveryDate varchar(50)
as -- exec [usp_VMI_Predicted_Vs_Delivered_Report] '44246','44199','','','1900-01-01','1900-01-01'
Begin
set nocount on
	Declare @sqlQuery varchar(4000)
	
	begin try
			drop table [@tmpReport]
	end try
	begin catch
	end catch
	
	set @sqlQuery = 'select P.SupplierName as [Supplier Name], P.ChainName as [Retailer Name], StoreIdentifier as [Store Number], 
					[ProductName] as [Product], UPC, convert(varchar(10),[Upcoming Delivery Date],101) as [Delivery Date], [Order Units], 
					''Ordered'' as RecordType
					into [@tmpReport]
					from PO_PurchaseOrderHistoryDataDetailed P
					where 1=1 '
					
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery + ' and P.ChainId=' + @ChainId

	if(@SupplierId<>'-1')
		set @sqlQuery = @sqlQuery + ' and P.SupplierId=' + @SupplierId
							
	if (convert(date, @FromDeliveryDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and P.[Upcoming Delivery Date] >= ''' + @FromDeliveryDate + ''''

	if(convert(date, @ToDeliveryDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and P.[Upcoming Delivery Date] <= ''' + @ToDeliveryDate + ''''
							
	if(@UPC<>'')
	   set @sqlQuery = @sqlQuery + ' and P.UPC like ''%' + @UPC + '%'''
	         
	if(@StoreNumber<>'')
	   set @sqlQuery = @sqlQuery + ' and P.StoreIdentifier like ''%' + @StoreNumber + '%'''
						
	set @sqlQuery = @sqlQuery + ' 					

					Union 

					select SP.SupplierName, C.ChainName, ST.StoreIdentifier, P.[ProductName], PD.IdentifierValue, 
					convert(varchar(10),S.[SaleDateTime],101), sum(Qty) as [Delivery Units],''Delivered'' as RecordType
					from StoreTransactions S
					inner join Suppliers SP on SP.SupplierId=S.SupplierId
					inner join Chains C on C.ChainId=S.ChainId
					inner join Stores ST on ST.StoreId=S.StoreId
					inner join Products P on P.ProductId=S.ProductId
					inner join ProductIdentifiers PD on PD.ProductId=S.ProductId and PD.ProductIdentifierTypeId in (2,8)
					where TransactionTypeId=5 '
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery + ' and S.ChainId=' + @ChainId

	if(@SupplierId<>'-1')
		set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId					
	
	if (convert(date, @FromDeliveryDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime >= ''' + @FromDeliveryDate + ''''

	if(convert(date, @ToDeliveryDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and S.SaleDateTime <= ''' + @ToDeliveryDate + ''''
							
	if(@UPC<>'')
	   set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @UPC + '%'''
	         
	if(@StoreNumber<>'')
	   set @sqlQuery = @sqlQuery + ' and ST.StoreIdentifier like ''%' + @StoreNumber + '%'''					
					
	set @sqlQuery = @sqlQuery + ' group by SP.SupplierName, C.ChainName, ST.StoreIdentifier, P.[ProductName], PD.IdentifierValue, S.[SaleDateTime]
								  having sum(qty)<>0
								  order by 4 '
	
	exec(@sqlQuery)
	
	SELECT [Supplier Name], [Store number], [Product], UPC, [Delivery Date], Ordered, Delivered
	FROM (
	SELECT [Supplier Name],[Retailer Name], [Store number], [Product], UPC, [Delivery Date], RecordType, [Order Units]
	FROM [@tmpReport]) up
	PIVOT (SUM([Order Units]) FOR RecordType IN (Ordered, Delivered)) AS pvt
	ORDER BY [Supplier Name],[Retailer Name], [Store number], [Product], UPC, [Delivery Date] desc
	
	begin try
		drop table [@tmpReport]
	end try
	begin catch
	end catch


End
GO
