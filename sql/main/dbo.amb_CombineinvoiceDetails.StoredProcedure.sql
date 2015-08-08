USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_CombineinvoiceDetails]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec  [CombineinvoiceDetails] '529442,529449,529432,529445,'
CREATE  PROCEDURE [dbo].[amb_CombineinvoiceDetails]
    @InvoiceNos varchar(8000)
AS 
BEGIN
	begin try
		Drop Table #tmpReport
		Drop Table #tmpInvoices
	end try
	begin catch
	end catch

	Create Table #tmpInvoices ([InvoiceNo]  int)
	DECLARE @NextString NVARCHAR(40)
	DECLARE @Pos INT
	DECLARE @NextPos INT
	DECLARE @Delimiter NVARCHAR(40)
	SET @Delimiter = ','
	SET @Pos = charindex(@Delimiter,@InvoiceNos)

	WHILE (@pos <> 0)
	BEGIN
		SET @NextString = substring(@InvoiceNos,1,@Pos - 1)
		Insert into #tmpInvoices 
		select top 1 @NextString from Stores
		
		SET @InvoiceNos = substring(@InvoiceNos,@pos+1,len(@InvoiceNos))
		SET @pos = charindex(@Delimiter,@InvoiceNos)
	END 	
			
	Select Id.SupplierId, Id.ChainId, Id.StoreID, Id.ProductId, convert(varchar,IR.InvoicePeriodEnd,101) as [Week Ending], Id.UnitCost as Cost, 
		SUM(isnull(SF.Qty,0)) as [Draws], 
		sum(Id.TotalQty) as [POS Units], SUM(isnull(ID1.TotalQty,0)) as [DCR Units]
	into #tmpReport
	from InvoiceDetails Id
		inner join InvoicesSupplier IR on IR.SupplierInvoiceID=ID.SupplierInvoiceID
		inner join #tmpInvoices t on t.InvoiceNo=ID.SupplierInvoiceId
		left join InvoiceDetails Id1 on ID1.SupplierID=ID.SupplierID and ID1.ChainID=ID.ChainID and ID1.StoreID=ID.StoreID and ID1.ProductID=ID.ProductID and ID1.InvoiceDetailTypeID=5 and ID1.SupplierInvoiceId =t.InvoiceNo
		left join StoreTransactions_Forward SF on SF.SupplierID=ID.SupplierID and SF.ChainID=ID.ChainID and SF.StoreID=ID.StoreID and SF.ProductID=ID.ProductID and SF.SaleDateTime=ID.SaleDate and SF.TransactionTypeId=29
	where ID.InvoiceDetailTypeId=1
	group by Id.SupplierId, Id.ChainId, Id.StoreID, Id.ProductId, IR.InvoicePeriodEnd, Id.UnitCost
	order by Id.SupplierId, Id.ChainId, Id.StoreID, Id.ProductId

	
	Select distinct S.SupplierIdentifier, C.ChainIdentifier, ST.LegacySystemStoreIdentifier, t.[Week Ending]
	from #tmpReport t
		inner join Suppliers S on S.SupplierId=t.SupplierId
		inner join Chains C on C.ChainId=t.ChainId
		inner join Stores ST on ST.StoreID =t.StoreId
		inner join Products P on P.ProductID=t.ProductID
		
	Select distinct S.SupplierIdentifier, C.ChainIdentifier, ST.LegacySystemStoreIdentifier, P.ProductName, t.[Week Ending],  
		t.Cost, t.[Draws], t.[Draws]-t.[POS Units] as [Returns], t.[POS Units], t.[DCR Units], t.[POS Units] + t.[DCR Units] as [TTL Units],
		(t.Cost*t.[POS Units]) as [POS Net], (t.Cost*t.[DCR Units]) as [DCR Net], (t.Cost*(t.[POS Units] + t.[DCR Units])) as [TTL Net]
	from #tmpReport t
		inner join Suppliers S on S.SupplierId=t.SupplierId
		inner join Chains C on C.ChainId=t.ChainId
		inner join Stores ST on ST.StoreID =t.StoreId
		inner join Products P on P.ProductID=t.ProductID
        
End
GO
