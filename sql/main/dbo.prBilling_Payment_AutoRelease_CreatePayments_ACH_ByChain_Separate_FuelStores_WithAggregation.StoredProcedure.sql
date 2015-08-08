USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain_Separate_FuelStores_WithAggregation]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain_Separate_FuelStores_WithAggregation]
as

SET XACT_ABORT ON

declare @MyID int=7419
declare @rec cursor 
declare @rec2 cursor
declare @entityidtopay int
declare @newpaymentid int
declare @chainidpaying int
declare @invoiceno nvarchar(50)
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @paymentamount money
declare @paymenttypeid int
declare @InvoiceDetailsTotalsMatch bit
declare @InvoiceRetailerTotalsMatch bit
declare @invoiceaggregationtypeid int --
declare @invoiceaggregationid int --
declare @accounttypeid int
declare @custom4 varchar(200)
declare @paymentHoldAmount MONEY

DECLARE @jobLastRan DATETIME
SELECT @jobLastRan = (SELECT PaymentLastRunDateTime FROM JobRunning WHERE JobName = 'DailyRegulatedBilling')

DECLARE @PaymentAggregationsTable TABLE (ChainID INT, SupplierID INT, PaymentTypeID INT, PaymentID INT)

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

begin try
begin transaction

--INSERT NEW INVOICES WITH FUTURE DUE DATES INTO BILLINGCONTROL_PAYMENTS_HELD TYPE 2
INSERT INTO DataTrue_Main.dbo.BillingControl_Payments_Held
(PaymentHeldTypeID, ChainID, SupplierID, RetailerInvoiceID, TotalAmount, Timestamp)
SELECT
2, i.ChainID, i.SupplierID, i.RetailerInvoiceID, SUM(i.TotalCost), GETDATE()
FROM DataTrue_Main.dbo.InvoiceDetails AS i
LEFT OUTER JOIN DataTrue_Main.dbo.BillingControl_Payments_Held AS held
ON i.ChainID = held.ChainID
AND i.SupplierID = held.SupplierID
AND i.RetailerInvoiceID = held.RetailerInvoiceID
WHERE 1 = 1
AND i.ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
AND i.InvoiceDetailTypeID = 2
AND CAST(i.PaymentDueDate AS DATE) > CAST(GETDATE() AS DATE)
AND i.PaymentID IS NULL
AND i.RecordType = 0
AND held.PaymentHeldID IS NULL
GROUP BY i.ChainID, i.SupplierID, i.RetailerInvoiceID

--INSERT INTO DataTrue_EDI.dbo.SupplierPaymentAccountTypes for missing account type 1s
DELETE FROM DataTrue_EDI.dbo.SupplierPaymentAccountTypes WHERE AccountTypeID = 1
INSERT INTO DataTrue_EDI.dbo.SupplierPaymentAccountTypes (SupplierID, StoreID, AccountTypeID, TypeDescription, SeparateFeesPerAccount)
SELECT DISTINCT t.SupplierID, s.StoreID, 1, 'Default account type', 0
FROM BillingControl AS t WITH (NOLOCK)
LEFT OUTER JOIN Stores AS s WITH (NOLOCK)
ON t.ChainID = s.ChainID
WHERE 1 = 1
AND t.ChainID > 0
AND t.ISACH = 1
AND t.IsActive = 1
AND t.BillingControlFrequency = 'Daily'
AND t.SupplierID <> 0
AND t.BusinessTypeID = 2
AND CONVERT(VARCHAR(10),t.SupplierID) + CONVERT(VARCHAR(10),s.StoreID) NOT IN 
(
	SELECT DISTINCT CONVERT(VARCHAR(10),t2.SupplierID) + CONVERT(VARCHAR(10),s2.StoreID) 
	FROM DataTrue_EDI.dbo.SupplierPaymentAccountTypes t2
	LEFT OUTER JOIN Stores AS s2 WITH (NOLOCK)
	ON t2.StoreID = s2.StoreID
)

DECLARE @RetailerInvoiceIDsToUpdate TABLE (RetailerInvoiceID INT)

