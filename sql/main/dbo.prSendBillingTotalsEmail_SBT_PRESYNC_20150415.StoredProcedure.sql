USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prSendBillingTotalsEmail_SBT_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 5/23/2014
-- Description:	Sends Email of Total when Newspaper Billing is Completed
-- =============================================
CREATE PROCEDURE [dbo].[prSendBillingTotalsEmail_SBT_PRESYNC_20150415] 

AS
BEGIN

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--DECLARE @ProcessedChainID INT
	--DECLARE @ProcessedChainName VARCHAR(150)
	--DECLARE @InvDate Date

	--DECLARE ProcessedCursor CURSOR FAST_FORWARD LOCAL FOR
	--			SELECT DISTINCT C.ChainID, C.ChainName, Cast(Dateadd(d, -7,B.NextBillingPeriodRunDateTime) as date) as InvDate
	--			FROM Chains C 
	--			Inner Join BillingControl B 
	--			on C.Chainid = B.EntityIDtoInvoice 
	--			and C.Chainid = B.Chainid
	--			WHERE B.EntityIDToInvoice IN (
	--								SELECT DISTINCT ENTITYIDTOINCLUDE 
	--								FROM ProcessStepEntities 
	--								WHERE ProcessStepName = 'prSendBillingEmail_PDI_SBT'
	--								and isactive = 1
	--							 )
	--			And Dateadd(d, -7,Cast(NextBillingPeriodRunDateTime as Date)) = Cast(Getdate() as date)
	--			and BusinessTypeID = 1
	--			--And B.BillingControlFrequency = 'weekly'				 
								 

	--OPEN ProcessedCursor
	--FETCH NEXT FROM ProcessedCursor INTO @ProcessedChainID, @ProcessedChainName, @InvDate


	--WHILE @@FETCH_STATUS = 0
	--	  BEGIN       
				--GET INVOICE DATA
				DECLARE @tmpProcessedInvoices TABLE (total varchar(50), deliveryfee varchar(50), adj varchar(50), costandfee varchar(50), totalretail varchar(50), chainid int, chainname varchar(50), WeekEnding varchar(50), SupplierName varchar(50))
				--DELETE FROM @tmpProcessedInvoices
				INSERT INTO @tmpProcessedInvoices (total, deliveryfee, adj, costandfee, totalretail, chainid, chainname, WeekEnding, SupplierName)
						
						Select Distinct A.[Total Cost],
						[Delivery Fee],
						C.[Retailer Adjustment], 
						D.[Cost With Delivery Fee], 
						E.[Total Retail], A.ChainID, A.ChainName, A.InvoicePeriodEnd, A.SupplierName

						From 
						(
							  select SUM(TotalQty*UnitCost) as [Total Cost], d.ChainID, C.ChainName, R.InvoicePeriodEnd, S.SupplierName, d.SupplierID
							  from InvoiceDetails d with (nolock) 
							  inner join Chains C on 
							  C.ChainID = d.ChainID
							  Inner join InvoicesRetailer R on
							  d.RetailerInvoiceID = R.RetailerInvoiceID
							  Inner Join Suppliers S
							  on d.SupplierID = S.SupplierID Inner Join DataTrue_EDI..ProcessStatus P
							  on P.ChainName = C.ChainIdentifier
							  where d.ChainID  in (
									SELECT DISTINCT ENTITYIDTOINCLUDE 
									FROM ProcessStepEntities 
									WHERE ProcessStepName = 'prSendBillingEmail'
								 )
							  and CAST(InvoiceDate as date) = CONVERT(date, getdate())
							  and InvoiceDetailTypeID in (1)
							  and P.Date = CONVERT(date, getdate())
							  and P.AllFilesReceived = 1
							  and P.BillingIsRunning = 1
							  and P.BillingComplete = 0
							  and InvoiceDetailTypeID in (1)
							  and RecordType = 0
							  group by d.ChainID, C.ChainName, R.InvoicePeriodEnd, S.SupplierName, d.SupplierID
						) A
						Left Join 
						(
							  Select SUM(ISNULL(TotalQty, 0) * ISNULL(UnitCost, 0)) as [Delivery Fee] ,d.ChainID, R.InvoicePeriodEnd, d.SupplierID
							  from InvoiceDetailS d with (nolock) 
							  inner join Chains C on 
							  C.ChainID = d.ChainID
							  Inner join InvoicesRetailer R on
							  d.RetailerInvoiceID = R.RetailerInvoiceID
							  Inner Join DataTrue_EDI..ProcessStatus P
							  on P.ChainName = C.ChainIdentifier
							  where d.ChainID  in (
									SELECT DISTINCT ENTITYIDTOINCLUDE 
									FROM ProcessStepEntities 
									WHERE ProcessStepName = 'prSendBillingEmail'
								 )
							  and CAST(InvoiceDate as date) = CONVERT(date, getdate())
							  and InvoiceDetailTypeID in (1)
							  and P.Date = CONVERT(date, getdate())
							  and P.AllFilesReceived = 1
							  and P.BillingIsRunning = 1
							  and P.BillingComplete = 0
							  and InvoiceDetailTypeID in (16)
							  and RecordType = 0
							  group by d.ChainID, R.InvoicePeriodEnd, d.SupplierID
						) B
						on A.ChainID = B.ChainID and A.InvoicePeriodEnd = B.InvoicePeriodEnd and A.SupplierID = B.SupplierID
						Left Join 
						(
							  Select (SUm(Isnull(Adjustment1, '0.00'))) [Retailer Adjustment], d.ChainID, R.InvoicePeriodEnd, d.SupplierID
							  from InvoiceDetailS d with (nolock)
							  inner join Chains C on 
							  C.ChainID = d.ChainID
							  Inner join InvoicesRetailer R on
							  d.RetailerInvoiceID = R.RetailerInvoiceID
							  Inner Join DataTrue_EDI..ProcessStatus P
							  on P.ChainName = C.ChainIdentifier
							  where d.ChainID  in (
									SELECT DISTINCT ENTITYIDTOINCLUDE 
									FROM ProcessStepEntities 
									WHERE ProcessStepName = 'prSendBillingEmail'
								 )
							  and CAST(InvoiceDate as date) = CONVERT(date, getdate())
							  and InvoiceDetailTypeID in (1)
							  and P.Date = CONVERT(date, getdate())
							  and P.AllFilesReceived = 1
							  and P.BillingIsRunning = 1
							  and P.BillingComplete = 0
							  and InvoiceDetailTypeID in (1, 16)
							  and RecordType = 0
							  Group by d.ChainID, R.InvoicePeriodEnd, d.SupplierID
						) C
						on A.ChainID = C.ChainID and A.InvoicePeriodEnd = C.InvoicePeriodEnd and A.SupplierID = C.SupplierID
						Left Join
						(
							  Select SUM(totalqty*UnitCost) [Cost With Delivery Fee], d.ChainID, R.InvoicePeriodEnd, d.SupplierID
							  from InvoiceDetailS d with (nolock)
							  inner join Chains C on 
							  C.ChainID = d.ChainID
							  Inner join InvoicesRetailer R on
							  d.RetailerInvoiceID = R.RetailerInvoiceID
							  Inner Join DataTrue_EDI..ProcessStatus P
							  on P.ChainName = C.ChainIdentifier
							  where d.ChainID  in (
									SELECT DISTINCT ENTITYIDTOINCLUDE 
									FROM ProcessStepEntities 
									WHERE ProcessStepName = 'prSendBillingEmail'
								 )
							  and CAST(InvoiceDate as date) = CONVERT(date, getdate())
							  and InvoiceDetailTypeID in (1)
							  and P.Date = CONVERT(date, getdate())
							  and P.AllFilesReceived = 1
							  and P.BillingIsRunning = 1
							  and P.BillingComplete = 0
							  and InvoiceDetailTypeID in (1, 16)
							  and RecordType = 0
							  Group by d.ChainID, R.InvoicePeriodEnd, d.SupplierID
						) D
						on A.ChainID = D.ChainID and A.InvoicePeriodEnd = D.InvoicePeriodEnd and A.SupplierID = D.SupplierID
						Left Join 
						(
							  Select SUM(TotalQty*UnitRetail) [Total Retail], d.ChainID, R.InvoicePeriodEnd, d.SupplierID
							  from InvoiceDetailS d with (nolock)
							  inner join Chains C on 
							  C.ChainID = d.ChainID
							  Inner join InvoicesRetailer R on
							  d.RetailerInvoiceID = R.RetailerInvoiceID
							  Inner Join DataTrue_EDI..ProcessStatus P
							  on P.ChainName = C.ChainIdentifier
							  where d.ChainID  in (
									SELECT DISTINCT ENTITYIDTOINCLUDE 
									FROM ProcessStepEntities 
									WHERE ProcessStepName = 'prSendBillingEmail'
								 )
							  and CAST(InvoiceDate as date) = CONVERT(date, getdate())
							  and InvoiceDetailTypeID in (1)
							  and P.Date = CONVERT(date, getdate())
							  and P.AllFilesReceived = 1
							  and P.BillingIsRunning = 1
							  and P.BillingComplete = 0
							  and InvoiceDetailTypeID in (1, 16)
							  and RecordType = 0
							  Group by d.ChainID, R.InvoicePeriodEnd, d.SupplierID
						) E
						On E.ChainID = A.ChainID and A.InvoicePeriodEnd = E.InvoicePeriodEnd and A.SupplierID = E.SupplierID

				--FETCH NEXT FROM ProcessedCursor INTO @ProcessedChainID, @ProcessedChainName, @InvDate
		  --END
		  
				UPDATE @tmpProcessedInvoices SET deliveryfee = 0 WHERE deliveryfee IS NULL
				
				Update @tmpProcessedInvoices Set WeekEnding = CONVERT(date, weekending)

				UPDATE @tmpProcessedInvoices
				SET total =  Convert(varchar(50),Convert(money,total))
								+ REPLICATE(' ', (10 - LEN(convert(money, total))))
				WHERE LEN(Convert(money,total)) < 11
				
				UPDATE @tmpProcessedInvoices
				SET deliveryfee = CONVERT(VARCHAR(100), CONVERT(MONEY, deliveryfee)) 
								+ REPLICATE(' ', (11 - LEN(CONVERT(MONEY, deliveryfee))))
				WHERE LEN(CONVERT(MONEY,deliveryfee)) < 12

				UPDATE @tmpProcessedInvoices
				SET adj = Convert(varchar(50), convert(money,adj))+ REPLICATE(' ', (11 - LEN(convert(money,adj))))
				WHERE LEN(convert(money, adj)) < 12

				UPDATE @tmpProcessedInvoices
				SET costandfee = CONVERT(varchar(50), Convert(money, costandfee)) + REPLICATE(' ', (27 - LEN(convert(money, costandfee))))
				WHERE LEN(CONVERT(money, costandfee)) < 28
				
				UPDATE @tmpProcessedInvoices
				SET totalretail = CONVERT(varchar(50), convert(money, totalretail)) + REPLICATE(' ', (11 - LEN(convert(money, totalretail))))
				WHERE LEN(CONVERT(money, totalretail)) < 12
				
				DECLARE @ProcessedRecords VARCHAR(MAX)
				SET @ProcessedRecords = 'TOTAL COST'					 + CHAR(9) + CHAR(9) 
										+ 'DELIVERY FEE'				 + CHAR(9) + CHAR(9) 
										+ 'iCONTROL FEE'				 + CHAR(9) + CHAR(9) 
										+ 'TOTAL COST WITH DELIVERY FEE' + CHAR(9) + CHAR(9)  
										+ 'TOTAL RETAIL'				 + CHAR(9) + CHAR(9) 
										+ 'WEEK ENDING'					 + CHAR(9) + CHAR(9)  
										+ 'CHAIN NAME'					 + CHAR(9) + CHAR(9)
										+ 'SUPPLIER NAME'				 + CHAR(13) + CHAR(10)    
	            
				SELECT @ProcessedRecords +=  x.total	+ CHAR(9) + CHAR(9) 
										+ x.deliveryfee + CHAR(9) + CHAR(9) 
										+ x.adj			+ CHAR(9) + CHAR(9) 
										+ x.costandfee  + CHAR(9) + CHAR(9) 
										+ x.totalretail + CHAR(9) + CHAR(9)
										+ WeekEnding	+ CHAR(9) + CHAR(9)
										+ chainname		+ CHAR(9) + CHAR(9)
										+ x.SupplierName+ CHAR(13) + CHAR(10)
				FROM @tmpProcessedInvoices x
				Order by x.chainid, x.SupplierName, x.WeekEnding
				
				DECLARE @ProcessedEmailBody VARCHAR(MAX)
				SET @ProcessedEmailBody = 'The following chains were billed.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
														   CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 
														   @ProcessedRecords + CHAR(13) + CHAR(10) 
	            
				--GET EMAIL ADDRESSES WHERE RECEIVE ACH NOTIFICATIONS IS TRUE
				DECLARE @Processedemailaddresses VARCHAR(MAX) = ''
				SET @Processedemailaddresses = 'datatrueit@icucsolutions.com; mindy.yu@icucsolutions.com; anthony.oginni@icucsolutions.com; edi@icucsolutions.com; invoices@icucsolutions.com; ap@icucsolutions.com'

				EXEC dbo.[prSendEmailNotification_PassEmailAddresses_HTML_Logos] 'SBT Billing Has been Processed'
					  ,@ProcessedEmailBody
					  ,'DataTrue System', 0, @Processedemailaddresses
	 --           FETCH NEXT FROM ProcessedCursor INTO @ProcessedChainID, @ProcessedChainName, @InvDate

	--CLOSE ProcessedCursor
	--DEALLOCATE ProcessedCursor

END
GO
