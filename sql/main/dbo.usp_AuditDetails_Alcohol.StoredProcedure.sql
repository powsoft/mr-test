USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AuditDetails_Alcohol]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_AuditDetails_Alcohol '1951025',''
CREATE PROCEDURE [dbo].[usp_AuditDetails_Alcohol] 

	 @RetailerInvoiceId varchar(50),
	 @Differential varchar(20)
	 
AS
BEGIN
	Declare @sqlQuery varchar(8000)

	Set @sqlQuery=' Select S.StoreIdentifier as StoreNumber, P.ProductName as [Product Name], PID.IdentifierValue as UPC, 
						cast(TotalCost as numeric(10,2)) as [Distributor Amount], 
						cast(isnull(sum(ST.Qty*ST.ReportedCost),0)as numeric(10,2)) as [Receiving Amount],
						cast(cast(TotalCost as numeric(10,2)) - isnull(sum(ST.Qty*ST.ReportedCost),0)as numeric(10,2)) as [Differences], 
						convert(varchar(10),PM.DateTimePaid,101) as  [Payment Due Date], 
						convert(varchar(10),ID.SaleDate,101) as [Delivery Date], ST.SaleDateTime as [Receiving Date],
						Id.RetailerInvoiceID as [Invoice No]
					From InvoiceDetails ID
					Inner Join Payments PM  on PM.PaymentID = ID.PaymentID 
					Inner Join Stores S on S.StoreID=ID.StoreID
					Inner Join Products P on P.ProductID=id.ProductID
					Left Join ProductIdentifiers PID on PID.ProductID=P.ProductID and PID.ProductIdentifierTypeId=2
					Left Join StoreTransactions ST on ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
					and ID.ProductID=ST.ProductID and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32
					Where 1=1 '

	if(@RetailerInvoiceId != '')
		Set @sqlQuery = @sqlQuery + ' and Id.RetailerInvoiceID = '+ @RetailerInvoiceId 
		
	Set @sqlQuery = @sqlQuery + ' GROUP BY S.StoreIdentifier,P.ProductName,PID.IdentifierValue,ID.TotalCost,
										PM.DateTimePaid,ST.SaleDateTime,ID.SaleDate,Id.RetailerInvoiceID '
	if(@Differential!='' )
		Set @sqlQuery = @sqlQuery + ' HAVING TotalCost - isnull(sum(ST.Qty*ST.ReportedCost),0) <> 0 '
		
	exec (@sqlQuery)
	
END
GO