--INSERT NEW INVOICES WITH ALL INVOICES NETTING TO $0
--INSERT INTO DataTrue_Main.dbo.BillingControl_Payments_Held
--(PaymentHeldTypeID, ChainID, SupplierID, RetailerInvoiceID, TotalAmount, Timestamp)
--SELECT
--3, i.ChainID, i.SupplierID, RetailerInvoiceID, SUM(t.TotalCost), GETDATE()
--FROM 
--(
--SELECT ChainID, SupplierID, SUM(TotalCost) AS TotalCost
--FROM DataTrue_Main.dbo.InvoiceDetails
--WHERE 1 = 1
--AND ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
--AND InvoiceDetailTypeID = 2
--AND CAST(PaymentDueDate AS DATE) > CAST(GETDATE() AS DATE)
--AND PaymentID IS NULL
--GROUP BY ChainID, SupplierID
--HAVING SUM(TotalCost) = 0
--) AS t
--INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS i
--ON i.ChainID = t.ChainID
--AND i.SupplierID = t.SupplierID
--WHERE 1 = 1
--AND ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
--AND InvoiceDetailTypeID = 2
--AND CAST(PaymentDueDate AS DATE) > CAST(GETDATE() AS DATE)
--AND PaymentID IS NULL
--GROUP BY i.ChainID, i.SupplierID, RetailerInvoiceID

--UPDATE HELD INVOICES WITH FUTURE DUE DATES THAT ARE NOW CURRENT FROM BILLINGCONTROL_PAYMENTS_HELD TYPE 2
INSERT INTO @RetailerInvoiceIDsToUpdate (RetailerInvoiceID)
SELECT DISTINCT bcph.RetailerInvoiceID 
FROM DataTrue_Main.dbo.InvoiceDetails AS id
INNER JOIN DataTrue_Main.dbo.BillingControl_Payments_Held AS bcph
ON id.RetailerInvoiceID = bcph.RetailerInvoiceID
AND bcph.PaymentHeldTypeID = 2
AND CONVERT(DATE, id.PaymentDueDate) <= CONVERT(DATE, GETDATE())
AND bcph.ReleasedDateTime IS NULL

IF (SELECT COUNT(*) FROM @RetailerInvoiceIDsToUpdate) > 0
	BEGIN
		UPDATE id
		SET id.ProcessID = @ProcessID
		FROM DataTrue_Main.dbo.InvoiceDetails AS id
		INNER JOIN @RetailerInvoiceIDsToUpdate AS r
		ON id.RetailerInvoiceID = r.RetailerInvoiceID

		UPDATE id
		SET id.ProcessID = @ProcessID
		FROM DataTrue_EDI.dbo.InvoiceDetails AS id
		INNER JOIN @RetailerInvoiceIDsToUpdate AS r
		ON id.RetailerInvoiceID = r.RetailerInvoiceID

		UPDATE id
		SET id.ProcessID = @ProcessID
		FROM DataTrue_Main.dbo.InvoicesRetailer AS id
		INNER JOIN @RetailerInvoiceIDsToUpdate AS r
		ON id.RetailerInvoiceID = r.RetailerInvoiceID

		UPDATE id
		SET id.ProcessID = @ProcessID
		FROM DataTrue_EDI.dbo.InvoicesRetailer AS id
		INNER JOIN @RetailerInvoiceIDsToUpdate AS r
		ON id.RetailerInvoiceID = r.RetailerInvoiceID
		
		UPDATE ph
		SET ph.ReleasedDateTime = GETDATE()
		FROM DataTrue_main.dbo.BillingControl_Payments_Held AS ph
		INNER JOIN @RetailerInvoiceIDsToUpdate AS r
		ON ph.RetailerInvoiceID = r.RetailerInvoiceID
	END

--TRUNCATE WORKING TABLE ON REMOTE SERVER
--OBSOLETE ONCE REPLICATION IS ENABLED
--DELETE FROM [IC-HQSQL1REPORT].[DataTrue_Report].[dbo].[WorkingTable_Billing_SupplierInvoice_Payments]

--INSERT INTO DataTrue_EDI.dbo.RetailerPaymentAccountTypes for missing account type 1s
DELETE FROM DataTrue_EDI.dbo.RetailerPaymentAccountTypes WHERE TypeID = 1
INSERT INTO DataTrue_EDI.dbo.RetailerPaymentAccountTypes (ChainID, TypeID, TypeDescription, Custom4)
SELECT DISTINCT t.ChainID, 1, 'Default account type', ISNULL(s.Custom4, '')
FROM BillingControl AS t WITH (NOLOCK)
LEFT OUTER JOIN Stores AS s WITH (NOLOCK)
ON t.ChainID = s.ChainID
WHERE 1 = 1
AND t.ChainID > 0
AND t.ISACH = 1
AND t.IsActive = 1
AND t.BillingControlFrequency = 'Daily'
AND t.BusinessTypeID = 2
AND CONVERT(VARCHAR(10),t.ChainID) + ISNULL(Custom4, '') NOT IN (SELECT DISTINCT CONVERT(VARCHAR(10),t2.ChainID) + ISNULL(Custom4, '') FROM DataTrue_EDI.dbo.RetailerPaymentAccountTypes t2)

