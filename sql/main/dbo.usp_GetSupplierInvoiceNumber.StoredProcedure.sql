USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSupplierInvoiceNumber]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [usp_GetSupplierInvoiceNumber] 40393,'40557','FULL','01/01/2014','02/02/2014','8308950','10'
CREATE PROC [dbo].[usp_GetSupplierInvoiceNumber]
(
@ChainID VARCHAR(20),
@SupplierID VARCHAR(20),
@BannerName VARCHAR(20),
@FromDate VARCHAR(20),
@ToDate VARCHAR(20),
@SupplierInvoiceNo VARCHAR(50),
@Count VARCHAR(20)
)
AS 
BEGIN
		DECLARE @Query VARCHAR(2000)
		set @BannerName = replace(@BannerName, '''''', '''')
	    set @BannerName = replace(@BannerName, '''', '''''')

		SET @Query = 'SELECT Distinct top '+ @Count +' S.SupplierInvoiceNumber as FldName 
					  
					  FROM dbo.StoreTransactions S With(NoLock) 
					  Inner join Chains C With(NoLock)  ON c.chainid=S.chainid
					  Inner join Suppliers Sup With(NoLock)  ON Sup.SupplierId=S.SupplierId
					  Inner join Stores ST With(NoLock)  ON St.StoreID=S.StoreId  and ST.chainid=c.ChainID
					  WHERE 1=1 '

        IF (@ChainID <> 'All' AND @ChainID <> '-1' AND @ChainID <> '')
            SET @Query += ' and C.ChainId = ' + @ChainId

        IF (@SupplierID <> 'All' AND @SupplierID <> '-1' AND @SupplierID <> '')
            SET @Query += ' and Sup.SupplierId = ' + @SupplierId;

		IF (@BannerName <> 'All' AND @BannerName <> '-1' AND @BannerName <> '' AND @BannerName <> 'FULL')
            SET @Query += ' and ST.Custom1 in(SELECT * FROM dbo.split('''+ @BannerName + ''', '',''))'


        IF (@FromDate <> '__/__/____' AND @FromDate <> '')
            SET @Query += ' and S.SaleDateTime >= ''' + @FromDate + ''''

        IF (@ToDate <> '__/__/____' AND @ToDate <> '')
            SET @Query += ' and S.SaleDateTime <= ''' + @ToDate + ''''
            
         IF (@SupplierInvoiceNo <> 'All' AND @SupplierInvoiceNo <> '-1' AND @SupplierInvoiceNo <> '')
            SET @Query += ' and S.SupplierInvoiceNumber like ''%' + @SupplierInvoiceNo + '%''';    

		EXEC(@Query);
		print(@Query);
END
GO
