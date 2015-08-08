USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoiceSummary_beta]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_InvoiceSummary_beta1 '65151','-1','-1','-1','','1900-01-01','1900-01-01','2','','','1','','1900-01-01','','','','','1900-01-01','1900-01-01',-1,'1'
--exec usp_InvoiceSummary_beta1 '65151','-1','-1','-1','','1900-01-01','1900-01-01','2','','','1','','1900-01-01','','','','','1900-01-01','1900-01-01',-1,''


CREATE procedure [dbo].[usp_InvoiceSummary_beta]
@ChainId varchar(10),
@SupplierId varchar(10),
@BannerId varchar(50),
@InvoiceTypeId varchar(10),
@InvoiceNumber varchar(255),
@SaleFromDate varchar(50),
@SaleToDate varchar(50),
@ProductIdentifierType int,
@ProductIdentifierValue varchar(250),
@StoreIdentifierType int,
@StoreIdentifierValue varchar(250),
@OtherOption int,
@Others varchar(250),
@PaymentDueDate varchar(50),
@FromInvoiceNumber varchar(255),
@ToInvoiceNumber varchar(255),
@SupplierInvoiceNumber varchar(255),
@InvoiceFromDate varchar(50),
@InvoiceToDate varchar(50),
@RegulatedSupplier varchar(10),
@ChainUser varchar(10),
@SupplierIdentifierValue varchar(10),
@RetailerIdentifierValue varchar(10)

as
--exec usp_InvoiceSummary_beta '79370','81523','Buc-ees','-1','','1900-01-01','1900-01-01','2','','1','','1','','1900-01-01','','','','1900-01-01','1900-01-01','-1','1','',''
Begin

