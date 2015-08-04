USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmail_InvoiceDetail_MoveTotals_New]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 10/17/2014
-- Description: To Email the Totals Moved from Store Transactions to Invoice Details
-- =============================================
CREATE PROCEDURE [dbo].[prSendEmail_InvoiceDetail_MoveTotals_New] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ProcessID INT

	SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

    -- Insert statements for procedure here
DECLARE @tmpProcessedRecords TABLE (total int, qty int, chainid int, chainname varchar(50), BusinessType varchar(50))
INSERT INTO @tmpProcessedRecords (total, qty, chainid, chainname, BusinessType)
		
		Select COUNT(InvoiceDetailID )'Total Records', Sum(TotalQty) as 'Total Quantity', C.Chainid, C.ChainName 'Chain Name', Case When RecordType = 2 Then 'Newspaper' Else case when Recordtype = 0 then 'SBT' Else 'Unknown' End END 
		From InvoiceDetails S with(NoLock) inner join Chains C on
		S.ChainID = C.ChainID
		 Where S.ChainId in (select EntityIDToInclude 
								from dbo.ProcessStepEntities 
								where ProcessStepName In ('prGetInboundPOSTransactions_New')
								and IsActive = 1)
		and Cast(S.DateTimeCreated as date) = Cast(GetDate() as Date) 
		and InvoiceDetailTypeID in (1)
		--and RecordType = 0
		--and S.ChainID In (60634, 75221, 79380)
		and ProcessID = @ProcessID
		Group by C.ChainID, C.ChainName, RecordType
		Order by C.ChainName

	UPDATE @tmpProcessedRecords
	SET BusinessType = BusinessType + REPLICATE(' ', (12 - LEN(BusinessType)))
	WHERE LEN(BusinessType) < 13

	UPDATE @tmpProcessedRecords
	SET qty = Convert(varchar(50), convert(int,qty)) + REPLICATE(' ', (13 - LEN(Convert(varchar(50), convert(int,qty)))))
	WHERE LEN(Convert(varchar(50), convert(int,qty))) < 14

	UPDATE @tmpProcessedRecords
	SET total = Convert(varchar(50), convert(int,total)) + REPLICATE(' ', (13 - LEN(Convert(varchar(50), convert(int,total)))))
	WHERE LEN(Convert(varchar(50), convert(int,total))) < 14


	DECLARE @ProcessedRecords VARCHAR(MAX)
	SET @ProcessedRecords = 'TOTAL RECORDS' + CHAR(9) +  CHAR(9) +'TOTAL QUANTITY' + CHAR(9) +  CHAR(9) +'BUSINESS TYPE'+ CHAR(9) + CHAR(9) +'CHAIN NAME'  + CHAR(13) + CHAR(10)    


	SELECT @ProcessedRecords += Rtrim(Convert(nvarchar,x.total)) + CHAR(9) + CHAR(9) + CHAR(9) + convert(varchar,qty) + CHAR(9) + CHAR(9) + CHAR(9) + BusinessType + CHAR(9) + CHAR(9)+ chainname  +  CHAR(13) + CHAR(10)
	FROM @tmpProcessedRecords x
	            
	DECLARE @ProcessedEmailBody VARCHAR(MAX)
	SET @ProcessedEmailBody = 'The following number of records have been inserted into Invoice Details.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
											   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											   @ProcessedRecords + CHAR(13) + CHAR(10) 

	--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
	DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
	SET @Processedemailaddresses = 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'

	EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Invoice Detail records have been Instered'
		  ,@ProcessedEmailBody
		  ,'DataTrue System', 0, @Processedemailaddresses
END
GO
