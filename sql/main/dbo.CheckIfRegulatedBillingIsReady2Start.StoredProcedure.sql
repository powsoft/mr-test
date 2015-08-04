USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[CheckIfRegulatedBillingIsReady2Start]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CheckIfRegulatedBillingIsReady2Start]
/*
 exec [dbo].[CheckIfRegulatedBillingIsReady2Start]
*/
AS
BEGIN	
	DECLARE @emailTO VARCHAR(500) = 'paul.tsyhura@icucsolutions.com'	--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	

	if not exists
	(	
		select ChainIdentifier, SupplierIdentifier from DataTrue_EDI.dbo.ACH_ExpectedFiles	
		--------------
		except	
		--------------
		select ChainName,SupplierIdentifier from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval 
		where 
			convert(date,TimeStamp) = convert(date,getdate())
		and RecordStatus = 0
		group by
		ChainName,SupplierIdentifier 
	)
	BEGIN
		exec dbo.prSendEmailNotification_PassEmailAddresses 'BILLING_REGULATED: All expected Suppliers submitted & approved their Invoices. READY to start BILLING_REGULATED.'
				, N'BILLING_REGULATED: all expected Suppliers submitted & approved their Invoices. READY to start BILLING_REGULATED.'
				,'DataTrue System', 0, @emailTO
	END
	ELSE
	BEGIN
		DECLARE @chain VARCHAR(100)
		DECLARE @supplier VARCHAR(100)
		DECLARE @EOL VARCHAR(20)
		SET @EOL = CHAR(13)+CHAR(10)
		DECLARE @recten CURSOR
		DECLARE @body VARCHAR(4000)
		
		
		
		--===========================
		/*
		[dbo].[ACHCustomerSubmissionScheduleRules]
([ChainID],	[SupplierID],[DayOfTheWeek],[OperationCode])
SELECT 
50964,64298,6,0 UNION ALL
SELECT
50964,51068,5,0

select * from dbo.ACHCustomerSubmissionScheduleRules
drop table #NO_FILES
SELECT DATENAME(weekday, GETDATE()),datepart(weekday, GETDATE())
		*/
		
		
		SET @body = 'Regulated Suppliers WHO SUBMITTED Invoices TODAY via WEB API:' + @EOL
		
		SELECT 
		--w.*, 
		c.ChainIdentifier, s.SupplierIdentifier
		INTO
			#WEB_UI
		FROM
		(
		SELECT CAST(DateTimeCreated as DATE) as DATE, DataTrueChainID, DataTrueSupplierID, COUNT(*) as RECNO
		FROM 
			DATATRUE_EDI.dbo.InboundInventory_web 
		WHERE 
			CAST(DateTimeCreated as DATE) = CAST(GETDATE() AS DATE)
		GROUP BY
			CAST(DateTimeCreated as DATE), DataTrueChainID, DataTrueSupplierID 

		) AS w
		--------------
		INNER JOIN
		--------------
		Chains As c ON w.DataTrueChainID = c.ChainID
		--------------
		INNER JOIN
		--------------
		Suppliers As s ON w.DataTrueSupplierID = s.SupplierID
		
		--====================================
		--====================================
		
		SET @recten = CURSOR LOCAL FAST_FORWARD FOR
		--===========================================================
		select ChainIdentifier, SupplierIdentifier from #WEB_UI
		--============================================================
		OPEN @recten
		FETCH NEXT FROM @recten INTO @chain, @supplier
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @body = @body + 'Chain: ' + @chain + '       Supplier: '+ @supplier + @EOL
			FETCH NEXT FROM @recten INTO @chain, @supplier
		END
		CLOSE @recten
		SET @body = @body + '===========================================================' + @EOL 
		
		--============================================================
		
		SELECT c.ChainIdentifier,SupplierIdentifier 
		INTO
			#NO_FILES
		FROM 
		[dbo].[ACHCustomerSubmissionScheduleRules] sr
		-------------
		INNER JOIN
		-------------
		Suppliers AS s ON sr.SupplierID = s.SupplierID
		-------------
		INNER JOIN
		-------------
		Chains AS c ON sr.ChainID = c.ChainID
		WHERE
			sr.[DayOfTheWeek] = datepart(weekday, GETDATE())
		AND sr.OperationCode = 0
		--============================
		SET @recten = CURSOR LOCAL FAST_FORWARD FOR
		--===========================================================
		select ChainIdentifier, SupplierIdentifier from #NO_FILES
		--============================================================
		OPEN @recten

		FETCH NEXT FROM @recten INTO @chain, @supplier
		SET @body = @body + 'List of Regulated Suppliers who IS NOT GOING TO SEND Invoices TODAY:' + @EOL
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @body = @body + 'Chain: ' + @chain + '       Supplier: '+ @supplier + @EOL
			FETCH NEXT FROM @recten INTO @chain, @supplier
		END
		CLOSE @recten
		SET @body = @body + '===========================================================' + @EOL 
		--============================================================
				
		SET @recten = CURSOR LOCAL FAST_FORWARD FOR
		--===========================================================
		(
		select ChainIdentifier, SupplierIdentifier from DataTrue_EDI.dbo.ACH_ExpectedFiles	
		--------------
		except	
		--------------
		select ChainName,SupplierIdentifier from DataTrue_EDI.dbo.Inbound846Inventory_ACH--_Approval 
		where 
			convert(date,TimeStamp) = convert(date,getdate())
		--and RecordStatus = 1
		group by
			ChainName,SupplierIdentifier
		)
		--------------
		except	
		--------------
		select ChainIdentifier, SupplierIdentifier from #NO_FILES
		--===========================================================	
		OPEN @recten

		FETCH NEXT FROM @recten INTO @chain, @supplier
		SET @body = @body + 'List of Regulated Suppliers we have not recieved Invoices yet:' + @EOL
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @body = @body + 'Chain: ' + @chain + 'Supplier: '+ @supplier + @EOL
			FETCH NEXT FROM @recten INTO @chain, @supplier
		END
		CLOSE @recten
				
		--============================================================
		--============================================================
		
		SET @recten = CURSOR LOCAL FAST_FORWARD FOR
		--===========================================================
		(
		select ChainIdentifier, SupplierIdentifier from DataTrue_EDI.dbo.ACH_ExpectedFiles	
		--------------
		except	
		--------------
		select ChainName,SupplierIdentifier from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval 
		where 
			convert(date,TimeStamp) = convert(date,getdate())
		and RecordStatus = 0
		group by
			ChainName,SupplierIdentifier
		)
		--------------
		except	
		--------------
		select ChainIdentifier, SupplierIdentifier from #NO_FILES	
		--===========================================================	
		OPEN @recten

		FETCH NEXT FROM @recten INTO @chain, @supplier
		SET @body = @body + '===========================================================' + @EOL + 'List of Regulated Suppliers we have not recieved Approvals from:' + @EOL
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @body = @body + 'Chain: ' + @chain + 'Supplier: '+ @supplier + @EOL
			FETCH NEXT FROM @recten INTO @chain, @supplier
		END
		CLOSE @recten
		
		--============================================================
		--============================================================
				
		SET @recten = CURSOR LOCAL FAST_FORWARD FOR
		--===========================================================
		(
		select ChainIdentifier, SupplierIdentifier from DataTrue_EDI.dbo.ACH_ExpectedFiles	
		--------------
		intersect	
		--------------
		select ChainName,SupplierIdentifier from DataTrue_EDI.dbo.Inbound846Inventory_ACH--_Approval 
		where 
			convert(date,TimeStamp) = convert(date,getdate())
		--and RecordStatus = 1
		group by
			ChainName,SupplierIdentifier
		)
		--------------
		except	
		--------------
		select ChainIdentifier, SupplierIdentifier from #NO_FILES
		--===========================================================	
		OPEN @recten

		FETCH NEXT FROM @recten INTO @chain, @supplier
		SET @body = @body + '===========================================================' + @EOL + 'List of Regulated Suppliers we have already recieved Invoices:' + @EOL
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @body = @body + 'Chain: ' + @chain + 'Supplier: '+ @supplier + @EOL
			FETCH NEXT FROM @recten INTO @chain, @supplier
		END
		CLOSE @recten
				
		--============================================================
		--============================================================
		
		SET @recten = CURSOR LOCAL FAST_FORWARD FOR
		--===========================================================
		(
		select ChainIdentifier, SupplierIdentifier from DataTrue_EDI.dbo.ACH_ExpectedFiles	
		--------------
		intersect	
		--------------
		select ChainName,SupplierIdentifier from DataTrue_EDI.dbo.Inbound846Inventory_ACH_Approval 
		where 
			convert(date,TimeStamp) = convert(date,getdate())
		and RecordStatus = 0
		group by
			ChainName,SupplierIdentifier
		)
		--------------
		except	
		--------------
		select ChainIdentifier, SupplierIdentifier from #NO_FILES
		--===========================================================	
		OPEN @recten

		FETCH NEXT FROM @recten INTO @chain, @supplier
		SET @body = @body + '===========================================================' + @EOL + 'List of Regulated Suppliers we have already recieved Approvals from:' + @EOL
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @body = @body + 'Chain: ' + @chain + 'Supplier: '+ @supplier + @EOL
			FETCH NEXT FROM @recten INTO @chain, @supplier
		END
		CLOSE @recten

		--============================================================================================
		--============================================================================================				
		
		DEALLOCATE @recten
		
		
		---- check is the JOB IS RUNNING 
		
		DECLARE @job_is_running INT
		SET @job_is_running = 0
		IF EXISTS
		(	SELECT 1 
				  FROM msdb.dbo.sysjobs J 
				  JOIN msdb.dbo.sysjobactivity A 
					  ON A.job_id=J.job_id 
				  WHERE J.name=N'Billing_Regulated' 
				  AND A.run_requested_date IS NOT NULL 
				  AND A.stop_execution_date IS NULL
		)
		BEGIN
			PRINT 'The Billing_Regulated job is running...'
			SET @job_is_running = 1
			SET @body = 'The Billing_Regulated job is currently running'
		END
		ELSE
		BEGIN
			PRINT 'The Billing_Regulated job is not running...'
			SET @job_is_running = 0
		END	
		
		---- check is the JOB IS RUNNING 
		
		print @body
		
		IF EXISTS
		(
			 select * from datatrue_edi.dbo.ProcessStatus_ACH
				where CONVERT(DATE,Date) = CONVERT(DATE,GETDATE()) and BillingComplete <> 1
		)
		BEGIN
			
			print 'send email'

			exec dbo.prSendEmailNotification_PassEmailAddresses 'UPDATE on Regulated Invoices'
			,@body
			,'DataTrue System', 0, @emailTO

		END

	END
END
/*
select * from dbo.ApprovalManagement

USE [DataTrue_Main]
GO

DROP TABLE [dbo].[ACHCustomerSubmissionScheduleRules]
CREATE TABLE [dbo].[ACHCustomerSubmissionScheduleRules]
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ChainID] [bigint] NOT NULL,
	[SupplierID] [bigint] NOT NULL,
	[DayOfTheWeek] [int] NOT NULL,
	[OperationCode] [int] NOT NULL
) ON [PRIMARY]

TRUNCATE TABLE [dbo].[ACHCustomerSubmissionScheduleRules]
;
INSERT INTO [dbo].[ACHCustomerSubmissionScheduleRules]
([ChainID],	[SupplierID],[DayOfTheWeek],[OperationCode])
SELECT 
50964,64298,6,0 UNION ALL
SELECT
50964,51068,5,0

SELECT * FROM [dbo].[ACHCustomerSubmissionScheduleRules]

SELECT DATENAME(weekday, GETDATE()),datepart(weekday, GETDATE())

*/
GO
