USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_SUP_Create_ACH_debug20130920]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery9.sql|7|0|C:\Users\vince.moore\AppData\Local\Temp\7\~vs38A6.sql


CREATE procedure [dbo].[prInvoiceDetail_SUP_Create_ACH_debug20130920]
--@invoicedetailtype tinyint,
@saledate date=null
/*
prInvoiceDetail_Retailer_POS_Create '6/2/2011', 1
*/
as

--declare @saledate date set @saledate = null --'11/7/2011'
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @batchid bigint
declare @batchstring nvarchar(255)
declare @invoicedetailtype tinyint
declare @invoicedetailswithnullretailerinvoiceid int

if @saledate is null
	set @saledate = GETDATE()

set @MyID = 24126
set @invoicedetailtype = 2 --SUPSource

begin try


select 
	StoreTransactionID
into 
	#tempStoreTransactions
	--select *
from 
	StoreTransactions WITH(NOLOCK)
WHERE 1=1
and	DateTimeCreated >= CONVERT(DATE,GETDATE()-2)  --ADDED BY PaulT 9-18-2013
and	TransactionStatus in (800, 801)
and TransactionTypeID in (5,8,9,14,20,21)
--and ChainID = 50964 - commented out by VM 05/07/2013 replaced with

and SupplierID in (select SupplierID from Suppliers WITH(NOLOCK) where IsRegulated = 1) 

--block below to get all chains currently being processed
--and ChainID in( 
--	Select c.ChainID 
--	From DataTrue_EDI.dbo.ProcessStatus_ach ps
--	Inner Join DataTrue_Main.dbo.Chains c On c.ChainIdentifier = ps.ChainName
--	Where BillingIsRunning = 1
--	And BillingComplete = 0
--	And CAST(ps.[Date] as date) = CAST(getdate() as date)
--)
and RuleCost <> 0
and Qty <> 0

/*commented BY PaulT 9-18-2013*/
--and SupplierID in
--(select SupplierID from Suppliers where IsRegulated = 1) 







if @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end
	
	DECLARE @tempinvoicedetails TABLE (ChainID int
           ,[StoreID] int
           ,[ProductID] int
           ,[BrandID] int
           ,[SupplierID] int
           ,SaleDateTime DATE
           ,UnitCost money);
