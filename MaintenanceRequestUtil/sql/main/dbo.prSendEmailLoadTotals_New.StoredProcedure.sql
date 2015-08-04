USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendEmailLoadTotals_New]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[prSendEmailLoadTotals_New] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	Select Recordid Into #TempRecordID
	From DataTrue_EDI..Inbound852Sales
	Where Banner = 'SV_JWL'
	and RecordStatus = 0

	DECLARE @tmpProcessedRecords TABLE (total int, qty int, chainid int, chainname varchar(50), BusinessType varchar(50))
	INSERT INTO @tmpProcessedRecords (total, qty, chainid, chainname, BusinessType)

		Select COUNT(RecordID )'Total Records', Sum(qty) as 'Total Quantity', C.Chainid, C.ChainName 'Chain Name', Case When I.RecordType = 2 Then 'Newspaper' Else case when Recordtype = 0 then 'SBT' Else 'Unknown' End END
		from DataTrue_EDI..Inbound852Sales I with(nolock)inner join Chains C
		on I.ChainIdentifier = C.ChainIdentifier 
		where 1=1
		and I.ChainIdentifier in (select Distinct EntityIdentifier 
										from dbo.ProcessStepEntities 
										where ProcessStepName In ('prGetInboundPOSTransactions_New')
										and IsActive = 1)
		and Qty <> 0
		AND (RecordStatus = 0)
		--and I.Banner not in (select Distinct EntityIdentifier 
		--						from dbo.ProcessStepEntities 
		--						where ProcessStepName In ('prGetInboundPOSTransactions_JWL_Newspaper'))
		--and C.ChainID in (60634, 75221, 79380)
		and RecordID not in (select RecordID from #TempRecordID)
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
	Where chainid = 40393
	and BusinessType = 'SBT'

	--Select *
	--from @tmpProcessedRecords
	
	DECLARE @ProcessedRecords VARCHAR(MAX)
	SET @ProcessedRecords = 'TOTAL RECORDS' + CHAR(9) +  CHAR(9) +'TOTAL QUANTITY' + CHAR(9) +  CHAR(9) +'BUSINESS TYPE'+ CHAR(9) + CHAR(9) +'CHAIN NAME'  + CHAR(13) + CHAR(10)    


	SELECT @ProcessedRecords += Rtrim(Convert(nvarchar,x.total)) + CHAR(9) + CHAR(9) + CHAR(9) + convert(varchar,qty) + CHAR(9) + CHAR(9) + CHAR(9) + BusinessType + CHAR(9) + CHAR(9)+ chainname  +  CHAR(13) + CHAR(10)
	FROM @tmpProcessedRecords x
	            
	DECLARE @ProcessedEmailBody VARCHAR(MAX)
	SET @ProcessedEmailBody = 'The following amount of records will be moved from EDI Inbound 852 Sales for these chains.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
											   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
											   @ProcessedRecords + CHAR(13) + CHAR(10) 

	--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
	DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
	SET @Processedemailaddresses = 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'

	EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'Record Processing Has Started'
		  ,@ProcessedEmailBody
		  ,'DataTrue System', 0, @Processedemailaddresses

End
GO
