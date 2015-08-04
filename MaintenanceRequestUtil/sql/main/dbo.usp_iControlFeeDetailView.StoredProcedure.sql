USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeDetailView]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* exec [usp_iControlFeeDetailView] '50964','','50965','December-2013',''
 EXEC usp_iControlFeeDetailViewToBeDeleted '50964','','50965','December-2013','','Chain'
 EXEC usp_iControlFeeDetailView '50964','50729','51080','May-2014','1900-01-01','1900-01-01'
 EXEC usp_iControlFeeDetailView '77941','-1','','December-2014','62366','Chain','12/01/2014','12/31/2014' */

CREATE PROC [dbo].[usp_iControlFeeDetailView]
@ChainId VARCHAR(10),
@SupplierId VARCHAR(10),
@StoreID VARCHAR(50),
@MonthYear VARCHAR(50),
@PersonID  VARCHAR(20),
@AccessLevel VARCHAR(20),
@FromInvoiceDate VARCHAR(20),
@ToInvoiceDate VARCHAR(20)

AS
	
BEGIN 
    DECLARE @sqlQuery VARCHAR(4000)
    
	SET @sqlQuery = 'SELECT DISTINCT R.ChainName AS [Retailer]
									  , ST.storeidentifier AS [Store #]
									  , S.SupplierName AS [Supplier]
									  , count(DISTINCT ID.RetailerInvoiceID) AS [Transactions]
									  , isnull(d.UnitCost, 0) AS [UnitPrice]
									  , d.UnitCost * count(DISTINCT ID.RetailerInvoiceID) AS  [Total $ Amount]

						FROM
							InvoiceDetails ID WITH (NOLOCK)
							INNER JOIN InvoicesRetailer IR WITH(NOLOCK) ON ID.RetailerInvoiceID = IR.RetailerInvoiceID
							JOIN InvoiceDetails d ON ID.ChainID = d.ChainID AND ID.SupplierID = d.SupplierID AND d.InvoiceDetailTypeID = 14
							INNER JOIN dbo.Chains R WITH(NOLOCK) ON ID.ChainID = R.ChainID
							INNER JOIN dbo.Suppliers S WITH(NOLOCK) ON ID.SupplierID = S.SupplierID
							INNER JOIN InvoiceDetailTypes IDT WITH(NOLOCK) ON IDT.InvoiceDetailTypeID = ID.InvoiceDetailTypeID
							--INNER JOIN Payments P WITH(NOLOCK) ON ID.PaymentID = P.PaymentID
							INNER JOIN Stores ST WITH(NOLOCK) ON ST.StoreID = ID.StoreID '
					
					IF(@AccessLevel = 'Chain')
						SET @sqlQuery += ' INNER JOIN RetailerAccess RA WITH(NOLOCK) ON RA.ChainID = R.ChainID '
					ELSE
						SET @sqlQuery += ' INNER JOIN SupplierBanners RA WITH(NOLOCK) ON RA.SupplierID = S.SupplierID AND RA.ChainID=R.ChainID '

				    SET @sqlQuery += ' WHERE 1 = 1 and id.InvoiceDetailTypeID =2 and abs(id.TotalCost) > .05 '
				    
	IF(@AccessLevel = 'Chain')
		BEGIN
			IF(@PersonID<>'')
				SET @sqlQuery += ' AND RA.PersonId=' + @PersonID
		END
		               
    IF(@ChainId<>'')
		SET @sqlQuery += ' AND R.ChainId=' + @ChainId

    IF(@SupplierId<>'' and @SupplierId <> '-1')
		SET @sqlQuery += ' AND S.SupplierId=' + @SupplierId
    
    IF(@StoreID<>'')
		SET @sqlQuery += ' AND ST.StoreID=' + @StoreID
        
	IF (CONVERT(DATE, @FromInvoiceDate ) > CONVERT(DATE,'1900-01-01'))
		SET @sqlQuery += ' AND CAST(IR.InvoiceDate AS DATE)>= CAST(''' + @FromInvoiceDate + ''' AS DATE)'

	IF(CONVERT(DATE, @ToInvoiceDate ) > CONVERT(DATE,'1900-01-01'))
		SET @sqlQuery += ' AND CAST(IR.InvoiceDate AS DATE) <= CAST(''' + @ToInvoiceDate + ''' AS DATE)'
		
    IF(@MonthYear<>'')
		SET @sqlQuery += ' AND datename (MONTH, cast(IR.InvoiceDate AS DATE)) + ''-'' + datename (YEAR, cast(IR.InvoiceDate AS DATE)) =''' + @MonthYear+''''
   
    SET @sqlQuery += ' GROUP BY R.ChainName
					, S.SupplierName
					, datename (MONTH, cast(IR.InvoiceDate AS DATE)) + ''-'' + datename (YEAR, cast(IR.InvoiceDate AS DATE)) 
					, S.SupplierId
					, R.ChainID
					, ST.StoreID
					, ST.StoreIdentifier
					, d.UnitCost'
   
    SET @sqlQuery += ' ORDER BY 1 , 2 ,3 '
	
    PRINT (@sqlQuery)
    EXEC (@sqlQuery)
	
END
GO
