USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendMissingSuppliers]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2/19/2015
-- Description:	This is to send an email of all records that are pending with a status of -3 from the working table
-- =============================================
CREATE PROCEDURE [dbo].[prSendMissingSuppliers] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Declare @Processing int

DECLARE @tmpProcessedRecords TABLE (chainid int, chainname varchar(50), UPC varchar(50), StoreIdentifier int,RecordType varchar(50))
INSERT INTO @tmpProcessedRecords (UPC, chainid, chainname, StoreIdentifier, RecordType)

Select Distinct Case When ISNULL(UPC, '') = '' Then RawProductIdentifier Else UPC End UPC, C.Chainid, C.ChainName, StoreIdentifier ,Case when W.RecordType = 2 Then 'Newspapers' Else 'SBT' End RecordType
From StoreTransactions_Working W with(nolock)
Inner Join Chains C On W.Chainid = C.Chainid
Where 1=1
and ProcessId In (Select ProcessID from JobProcesses where JobRunningID = 14)
and Workingstatus = -3
and Workingsource = 'POS'
and convert(date, W.DateTimeCreated)  = Dateadd(day, -1, CONVERT(date, getdate()))
and C.ChainID <> 42491

Delete
--Select *
from @tmpProcessedRecords
where RecordType = 'SBT'
and chainid in (Select EntityIDToInclude from ProcessStepEntities where ProcessStepName = 'prGetInboundPOSTransactions_PDI')

Select @Processing = COUNT(*)
					--Select *
					from @tmpProcessedRecords
					
If @Processing > 0
	Begin
	
	UPDATE @tmpProcessedRecords
	SET chainname = chainname + REPLICATE(' ', (14 - LEN(chainname)))
	WHERE LEN(chainname) < 15

	DECLARE @ProcessedRecords VARCHAR(MAX)
	SET @ProcessedRecords = 'CHAIN NAME'  +  CHAR(9) + CHAR(9) + CHAR(9) + 'UPC' + CHAR(9) + CHAR(9) + CHAR(9) + 'STORE IDENTIFIER' + CHAR(9) +'RECORD TYPE' +CHAR(13) + CHAR(10)    


	SELECT @ProcessedRecords += left(chainname, 15)  +  CHAR(9) + CHAR(9) + CHAR(9) + Rtrim(Convert(nvarchar,x.UPC)) + CHAR(9) + CHAR(9) + Rtrim(Convert(nvarchar,x.StoreIdentifier)) + CHAR(9) + CHAR(9)+ CHAR(9)+RecordType +CHAR(13) + CHAR(10)
	FROM @tmpProcessedRecords x
	Order by x.chainid
	            
	DECLARE @ProcessedEmailBody VARCHAR(MAX)
	SET @ProcessedEmailBody = 'The following Records were not able to be matched to a Supplier ID, and are pending.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
											   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											   @ProcessedRecords + CHAR(13) + CHAR(10) 

	--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
	DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
	SET @Processedemailaddresses = 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com; amol.sayal@icucsolutions.com;esther.ortiz@icucsolutions.com; larry.wilbur@icucsolutions.com; heather.derr@icucsolutions.com; mark.alguire@icucsolutions.com; anthony.cannady@icucsolutions.com; allen.bernhardt@icucsolutions.com; rob.jackson@icucsolutions.com'
	
	EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Unmatched Suppliers'
	  ,@ProcessedEmailBody
	  ,'DataTrue System', 0, @Processedemailaddresses
	  
	End
END
GO
