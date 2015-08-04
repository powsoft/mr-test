USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prValidateEDI_SyncTotals_ToDeploy]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 02/05/2015
-- Description:	Validates that all records that were billed have been sync'd to EDI
-- =============================================

CREATE Procedure [dbo].[prValidateEDI_SyncTotals_ToDeploy]

	AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
Declare @rec cursor
Declare @ChainName varchar(50)
Declare @CurrentDate date = Convert(date, getdate())
Declare @InvQty int
Declare @EDIQty2 Int

Set @Rec = CURSOR Local Fast_Forward For

Select ChainName
from DataTrue_EDI..ProcessStatus
where 1=1
and Date = CONVERT(date, GETDATE())
and BillingComplete = 0
and BillingIsRunning = 1
and AllFilesReceived = 1

Open @Rec
Fetch From @Rec Into @ChainName

While @@FETCH_STATUS = 0

Begin


declare @minsaledate   date=   (select MIN (StartDate) from BillingControl_Expanded_POS Where ChainIdentifier = @ChainName)     
declare @maxsaledate  date =   (select Max (endDate) from BillingControl_Expanded_POS Where ChainIdentifier = @ChainName)  



Select @INVQty =  SUM(TotalQty)
-- Select SUM(TotalQty)
from (Select Max(EndDate) EndDate, ChainId, Min(StartDate) StartDate, StoreID, SupplierID, ChainIdentifier
		From BillingControl_Expanded_POS
		Where ChainIdentifier = @ChainName
		Group by ChainId, StoreID, SupplierID, ChainIdentifier ) B
	inner hash join 
 (select TotalQty,ChainID,StoreID,SupplierID,SaleDate from
  InvoiceDetails I with(nolock,index(27))
  where InvoiceDetailTypeID in (1)   
  and Convert(date, SaleDate) between @minsaledate and @maxsaledate
)i
  On I.ChainID = B.ChainID    
  and I.StoreID = B.StoreID    
  and I.SupplierID = B.SupplierID  
  and Convert (date, i.SaleDate) between b.StartDate and b.EndDate 


Select @EDIQty2 =  SUM(TotalQty)
-- Select SUM(TotalQty)
from (Select Max(EndDate) EndDate, ChainId, Min(StartDate) StartDate, StoreID, SupplierID, ChainIdentifier
		From BillingControl_Expanded_POS
		Where ChainIdentifier = @ChainName
		Group by ChainId, StoreID, SupplierID, ChainIdentifier ) B
	inner hash join 
 (select TotalQty,ChainID,StoreID,SupplierID,SaleDate from
  datatrue_edi..InvoiceDetails I with(nolock,index(94))
  where InvoiceDetailTypeID in (1)   
  and Convert(date, SaleDate) between @minsaledate and @maxsaledate
)i
  On I.ChainID = B.ChainID    
  and I.StoreID = B.StoreID    
  and I.SupplierID = B.SupplierID  
  and Convert (date, i.SaleDate) between b.StartDate and b.EndDate 


IF @EDIQty2 <> @INVQty
	
	Begin
		
		Declare @ErrorMessage as Varchar(1000)
		Set @ErrorMessage = 'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue. EDI Invoice Detail Quantity = ' + Cast(@EDIQty2 as varchar) +  ' Invoice Detail Quantity = ' + cast(@INVQty as Varchar) + 'For Chain ' + @ChainName
		
		exec [msdb].[dbo].[sp_stop_job] 
		@job_name = 'DailyPOSBilling_NEW'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Post-Invoicing Validation Failed'
				, @ErrorMessage
				,'DataTrue System', 0, 'Datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com'	
	
	End

Fetch From @Rec Into @ChainName
	
End

Close @Rec
Deallocate @Rec
END
GO