/*
set @invoicedetailswithnullretailerinvoiceid  = 0
select @invoicedetailswithnullretailerinvoiceid = count(InvoiceDetailID) from InvoiceDetails where RetailerInvoiceID is null and InvoiceDetailTypeID = 1 --and SaleDate < '7/9/2012'	
if @invoicedetailswithnullretailerinvoiceid > 0
	begin
			update i set i.[TotalQty] = i.[TotalQty] + s.TotalQty
				   ,i.[TotalCost] = i.[TotalCost] + s.TotalCost
				   ,i.[TotalRetail] = i.[TotalRetail] + s.TotalRetail
				   ,i.[UnitRetail] =  (i.[TotalRetail] + s.TotalRetail)/(i.[TotalQty] + s.TotalQty)
				   ,i.[LastUpdateUserID] = @MyID
				   ,i.[DateTimeLastUpdate] = getdate()
				   ,i.[BatchID] = isnull([BatchID], '') + ' ' + @batchstring
				   output inserted.ChainID,inserted.StoreID,inserted.ProductID,
				   inserted.BrandID,inserted.SupplierID,inserted.SaleDate,inserted.UnitCost
				   into @tempinvoicedetails
			from [DataTrue_Main].[dbo].[InvoiceDetails] i inner join
			(select ChainID
				   ,StoreID
				   ,ProductID
				   ,BrandID
				   ,SupplierID
				   ,SUM(Qty) as TotalQty
				   ,SUM(Qty * (RuleCost - isnull(PromoAllowance, 0))) as TotalCost
				   ,SUM(Qty * RuleRetail) as TotalRetail
				   ,SUM(Qty * (RuleCost))/SUM(Qty) as UnitCost
				   ,SUM(Qty * RuleRetail)/SUM(Qty) as UnitRetail
				   ,CAST(SaleDateTime as DATE) as SaleDate
				   ,ChainIdentifier
				   ,StoreIdentifier
				   ,StoreName
				   ,ProductIdentifier
				   ,ProductQualifier
				   ,RawProductIdentifier
				   ,SupplierName
				   ,SupplierIdentifier
				   ,BrandIdentifier
				   ,DivisionIdentifier
				   ,UOM
				   ,SalePrice
				   ,ReportedAllowance as Allowance
				   ,InvoiceNo
				   ,PONo
				   ,CorporateName
				   ,CorporateIdentifier
				   ,Banner
				   ,PromoTypeID
				   ,PromoAllowance
				   ,SBTNumber
				FROM [dbo].[StoreTransactions] t
				inner join ##tempStoreTransactions tmp
				on t.StoreTransactionID = tmp.StoreTransactionID
				group by [ChainID]
				   ,[StoreID]
				   ,[ProductID]
				   ,[BrandID]
				   ,[SupplierID]
				   ,CAST(SaleDateTime as DATE)
				   ,RuleCost--) S
				   ,ChainIdentifier
				   ,StoreIdentifier
				   ,StoreName
				   ,ProductIdentifier
				   ,ProductQualifier
				   ,RawProductIdentifier
				   ,SupplierName
				   ,SupplierIdentifier
				   ,BrandIdentifier
				   ,DivisionIdentifier
				   ,UOM
				   ,SalePrice
				   ,ReportedAllowance
				   ,InvoiceNo
				   ,PONo
				   ,CorporateName
				   ,CorporateIdentifier
				   ,Banner
				   ,PromoTypeID
				   ,PromoAllowance
				   ,SBTNumber
				having SUM(Qty) <> 0) S
			on i.ChainID = s.ChainID
			and i.ChainID <> 44125
			and i.StoreID = s.StoreID 
			and i.ProductID = s.ProductID
			and i.BrandID = s.BrandID
			and i.SupplierID = s.SupplierID
			--and i.SaleDate = s.SaleDate
			and DATEDIFF(D,i.SaleDate,s.SaleDate)=0
			and i.UnitCost = s.UnitCost
			and i.RetailerInvoiceID is null
			--and i.SupplierInvoiceID is null
			--and i.TotalQty > 0
			and i.InvoiceDetailTypeID = @invoicedetailtype
	end
*/	
	BEGIN TRANSACTION
	
	--INSERT into InvoiceDetails
 --          ([ChainID]
 --          ,[StoreID]
 --          ,[ProductID]
 --          ,[BrandID]
 --          ,[SupplierID]
 --          ,[InvoiceDetailTypeID]
 --          ,[TotalQty]
 --          ,[TotalCost]
 --          ,[TotalRetail]
 --          ,[UnitCost]
 --          ,[UnitRetail]
 --          ,[LastUpdateUserID]
 --          ,[SaleDate]
 --          ,[BatchID]
 --          ,StoreIdentifier
 --          ,StoreName
 --          ,ProductIdentifier
 --          ,ProductQualifier
 --          ,RawProductIdentifier
 --          ,SupplierName
 --          ,SupplierIdentifier
 --          ,BrandIdentifier
 --          ,DivisionIdentifier
 --          ,UOM
 --          ,SalePrice
 --          ,Allowance
 --          ,InvoiceNo
 --          ,PONo
 --          ,CorporateName
 --          ,CorporateIdentifier
 --          ,Banner
 --          ,PromoTypeID
 --          ,PromoAllowance
 --          ,SBTNumber
 --          ,[PaymentDueDate]
	--	  ,[Adjustment1]
	--	  ,[Adjustment2]
	--	  ,[Adjustment3]
	--	  ,[Adjustment4]
	--	  ,[Adjustment5]
	--	  ,[Adjustment6]
	--	  ,[Adjustment7]
	--	  ,[Adjustment8]
	--	  ,[VIN]
	--	  ,[RawStoreIdentifier]
	--	  ,[Route]
	--	  ,[SourceID])
     select s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.BrandID
           ,s.SupplierID
           ,@invoicedetailtype
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) as TotalQty
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * (RuleCost))+isnull(Adjustment1, 0)+isnull(Adjustment2, 0)+isnull(Adjustment3, 0)+isnull(Adjustment4, 0)+isnull(Adjustment5, 0)+isnull(Adjustment6, 0)+isnull(Adjustment7, 0)+isnull(Adjustment8, 0) as TotalCost
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleRetail) as TotalRetail
           ,0 --SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleCost)/SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) as UnitCost
           ,0 --,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleRetail)/SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) as UnitRetail
           ,@MyID
           ,CAST(s.SaleDateTime as DATE) as SaleDate
           ,@batchstring --ChainIdentifier
           ,StoreIdentifier
           ,StoreName
           ,ProductIdentifier
           ,ProductQualifier
           ,RawProductIdentifier
           ,SupplierName
           ,SupplierIdentifier
           ,BrandIdentifier
           ,DivisionIdentifier
           ,UOM
           ,SalePrice
           ,ReportedAllowance as Allowance
           ,SupplierInvoiceNumber
           ,PONo
           ,CorporateName
           ,CorporateIdentifier
           ,Banner
           ,PromoTypeID
           ,PromoAllowance
           ,SBTNumber
           ,[InvoiceDueDate]
		  ,isnull([Adjustment1],0)
		  ,isnull([Adjustment2],0)
		  ,isnull([Adjustment3],0)
		  ,isnull([Adjustment4],0)
		  ,isnull([Adjustment5],0)
		  ,isnull([Adjustment6],0)
		  ,isnull([Adjustment7],0)
		  ,isnull([Adjustment8] ,0)
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route   
		  ,[SourceID]       
		FROM [dbo].[StoreTransactions] s
		inner join #tempStoreTransactions tmp
		on s.StoreTransactionID = tmp.StoreTransactionID
		left join @tempinvoicedetails i
		on i.ChainID = s.ChainID
		and i.StoreID = s.StoreID 
		and i.ProductID = s.ProductID
		and i.BrandID = s.BrandID
		and i.SupplierID = s.SupplierID
		--and i.SaleDateTime = s.SaleDateTime
		and DATEDIFF(D,i.SaleDateTime,s.SaleDateTime)=0
		--and i.UnitCost = SUM(Qty * (RuleCost))/SUM(Qty)--s.UnitCost
		where i.ChainID is null
		group by s.[ChainID]
           ,s.[StoreID]
           ,s.[ProductID]
           ,s.[BrandID]
           ,s.[SupplierID]
           ,CAST(s.SaleDateTime as DATE)
           ,s.RuleCost--) S
           ,s.ChainIdentifier
           ,s.StoreIdentifier
           ,s.StoreName
           ,s.ProductIdentifier
           ,s.ProductQualifier
           ,s.RawProductIdentifier
           ,s.SupplierName
           ,s.SupplierIdentifier
           ,s.BrandIdentifier
           ,s.DivisionIdentifier
           ,s.UOM
           ,s.SalePrice
           ,s.ReportedAllowance
           ,s.SupplierInvoiceNumber
           ,s.PONo
           ,s.CorporateName
           ,s.CorporateIdentifier
           ,s.Banner
           ,s.PromoTypeID
           ,s.PromoAllowance
           ,s.SBTNumber
           ,[InvoiceDueDate]
		  ,isnull([Adjustment1],0)
		  ,isnull([Adjustment2],0)
		  ,isnull([Adjustment3],0)
		  ,isnull([Adjustment4],0)
		  ,isnull([Adjustment5],0)
		  ,isnull([Adjustment6],0)
		  ,isnull([Adjustment7],0)
		  ,isnull([Adjustment8] ,0) 
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route 
		  ,[SourceID]        
        --having SUM(Qty) = 0 
		having (SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) = 0) -- PAUL's addition 9/20/2013
	
	
	
	/*
	
	

MERGE INTO [DataTrue_Main].[dbo].[InvoiceDetails] i

USING (select ChainID
           ,StoreID
           ,ProductID
           ,BrandID
           ,SupplierID
 --          ,1 --POSSource
           ,SUM(Qty) as TotalQty
           ,SUM(Qty * (RuleCost - isnull(PromoAllowance, 0))) as TotalCost
           ,SUM(Qty * RuleRetail) as TotalRetail
           ,SUM(Qty * (RuleCost))/SUM(Qty) as UnitCost
           ,SUM(Qty * RuleRetail)/SUM(Qty) as UnitRetail
           ,CAST(SaleDateTime as DATE) as SaleDate
            ,ChainIdentifier
,StoreIdentifier
,StoreName
,ProductIdentifier
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,ReportedAllowance as Allowance
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber
		FROM [dbo].[StoreTransactions] t
		inner join ##tempStoreTransactions tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
	    group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,CAST(SaleDateTime as DATE)
           ,RuleCost--) S
                       ,ChainIdentifier
           ,StoreIdentifier
,StoreName
,ProductIdentifier
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,ReportedAllowance
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber
		--having SUM(Qty * RuleCost) <> 0) S
		having SUM(Qty) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.UnitCost = s.UnitCost
	and i.RetailerInvoiceID is null
	and i.SupplierInvoiceID is null
	and i.TotalQty > 0
	and i.InvoiceDetailTypeID = @invoicedetailtype

WHEN MATCHED THEN

update set [TotalQty] = i.[TotalQty] + s.TotalQty
           ,[TotalCost] = i.[TotalCost] + s.TotalCost
           ,[TotalRetail] = i.[TotalRetail] + s.TotalRetail
           --,[UnitCost] =  (i.[TotalCost] + s.TotalCost)/(i.[TotalQty] + s.TotalQty)
           ,[UnitRetail] =  (i.[TotalRetail] + s.TotalRetail)/(i.[TotalQty] + s.TotalQty)
           ,[LastUpdateUserID] = @MyID
		   ,[DateTimeLastUpdate] = getdate()
		   ,[BatchID] = isnull([BatchID], '') + ' ' + @batchstring
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[TotalCost]
           ,[TotalRetail]
           ,[UnitCost]
           ,[UnitRetail]
           ,[LastUpdateUserID]
           ,[SaleDate]
           ,[BatchID]
           ,StoreIdentifier
,StoreName
,ProductIdentifier
,ProductQualifier
,RawProductIdentifier
,SupplierName
,SupplierIdentifier
,BrandIdentifier
,DivisionIdentifier
,UOM
,SalePrice
,Allowance
,InvoiceNo
,PONo
,CorporateName
,CorporateIdentifier
,Banner
,PromoTypeID
,PromoAllowance
,SBTNumber)
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.[SupplierID]
			,@invoicedetailtype
			,s.TotalQty
			,s.TotalCost
			,s.TotalRetail
			,s.UnitCost
			,s.UnitRetail
			,@MyID
			,s.SaleDate
			,@batchstring
			,s.StoreIdentifier
,s.StoreName
,s.ProductIdentifier
,s.ProductQualifier
,s.RawProductIdentifier
,s.SupplierName
,s.SupplierIdentifier
,s.BrandIdentifier
,s.DivisionIdentifier
,s.UOM
,s.SalePrice
,s.Allowance
,s.InvoiceNo
,s.PONo
,s.CorporateName
,s.CorporateIdentifier
,s.Banner
,s.PromoTypeID
,s.PromoAllowance
,s.SBTNumber);
*/

