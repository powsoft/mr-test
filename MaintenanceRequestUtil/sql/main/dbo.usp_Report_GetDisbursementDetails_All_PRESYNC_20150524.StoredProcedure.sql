USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetDisbursementDetails_All_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_GetDisbursementDetails_All_PRESYNC_20150524] 
 -- usp_Report_GetDisbursementDetails_All '40393,44199','40384','All','-1','40558,41440,44246','-1','0','01/01/2013','12/31/2013'
 @chainID varchar(1000),
 @PersonID int,
 @Banner varchar(50),
 @ProductUPC varchar(20),
 @SupplierId varchar(1000),
 @StoreId varchar(10),
 @LastxDays int,
 @StartDate varchar(20),
 @EndDate varchar(20) 
AS
BEGIN
declare @AttValue int

select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
Declare @Query varchar(8000)

  SET @Query = 'select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], ss.StoreIdentifier as [Store Number], 
    Ir.SupplierInvoiceId as [Invoice No], 
    convert(varchar,IR.InvoiceDate,101) as [InvoiceCreationDate],
    convert(varchar,IR.InvoicePeriodStart,101) as InvoicePeriodStart,
    convert(varchar,IR.InvoicePeriodEnd,101) as InvoicePeriodEnd,
    ''$''+ Convert(varchar(50), round(IR.OriginalAmount,2)) as NetInvoice, 
    ''$''+ Convert(varchar(50), round(SUM(ID.TotalCost),2)) as TotalPaid, 
    ''$''+ Convert(varchar(50), round(SUM(ID.TotalRetail),2)) as Retail, 
    Pd.BatchNo  AS  [Batch Number],
    Pd.Checkno  AS  [Check Number],
    convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
    IT.InvoiceTypeName as InvoiceType,
    convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
    (PH.CheckNoReceived) as RetailerCheckNumber,
    ST.StatusName AS [Payment Status], 
    P.PaymentId, ID.SupplierID,ID.Storeid
    
    from InvoicesSupplier IR
    inner join datatrue_report.dbo.InvoiceDetails ID on ID.SupplierInvoiceID=IR.SupplierInvoiceID
    inner join datatrue_report.dbo.Suppliers S on ID.SupplierID=S.SupplierID
    inner join Chains c on ID.chainid=c.chainid
    inner join stores ss on ID.StoreID=ss.StoreID 
    inner join supplierbanners sb on sb.supplierid=ID.supplierid AND ss.Custom1=sb.Banner AND ss.Custom1=sb.Banner AND sb.Status=''Active''
    inner join Payments P on P.PaymentID=ID.PaymentID
    inner join PaymentHistory PH on PH.PaymentID=ID.PaymentID and Ph.PaymentStatus=P.Paymentstatus
    inner join Statuses ST on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
    inner join InvoiceTypes IT on IR.InvoiceTypeID=IT.InvoiceTypeID
    left join PaymentDisbursements PD on PD.DisbursementId=PH.DisbursementID  
    
    where 1=1 '
 
 --if @AttValue =17
	-- set @query = @query + ' and C.ChainID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
 --else
	-- set @query = @query + ' and S.SupplierID in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
                  
 if(@chainID  <>'-1') 
	set @Query  = @Query  +  ' and C.ChainID in (' + @chainID +')'

 if(@SupplierId<>'-1') 
	set @Query  = @Query  + ' and S.SupplierId in (' + @SupplierId  +')'

 if(@Banner<>'All') 
	set @Query  = @Query + ' and ss.Custom1 like ''%' + @Banner + '%'''

 if(@StoreId <>'-1')
	set @Query = @Query + ' and ID.StoreId= ' + @StoreId
 
 if (@LastxDays > 0)
	begin
		set @startDate= convert(varchar(10),dateadd(d, -1 * @LastxDays, { fn NOW()}) , 101)
		set @EndDate= convert(varchar(10), { fn NOW() } ,101)
	end
		
 if(convert(date, @StartDate ) > convert(date,'1900-01-01'))
	set @Query = @Query + ' and IR.InvoiceDate >= ''' + @StartDate + ''''
  
 if(convert(date, @EndDate ) > convert(date,'1900-01-01'))
	set @Query = @Query + ' and IR.InvoiceDate <= ''' + @EndDate + '''' 
  
 set @Query = @Query + ' group by S.SupplierName, C.ChainName, ss.StoreIdentifier, Ir.SupplierInvoiceId, 
     convert(varchar,IR.InvoiceDate,101), convert(varchar,IR.InvoicePeriodStart,101), convert(varchar,IR.InvoicePeriodEnd,101), 
     Pd.BatchNo, Pd.Checkno, convert(varchar,Pd.DisbursementDate,101), IT.InvoiceTypeName, IR.OriginalAmount,
     convert(varchar,PH.DatePaymentReceived,101), PH.CheckNoReceived, ST.StatusName, 
     P.PaymentID, ID.SupplierID,ID.Storeid'  
	
	print @query
	exec (@Query )
 
END
GO
