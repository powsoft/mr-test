USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateChainsToBill_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2014/12/05
-- Description:	Stops the new Daily job from running if there are no chains that need to be billed
-- =============================================
CREATE PROCEDURE [dbo].[prValidateChainsToBill_PRESYNC_20150329] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Declare @currentDate date
Declare @ChainsToBill2 Int
Declare @UpdateChains int
Declare @STQty int
Set @currentDate = convert(date, GETDATE())

	Update P Set RecordTypeID = 2
	--Select *
	from DataTrue_EDI..ProcessStatus P
	where ChainName not in ('SV', 'BAS', 'ACK')
	and Date = CONVERT(date, getdate())
	and BillingComplete = 0
	and P.RecordTypeID = 0

	Select @STQty = COUNT(StoreTransactionID)
	from StoreTransactions T with(nolock)
	Inner Join Chains C on C.ChainID = T.ChainID
	Inner Join DataTrue_EDI..ProcessStatus P
	on P.ChainName = C.ChainIdentifier
	where ProcessID = (Select LastProcessID from JobRunning where JobRunningID = 14)
	and CONVERT(date, T.DateTimeCreated) = CONVERT(Date, getdate())
	and P.AllFilesReceived = 1
	and P.BillingComplete = 0
	and P.BillingIsRunning = 0
	and P.RecordTypeID = 2
	
	--If @STQty = 0
	--	Begin
		
	--				exec [msdb].[dbo].[sp_stop_job] 
	--				@job_name = 'DailyPOSBilling_New'
		
	--	End


Select @UpdateChains = COUNT(distinct CHainName)
					from DataTrue_EDI..ProcessStatus
					where BillingComplete = 0
					and BillingIsRunning = 0
					and AllFilesReceived = 1
					and ChainName in (Select EntityIdentifier
										From ProcessStepEntities
										where ProcessStepName = 'prGetInboundPOSTransactions_New')
					and Date = convert(date, GETDATE())
					and RecordTypeID = 2
					

					
		If @UpdateChains > 0 
		
			Begin


				update s set s.BillingIsRunning = 1
				from [DataTrue_EDI].[dbo].[ProcessStatus] s
				where upper(ltrim(rtrim(ChainName))) in (Select EntityIdentifier 
															From ProcessStepEntities 
															where ProcessStepName = 'prGetInboundPOSTransactions_New')
				and CAST(date as date) = @currentdate
				and isnull(BillingComplete, 0) = 0
				and ISNULL(BillingIsRunning, 0) = 0
				and isnull(AllFilesReceived, 0) = 1
				and RecordTypeID = 2
				
			End
			

	Select @ChainsToBill2 = COUNT(distinct CHainName)
	from DataTrue_EDI..ProcessStatus
	where BillingComplete = 0
	and BillingIsRunning = 1
	and AllFilesReceived = 1
	and ChainName in (Select EntityIdentifier
						From ProcessStepEntities
						where ProcessStepName = 'prGetInboundPOSTransactions_New')
	and Date = @currentDate	
	and RecordTypeID = 2	
		
		If @ChainsToBill2 > 0 --and @STQty > 0
			Begin
				
				Declare @ChainsToBill varchar(8000)=''
				Select @ChainsToBill += CHainName +CHAR(13) + CHAR(10) 
					from DataTrue_EDI..ProcessStatus
					where BillingComplete = 0
					and BillingIsRunning = 1
					and AllFilesReceived = 1
					and ChainName in (Select EntityIdentifier
										From ProcessStepEntities
										where ProcessStepName = 'prGetInboundPOSTransactions_New')
					and Date = @currentDate
					and RecordTypeID = 2
					
				DECLARE @ProcessedEmailBody VARCHAR(MAX)
				SET @ProcessedEmailBody = 'The following chains are to be billed.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
														   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
														   @ChainsToBill + CHAR(13) + CHAR(10) 
				
				exec dbo.prSendEmailNotification_PassEmailAddresses 'Invoicing Process Started'
				,@ProcessedEmailBody
				,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'

			End
    
		
		--Print @ChainsToBill

		If @ChainsToBill2 < 1 --or @STQty > 0

			Begin
			
			exec [msdb].[dbo].[sp_stop_job] 
					@job_name = 'DailyPOSBilling_New'

			End
			
END
GO
