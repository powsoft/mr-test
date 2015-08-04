USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateBillingDCR_Newspapers]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prValidateBillingDCR_Newspapers]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--GET PROCESSID
	DECLARE @ProcessID INT
	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'NewspaperShrink_Invoice'
	
	--CHECK TOTALS
	DECLARE @CalcTable TABLE
	(
	InvoiceDetailsTotal NUMERIC(18, 9), 
	InvoiceDetailsEDITotal NUMERIC(18, 9),
	InvoicesRetailerTotal NUMERIC(18, 9),
	InvoicesRetailerEDITotal NUMERIC(18, 9),
	InvoicesSupplierTotal NUMERIC(18, 9),
	InvoicesSupplierEDITotal NUMERIC(18, 9)
	)
	
	INSERT INTO @CalcTable VALUES (0, 0, 0, 0, 0, 0)
	
	UPDATE c
	SET c.InvoiceDetailsTotal = i.InvoiceDetailsTotal
	FROM @CalcTable AS c
	INNER JOIN
	(
	SELECT SUM(ISNULL(TotalCost, 0)) AS InvoiceDetailsTotal
	FROM DataTrue_Main.dbo.InvoiceDetails
	WHERE ProcessID = @ProcessID
	) AS i
	ON 1 = 1
	
	UPDATE c
	SET c.InvoiceDetailsEDITotal = i.InvoiceDetailsEDITotal
	FROM @CalcTable AS c
	INNER JOIN
	(
	SELECT SUM(ISNULL(TotalCost, 0)) AS InvoiceDetailsEDITotal
	FROM DataTrue_EDI.dbo.InvoiceDetails_Shrink
	WHERE ProcessID = @ProcessID
	) AS i
	ON 1 = 1
	
	UPDATE c
	SET c.InvoicesRetailerTotal = i.InvoicesRetailerTotal
	FROM @CalcTable AS c
	INNER JOIN
	(
	SELECT SUM(ISNULL(OriginalAmount, 0)) AS InvoicesRetailerTotal
	FROM DataTrue_Main.dbo.InvoicesRetailer
	WHERE ProcessID = @ProcessID
	) AS i
	ON 1 = 1
	
	UPDATE c
	SET c.InvoicesRetailerEDITotal = i.InvoicesRetailerEDITotal
	FROM @CalcTable AS c
	INNER JOIN
	(
	SELECT SUM(ISNULL(OriginalAmount, 0)) AS InvoicesRetailerEDITotal
	FROM DataTrue_EDI.dbo.InvoicesRetailer
	WHERE ProcessID = @ProcessID
	) AS i
	ON 1 = 1
	
	UPDATE c
	SET c.InvoicesSupplierTotal = i.InvoicesSupplierTotal
	FROM @CalcTable AS c
	INNER JOIN
	(
	SELECT SUM(ISNULL(OriginalAmount, 0)) AS InvoicesSupplierTotal
	FROM DataTrue_Main.dbo.InvoicesSupplier
	WHERE ProcessID = @ProcessID
	) AS i
	ON 1 = 1
	
	UPDATE c
	SET c.InvoicesSupplierEDITotal = i.InvoicesSupplierEDITotal
	FROM @CalcTable AS c
	INNER JOIN
	(
	SELECT SUM(ISNULL(OriginalAmount, 0)) AS InvoicesSupplierEDITotal
	FROM DataTrue_EDI.dbo.InvoicesSupplier
	WHERE ProcessID = @ProcessID
	) AS i
	ON 1 = 1
	
	SELECT * FROM @CalcTable
	WHERE CONVERT(MONEY,InvoiceDetailsTotal) <> CONVERT(MONEY,InvoiceDetailsTotal) 
	OR CONVERT(MONEY,InvoiceDetailsTotal) <> CONVERT(MONEY,InvoiceDetailsEDITotal) 
	OR CONVERT(MONEY,InvoiceDetailsTotal) <> CONVERT(MONEY,InvoicesRetailerTotal) 
	OR CONVERT(MONEY,InvoiceDetailsTotal) <> CONVERT(MONEY,InvoicesRetailerEDITotal) 
	OR CONVERT(MONEY,InvoiceDetailsTotal) <> CONVERT(MONEY,InvoicesSupplierTotal) 
	OR CONVERT(MONEY,InvoiceDetailsTotal) <> CONVERT(MONEY,InvoicesSupplierEDITotal) 
	IF @@ROWCOUNT > 0
		BEGIN
			DECLARE @body4 NVARCHAR(2000)
			SELECT @body4 = 
			'DCR Newspaper Billing Job Validation has Failed.  Invoice tables totals do not match'
			EXEC dbo.prSendEmailNotification_PassEmailAddresses 'DCR Newspaper Billing Job Validation has Failed.'
			,@body4
			,'DataTrue System', 0
			,'datatrueit@icontroldsd.com; edi@icontroldsd.com'--'datatrueit@icontroldsd.com; edi@icontroldsd.com'
			RAISERROR ('The DCR Newspaper Billing Job has stopped at Validation STAGE. VALIDATION is not completed.' , 16 , 1)
		END
	
END
GO
