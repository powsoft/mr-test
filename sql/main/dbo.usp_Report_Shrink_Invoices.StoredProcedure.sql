USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Shrink_Invoices]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_Report_Shrink_Invoices '-1','2','All','','-1','-1','','1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_Shrink_Invoices]

@chainID varchar(1000),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(1000),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
AS
Begin

Declare @sqlQuery varchar(max)

set @sqlQuery = 'select ' + @MaxRowsCount + ' c.ChainName, t.Custom1 as Banner, s.SupplierName as [Supplier Name], t.StoreIdentifier as StoreNum, i.SBTNumber, 
						i.RetailerInvoiceID as InvoiceNo, 
						cast(SUM(i.FinalInvoiceTotalCost/i.TotalCost*i.Totalqty ) as decimal(7,0)) as  [No Of Units], 
						cast( SUM(i.FinalInvoiceTotalCost) as decimal(7,2)) As [Total Cost],
						convert(varchar(10), i.DateTimeCreated, 101) as [Invoice Date], 
						convert(varchar(10), SaleDate, 101) as [Shrink Settled-Up to Date]

				from InvoiceDetails i with(nolock) 
					inner join Suppliers s with(nolock)  on s.supplierid=i.supplierid
					inner join stores t with(nolock)  on t.StoreID =i.StoreID 
					inner join Chains c with(nolock)  on c.ChainID=i.ChainID
					inner join SupplierBanners SB with(nolock)  on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=t.Custom1
				where i.RetailerInvoiceID is not null AND ISNULL(FinalInvoiceTotalCost,0) <>0 
				and InvoiceDetailTypeID = 11  
				AND ISNULL(TotalQty,0)!=0'				


if(@chainID  <>'-1') 
		set @sqlQuery   = @sqlQuery  +  ' and c.ChainID in (' + @chainID +')'

if(@Banner<>'All') 
set @sqlQuery  = @sqlQuery + ' and t.Custom1 like ''%' + @Banner + '%'''

if(@SupplierId<>'-1') 
set @sqlQuery  = @sqlQuery  + ' and s.SupplierId in (' + @SupplierId  +')'
			
	
if (@LastxDays > 0)
		set @sqlQuery = @sqlQuery + ' and (i.DateTimeCreated between dateadd(d,-' +  cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'  
	
if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and i.DateTimeCreated >= ''' + @StartDate  + ''''

	if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and i.DateTimeCreated <= ''' + @EndDate  + ''''
	
	if(@StoreId <>'-1') 
set @sqlQuery = @sqlQuery + ' and t.StoreIdentifier like ''%' + @StoreId + '%'''

set @sqlQuery = @sqlQuery +  ' group by i.RetailerInvoiceID, s.SupplierName, c.ChainName, t.Custom1, t.StoreIdentifier, i.SBTNumber, i.DateTimeCreated, SaleDate'

set @sqlQuery = @sqlQuery + ' order by t.StoreIdentifier, saledate';

print(@sqlQuery);
exec(@sqlQuery);

End
GO
