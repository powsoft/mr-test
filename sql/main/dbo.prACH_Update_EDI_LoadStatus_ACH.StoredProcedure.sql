USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prACH_Update_EDI_LoadStatus_ACH]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prACH_Update_EDI_LoadStatus_ACH]

@PreValidation BIT = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	BEGIN TRY
		BEGIN TRANSACTION
		
			DECLARE @ProcessID INT
			SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'
			
			DECLARE @jobLastRan DATETIME
			SET @jobLastRan = (SELECT JobLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling')
			
			DECLARE @RegulatedChains TABLE
			(
				ChainID INT
			);

			INSERT INTO @RegulatedChains (ChainID)
			SELECT DISTINCT ChainID
			FROM DataTrue_EDI.dbo.InvoiceDetails AS ID WITH (NOLOCK)
			WHERE ID.ProcessID = @ProcessID
			
			DECLARE @BilledPerFileTable TABLE (ChainID INT, SupplierID INT, Filename VARCHAR(240), Total MONEY)
			
			INSERT INTO @BilledPerFileTable (ChainID, SupplierID, Filename, Total)
			SELECT DISTINCT ID.ChainID, ID.SupplierID, SC.SourceName, SUM(ID.TotalCost) AS Total
			FROM DataTrue_Main..InvoicesRetailer AS IR
			INNER JOIN DataTrue_Main..InvoiceDetails AS ID
			ON IR.RetailerInvoiceID = ID.RetailerInvoiceID
			INNER JOIN DataTrue_Main..Suppliers AS S
			ON ID.SupplierID = S.SupplierID
			INNER JOIN DataTrue_Main..Source AS SC
			ON ID.SourceID = SC.SourceID
			WHERE 1 = 1
			AND IR.DateTimeCreated >= @jobLastRan
			AND ID.DateTimeCreated >= @jobLastRan
			AND IR.InvoiceTypeID = 1
			AND ID.InvoiceDetailTypeID = 2
			AND ID.ChainID IN (SELECT ChainID FROM @RegulatedChains)
			GROUP BY ID.ChainID, ID.SupplierID, SC.SourceName
			
			IF @PreValidation = 1
				BEGIN	
					
					DECLARE @ACHStatusTable TABLE (ChainIdentifier VARCHAR(120), SupplierEDIName VARCHAR(120), FileName VARCHAR(240), FailedValidationAmt MONEY)
					INSERT INTO @ACHStatusTable (ChainIdentifier, SupplierEDIName, FileName, FailedValidationAmt)
					SELECT DISTINCT
					ACH.ChainName,
					ACH.EdiName,
					ACH.FileName,
					CONVERT(MONEY,	
						SUM(ACH.Qty*ACH.Cost) 
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount1,0)))
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount2,0)))
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount3,0)))
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount4,0)))
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount5,0)))
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount6,0)))
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount7,0)))
						+SUM(CONVERT(float,ISNULL(ACH.AlllowanceChargeAmount8,0))))
					FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH] AS ACH WITH (NOLOCK)
					WHERE 1 = 1
					AND TimeStamp > @jobLastRan
					AND RecordStatus = 255
					GROUP BY ACH.ChainName, ACH.EdiName, ACH.FileName
					
					DECLARE @ApprovalPendingTable TABLE (ChainIdentifier VARCHAR(120), SupplierEDIName VARCHAR(120), FileName VARCHAR(240), PendingAmt MONEY)
					INSERT INTO @ApprovalPendingTable (ChainIdentifier, SupplierEDIName, FileName, PendingAmt)
					SELECT DISTINCT
					Approval.ChainName,
					Approval.EdiName,
					Approval.FileName,
					CONVERT(MONEY,	
						SUM(Approval.Qty*Approval.Cost) 
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount1,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount2,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount3,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount4,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount5,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount6,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount7,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount8,0))))
					FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] AS Approval WITH (NOLOCK)
					WHERE 1 = 1
					AND RecordStatus IN (0, 2, 4, 5, 6)
					GROUP BY Approval.ChainName, Approval.EdiName, Approval.FileName
					
					DECLARE @ApprovalRejectedTable TABLE (ChainIdentifier VARCHAR(120), SupplierEDIName VARCHAR(120), FileName VARCHAR(240), RejectedAmt MONEY)
					INSERT INTO @ApprovalRejectedTable (ChainIdentifier, SupplierEDIName, FileName, RejectedAmt)
					SELECT DISTINCT
					Approval.ChainName,
					Approval.EdiName,
					Approval.FileName,
					CONVERT(MONEY,	
						SUM(Approval.Qty*Approval.Cost) 
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount1,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount2,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount3,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount4,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount5,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount6,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount7,0)))
						+SUM(CONVERT(float,ISNULL(Approval.AlllowanceChargeAmount8,0))))
					FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH_Approval] AS Approval WITH (NOLOCK)
					WHERE 1 = 1
					AND ApprovalTimeStamp > @jobLastRan
					AND RecordStatus IN (3)
					GROUP BY Approval.ChainName, Approval.EdiName, Approval.FileName	
					
					UPDATE EDI
					SET EDI.LoadStatus = 3, EDI.UpdatedTimeStamp = GETDATE()
					FROM [DataTrue_EDI].[dbo].[EDI_LoadStatus_ACH] AS EDI WITH (TABLOCKX)
					INNER JOIN @BilledPerFileTable AS Billed
					ON 1 = 1
					AND Billed.Filename = LTRIM(RTRIM(EDI.FileName))
					AND Billed.ChainID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = EDI.Chain)
					AND Billed.SupplierID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = EDI.PartnerID)
					
					UPDATE EDI
					SET EDI.PendingAmt = 0
					FROM [DataTrue_EDI].[dbo].[EDI_LoadStatus_ACH] AS EDI 
					WHERE EDI.UpdatedTimeStamp > @jobLastRan
					
					UPDATE EDI
					SET EDI.PendingAmt = Pending.PendingAmt, UpdatedTimeStamp = GETDATE()
					FROM [DataTrue_EDI].[dbo].[EDI_LoadStatus_ACH] AS EDI 
					INNER JOIN @ApprovalPendingTable AS Pending
					ON 1 = 1
					AND Pending.Filename = LTRIM(RTRIM(EDI.FileName))
					AND Pending.ChainIdentifier = EDI.Chain
					AND Pending.SupplierEDIName = EDI.PartnerID
					
					UPDATE EDI
					SET EDI.RejectedAmt = Rejected.RejectedAmt, UpdatedTimeStamp = GETDATE()
					FROM [DataTrue_EDI].[dbo].[EDI_LoadStatus_ACH] AS EDI 
					INNER JOIN @ApprovalRejectedTable AS Rejected
					ON 1 = 1
					AND Rejected.Filename = LTRIM(RTRIM(EDI.FileName))
					AND Rejected.ChainIdentifier = EDI.Chain
					AND Rejected.SupplierEDIName = EDI.PartnerID
					
					UPDATE EDI
					SET EDI.FailedValidationAmt = ACH.FailedValidationAmt, UpdatedTimeStamp = GETDATE()
					FROM [DataTrue_EDI].[dbo].[EDI_LoadStatus_ACH] AS EDI 
					INNER JOIN @ACHStatusTable AS ACH
					ON 1 = 1
					AND ACH.Filename = LTRIM(RTRIM(EDI.FileName))
					AND ACH.ChainIdentifier = EDI.Chain
					AND ACH.SupplierEDIName = EDI.PartnerID

				END
			ELSE
				BEGIN
								
					UPDATE EDI
					SET EDI.BilledAmt += Billed.Total
					FROM [DataTrue_EDI].[dbo].[EDI_LoadStatus_ACH] AS EDI WITH(TABLOCKX)
					INNER JOIN @BilledPerFileTable AS Billed
					ON 1 = 1
					AND Billed.Filename = LTRIM(RTRIM(EDI.FileName))
					AND Billed.ChainID = (SELECT ChainID FROM DataTrue_Main.dbo.Chains WHERE ChainIdentifier = EDI.Chain)
					AND Billed.SupplierID = (SELECT SupplierID FROM DataTrue_Main.dbo.Suppliers WHERE EDIName = EDI.PartnerID)
										
					
				END	
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH	
	
		ROLLBACK TRANSACTION
	
		DECLARE @ErrorMessage VARCHAR(1000)
		
		SET @ErrorMessage = 'An exception was encountered in prACH_Update_EDI_LoadStatus_ACH: ' + ERROR_MESSAGE()
	
		EXEC dbo.prSendEmailNotification_PassEmailAddresses 'ERROR in job Billing_Regulated_NewInvoiceData'
			,@ErrorMessage
			,'DataTrue System', 0, 'datatrueit@icontroldsd.com;edi@icontroldsd.com'		
			
		EXEC [msdb].[dbo].[sp_stop_job] 
		@job_name = 'Billing_Regulated_NewInvoiceData'
	
	END CATCH
	
	
END
GO