select CAST(null as int) as InvoiceDetailID into #invoicedetailstopay

set @rec = CURSOR local fast_forward FOR

	select Distinct EntityIDToInvoice 
	from BillingControl
	where AutoReleasePaymentWhenDue = 1
	AND ISACH = 1
	AND IsActive = 1
	AND EntityIDToInvoice = SupplierID
	AND BillingControlFrequency = 'Daily'
	AND BusinessTypeID = 2
	
open @rec

fetch next from @rec into @entityidtopay

while @@FETCH_STATUS = 0
	begin
	
	
			SET @rec2 = CURSOR LOCAL FAST_FORWARD FOR
			SELECT DISTINCT a.ChainID, t.TypeID, CASE WHEN t.TypeID = 1 THEN '' ELSE t.Custom4 END
			FROM InvoiceDetails AS a --WITH (NOLOCK,index(83))
			INNER JOIN Stores AS s WITH (NOLOCK)
			ON a.StoreID = s.StoreID
			INNER JOIN DataTrue_EDI.dbo.RetailerPaymentAccountTypes AS t WITH (NOLOCK)
			ON ISNULL(s.Custom4, '') = t.Custom4
			WHERE 1 = 1
			AND a.ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
			AND a.InvoiceDetailTypeID = 2
			AND CAST(PaymentDueDate AS DATE) <= CAST(GETDATE() AS DATE)
			AND PaymentID IS NULL

			open @rec2

			fetch next from @rec2 into @chainidpaying, @accounttypeid, @custom4
			
			while @@FETCH_STATUS = 0
				begin
				

		
					SET @paymentHoldAmount = (SELECT PaymentHoldUntilGreaterThanAmount
											  FROM BillingControl_Payments
											  WHERE ChainID = @chainidpaying
											  AND SupplierID = @entityidtopay)
				
					set @invoiceaggregationtypeid = 0
					
					select @invoiceaggregationtypeid = AggregationTypeID
					from datatrue_main.dbo.billingcontrol nolock
					where EntityIDToInvoice = @entityidtopay
					and ChainID = @chainidpaying
					and BillingControlFrequency = 'Daily'
					
		

DECLARE @RowCount INT		

					truncate table #invoicedetailstopay
					
					IF @accounttypeid > 1  --STORES FOR UNIQUE RETAILER BANK ACCOUNT
						BEGIN
							
							insert into #invoicedetailstopay
							select InvoiceDetailID 
							from InvoiceDetails as ivd --with (nolock,index(83))
							where ivd.ChainID = @chainidpaying
							and SupplierID = @entityidtopay 
							and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
							and PaymentID is null			
							and ivd.StoreID in
								(
									select storeid from stores where ChainID = @chainidpaying and isnull(Custom4, '') = @custom4
								) 
							and RecordType not in (3)
							and ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
							
							SET @RowCount = @@ROWCOUNT
						
						END
						
					ELSE IF @accounttypeid = 1 --STORES FOR DEFAULT RETAILER BANK ACCOUNT
						BEGIN
						
							insert into #invoicedetailstopay
							select InvoiceDetailID 
							from InvoiceDetails as ivd --with (nolock,index(83))
							where ivd.ChainID = @chainidpaying
							and SupplierID = @entityidtopay 
							and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
							and PaymentID is null			
							and ivd.StoreID in
								(
									select storeid from stores where ChainID = @chainidpaying and isnull(Custom4, '') <> (SELECT Custom4 FROM DataTrue_EDI.dbo.RetailerPaymentAccountTypes WHERE ChainID = @chainidpaying AND TypeID <> 1)
								) 
							and RecordType not in (3)
							and ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
							
							SET @RowCount = @@ROWCOUNT
							
							IF @RowCount = 0 --RETAILER DOES NOT HAVE ANY NON-BLANK CUSTOM 4'S THAT ARE NOT DEFAULT BANK ACCNT
								BEGIN
									insert into #invoicedetailstopay
									select InvoiceDetailID 
									from InvoiceDetails as ivd --with (nolock,index(83))
									where ivd.ChainID = @chainidpaying
									and SupplierID = @entityidtopay 
									and cast(PaymentDueDate as date) <= CAST(getdate() as date) 
									and PaymentID is null			
									and ivd.StoreID in
										(
											select storeid from stores where ChainID = @chainidpaying and isnull(Custom4, '') = @custom4
										) 
									and RecordType not in (3)
									and ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
									
									SET @RowCount = @@ROWCOUNT
									
								END
		
						END		
					
