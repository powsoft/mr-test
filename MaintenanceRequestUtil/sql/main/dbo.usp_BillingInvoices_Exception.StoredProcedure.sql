USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_BillingInvoices_Exception]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  usp_BillingInvoices_Exception '40393','40558','Cub Foods','06/23/2013','06/24/2013',2,'',1,'31574','UPC ASC',1,25,0

CREATE procedure [dbo].[usp_BillingInvoices_Exception]

@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@FromInvoiceDate varchar(50),
@ToInvoiceDate varchar(50),
@ProductIdentifierType varchar(10),
@ProductIdentifierValue varchar(50),
@StoreIdentifierType varchar(10),
@StoreIdentifierValue varchar(50),
@OrderBy varchar(100),
@StartIndex int,
@PageSize int,
@DisplayMode int

as

Begin

Declare @sqlQuery varchar(8000)
Declare @CostFormat varchar(10)
 
	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	else
		set @CostFormat=4
	
	set @sqlQuery = 'select C.ChainName as [Retailer Name], SP.SupplierName as [Supplier Name], ST.Custom1 as Banner,ST.StoreIdentifier as [Store Number], PD.IdentifierValue as UPC, P.ProductName as Product, 
						PID.IdentifierValue as [Vendor Item Number], S.Qty as [Total Qty], convert(varchar(10), D.DateTimeCreated, 101) as [Invoice Date], 
						cast(D.TotalCost as numeric(10,' + @CostFormat + '))  as [Total Cost]
						from dbo.StoreTransactions S 
						inner join dbo.Chains C on C.ChainId=S.ChainId
						inner join dbo.Suppliers SP on SP.SupplierId=S.SupplierId
						inner join dbo.Stores ST on ST.StoreId=S.StoreId and ST.ChainId=S.ChainId
						inner join dbo.Products P on P.ProductId=S.ProductId
						inner join dbo.ProductIdentifiers PD on PD.ProductId=S.ProductId 
						--and PD.ProductIdentifierTypeId= case when SP.IsRegulated=1 then 3 else 2 end
						and (PD.ProductIdentifierTypeId= case when SP.IsRegulated=1 then 3 else 2 end or PD.ProductIdentifierTypeId= case when SP.IsRegulated=1 then 3 else 8 end)
						inner join dbo.InvoiceDetails D on D.SupplierId=S.SupplierID and D.ChainId=S.ChainId and D.StoreId=S.StoreId and D.ProductId=S.ProductId and D.SaleDate=S.SaleDateTime
						Left JOIN  dbo.ProductIdentifiers PID ON PID.ProductID = P.ProductID and PID.ProductIdentifierTypeId = 3 and PID.OwnerEntityId=SP.SupplierID 
						WHERE  1=1  '

	set @sqlQuery = @sqlQuery + ' and S.UnAuthorizedAssignment = 1 '
	
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery + ' and S.ChainID=' + @ChainId

	if(@SupplierId<>'-1')
		set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId

	if(@BannerId<>'-1')
		set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @BannerId + ''''

	if (convert(date, @FromInvoiceDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and convert(DATE,D.DateTimeCreated,101) >= ''' + @FromInvoiceDate + '''';

	if(convert(date, @ToInvoiceDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and convert(DATE,D.DateTimeCreated,101) <=''' + @ToInvoiceDate + '''';

	if(@ProductIdentifierValue<>'')
	begin

		-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
			
		else if (@ProductIdentifierType=7)
			 set @sqlQuery = @sqlQuery + ' and PID.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
	end

	if(@StoreIdentifierValue<>'')
	begin
		-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
		if (@StoreIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and ST.StoreIdentifier like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
		else if (@StoreIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
	end

	--set @sqlQuery = @sqlQuery + ' order by 1,2,3,4,5';
	
	set @sqlQuery = [dbo].GetPagingQuery_New('SELECT DISTINCT * FROM  (' +@sqlQuery+ ') as temp ', @orderby, @StartIndex ,@PageSize ,@DisplayMode)

	print @sqlQuery;

	exec (@sqlQuery);
	
	

End
GO
