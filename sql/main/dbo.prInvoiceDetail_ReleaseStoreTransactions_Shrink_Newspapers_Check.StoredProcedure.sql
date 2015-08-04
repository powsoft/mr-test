USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Shrink_Newspapers_Check]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Shrink_Newspapers_Check]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @CheckCount INT
	SET @CheckCount = 0
	
	SELECT @CheckCount += COUNT(t.StoreTransactionID)
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS t
	INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
	ON f.storetransactionid = t.StoreTransactionID
	AND t.TransactionStatus IN (0, -800)
	AND ISNULL(t.ShrinkLocked, 0) = 0
	AND f.status = 3

 	SELECT @CheckCount += COUNT(t.StoreTransactionID)
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS t
	INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
	ON f.storetransactionid = t.StoreTransactionID
	AND t.TransactionStatus IN (0, -800)
	--AND ISNULL(t.ShrinkLocked, 0) = 0
	AND f.status = 1
	
	SELECT @CheckCount += COUNT(t.StoreTransactionID)
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS t
	INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
	ON f.storetransactionid = t.StoreTransactionID
	AND t.TransactionStatus IN (0, -800)
	--AND ISNULL(t.ShrinkLocked, 0) = 0
	AND f.status = 6
	
	IF @CheckCount = 0
		BEGIN
			EXEC [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Newspapers_Shrink_NewInvoiceData'
		END

END
GO
