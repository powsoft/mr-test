USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_ReleaseStoreTransactions_New_ToDeploy]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 8/25/2014
-- Description:	Release Store Transaction Records for Invoice Detail Creation
-- =============================================
CREATE PROCEDURE [dbo].[prInvoiceDetail_ReleaseStoreTransactions_New_ToDeploy]


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
				and T.SaleDateTime between P.ActiveStartDate and P.ActiveLastDate
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13, 14))

			commit Transaction --End Surrogate Cost Rules for POS Billing


			begin transaction --Begin Store Transaction Release for Invoicing 

				Select Distinct S.StoreTransactionID INto #tempStoreTransactions --Drop Table #tempStoreTransactions
				--Select Distinct S.*
				from (Select Max(EndDate) EndDate, Storeid, Supplierid, Chainid, ChainIdentifier 
					 From BillingControl_Expanded_POS T
					 Inner Join DataTrue_EDI..ProcessStatus P
					 on P.ChainName = T.ChainIdentifier
					 Where P.AllFilesReceived = 1
					 and P.BillingComplete = 0
					 and P.BillingIsRunning = 1
					 and P.Date = CONVERT(date, getdate())
					 and P.RecordTypeID = 2
					 and T.BillingControlID not in (Select BillingControlID from BillingControl where ChainID = 40393 and BusinessTypeID = 4)
					 Group By Storeid, Supplierid, Chainid, ChainIdentifier ) T
				Inner Join StoreTransactions S with(nolock)
				On T.StoreID = S.StoreID
				And T.SupplierID = S.SupplierID 
				WHere 1=1
				and ProcessID in (Select ProcessID from JobProcesses where JobRunningID in (9,13, 14))
				and Convert(date, S.SaleDateTime) <= EndDate
				and TransactionStatus in (0,2)
				and TransactionTypeID in (2, 6)
				and Qty <> 0
				and Isnull(InvoiceBatchID, 0) = 0
				and Isnull(RuleCost, 0) <> 0
				and RuleRetail is not null
				and Isnull(S.StoreID,0) <> 0
				and Isnull(ProductID,0) <> 0
				option (recompile)

		
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
