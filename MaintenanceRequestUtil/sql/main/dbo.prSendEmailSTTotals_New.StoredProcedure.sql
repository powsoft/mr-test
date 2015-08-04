USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailSTTotals_New]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prSendEmailSTTotals_New] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	Declare @PRocessID int
	Select @PRocessID = LastProcessID from JobRunning where JobRunningID = 14

	DECLARE @tmpProcessedRecords TABLE (total int, qty int, chainid int, chainname varchar(50), BusinessType varchar(50))
	INSERT INTO @tmpProcessedRecords (total, qty, chainid, chainname, BusinessType)

		Select COUNT(StoreTransactionID )'Total Records', Sum(qty) as 'Total Quantity', C.Chainid, C.ChainName 'Chain Name', Case When I.RecordType = 2 Then 'Newspaper' Else case when Recordtype = 0 then 'SBT' Else 'Unknown' End END
		from StoreTransactions I with(nolock)inner join Chains C
		on I.ChainId = C.ChainId 
		where 1=1
		and I.ChainId in (select Distinct EntityIDToInclude 
										from dbo.ProcessStepEntities 
										where ProcessStepName In ('prGetInboundPOSTransactions_New')
										and IsActive = 1)
		and CONVERT(date, I.DateTimeCreated) = CONVERT(Date, Getdate())
		and TransactionTypeID in (2,6)
		--and I.ChainID In (60634, 75221, 79380)
		and ProcessID = @ProcessID
		Group by C.ChainID, C.ChainName, I.RecordType
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
	
	Delete
	from @tmpProcessedRecords
	where chainid = 40393
	and BusinessType = 'Unknown'

	DECLARE @ProcessedRecords VARCHAR(MAX)
	SET @ProcessedRecords = 'TOTAL RECORDS' + CHAR(9) +  CHAR(9) +'TOTAL QUANTITY' + CHAR(9) +  CHAR(9) +'BUSINESS TYPE'+ CHAR(9) + CHAR(9) +'CHAIN NAME'  + CHAR(13) + CHAR(10)    


	SELECT @ProcessedRecords += Rtrim(Convert(nvarchar,x.total)) + CHAR(9) + CHAR(9) + CHAR(9) + convert(varchar,qty) + CHAR(9) + CHAR(9) + CHAR(9) + BusinessType + CHAR(9) + CHAR(9)+ chainname  +  CHAR(13) + CHAR(10)
	FROM @tmpProcessedRecords x
	            
	DECLARE @ProcessedEmailBody VARCHAR(MAX)
	SET @ProcessedEmailBody = 'The following number of records have been inserted into Store Transactions, and are able to be viewed in Store Activities.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
											   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											   @ProcessedRecords + CHAR(13) + CHAR(10) 

	--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
	DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
	SET @Processedemailaddresses = 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'

	EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Store Transactions have been Instered'
		  ,@ProcessedEmailBody
		  ,'DataTrue System', 0, @Processedemailaddresses

End
GO