Declare @sqlQuery varchar(4000)
Declare @CostFormat varchar(10)
 
	 if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	 else if(@ChainId<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @ChainId
	 else
		set @CostFormat=4
	 
	set @CostFormat=isnull(@costFormat,4)
			 
	set @sqlQuery = 'SELECT distinct C.ChainName as [Retailer Name], S.SupplierName AS [Supplier Name], ST.StoreName AS [Store Name], 
				ST.Custom2 AS [SBT Number], ST.Custom1 AS Banner,
                IT.InvoiceTypeName AS Type, R.RetailerInvoiceID as [Retailer Invoice No], R.InvoiceNumber  as [Supplier Invoice Number],
                convert(varchar(10), R.InvoiceDate, 101) as [Invoice Date], 
                cast(sum(IsNull(ID.TotalCost-case when S.IsRegulated=0 and ' + @ChainUser + '=0 then isnull(ID.Adjustment1,0) else 0 end,0)) as numeric(10,' + @CostFormat + ')) as [Total Cost],
								cast(sum(ID.[UnitRetail]*ID.TotalQty) as numeric(10,' + @CostFormat + '))  as [Total Retail],
                convert(varchar(10), R.InvoicePeriodStart, 101) as [Invoice Period Start Date],
                convert(varchar(10), R.InvoicePeriodEnd, 101) as [Invoice Period End Date],
                convert(varchar(10), ID.PaymentDueDate, 101) as [Payment Due Date],
                WH.WarehouseName as [Distribution Center], SUV.RegionalMgr as [Regional Manager], 
                SUV.SalesRep as [Sales Representative],
                case when S.IsRegulated=1 and (select COUNT(distinct SupplierAccountNumber) from StoresUniqueValues where StoreID=ID.StoreID and SupplierID=ID.SupplierID)>1 
					then ID.RawStoreIdentifier 
				else SUV.supplieraccountnumber end as [Supplier Acct Number],
                SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number],
                ID.RefIDToOriginalInvNo as [Invoice Aggregator Number],
                S.SupplierIdentifier as [Wholesaler ID #]
        FROM    InvoicesRetailer R WITH (NOLOCK)
        inner join InvoiceDetails ID WITH (NOLOCK) on ID.RetailerInvoiceID=R.RetailerInvoiceID
        inner join Suppliers S WITH (NOLOCK) on S.SupplierID=ID.SupplierID
        inner join Chains C WITH (NOLOCK) on C.ChainID=ID.ChainID
        inner join InvoiceTypes IT WITH (NOLOCK) on IT.InvoiceTypeID=R.InvoiceTypeID
        INNER Join Stores ST WITH (NOLOCK) on ST.StoreID=ID.StoreID 
        Inner Join SupplierBanners SB WITH (NOLOCK) on SB.SupplierId=S.SupplierId and SB.Banner=ST.Custom1 
        LEFT OUTER JOIN  dbo.StoresUniqueValues SUV WITH (NOLOCK) ON SUV.StoreID = ST.StoreID and SUV.SupplierID=S.SupplierID
        left JOIN Warehouses WH WITH (NOLOCK) ON WH.ChainID=C.ChainID and WH.WarehouseId=SUV.DistributionCenter
        WHERE 1=1 --and abs(id.TotalCost) > .05  
        and	ID.InvoiceDetailId 	not in (Select distinct InvoiceDetailId
											from InvoiceDetails I with (nolock) 
											where  abs(TotalCost)=0.01  and PaymentID IS not null and ProcessID is null and Storeid=51020
										)'
                 
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId

	if(@SupplierId<>'-1')
		set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId

	if(@BannerId<>'-1')
		set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @BannerId + ''''

	if(@InvoiceTypeId<>'-1')
		set @sqlQuery = @sqlQuery + ' and IT.InvoiceTypeID=' + @InvoiceTypeId

	if(len(@InvoiceNumber)>0)
		set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId =' + @InvoiceNumber

	if(len(@FromInvoiceNumber)>0)
		set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId >=' + @FromInvoiceNumber

	if(len(@ToInvoiceNumber)>0)
		set @sqlQuery = @sqlQuery + ' and R.RetailerInvoiceId <=' + @ToInvoiceNumber    
	    
	if(@SupplierInvoiceNumber<>'')
	  set @sqlQuery = @sqlQuery + ' and R.InvoiceNumber like ''%' + @SupplierInvoiceNumber + '%'''
	    
	if (convert(date, @SaleFromDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and ID.SaleDate>= ''' + @SaleFromDate + ''''

	if(convert(date, @SaleToDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and ID.SaleDate <= ''' + @SaleToDate + ''''
	
	if (convert(date, @InvoiceFromDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and cast(ID.DateTimeCreated as date) >= ''' + @InvoiceFromDate + ''''

	if(convert(date, @InvoiceToDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and cast(ID.DateTimeCreated as date) <= ''' + @InvoiceToDate + ''''
	
	if(convert(date, @PaymentDueDate ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and ID.PaymentDueDate = ''' + @PaymentDueDate + ''''    
	
	 if(@SupplierIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and S.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
		
	if(@RetailerIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
		    
	if(@StoreIdentifierValue<>'')
	begin
	  -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
	 if (@StoreIdentifierType=1)
	  set @sqlQuery = @sqlQuery + ' and ST.storeidentifier ' + @StoreIdentifierValue
	 else if (@StoreIdentifierType=2)
	  set @sqlQuery = @sqlQuery + ' and ST.Custom2 ' + @StoreIdentifierValue
	 else if (@StoreIdentifierType=3)
	  set @sqlQuery = @sqlQuery + ' and ST.StoreName ' + @StoreIdentifierValue
	end

	if(@Others<>'')
	 begin
	  -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
	  -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
	                          
	  if (@OtherOption=1)
	   set @sqlQuery = @sqlQuery + ' and WH.WarehouseName ' + @Others 
	  else if (@OtherOption=2)
	   set @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr ' + @Others 
	  else if (@OtherOption=3)
	   set @sqlQuery = @sqlQuery + ' and SUV.SalesRep ' + @Others 
	  else if (@OtherOption=4)
	   set @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber ' + @Others 
	  else if (@OtherOption=5)
	   set @sqlQuery = @sqlQuery + ' and SUV.DriverName ' + @Others 
	  else if (@OtherOption=6)
	   set @sqlQuery = @sqlQuery + ' and SUV.RouteNumber ' + @Others 

	end
	
	IF(@RegulatedSupplier <> '-1')
	BEGIN	
		if(@RegulatedSupplier = '2')
			set @sqlQuery = @sqlQuery + ' and ID.RecordType = 2 '
		else if(@RegulatedSupplier = '3')
			set @sqlQuery = @sqlQuery + ' and ID.RecordType <> 2 and S.IsRegulated =0 '
		else 
			set @sqlQuery = @sqlQuery + ' and S.IsRegulated=' + @RegulatedSupplier
	END
  
	set @sqlQuery = @sqlQuery + '  group by  C.ChainName, S.SupplierName, ST.StoreName, 
									ST.Custom2, ST.Custom1,IT.InvoiceTypeName, R.RetailerInvoiceID, R.InvoiceNumber,
									convert(varchar(10), R.InvoiceDate, 101), 
									cast(IsNull(R.OriginalAmount,0) as numeric(10,2)),
									convert(varchar(10), R.InvoicePeriodStart, 101),
									convert(varchar(10), R.InvoicePeriodEnd, 101),
									convert(varchar(10), ID.PaymentDueDate, 101),
									WH.WarehouseName, SUV.RegionalMgr,
									SUV.SalesRep,ID.StoreId, ID.SupplierID,ID.RawStoreIdentifier,
									S.IsRegulated,SUV.supplieraccountnumber ,
									SUV.DriverName, SUV.RouteNumber,
									ID.RefIDToOriginalInvNo,S.SupplierIdentifier '
	print(@sqlQuery)
	exec(@sqlQuery)

End
GO
