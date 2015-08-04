USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AuditDetails_Alcohol_Backup_20130201]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- usp_AuditDetails_Alcohol 439071,'12'
create PROCEDURE [dbo].[usp_AuditDetails_Alcohol_Backup_20130201] 

	 @SupplierInvoiceNumber varchar(50),
	 @Differential varchar(20)
	 
AS
BEGIN
	Declare @sqlQuery varchar(8000)

	Set @sqlQuery=' Select S.StoreIdentifier as StoreNumber, P.ProductName as [Product Name], PID.IdentifierValue as UPC, TotalCost as [ACH Amount], 
					isnull(sum(ST.Qty*ST.ReportedCost),0) as [Receiving Amount],
					TotalCost - isnull(sum(ST.Qty*ST.ReportedCost),0) as [Differences], 
					convert(varchar(10),PM.DateTimePaid,101) as  [ACH Payment Date], 
					convert(varchar(10),ID.SaleDate,101) as [Delivery Date], ST.SaleDateTime as [Receiving Date]
					From InvoiceDetails ID
					Inner Join Payments PM  on PM.AppliesToRef=ID.SupplierInvoiceID
					Inner Join Stores S on S.StoreID=ID.StoreID
					Inner Join Products P on P.ProductID=id.ProductID
					Inner Join ProductIdentifiers PID on PID.ProductID=P.ProductID
					Left Join StoreTransactions ST on ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
					and ID.ProductID=ST.ProductID and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32
					Where 1=1 '

	if(@SupplierInvoiceNumber != '')
		Set @sqlQuery = @sqlQuery + ' and ID.SupplierInvoiceID = '+ @SupplierInvoiceNumber
		
	Set @sqlQuery = @sqlQuery + ' GROUP BY S.StoreIdentifier,P.ProductName,PID.IdentifierValue,ID.TotalCost,
										PM.DateTimePaid,ST.SaleDateTime,ID.SaleDate '
	if(@Differential!='' )
		Set @sqlQuery = @sqlQuery + ' HAVING TotalCost - isnull(sum(ST.Qty*ST.ReportedCost),0) <> 0 '
		
exec(@sqlQuery)
	
END
GO
