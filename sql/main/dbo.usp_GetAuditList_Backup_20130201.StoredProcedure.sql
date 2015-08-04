USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAuditList_Backup_20130201]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_GetAuditList 42255, 40393,'12/15/2012'
create  procedure [dbo].[usp_GetAuditList_Backup_20130201]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @PaymentDate varchar(20)
 
as

Begin
Declare @sqlQuery varchar(4000)
	
	set @sqlQuery = 'SELECT distinct ID.SupplierInvoiceID, S.SupplierName AS [Supplier Name],
					convert(varchar(10), PM.DateTimePaid, 101) as [ACH Payment Date],
					PM.Amount as [ACH Amount], 
				   (select isnull(sum(ST.Qty*ST.ReportedCost),0) from StoreTransactions ST where ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
				   and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32) as [Receiving Amount],
				   PM.Amount-(select isnull(sum(ST.Qty*ST.ReportedCost),0) from StoreTransactions ST where ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
				   and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32) as [Differential]
				   into [@tmpAuditList]
			   from Payments PM 
			   inner join InvoiceDetails ID on PM.AppliesToRef=ID.SupplierInvoiceID
			   inner join Suppliers S on S.SupplierID=ID.SupplierID
			   WHERE  PM.PaymentStatus=96 '

	if(@SupplierId<>'-1')
		set @sqlQuery += ' and S.SupplierId=' + @SupplierId

	if(@ChainId<>'-1')
		set @sqlQuery += ' and ID.ChainId=' + @ChainId
		
	if (convert(date, @PaymentDate  ) > convert(date,'1900-01-01'))
        set @sqlQuery = @sqlQuery + ' and convert(varchar(10), PM.DateTimePaid, 101)  = ''' + @PaymentDate  + ''''
    
    exec (@sqlQuery)
    
    Select distinct SupplierInvoiceID, [Supplier Name],[ACH Payment Date], [ACH Amount], 
				   case when [Receiving Amount]=0 then 'Not Received' else cast([Receiving Amount] as varchar) end as [Receiving Amount],
				   case when [Receiving Amount]=0 then 'Pending' else cast([Differential] as varchar) end as [Differential] from [@tmpAuditList]
    
    begin try
        Drop Table [@tmpAuditList]
	end try
	begin catch
	end catch
            
End
GO