/*
--********************Credits Begin**************************
select StoreTransactionID
into ##tempStoreTransactions2
from StoreTransactions
where TransactionStatus = 800
and TransactionTypeID in (2,7)
and cast(SaleDateTime as date) <= cast(@saledate as date)
and Qty < 0

if @batchid is null and @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end

MERGE INTO [DataTrue_Main].[dbo].[InvoiceDetails] i

USING (select ChainID
           ,StoreID
           ,ProductID
           ,BrandID
           ,SupplierID
 --          ,1 --POSSource
           ,SUM(Qty) as TotalQty
           ,SUM(Qty * RuleCost) as TotalCost
           ,SUM(Qty * RuleRetail) as TotalRetail
           ,SUM(Qty * RuleCost)/SUM(Qty) as UnitCost
           ,SUM(Qty * RuleRetail)/SUM(Qty) as UnitRetail
           ,CAST(SaleDateTime as DATE) as SaleDate
		FROM [dbo].[StoreTransactions] t
		inner join ##tempStoreTransactions2 tmp
		on t.StoreTransactionID = tmp.StoreTransactionID
	    group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,CAST(SaleDateTime as DATE)) S
		--having SUM(Qty) <> 0) S
	on i.ChainID = s.ChainID
	and i.StoreID = s.StoreID 
	and i.ProductID = s.ProductID
	and i.BrandID = s.BrandID
	and i.SupplierID = s.SupplierID
	and i.SaleDate = s.SaleDate
	and i.RetailerInvoiceID is null
	and i.SupplierInvoiceID is null
	and i.TotalQty < 0
	and i.InvoiceDetailTypeID = @invoicedetailtype

WHEN MATCHED THEN

update set [TotalQty] = i.[TotalQty] + s.TotalQty
           ,[TotalCost] = i.[TotalCost] + s.TotalCost
           ,[TotalRetail] = i.[TotalRetail] + s.TotalRetail
           ,[UnitCost] =  (i.[TotalCost] + s.TotalCost)/(i.[TotalQty] + s.TotalQty)
           ,[UnitRetail] =  (i.[TotalRetail] + s.TotalRetail)/(i.[TotalQty] + s.TotalQty)
           ,[LastUpdateUserID] = @MyID
		   ,[DateTimeLastUpdate] = getdate()
		   ,[BatchID] = isnull([BatchID], '') + ' ' + @batchstring
	
WHEN NOT MATCHED 

THEN INSERT 
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[TotalCost]
           ,[TotalRetail]
           ,[UnitCost]
           ,[UnitRetail]
           ,[LastUpdateUserID]
           ,[SaleDate]
           ,[BatchID])
     VALUES
           (s.[ChainID]
           ,s.[StoreID]
			,s.[ProductID]
			,s.[BrandID]
			,s.[SupplierID]
			,@invoicedetailtype
			,s.TotalQty
			,s.TotalCost
			,s.TotalRetail
			,s.UnitCost
			,s.UnitRetail
			,@MyID
			,s.SaleDate
			,@batchstring);

*/

--********************Credits End****************************


update t set TransactionStatus = case when transactionstatus = 800 then 810 else 811 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join #tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID

/*--credits
update t set TransactionStatus = 810, InvoiceBatchID = @batchid
from StoreTransactions t
inner join ##tempStoreTransactions2 tmp2
on t.StoreTransactionID = tmp2.StoreTransactionID
*/

commit transaction
	
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
			@job_name = 'Billing_Regulated'
			
		Update 	DataTrue_Main.dbo.JobRunning
		Set JobIsRunningNow = 0
		Where JobName = 'DailyRegulatedBilling'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated Job Stopped'
			,'An exception occurred in prInvoiceDetail_SUP_Create_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'vince.moore@icontroldsd.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch

return
GO
