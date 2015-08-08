USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_GetDisbursementDetails]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[usp_Report_GetDisbursementDetails] 
 -- exec usp_Report_GetDisbursementDetails 40393,44183,'All','-1','40570','-1',2,'1900-01-01','1900-01-01'


 @chainID varchar(20),
 @PersonID int,
 @Banner varchar(50),
 @ProductUPC varchar(20),
 @SupplierId varchar(10),
 @StoreId varchar(10),
 @LastxDays int,
 @StartDate varchar(20),
 @EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 ' 
AS
BEGIN
declare @AttValue int

select @attvalue = AttributeID  from AttributeValues with(nolock) where OwnerEntityID=@PersonID and AttributeID=17
 
Declare @Query varchar(8000)

  SET @Query = 'select distinct ' + @MaxRowsCount + ' S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], ss.StoreIdentifier as [Store Number], 
    Ir.SupplierInvoiceId as [Invoice No], 
    convert(varchar,IR.InvoiceDate,101) as [InvoiceCreationDate],
    convert(varchar,IR.InvoicePeriodStart,101) as InvoicePeriodStart,
    convert(varchar,IR.InvoicePeriodEnd,101) as InvoicePeriodEnd,
    ''$''+ Convert(varchar(50), round(isnull(IR.OriginalAmount,0),2)) as NetInvoice, 
    ''$''+ Convert(varchar(50), round(SUM(isnull(ID.TotalCost,0)),2)) as TotalPaid, 
    ''$''+ Convert(varchar(50), round(SUM(isnull(ID.TotalRetail,0)),2)) as Retail, 
    Pd.BatchNo  AS  [Batch Number],
    Pd.Checkno  AS  [Check Number],
    convert(varchar,Pd.DisbursementDate,101)  AS  [DisbursementDate],
    IT.InvoiceTypeName as InvoiceType,
    convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
    (PH.CheckNoReceived) as RetailerCheckNumber,
    ST.StatusName AS [Payment Status], 
    P.PaymentId, ID.SupplierID,ID.Storeid
    
    from InvoicesSupplier IR with(nolock)
    inner join InvoiceDetails ID with(nolock) on ID.SupplierInvoiceID=IR.SupplierInvoiceID
    inner join Suppliers S with(nolock) on ID.SupplierID=S.SupplierID
    inner join Chains c with(nolock) on ID.chainid=c.chainid
    inner join stores ss with(nolock) on ID.StoreID=ss.StoreID 
    inner join SupplierBanners sb with(nolock) on sb.supplierid=ID.supplierid AND ss.Custom1=sb.Banner AND ss.Custom1=sb.Banner AND sb.Status=''Active''
    inner join Payments P with(nolock) on P.PaymentID=ID.PaymentID
    inner join PaymentHistory PH with(nolock) on PH.PaymentID=ID.PaymentID and Ph.PaymentStatus=P.Paymentstatus
    inner join Statuses ST with(nolock) on ST.StatusIntValue=P.PaymentStatus and ST.StatusTypeID=14
    inner join InvoiceTypes IT with(nolock) on IR.InvoiceTypeID=IT.InvoiceTypeID
    left join PaymentDisbursements PD with(nolock) on PD.DisbursementId=PH.DisbursementID  
    
    where 1=1 '
 
if @AttValue =17
			set @query = @query + ' and c.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		else
			set @query = @query + ' and s.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'

                  
 if(@chainID  <>'-1') 
	set @Query  = @Query  +  ' and C.ChainID=' + @chainID 

 if(@SupplierId<>'-1') 
	set @Query  = @Query  + ' and S.SupplierId=' + @SupplierId  

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
 
 exec (@Query )
 print (@query)
END
GO
