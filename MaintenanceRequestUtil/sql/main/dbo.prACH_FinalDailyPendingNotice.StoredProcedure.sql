USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prACH_FinalDailyPendingNotice]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prACH_FinalDailyPendingNotice]
AS

--------DECLARE VARIABLES------------
DECLARE @jobLastRan DATETIME
DECLARE @errorMessage nVARCHAR(4000)
DECLARE @errorLocation nVARCHAR(255)
DECLARE @errorSenderString nVARCHAR(255)
DECLARE @loadStatus smallint
DECLARE @MyID int

--=======================================
--           POST PROCESSING
--=======================================

--SEND NOTIFICATIONS OF PENDING APPROVALS
BEGIN TRY

	--LOOP THROUGH SUPPLIERS WITH PENDING APPROVAL
	DECLARE @NotificationSupplierID INT
	DECLARE @NotificationSupplierIdentifier VARCHAR(150)
	DECLARE @NotificationChainName VARCHAR(150)
	
	DECLARE NotificationCursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT DISTINCT s.SupplierID, Approval.SupplierIdentifier, Approval.ChainName
	FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] AS Approval WITH (NOLOCK)
	INNER JOIN [DataTrue_Main].[dbo].[Suppliers] AS s WITH (NOLOCK)
	ON Approval.EdiName = S.EDIName
	WHERE 1 =1
	AND Approval.ApprovalTimeStamp >= @jobLastRan
	AND Approval.RecordStatus IN (2, 5)
	
	OPEN NotificationCursor
	FETCH NEXT FROM NotificationCursor INTO @NotificationSupplierID, @NotificationSupplierIdentifier, @NotificationChainName

	WHILE @@FETCH_STATUS = 0
		BEGIN		
			--GET INVOICE DATA
			DECLARE @tmpValidInvoices TABLE (ChainIdentifier VARCHAR(100), InvoiceNo VARCHAR(100), InvoiceTotal VARCHAR(100), DeliveryDate VARCHAR(20), SupplierIdentifier VARCHAR(50), FileName VARCHAR(200))
			DELETE FROM @tmpValidInvoices
			INSERT INTO @tmpValidInvoices (ChainIdentifier, InvoiceNo, InvoiceTotal, DeliveryDate, SupplierIdentifier, FileName)
			(
			SELECT DISTINCT
			LTRIM(RTRIM(Approval.ChainName)),
			LTRIM(RTRIM(Approval.ReferenceIDentification)),
			CONVERT(DECIMAL(20,2),	
					SUM(Approval.Qty*Approval.Cost) 
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount1,0)))
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount2,0)))
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount3,0)))
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount4,0)))
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount5,0)))
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount6,0)))
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount7,0)))
					+SUM(CONVERT(FLOAT,ISNULL(Approval.AlllowanceChargeAmount8,0)))
					 ),
			Approval.EffectiveDate,
			Approval.SupplierIdentifier,
			Approval.Filename
			FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] AS Approval WITH (NOLOCK)
			WHERE Approval.RecordStatus = 2
			AND	TimeStamp >= @jobLastRan
			AND SupplierIdentifier = @NotificationSupplierIdentifier
			AND ChainName = @NotificationChainName
			GROUP BY Approval.ChainName, Approval.ReferenceIDentification, Approval.EffectiveDate, Approval.SupplierIdentifier, Approval.FileName
			)
			
			UPDATE @tmpValidInvoices
			SET InvoiceNo = InvoiceNo + REPLICATE(' ', (10 - LEN(InvoiceNo)))
			WHERE LEN(InvoiceNo) < 11

			UPDATE @tmpValidInvoices
			SET InvoiceTotal = InvoiceTotal + REPLICATE(' ', (13 - LEN(InvoiceTotal)))
			WHERE LEN(InvoiceTotal) < 14
			
			DECLARE @ValidRecords VARCHAR(MAX)
			SET @ValidRecords = 'INVOICE NO' + CHAR(9) + 'INVOICE TOTAL' + CHAR(9) + CHAR(9) + 'DELIVERY DATE' + CHAR(9) + CHAR(9) + 'FILE' + CHAR(13) + CHAR(10)	
			SELECT @ValidRecords += x.InvoiceNo + CHAR(9) + x.InvoiceTotal + CHAR(9) + CHAR(9) + REPLACE(CONVERT(VARCHAR(20), x.DeliveryDate), '12:00AM', '') + CHAR(9) + CHAR(9) + x.FileName + CHAR(13) + CHAR(10)
			FROM @tmpValidInvoices x
			
			DECLARE @validEmailBody VARCHAR(MAX)
			SET @validEmailBody = 'Please be aware the below invoices are still invoices pending approval.  Invoices pending past 2PM will not be processed until the following day.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
										'RETAILER: ' + (SELECT ChainName FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = @NotificationChainName) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
										'SUPPLIER: ' + (SELECT Suppliername FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = @NotificationSupplierIdentifier) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
										 @ValidRecords
			
			--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
			DECLARE @emailaddresses VARCHAR(5000) = ''
			SELECT @emailaddresses += Email + '; '
			FROM [DataTrue_Main].[dbo].[ContactInfo] AS c WITH (NOLOCK)
			WHERE c.OwnerEntityID = @NotificationSupplierID	
			AND c.ReceiveACHNotifications = 1
			SET @emailaddresses = @emailaddresses + 'edi@icucsolutions.com'
			IF ISNULL(@emailaddresses, '') = ''
				BEGIN
					SET @emailaddresses = 'edi@icucsolutions.com'
				END
			EXEC dbo.prSendEmailNotification_PassEmailAddresses 'Regulated Invoices Are Pending Approval'
				,@validEmailBody
				,'DataTrue System', 0, @emailaddresses, '', 'datatrueit@icontroldsd.com'	
			FETCH NEXT FROM NotificationCursor INTO @NotificationSupplierID, @NotificationSupplierIdentifier, @NotificationChainName
		END
	CLOSE NotificationCursor
	DEALLOCATE NotificationCursor

END TRY

BEGIN CATCH

ROLLBACK TRANSACTION

		SET @errormessage = error_message()
		SET @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		SET @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec dbo.prSendEmailNotification_PassEmailAddresses 'ERROR in job [prACH_FinalDailyPendingNotice]'
			,'An exception was encountered in prACH_MovePendingRecordsToApprovalTable'
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
		
END CATCH

RETURN
GO
