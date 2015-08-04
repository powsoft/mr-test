USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetAuditList_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_Report_GetAuditList_All] '40393,44199','40384','All','-1','40558,41440,44246','-1','0','07/01/2013','07/06/2013'
CREATE  procedure [dbo].[usp_Report_GetAuditList_All] 
 
@chainID varchar(max),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(max),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20) 

AS
BEGIN

Declare @Query varchar(max)

  set @Query = 'SELECT distinct ID.SupplierInvoiceID, S.SupplierName AS [Supplier Name],
				convert(varchar(10), PM.DateTimePaid, 101) as [ACH Payment Date],
				PM.AmountOriginallyBilled as [ACH Amount], 
				(select isnull(sum(ST.Qty*ST.ReportedCost),0) from StoreTransactions ST where ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
				and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32) as [Receiving Amount],
				PM.AmountOriginallyBilled-(select isnull(sum(ST.Qty*ST.ReportedCost),0) from StoreTransactions ST where ST.SupplierId=ID.SupplierID and ST.ChainID=ID.ChainID and ST.StoreID=ID.StoreID 
				and ID.SaleDate=ST.SaleDateTime and ST.TransactionTypeID=32) as [Differential]
				into [#tmpAuditList]
				from Payments PM  WITH(NOLOCK) 
				inner join InvoiceDetails ID on PM.PaymentID = ID.PaymentID --PM.AppliesToRef=ID.SupplierInvoiceID
				inner join Suppliers S on S.SupplierID=ID.SupplierID
				WHERE  PM.PaymentStatus=2 '
   
	if(@chainID  <>'-1') 
		set @Query  = @Query  +  ' and ID.ChainId in (' + @chainID +')'

	if(@SupplierId<>'-1') 
		set @Query  = @Query  + ' and S.SupplierId in (' + @SupplierId  +')'

	if (@LastxDays > 0)
		set @Query = @Query + ' and (PM.DateTimePaid >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and PM.DateTimePaid <=getdate()) '  

	if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and PM.DateTimePaid >= ''' + @StartDate  + '''';

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @Query = @Query + ' and PM.DateTimePaid <= ''' + @EndDate  + '''';


	
    set @Query = @Query + ';
	Select distinct SupplierInvoiceID, [Supplier Name],[ACH Payment Date], [ACH Amount],
	case when [Receiving Amount]=0 then ''Not Received'' else cast([Receiving Amount] as varchar) end as [Receiving Amount],
	case when [Receiving Amount]=0 then ''Pending'' else cast([Differential] as varchar) end as [Differential] from [#tmpAuditList]; drop table #tmpAuditList '
exec (@query)
	 
 
END
GO
