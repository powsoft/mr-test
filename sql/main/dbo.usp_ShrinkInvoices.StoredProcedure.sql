USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ShrinkInvoices]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_ShrinkInvoices] 40393, 41464,'-1','','',''
CREATE procedure [dbo].[usp_ShrinkInvoices]

@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@InvoiceDate varchar(20),
@LastSettleDate varchar(20)
as
Begin

Declare @sqlQuery varchar(4000)

set @sqlQuery = 'select c.ChainName, t.Custom1 as Banner, s.SupplierName as [Supplier Name], t.StoreIdentifier as StoreNum, i.SBTNumber, 
						i.RetailerInvoiceID as InvoiceNo, 
						cast(SUM(i.FinalInvoiceTotalCost/i.TotalCost*i.Totalqty ) as decimal(7,0)) as  [No Of Units], 
						cast( SUM(i.FinalInvoiceTotalCost) as decimal(7,2)) As [Total Cost],
						convert(varchar(10), i.DateTimeCreated, 101) as [Invoice Date], 
						convert(varchar(10), SaleDate, 101) as [Shrink Settled-Up to Date]

				from InvoiceDetails i
					inner join suppliers s on s.supplierid=i.supplierid
					inner join stores t on t.StoreID =i.StoreID 
					inner join Chains c on c.ChainID=i.ChainID
					inner join SupplierBanners SB on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=t.Custom1
				where i.RetailerInvoiceID is not null AND ISNULL(FinalInvoiceTotalCost,0) <>0 AND ISNULL(TotalQty,0)!=0
				and InvoiceDetailTypeID = 11  '

if(@ChainId<>'-1' and @ChainId<>'')
	set @sqlQuery = @sqlQuery + ' and c.ChainID=' + @ChainId

if(@SupplierId<>'-1')
	set @sqlQuery = @sqlQuery + ' and s.SupplierId=' + @SupplierId

if(@BannerId<>'-1')
	set @sqlQuery = @sqlQuery + ' and t.custom1=''' + @BannerId + ''''

if(@InvoiceDate<>'-1')
	set @sqlQuery = @sqlQuery + ' and convert(varchar(10), i.DateTimeCreated, 101)=''' + @InvoiceDate + ''''

if(@LastSettleDate<>'-1')
	set @sqlQuery = @sqlQuery + ' and i.SaleDate=''' + @LastSettleDate + ''''

set @sqlQuery = @sqlQuery +  ' group by i.RetailerInvoiceID, s.SupplierName, c.ChainName, t.Custom1, t.StoreIdentifier, i.SBTNumber, i.DateTimeCreated, SaleDate'

set @sqlQuery = @sqlQuery + ' order by t.StoreIdentifier, saledate';

exec(@sqlQuery);

End
GO
