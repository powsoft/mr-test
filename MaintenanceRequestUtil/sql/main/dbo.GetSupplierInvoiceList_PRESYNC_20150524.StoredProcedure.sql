USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[GetSupplierInvoiceList_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [GetSupplierInvoiceList] 40393,'40557','aj','01/01/2014','05/05/2014'
CREATE PROC [dbo].[GetSupplierInvoiceList_PRESYNC_20150524]
(
@ChainID VARCHAR(20),
@SupplierID VARCHAR(20),
@BannerName VARCHAR(20),
@FromDate VARCHAR(20),
@ToDate VARCHAR(20)
)
AS 
BEGIN
		DECLARE @Query VARCHAR(2000)
		set @BannerName = replace(@BannerName, '''''', '''')
	    set @BannerName = replace(@BannerName, '''', '''''')

		SET @Query = 'SELECT Distinct S.SupplierInvoiceNumber 
					  
					  FROM dbo.StoreTransactions S With(NoLock) 
					  Inner join Chains C With(NoLock)  ON c.chainid=S.chainid
					  Inner join Suppliers Sup With(NoLock)  ON Sup.SupplierId=S.SupplierId
					  Inner join Stores ST With(NoLock)  ON St.StoreID=S.StoreId  and ST.chainid=c.ChainID
					  WHERE 1=1 '

        IF (@ChainID <> 'All' AND @ChainID <> '-1' AND @ChainID <> '')
            SET @Query += ' and C.ChainId = ' + @ChainId

        IF (@SupplierID <> 'All' AND @SupplierID <> '-1' AND @SupplierID <> '')
            SET @Query += ' and Sup.SupplierId = ' + @SupplierId;
			 
        --IF (@BannerName <> 'All' AND @BannerName <> '-1' AND @BannerName <> '' AND @BannerName <> 'FULL')
         --   SET @Query += ' and S.StoreId in (select distinct storeid from dbo.Stores where Custom1=''' + @BannerName + ''')';

		IF (@BannerName <> 'All' AND @BannerName <> '-1' AND @BannerName <> '' AND @BannerName <> 'FULL')
            SET @Query += ' and ST.Custom1 in(SELECT * FROM dbo.split('''+ @BannerName + ''', '',''))'


        IF (@FromDate <> '__/__/____' AND @FromDate <> '')
            SET @Query += ' and S.SaleDateTime >= ''' + @FromDate + ''''

        IF (@ToDate <> '__/__/____' AND @ToDate <> '')
            SET @Query += ' and S.SaleDateTime <= ''' + @ToDate + ''''

		EXEC(@Query);
END
GO