If @RowCount > 0
	begin
					select @paymentamount = SUM(InvoiceTotal)
					FROM
					(
					SELECT InvoiceNo, ROUND(SUM(TotalCost), 2) AS InvoiceTotal
					from InvoiceDetails as ivd with (nolock)
					where InvoiceDetailID in
					(select InvoiceDetailID from #invoicedetailstopay)
					GROUP BY InvoiceNo
					) AS temp
					
					IF @paymentHoldAmount IS NOT NULL
						BEGIN
							SELECT @paymentamount += ISNULL(SUM(TotalAmount), 0)
							FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held]
							WHERE ChainID = @chainidpaying
							AND SupplierID = @entityidtopay
							AND ReleasedDateTime IS NULL
							AND PaymentHeldTypeID = 1
							
							IF @paymentamount > @paymentHoldAmount
								BEGIN
									--APPEND #INVOICEDETAILIDS
									INSERT INTO #invoicedetailstopay
									SELECT InvoiceDetailID 
									FROM InvoiceDetails
									WHERE RetailerInvoiceID IN (SELECT RetailerInvoiceID 
																FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held]
																WHERE ChainID = @chainidpaying
																AND SupplierID = @entityidtopay
																AND ReleasedDateTime IS NULL
																AND PaymentHeldTypeID = 1)
									--UPDATE DATETIMELASTUPDATE IN MAIN/INVOICESRETAILER					
									UPDATE DataTrue_Main.dbo.InvoicesRetailer
									SET DateTimeLastUpdate = GETDATE()
									WHERE RetailerInvoiceID IN (SELECT RetailerInvoiceID 
																FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held]
																WHERE ChainID = @chainidpaying
																AND SupplierID = @entityidtopay
																AND ReleasedDateTime IS NULL
																AND PaymentHeldTypeID = 1)
									--UPDATE DATETIMELASTUPDATE IN EDI/INVOICESRETAILER							
									UPDATE DataTrue_EDI.dbo.InvoicesRetailer
									SET DateTimeLastUpdate = GETDATE()
									WHERE RetailerInvoiceID IN (SELECT RetailerInvoiceID 
																FROM [DataTrue_Main].[dbo].[BillingControl_Payments_Held]
																WHERE ChainID = @chainidpaying
																AND SupplierID = @entityidtopay
																AND ReleasedDateTime IS NULL
																AND PaymentHeldTypeID = 1)
									--REMOVE INVOICERETAILERIDS FROM PAYMENTS HELD TABLE						
									UPDATE [DataTrue_Main].[dbo].[BillingControl_Payments_Held]
									SET ReleasedDateTime = GETDATE()
									WHERE ChainID = @chainidpaying
									AND SupplierID = @entityidtopay
									AND ReleasedDateTime IS NULL
									AND PaymentHeldTypeID = 1
								END
							ELSE
								BEGIN
									INSERT INTO [DataTrue_Main].[dbo].[BillingControl_Payments_Held]
									(ChainID, SupplierID, RetailerInvoiceID, TotalAmount, PaymentHeldTypeID)
									SELECT ChainID, SupplierID, RetailerInvoiceID, SUM(TotalCost), 1--1 Type is for locked
									FROM InvoiceDetails AS i
									INNER JOIN #invoicedetailstopay AS i2
									ON i.InvoiceDetailID = i2.InvoiceDetailID
									GROUP BY ChainID, SupplierID, RetailerInvoiceID
									
									GOTO SkipChain;
								END
						END
					
					--CANNOT CREATE $0 PAYMENT
					IF @paymentamount = 0
						BEGIN
							GOTO SkipChain
						END
										
					select @paymenttypeid = case when @paymentamount < 0 then 5 else 4 end

					INSERT INTO [DataTrue_Main].[dbo].[Payments]
					   ([PaymentTypeID]
					   ,[PayerEntityID]
					   ,[PayeeEntityID]
					   ,[LastUpdateUserID]
					   ,[AmountOriginallyBilled]
					   ,[ACHAccountTypeID])
					VALUES
					   (@paymenttypeid
					   ,@chainidpaying
					   ,@entityidtopay
					   ,@MyID
					   ,ROUND(@paymentamount, 2)
					   ,@accounttypeid) --<LastUpdateUserID, int,>)

					
					set @newpaymentid = SCOPE_IDENTITY()
					
					update d
					set d.paymentid = @newpaymentid
					from DataTrue_Main.dbo.InvoiceDetails d
					inner join #invoicedetailstopay p
					on d.InvoiceDetailID = p.InvoiceDetailID
									
					update ed set ed.paymentid = md.PaymentID
					from datatrue_edi.dbo.InvoiceDetails ed
					inner join datatrue_main.dbo.InvoiceDetails md
					on ed.InvoiceDetailID = md.InvoiceDetailID
					inner join #invoicedetailstopay t
					on md.InvoiceDetailID = t.InvoiceDetailID
					
					--OBSOLETE ONCE REPLICATION IS ENABLED
					--IF EXISTS (SELECT name 
					--FROM [IC-HQSQL1REPORT].master.dbo.sysdatabases 
					--WHERE ('[' + name + ']' = 'DataTrue_Report' 
					--OR name = 'DataTrue_Report'))
					--	BEGIN
					--		INSERT INTO [IC-HQSQL1REPORT].[DataTrue_Report].[dbo].[WorkingTable_Billing_SupplierInvoice_Payments]
					--		(InvoiceDetailID, PaymentID)
					--		SELECT ivd.InvoiceDetailID, ivd.PaymentID
					--		FROM DataTrue_Main.dbo.InvoiceDetails ivd
					--		INNER JOIN #invoicedetailstopay t
					--		ON ivd.InvoiceDetailID = t.InvoiceDetailID
					--	END

					INSERT INTO [DataTrue_EDI].[dbo].[Payments]
							   ([PaymentID]
							   ,[PaymentTypeID]
							   ,[ChainID]
							   ,[SupplierID]
							   ,[AmountOriginallyBilled]
							   ,[LastUpdateUserID]
							   ,[ACHAccountTypeID])
					SELECT [PaymentID]
						  ,[PaymentTypeID]
						  ,[PayerEntityID]
						  ,[PayeeEntityID]
						  ,ABS([AmountOriginallyBilled])
						  ,[LastUpdateUserID]
						  ,[ACHAccountTypeID]
					  FROM [DataTrue_Main].[dbo].[Payments]	nolock
					  where paymentid = @newpaymentid
					  
					INSERT INTO @PaymentAggregationsTable (ChainID, SupplierID, PaymentTypeID, PaymentID)
					VALUES (@chainidpaying, @entityidtopay, CASE WHEN @paymentamount < 0 THEN 5 ELSE 4 END, @newpaymentid)
					  
