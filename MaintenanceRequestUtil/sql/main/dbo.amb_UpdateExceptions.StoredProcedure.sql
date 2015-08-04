USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateExceptions]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_UpdateExceptions '2' ,'1','0'
CREATE PROCEDURE [dbo].[amb_UpdateExceptions]
    @StoreTransactionExceptionID VARCHAR(2000) ,
    @NewStatus VARCHAR(20),
    @UserId varchar(20)
AS 

    BEGIN
        INSERT  INTO StoreTransactions_Exceptions
			([StoreTransactionExceptionTypeID],[StoreTransactionID],[ReportedSupplierIdentifier],[ExpectedSupplierIdentifier]
			,[ExpectedSupplierName],[ReportedSupplierName],[Qty],[SetupCost]
			,[SetupRetail],[SetupAllowance],[ReportedCost],[ReportedRetail]
			,[ExpectedAllowance],[ReportedAllowance],[SaleDateTime],[ProcessingErrorDesc],[SupplierID],[ChainID],[StoreId],ProductID, UPC, TransactionTypeId
			,[Comments],[DateTimeCreated],[LastUpdateUserID],[ExceptionStatus] )
			
		 SELECT [StoreTransactionExceptionTypeID], [StoreTransactionID],[ReportedSupplierIdentifier],[ExpectedSupplierIdentifier]
			,[ExpectedSupplierName],[ReportedSupplierName],[Qty],[SetupCost]
			,[SetupRetail],[SetupAllowance],[ReportedCost],[ReportedRetail]
			,[ExpectedAllowance],[ReportedAllowance],[SaleDateTime],[ProcessingErrorDesc],[SupplierID],[ChainID],[StoreId],ProductID, UPC, TransactionTypeId
			,[Comments],GETDATE(),@UserId,@NewStatus
			
		 FROM    StoreTransactions_Exceptions E
		 WHERE   E.StoreTransactionExceptionID = (@StoreTransactionExceptionID)
        
    END
GO
