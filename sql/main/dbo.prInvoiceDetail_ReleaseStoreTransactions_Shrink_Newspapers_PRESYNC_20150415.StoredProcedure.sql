USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Shrink_Newspapers_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prInvoiceDetail_ReleaseStoreTransactions_Shrink_Newspapers_PRESYNC_20150415]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE t
	SET t.TransactionStatus = -800, t.ShrinkLocked = 1, t.LastUpdateUserID = GETDATE()
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS t
	INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
	ON f.storetransactionid = t.StoreTransactionID
	AND t.TransactionStatus IN (0, -800)
	AND ISNULL(t.ShrinkLocked, 0) = 0
	AND f.status = 3

 	UPDATE t
 	SET t.TransactionStatus = 800, t.ShrinkLocked = 1
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS t
	INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
	ON f.storetransactionid = t.StoreTransactionID
	AND t.TransactionStatus IN (0, -800)
	--AND ISNULL(t.ShrinkLocked, 0) = 0
	AND f.status = 1
	
	UPDATE t
 	SET t.TransactionStatus = 820, t.ShrinkLocked = 1
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS t
	INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
	ON f.storetransactionid = t.StoreTransactionID
	AND t.TransactionStatus IN (0, -800)
	--AND ISNULL(t.ShrinkLocked, 0) = 0
	AND f.status = 6
	
	UPDATE t
	SET t.ProductIdentifier = t.UPC
	FROM [DataTrue_Main].[dbo].[StoreTransactions] AS t
	INNER JOIN [DataTrue_Main].[dbo].[InventoryReport_Newspaper_Shrink_Facts] AS f
	ON f.storetransactionid = t.StoreTransactionID
	WHERE ISNULL(t.ProductIdentifier, '') = ''
	AND ISNULL(t.UPC, '') <> ''

END
GO