--added by charlie 20130910
if @invoiceaggregationtypeid = 1 --this is a single aggregationid assigned to all the RetailerInvoiceID's on a specific payment
	begin
	
		INSERT INTO [DataTrue_EDI].[dbo].[Aggregations]
           ([AggregationTypeID]
           ,[AggregationValue])
		VALUES
           (1 --<AggregationTypeID, int,>
           ,'') --<AggregationValue, nvarchar(50),>)
	
		set @invoiceaggregationid = SCOPE_IDENTITY()
	
		update [DataTrue_EDI].[dbo].[Aggregations]
		set AggregationValue = CAST(@invoiceaggregationid as nvarchar(50))
		where AggregationID = @invoiceaggregationid
		
		update datatrue_main.dbo.InvoicesRetailer
		set AggregationID = @invoiceaggregationid
		where RetailerInvoiceID in
		(Select distinct RetailerInvoiceID from InvoiceDetails where InvoiceDetailID in (select distinct InvoiceDetailID from #invoicedetailstopay))

		update datatrue_edi.dbo.InvoicesRetailer
		set AggregationID = @invoiceaggregationid
		where RetailerInvoiceID in
		(Select distinct RetailerInvoiceID from InvoiceDetails where InvoiceDetailID in (select distinct InvoiceDetailID from #invoicedetailstopay))
	end

end	

SkipChain:
					  						
					fetch next from @rec2 into @chainidpaying, @accounttypeid, @custom4

				end


	
		fetch next from @rec into @entityidtopay
		
	end

DECLARE @AggregatePaymentCursor CURSOR 
DECLARE @AggregatePaymentID INT
DECLARE @AggregatedChainID INT
DECLARE @AggregatedSupplierID INT
DECLARE @AggregatedPaymentTypeID INT
DECLARE @SupplierAccountTypeID INT

SET @AggregatePaymentCursor = CURSOR LOCAL FAST_FORWARD FOR
SELECT DISTINCT p.ChainID, p.SupplierID, p.PaymentTypeID, t.AccountTypeID
FROM @PaymentAggregationsTable AS p
INNER JOIN DataTrue_Main.dbo.Stores AS s
ON p.ChainID = s.ChainID
INNER JOIN DataTrue_EDI.dbo.SupplierPaymentAccountTypes AS t
ON t.StoreID = s.StoreID
AND t.SupplierID = p.SupplierID
	
OPEN @AggregatePaymentCursor

FETCH NEXT FROM @AggregatePaymentCursor INTO @AggregatedChainID, @AggregatedSupplierID, @AggregatedPaymentTypeID, @SupplierAccountTypeID

WHILE @@FETCH_STATUS = 0
	BEGIN
	
		INSERT INTO [DataTrue_Main].[dbo].[Payments]
					   ([PaymentTypeID]
					   ,[PayerEntityID]
					   ,[PayeeEntityID]
					   ,[LastUpdateUserID]
					   ,[AmountOriginallyBilled]
					   ,[ACHAccountTypeID])
					VALUES (0,0,0,0,0,0)
					
		SELECT @AggregatePaymentID = SCOPE_IDENTITY()	 
		
		DELETE FROM DataTrue_Main.dbo.Payments WHERE PaymentID = @AggregatePaymentID  
		
		INSERT INTO DataTrue_Main.dbo.PaymentAggregations (AggregatePaymentID, ChainID, SupplierID, PaymentTypeID, PaymentID, RetailerInvoiceID)
		SELECT DISTINCT @AggregatePaymentID, @AggregatedChainID, @AggregatedSupplierID, @AggregatedPaymentTypeID, p.PaymentID, i.RetailerInvoiceID
		FROM @PaymentAggregationsTable AS p
		INNER JOIN DataTrue_Main.dbo.InvoiceDetails AS i
		ON p.PaymentID = i.PaymentID
		INNER JOIN #invoicedetailstopay AS t
		ON i.InvoiceDetailID = t.InvoiceDetailID
		INNER JOIN DataTrue_EDI.dbo.SupplierPaymentAccountTypes AS s
		ON s.StoreID = i.StoreID
		AND s.SupplierID = i.SupplierID
		AND s.AccountTypeID = @SupplierAccountTypeID
		WHERE p.ChainID = @AggregatedChainID 
		AND p.SupplierID = @AggregatedSupplierID 
		AND PaymentTypeID = @AggregatedPaymentTypeID		
		
		FETCH NEXT FROM @AggregatePaymentCursor INTO @AggregatedChainID, @AggregatedSupplierID, @AggregatedPaymentTypeID, @SupplierAccountTypeID
	END
	
CLOSE @AggregatePaymentCursor
DEALLOCATE @AggregatePaymentCursor	

UPDATE p
SET p.AggregatePaymentID = pa.AggregatePaymentID
FROM DataTrue_Main.dbo.Payments AS p
INNER JOIN 
(
SELECT TOP 1 pa.AggregatePaymentID, pa.PaymentID
FROM DataTrue_Main.dbo.PaymentAggregations AS pa
ORDER BY pa.AggregatePaymentID
) AS pa
ON p.PaymentID = pa.PaymentID

UPDATE p
SET p.AggregatePaymentID = pa.AggregatePaymentID
FROM DataTrue_EDI.dbo.Payments AS p
INNER JOIN 
(
SELECT TOP 1 pa.AggregatePaymentID, pa.PaymentID
FROM DataTrue_Main.dbo.PaymentAggregations AS pa
ORDER BY pa.AggregatePaymentID
) AS pa
ON p.PaymentID = pa.PaymentID

--OBSOLETE ONCE REPLICATION IS ENABLED
--IF EXISTS (SELECT name 
--FROM [IC-HQSQL1REPORT].master.dbo.sysdatabases 
--WHERE ('[' + name + ']' = 'DataTrue_Report' 
--OR name = 'DataTrue_Report'))
--	BEGIN
	
--		INSERT INTO [IC-HQSQL1REPORT].DataTrue_Report.dbo.Payments
--		(
--		[PaymentID]
--		,[PaymentTypeID]
--		,[PayerEntityID]
--		,[PayeeEntityID]
--		,[AmountOriginallyBilled]
--		,[PaymentStatus]
--		,[DateTimePaid]
--		,[DateTimeCreated]
--		,[LastUpdateUserID]
--		,[DateTimeLastUpdate]
--		,[Comments]
--		,[ACHAccountTypeID]
--		,[AggregatePaymentID]
--		)
--		SELECT
--		[PaymentID]
--		,[PaymentTypeID]
--		,[PayerEntityID]
--		,[PayeeEntityID]
--		,[AmountOriginallyBilled]
--		,[PaymentStatus]
--		,[DateTimePaid]
--		,[DateTimeCreated]
--		,[LastUpdateUserID]
--		,[DateTimeLastUpdate]
--		,[Comments]
--		,[ACHAccountTypeID]
--		,[AggregatePaymentID]
--		FROM DataTrue_Main.dbo.Payments nolock
--		WHERE PaymentTypeID IN (4,5)
--		AND PaymentID NOT IN (SELECT PaymentID FROM [IC-HQSQL1REPORT].DataTrue_Report.dbo.Payments nolock)	
		
--		EXEC ('UPDATE i
--			   SET i.PaymentID = t.PaymentID
--			   FROM DataTrue_Report.dbo.InvoiceDetails AS i
--			   INNER JOIN [DataTrue_Report].[dbo].[WorkingTable_Billing_SupplierInvoice_Payments] AS t
--			   ON i.InvoiceDetailID = t.InvoiceDetailID') AT [IC-HQSQL1REPORT]
			   
--		EXEC ('UPDATE h
--			   SET h.PaymentID = i.PaymentID
--			   FROM DataTrue_Report.dbo.InvoicesRetailer AS h
--			   INNER JOIN DataTrue_Report.dbo.InvoiceDetails AS i
--			   ON h.RetailerInvoiceID = i.RetailerInvoiceID
--			   INNER JOIN [DataTrue_Report].[dbo].[WorkingTable_Billing_SupplierInvoice_Payments] AS t
--			   ON i.InvoiceDetailID = t.InvoiceDetailID') AT [IC-HQSQL1REPORT]
		
--	END
	
	update h set h.PaymentID = d.PaymentID
	from DataTrue_Main.dbo.InvoicesRetailer h
	inner join DataTrue_Main.dbo.InvoiceDetails d
	on h.RetailerInvoiceID = d.RetailerInvoiceID
	where d.ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
	--and cast(h.datetimecreated as date) >= cast(GETDATE() as date)
	and h.PaymentID is null
	and d.PaymentID is not null	
	
	update h set h.PaymentID = d.PaymentID
	from DataTrue_EDI.dbo.InvoicesRetailer h
	inner join DataTrue_Main.dbo.InvoiceDetails d
	on h.RetailerInvoiceID = d.RetailerInvoiceID
	where d.ProcessID IN (SELECT ProcessID FROM DataTrue_Main.dbo.JobProcesses WHERE JobRunningID = 3 AND Timestamp > @jobLastRan)
	--and cast(h.datetimecreated as date) >= cast(GETDATE() as date)
	and h.PaymentID is null
	and d.PaymentID is not null		
	
close @rec
deallocate @rec


commit transaction	
end try
begin catch
rollback transaction
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		IF EXISTS(     
			select 1 
			from msdb.dbo.sysjobs_view job  
			inner join msdb.dbo.sysjobactivity activity on job.job_id = activity.job_id 
			where  
				activity.run_Requested_date is not null  
			and activity.stop_execution_date is null  
			and job.name = 'Billing_Regulated' 
		) 
		Begin
			exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'Billing_Regulated'
		End
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'	

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in prBilling_Payment_AutoRelease_CreatePayments_ACH_ByChain.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
		
end catch	

return
GO
