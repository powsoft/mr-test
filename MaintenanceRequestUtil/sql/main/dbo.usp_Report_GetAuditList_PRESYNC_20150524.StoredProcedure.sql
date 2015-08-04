USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetAuditList_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_Report_GetAuditList] '50964','50729','All','-1','-1','-1','180','1900-01-01','1900-01-01'
CREATE procedure [dbo].[usp_Report_GetAuditList_PRESYNC_20150524] 
 
@chainID varchar(20),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(10),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20) 

AS
BEGIN

Declare @Query varchar(8000)

  set @Query = 'SELECT distinct ID.SupplierInvoiceID, S.SupplierName AS [Supplier Name],
				convert(varchar(10), PM.DateTimePaid, 101) as [ACH Payment Date],
				PM.AmountOriginallyBilled as [ACH Amount], 
				(select isnull(sum(ST.Qty*ST.ReportedCost),0) from datatrue_report.dbo.StoreTransactions ST where ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
				and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32) as [Receiving Amount],
				PM.AmountOriginallyBilled-(select isnull(sum(ST.Qty*ST.ReportedCost),0) from datatrue_report.dbo.StoreTransactions ST where ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
				and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32) as [Differential]
				into [@tmpAuditList]
				from Payments PM 
				inner join datatrue_report.dbo.InvoiceDetails ID on PM.PaymentID = ID.PaymentID --PM.AppliesToRef=ID.SupplierInvoiceID
				inner join datatrue_report.dbo.Suppliers S on S.SupplierID=ID.SupplierID
				WHERE  PM.PaymentStatus=2 '
      
	if(@chainID  <>'-1') 
		set @Query  = @Query  +  ' and ID.ChainId=' + @chainID 

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and S.SupplierId=' + @SupplierId  

	if (@LastxDays > 0)
		set @Query = @Query + ' and (PM.DateTimePaid >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and PM.DateTimePaid <=getdate()) '  

	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and PM.DateTimePaid >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and PM.DateTimePaid <= ''' + @EndDate  + '''';

	exec (@query)
    
	Select distinct SupplierInvoiceID, [Supplier Name],[ACH Payment Date], [ACH Amount],
	case when [Receiving Amount]=0 then 'Not Received' else cast([Receiving Amount] as varchar) end as [Receiving Amount],
	case when [Receiving Amount]=0 then 'Pending' else cast([Differential] as varchar) end as [Differential] from [@tmpAuditList]

	begin try
		Drop Table [@tmpAuditList]
	end try
	begin catch
	end catch
 
END
GO
