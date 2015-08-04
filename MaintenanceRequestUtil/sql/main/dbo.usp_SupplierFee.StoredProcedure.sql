USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SupplierFee]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_SupplierFee] '65669','-1','02/01/2014','02/28/2014','','','','','Chain'
-- exec [usp_SupplierFee] '50964','50729','04/29/2014','05/26/2014','1506','','','','Supplier'
CREATE PROC [dbo].[usp_SupplierFee]
@ChainId VARCHAR(10),
@SupplierId VARCHAR(10),
@InvoiceFromdate VARCHAR(50),
@InvoiceTodate VARCHAR(50),
@StoreIdentifierType VARCHAR(20),
@StoreIdentifierValue VARCHAR(250),
@SupplierIdentifierValue VARCHAR(20),
@RetailerIdentifierValue VARCHAR(20),
@PersonID  VARCHAR(20),
@AccessLevel VARCHAR(20)
AS
	
BEGIN 
  DECLARE @sqlQuery VARCHAR(4000)
	DECLARE @AttValue INT
	
	SELECT @attvalue = AttributeID  FROM AttributeValues WHERE OwnerEntityID=@PersonID and AttributeID=17
	SET @sqlQuery = 'SELECT DISTINCT  
										R.ChainName AS [Retailer]
									, ST.StoreIdentifier AS [Store #]
								  , S.SupplierName AS [Supplier]
									, S.SupplierId
									, R.ChainID
									, datename (MONTH, cast(IR.InvoiceDate AS DATE)) + ''-'' + datename (YEAR, cast(IR.InvoiceDate AS DATE)) AS [Month]
									, ST.StoreID
									, d.UnitCost AS [UnitPrice]
									, count(DISTINCT ID.SupplierInvoiceID) AS [Transactions]
									, d.UnitCost * count(DISTINCT ID.SupplierInvoiceID) AS [Total $ Amount]

						FROM
							InvoiceDetails ID WITH (NOLOCK)
							INNER JOIN InvoicesSupplier IR WITH(NOLOCK) ON ID.SupplierInvoiceID = IR.SupplierInvoiceID
							JOIN InvoiceDetails d ON ID.ChainID = d.ChainID AND ID.SupplierID = d.SupplierID AND d.InvoiceDetailTypeID = 15
							INNER JOIN dbo.Chains R WITH(NOLOCK) ON ID.ChainID = R.ChainID
							INNER JOIN dbo.Suppliers S WITH(NOLOCK) ON ID.SupplierID = S.SupplierID
							INNER JOIN Payments P WITH(NOLOCK) ON ID.PaymentID = P.PaymentID
							INNER JOIN Stores ST WITH(NOLOCK) ON ST.StoreID = ID.StoreID and ST.ChainId = ID.ChainId '
							
						IF(@AccessLevel = 'Chain')
							SET @sqlQuery += ' INNER JOIN RetailerAccess RA WITH(NOLOCK) ON RA.ChainID = R.ChainID '
						ELSE
							SET @sqlQuery += ' INNER JOIN SupplierBanners RA WITH(NOLOCK) ON RA.SupplierID = S.SupplierID AND RA.ChainID=R.ChainID '

						SET @sqlQuery += ' WHERE 1 = 1  AND id.InvoiceDetailTypeID=2 AND abs(ID.TotalCost ) > .05 '
	
	 IF(@AccessLevel = 'Chain')
		 BEGIN
			IF(@PersonID <> '' )
				SET @sqlQuery += ' AND RA.PersonId=' + @PersonID
		 END
	             
    IF(@ChainId<>'-1')
		SET @sqlQuery += ' AND R.ChainId=' + @ChainId

    IF(@SupplierId<>'-1')
		SET @sqlQuery += ' AND S.SupplierId=' + @SupplierId
        
	IF (CONVERT(DATE, @InvoiceFromdate ) > CONVERT(DATE,'1900-01-01'))
		SET @sqlQuery += ' AND CAST(IR.InvoiceDate AS DATE)>= CAST(''' + @InvoiceFromdate + ''' AS DATE)'

	IF(CONVERT(DATE, @InvoiceTodate ) > CONVERT(DATE,'1900-01-01'))
		SET @sqlQuery += ' AND CAST(IR.InvoiceDate AS DATE) <= CAST(''' + @InvoiceTodate + ''' AS DATE)'
   
  --  IF(@StoreNo<>'')
		--SET @sqlQuery += ' AND ST.storeidentifier=''' + @StoreNo+''''
		
    if(@SupplierIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and S.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
			
	if(@RetailerIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and R.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
    
	if(@StoreIdentifierValue<>'')
	begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
			if (@StoreIdentifierType=1)
					set @sqlQuery = @sqlQuery + ' and ST.StoreIdentifier ' + @StoreIdentifierValue 
			else if (@StoreIdentifierType=2)
					set @sqlQuery = @sqlQuery + ' and ST.Custom2 ' + @StoreIdentifierValue 
			else if (@StoreIdentifierType=3)
					set @sqlQuery = @sqlQuery + ' and ST.StoreName ' + @StoreIdentifierValue 
	end

    SET @sqlQuery += 'GROUP BY R.ChainName
							, datename (MONTH, cast(IR.InvoiceDate AS DATE)) + ''-'' + datename (YEAR, cast(IR.InvoiceDate AS DATE)) 
							, S.SupplierName
							, S.SupplierId
							, R.ChainID
							, ST.StoreID
							, ST.StoreIdentifier
							, d.UnitCost '
    
	SET @sqlQuery += ' ORDER BY 1 , 2 ,3 '
	
	EXEC (@sqlQuery)
	
END
GO
