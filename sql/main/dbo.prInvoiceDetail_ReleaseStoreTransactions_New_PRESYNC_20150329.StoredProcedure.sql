USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_New_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/25/2014
-- Description:	Release Store Transaction Records for Invoice Detail Creation
-- =============================================
CREATE PROCEDURE [dbo].[prInvoiceDetail_ReleaseStoreTransactions_New_PRESYNC_20150329]


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @errormessage nvarchar(4000)
	declare @errorlocation nvarchar(255)
	declare @errorsenderstring nvarchar(255)
	declare @MyID int

	set @MyID = 24134

	begin try 

		DECLARE @ProcessID INT

		SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobRunningID = 14

			Begin Transaction --Begin Surrogate Cost Rule for POS Billing

				update t set t.rulecost = s.UnitPrice, t.RuleRetail = s.UnitRetail 
				--select *
				from StoreTransactions t
				inner join productprices s
				on t.StoreID = s.StoreID
				and t.ProductID = s.ProductID
				and t.SupplierID = s.supplierid
				and CAST(t.saledatetime as date) between s.ActiveStartDate and s.ActiveLastDate
				and s.ProductPriceTypeID = 3
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9, 14))
				and RecordType = 2
				
				update t set t.rulecost = s.UnitPrice, t.RuleRetail = s.UnitRetail 
				--select *
				from StoreTransactions t
				inner join productprices s
				on t.StoreID = s.StoreID
				and t.ProductID = s.ProductID
				and t.SupplierID = s.supplierid
				--and CAST(t.saledatetime as date) between s.ActiveStartDate and s.ActiveLastDate
				and s.ProductPriceTypeID = 3
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9, 14))
				and RecordType = 2
				
				update t set rulecost = UnitPrice, ruleretail = UnitRetail
				--Select distinct t.* 
				from [dbo].[StoreTransactions] t
				inner join ProductPrices p
				on t.ProductID = p.ProductID
				and t.SupplierID = p.SupplierID
				and t.ChainID = p.ChainID
				and CAST(T.SaleDateTime as date) between p.ActiveStartDate AND P.ActiveLastDate
				AND P.ProductPriceTypeID = 3
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9, 14))
				and RecordType = 2
				
				update t set rulecost = UnitPrice, ruleretail = UnitRetail
				--Select distinct t.* 
				from [dbo].[StoreTransactions] t
				inner join ProductPrices p
				on t.ProductID = p.ProductID
				and t.SupplierID = p.SupplierID
				and t.ChainID = p.ChainID
				--and CAST(T.SaleDateTime as date) between p.ActiveStartDate AND P.ActiveLastDate
				AND P.ProductPriceTypeID = 3
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9, 14))
				and RecordType = 2
				
				update t set rulecost = UnitPrice, ruleretail = UnitRetail 
				--Select distinct t.*
				from [dbo].[StoreTransactions] t
				inner join ProductPrices p
				on t.ChainID = p.ChainID
				and t.ProductID = p.ProductID
				AND P.ProductPriceTypeID = 3
				and CAST(T.SaleDateTime as date) between p.ActiveStartDate AND P.ActiveLastDate
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID In (9, 14))
				and RecordType = 2
				
				update t set rulecost = UnitPrice, ruleretail = UnitRetail 
				--Select distinct t.*
				from [dbo].[StoreTransactions] t
				inner join ProductPrices p
				on t.ChainID = p.ChainID
				and t.ProductID = p.ProductID
				AND P.ProductPriceTypeID = 3
				--and CAST(T.SaleDateTime as date) between p.ActiveStartDate AND P.ActiveLastDate
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9, 14))
				and RecordType = 2
																
				update t set rulecost = UnitPrice, ruleretail = UnitRetail
				--Select distinct t.* 
				from [dbo].[StoreTransactions] t
				inner join ProductPrices p
				on t.ProductID = p.ProductID
				and t.SupplierID = p.SupplierID
				and CAST(T.SaleDateTime as date) between p.ActiveStartDate AND P.ActiveLastDate
				AND P.ProductPriceTypeID = 3
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9, 14))
				and RecordType = 2

				update t set rulecost = UnitPrice, ruleretail = UnitRetail
				--Select distinct t.* 
				from [dbo].[StoreTransactions] t
				inner join ProductPrices p
				on t.ProductID = p.ProductID
				and t.SupplierID = p.SupplierID
				AND P.ProductPriceTypeID = 3
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,14))
				and RecordType = 2
				
				update t set rulecost = UnitPrice, ruleretail = UnitRetail
				--Select distinct TransactionStatus, t.* 
				from [dbo].[StoreTransactions] t
				inner join ProductPrices p
				on t.ProductID = p.ProductID
				and t.SupplierID = 0
				AND P.ProductPriceTypeID = 3
				and Isnull(RuleCost, 0) = 0
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,14))
				and RecordType = 2
				and TransactionStatus not in (813)

				
				Update T Set T.ProductPriceTypeID = P.ProductPriceTypeID, SetupCost = UnitPrice, SetupRetail = UnitRetail, RuleRetail = UnitRetail, RuleCost = UnitPrice
				--Select distinct T.*
				from StoreTransactions T with(nolock)
				inner join ProductPrices P
				on T.ChainID = P.ChainID
				and T.SupplierID = P.SupplierID
				and T.StoreID = P.StoreID
				and T.ProductID = P.ProductID
				where T.TransactionStatus = 0
				and T.SetupCost is null
				and P.ProductPriceTypeID = 3
				and Isnull(T.RuleCost,0) = 0
				and TransactionTypeID in (2,6)
				--and T.ChainID not in (select Distinct EntityIDToInclude 
				--								from dbo.ProcessStepEntities 
				--								where ProcessStepName In ('prGetInboundPOSTransactions_BAS', 'prGetInboundPOSTransactions'))
				--and T.ChainID <> 44285
				and T.SaleDateTime between P.ActiveStartDate and P.ActiveLastDate
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13, 14))

			commit Transaction --End Surrogate Cost Rules for POS Billing


			begin transaction --Begin Store Transaction Release for Invoicing 

				select Distinct StoreTransactionID 
				into #tempStoreTransactions 
				--select * 
				from StoreTransactions t 
				inner join Chains S
				on T.ChainID = S.ChainID 
				Inner Join DataTrue_EDI..ProcessStatus P
				on P.ChainName = S.ChainIdentifier
				inner join (Select Chainid, MAX(NextBillingPeriodEndDateTime) BillingDate, Case when BusinessTypeID = 4 then 0 Else 2 END As RecordType
							From BillingControl
							Where BusinessTypeID = 1
							and cast(NextBillingPeriodRunDateTime as date) = CAST(Getdate() as date)
							Group by ChainID, BusinessTypeID) B
				On t.ChainID = B.ChainID
				where 1=1 
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13, 14))
				and TransactionTypeID in (2, 6)
				and Qty <> 0
				and Isnull(InvoiceBatchID, 0) = 0
				and Isnull(RuleCost, 0) <> 0
				and RuleRetail is not null
				and Isnull(StoreID,0) <> 0
				and Isnull(ProductID,0) <> 0
				and CAST(SaleDateTime as date) <= (CAST(B.BillingDate as date))
				and P.AllFilesReceived = 1
				and P.BillingComplete = 0
				and P.BillingIsRunning = 1
				and P.Date = CAST(getdate() as Date)
				and TransactionStatus in (0,2)
				and P.RecordTypeID = 2


				update t
				set transactionstatus = case when transactionstatus = 2 then 800 else 801 end, DateTimeLastUpdate = GETDATE(), ProcessID = @ProcessID
				from  StoreTransactions t
				inner join #tempStoreTransactions tmp
				on t.StoreTransactionID = tmp.StoreTransactionID
				where TransactionStatus <> -801
				and 
				(
				(TransactionStatus = 2 and TransactionTypeID not in (10,11))
				or
				(TransactionStatus = 0 and TransactionTypeID in (2,4,5,6,7,8,9,14,16,17,18,19,20,21,22,23))
				)     
				     
			commit transaction --End Store Transaction Release for Invoicing
		
		end try
		
		begin catch
				rollback transaction
				
				set @errormessage = error_message()
				set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
				set @errorsenderstring = ERROR_PROCEDURE()
				
				exec dbo.prLogExceptionAndNotifySupport
				1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,@MyID

				exec [msdb].[dbo].[sp_stop_job] 
					@job_name = 'DailyPOSBilling_New'

				exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Processing Has Stopped'
						,'Daily processing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
						,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'		
				
		end catch
END
GO
