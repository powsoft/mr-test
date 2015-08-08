USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_SUP_Create_ACH]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery9.sql|7|0|C:\Users\vince.moore\AppData\Local\Temp\7\~vs38A6.sql


CREATE procedure [dbo].[prInvoiceDetail_SUP_Create_ACH]
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

DECLARE @ProcessID INT

SELECT @ProcessID = LastProcessID FROM DataTrue_Main.dbo.JobRunning WHERE JobName = 'DailyRegulatedBilling'

DECLARE @tempStoreTransactions TABLE
(
	StoreTransactionID INT
);

--update st
--set st.PONo = st2.PONo
----select st.pono, st2.pono, st.*
--from DataTrue_Main.dbo.StoreTransactions as st
--inner join DataTrue_Main.dbo.StoreTransactions as st2
--on st.ChainID = st2.ChainID
--and st.SupplierID = st2.SupplierID
--and st.SaleDateTime = st2.SaleDateTime
--and st.SupplierInvoiceNumber = st2.SupplierInvoiceNumber
--and st.TransactionTypeID IN (5, 8)
--and st2.TransactionTypeID = 32
--where st.ProcessID = @ProcessID

--select 
--	StoreTransactionID
--into 
--	@tempStoreTransactions
	--select *
insert into @tempStoreTransactions (StoreTransactionID)
select StoreTransactionID
from 
	StoreTransactions WITH(NOLOCK)
WHERE 1=1
and	DateTimeCreated >= CONVERT(DATE,GETDATE()-2)  --ADDED BY PaulT 9-18-2013
and	TransactionStatus in (800, 801)
and TransactionTypeID in (5,8,9,14,20,21)
and ProcessID = @ProcessID
--AND (case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * (RuleCost))+ (isnull(Adjustment1, 0))+(isnull(Adjustment2, 0))+(isnull(Adjustment3, 0))+(isnull(Adjustment4, 0))+(isnull(Adjustment5, 0))+(isnull(Adjustment6, 0))+(isnull(Adjustment7, 0))+(isnull(Adjustment8, 0)) <> 0


--REMOVE $0 LINE ITEMS WHERE APPLICABLE (REGULATED)
DELETE t 
FROM @tempStoreTransactions AS t
INNER JOIN StoreTransactions AS st
ON t.StoreTransactionID = st.StoreTransactionID
INNER JOIN BillingControl AS bc
ON st.ChainID = bc.ChainID
AND bc.SupplierID = 0
AND bc.BusinessTypeID = 2
INNER JOIN BillingControl_SUP AS bcs
ON bc.BillingControlID = bcs.BillingControlID
WHERE bcs.AllowBillingZeroDollarLineItemsRegulated = 0
AND (case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * (RuleCost))+ (isnull(Adjustment1, 0))+(isnull(Adjustment2, 0))+(isnull(Adjustment3, 0))+(isnull(Adjustment4, 0))+(isnull(Adjustment5, 0))+(isnull(Adjustment6, 0))+(isnull(Adjustment7, 0))+(isnull(Adjustment8, 0)) = 0
AND st.RecordType = 0 --REGULATED

--REMOVE $0 LINE ITEMS WHERE APPLICABLE (NON-REGULATED)
DELETE t 
FROM @tempStoreTransactions AS t
INNER JOIN StoreTransactions AS st
ON t.StoreTransactionID = st.StoreTransactionID
INNER JOIN BillingControl AS bc
ON st.ChainID = bc.ChainID
AND bc.SupplierID = 0
AND bc.BusinessTypeID = 2
INNER JOIN BillingControl_SUP AS bcs
ON bc.BillingControlID = bcs.BillingControlID
WHERE bcs.AllowBillingZeroDollarLineItems = 0
AND (case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * (RuleCost))+ (isnull(Adjustment1, 0))+(isnull(Adjustment2, 0))+(isnull(Adjustment3, 0))+(isnull(Adjustment4, 0))+(isnull(Adjustment5, 0))+(isnull(Adjustment6, 0))+(isnull(Adjustment7, 0))+(isnull(Adjustment8, 0)) = 0
AND st.RecordType = 3 --NON-REGULATED

--GET INVOICES WITH $0 TOTAL
DECLARE @ZeroInvoicesTable TABLE (ChainID INT, StoreID INT, ProductID INT, SupplierID INT, SaleDateTime DATE, SupplierInvoiceNumber VARCHAR(120))
INSERT INTO @ZeroInvoicesTable (ChainID, StoreID, ProductID, SupplierID, SaleDateTime, SupplierInvoiceNumber)
SELECT s.ChainID, s.StoreID, s.ProductID, s.SupplierID, CAST(s.SaleDateTime as DATE) AS SaleDateTime, SupplierInvoiceNumber
FROM DataTrue_Main.dbo.StoreTransactions AS s
WHERE s.ProcessID = @ProcessID
AND s.TransactionTypeID IN (5,8,9,14,20,21)
and Qty <> 0
and (RuleCost <> 0 or ISNULL(adjustment1, 0) <> 0
					or ISNULL(adjustment2, 0) <> 0
					or ISNULL(adjustment3, 0) <> 0
					or ISNULL(adjustment4, 0) <> 0
					or ISNULL(adjustment5, 0) <> 0
					or ISNULL(adjustment6, 0) <> 0
					or ISNULL(adjustment7, 0) <> 0
					or ISNULL(adjustment8, 0) <> 0)
group by s.[ChainID]
           ,s.[StoreID]
           ,s.[ProductID]
           ,s.[BrandID]
           ,s.[SupplierID]
           ,CAST(s.SaleDateTime as DATE)
           ,s.SupplierInvoiceNumber
		having
		(
		SUM
		(
		(case when transactiontypeid IN (5, 9, 20) then qty else qty * -1 end * rulecost)
		+ISNULL(adjustment1, 0)
		+ISNULL(adjustment2, 0)
		+ISNULL(adjustment3, 0)
		+ISNULL(adjustment4, 0)
		+ISNULL(adjustment5, 0)
		+ISNULL(adjustment6, 0)
		+ISNULL(adjustment7, 0)
		+ISNULL(adjustment8, 0)
		) = 0
		)

--REMOVE $0 INVOICES WHERE APPLICABLE (REGULATED)
DELETE t
FROM @tempStoreTransactions t
INNER JOIN StoreTransactions AS s
ON t.StoreTransactionID = s.StoreTransactionID
INNER JOIN @ZeroInvoicesTable AS z
ON z.ChainID = s.ChainID
AND z.ProductID = s.ProductID
AND z.StoreID = s.StoreID
AND z.SupplierID = s.SupplierID
AND z.SaleDateTime = s.SaleDateTime
AND z.SupplierInvoiceNumber = s.SupplierInvoiceNumber
AND s.TransactionTypeID IN (5,8,9,14,20,21)
AND s.ProcessID = @ProcessID
INNER JOIN BillingControl AS bc
ON s.ChainID = bc.ChainID
AND bc.SupplierID = 0
AND bc.BusinessTypeID = 2
INNER JOIN BillingControl_SUP AS bcs
ON bc.BillingControlID = bcs.BillingControlID
WHERE bcs.AllowBillingZeroDollarInvoicesRegulated = 0
AND s.RecordType = 0

--REMOVE $0 INVOICES WHERE APPLICABLE (NON-REGULATED)
DELETE t
FROM @tempStoreTransactions t
INNER JOIN StoreTransactions AS s
ON t.StoreTransactionID = s.StoreTransactionID
INNER JOIN @ZeroInvoicesTable AS z
ON z.ChainID = s.ChainID
AND z.ProductID = s.ProductID
AND z.StoreID = s.StoreID
AND z.SupplierID = s.SupplierID
AND z.SaleDateTime = s.SaleDateTime
AND z.SupplierInvoiceNumber = s.SupplierInvoiceNumber
AND s.TransactionTypeID IN (5,8,9,14,20,21)
AND s.ProcessID = @ProcessID
INNER JOIN BillingControl AS bc
ON s.ChainID = bc.ChainID
AND bc.SupplierID = 0
AND bc.BusinessTypeID = 2
INNER JOIN BillingControl_SUP AS bcs
ON bc.BillingControlID = bcs.BillingControlID
WHERE bcs.AllowBillingZeroDollarInvoices = 0
AND s.RecordType = 3

if (SELECT COUNT(StoreTransactionID) FROM @tempStoreTransactions) > 0
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
				inner join #@tempStoreTransactions tmp
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
	
	INSERT into InvoiceDetails
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
           ,SBTNumber
           ,[PaymentDueDate]
		  ,[Adjustment1]
		  ,[Adjustment2]
		  ,[Adjustment3]
		  ,[Adjustment4]
		  ,[Adjustment5]
		  ,[Adjustment6]
		  ,[Adjustment7]
		  ,[Adjustment8]
		  ,[VIN]
		  ,[RawStoreIdentifier]
		  ,[Route]
		  ,[SourceID]
		  ,[AccountCode]
		  ,[RecordType]
		  ,[ProcessID]
		  ,[RefIDToOriginalInvNo]
		  ,[PackSize]
		  ,[EDIRecordID]
		  )
     select s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.BrandID
           ,s.SupplierID
           ,@invoicedetailtype
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) as TotalQty
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * (RuleCost))+ Sum(isnull(Adjustment1, 0))+Sum(isnull(Adjustment2, 0))+Sum(isnull(Adjustment3, 0))+Sum(isnull(Adjustment4, 0))+Sum(isnull(Adjustment5, 0))+Sum(isnull(Adjustment6, 0))+Sum(isnull(Adjustment7, 0))+Sum(isnull(Adjustment8, 0)) as TotalCost
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleRetail) as TotalRetail
           ,CASE WHEN SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) <> 0 THEN SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleCost)/SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) ELSE MAX(RuleCost) END as UnitCost
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
		  ,SUM(isnull([Adjustment1],0))
		  ,SUM(isnull([Adjustment2],0))
		  ,SUM(isnull([Adjustment3],0))
		  ,SUM(isnull([Adjustment4],0))
		  ,SUM(isnull([Adjustment5],0))
		  ,SUM(isnull([Adjustment6],0))
		  ,SUM(isnull([Adjustment7],0))
		  ,SUM(isnull([Adjustment8],0))
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route   
		  ,[SourceID]  
		  ,s.[AccountCode] 
		  ,s.[RecordType]  
		  ,s.[ProcessID]  
		  ,s.[RefIDToOriginalInvNo]
		  ,s.[PackSize]
		  ,MAX(s.[EDIRecordID])
		FROM [dbo].[StoreTransactions] AS s WITH (NOLOCK)
		inner join @tempStoreTransactions tmp
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
		AND (SELECT ISNULL(MaintainEDICreditSeparation, 0) FROM BillingControl bc INNER JOIN BillingControl_SUP bcs ON bc.BillingControlID = bcs.BillingControlID AND bc.BusinessTypeID = 2 WHERE bc.ChainID = s.ChainID AND bc.SupplierID = 0) = 0
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
		  --,isnull([Adjustment1],0)
		  --,isnull([Adjustment2],0)
		  --,isnull([Adjustment3],0)
		  --,isnull([Adjustment4],0)
		  --,isnull([Adjustment5],0)
		  --,isnull([Adjustment6],0)
		  --,isnull([Adjustment7],0)
		  --,isnull([Adjustment8] ,0) 
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route 
		  ,[SourceID]     
		  ,s.[AccountCode]   
		  ,s.[RecordType]
		  ,s.[ProcessID]
		  ,s.[RefIDToOriginalInvNo]
		  ,s.[PackSize]
        --having SUM(Qty) <> 0 
		having
		(
		SUM
		(
		(case when transactiontypeid IN (5, 9, 20) then qty else qty * -1 end * rulecost)
		+ISNULL(adjustment1, 0)
		+ISNULL(adjustment2, 0)
		+ISNULL(adjustment3, 0)
		+ISNULL(adjustment4, 0)
		+ISNULL(adjustment5, 0)
		+ISNULL(adjustment6, 0)
		+ISNULL(adjustment7, 0)
		+ISNULL(adjustment8, 0)
		) <> 0
		)
		
		
		--INSERT DEBITS OF MAINTAIN EDI SEPARATION
		INSERT into InvoiceDetails
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
           ,SBTNumber
           ,[PaymentDueDate]
		  ,[Adjustment1]
		  ,[Adjustment2]
		  ,[Adjustment3]
		  ,[Adjustment4]
		  ,[Adjustment5]
		  ,[Adjustment6]
		  ,[Adjustment7]
		  ,[Adjustment8]
		  ,[VIN]
		  ,[RawStoreIdentifier]
		  ,[Route]
		  ,[SourceID]
		  ,[AccountCode]
		  ,[RecordType]
		  ,[ProcessID]
		  ,[RefIDToOriginalInvNo]
		  ,[PackSize]
		  ,[EDIRecordID]
		  )
     select s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.BrandID
           ,s.SupplierID
           ,@invoicedetailtype
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) as TotalQty
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * (RuleCost))+ Sum(isnull(Adjustment1, 0))+Sum(isnull(Adjustment2, 0))+Sum(isnull(Adjustment3, 0))+Sum(isnull(Adjustment4, 0))+Sum(isnull(Adjustment5, 0))+Sum(isnull(Adjustment6, 0))+Sum(isnull(Adjustment7, 0))+Sum(isnull(Adjustment8, 0)) as TotalCost
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleRetail) as TotalRetail
           ,CASE WHEN SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) <> 0 THEN SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleCost)/SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) ELSE MAX(RuleCost) END as UnitCost
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
		  ,SUM(isnull([Adjustment1],0))
		  ,SUM(isnull([Adjustment2],0))
		  ,SUM(isnull([Adjustment3],0))
		  ,SUM(isnull([Adjustment4],0))
		  ,SUM(isnull([Adjustment5],0))
		  ,SUM(isnull([Adjustment6],0))
		  ,SUM(isnull([Adjustment7],0))
		  ,SUM(isnull([Adjustment8],0))
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route   
		  ,[SourceID]  
		  ,s.[AccountCode] 
		  ,s.[RecordType]  
		  ,s.[ProcessID]  
		  ,s.[RefIDToOriginalInvNo]
		  ,s.[PackSize]
		  ,MAX(s.EDIRecordID)
		FROM [dbo].[StoreTransactions] AS s WITH (NOLOCK)
		inner join @tempStoreTransactions tmp
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
		AND (SELECT ISNULL(MaintainEDICreditSeparation, 0) FROM BillingControl bc INNER JOIN BillingControl_SUP bcs ON bc.BillingControlID = bcs.BillingControlID AND bc.BusinessTypeID = 2 WHERE bc.ChainID = s.ChainID AND bc.SupplierID = 0) =	1
		AND s.TransactionTypeID IN (5, 9, 20)
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
		  --,isnull([Adjustment1],0)
		  --,isnull([Adjustment2],0)
		  --,isnull([Adjustment3],0)
		  --,isnull([Adjustment4],0)
		  --,isnull([Adjustment5],0)
		  --,isnull([Adjustment6],0)
		  --,isnull([Adjustment7],0)
		  --,isnull([Adjustment8] ,0) 
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route 
		  ,[SourceID]     
		  ,s.[AccountCode]   
		  ,s.[RecordType]
		  ,s.[ProcessID]
		  ,s.[RefIDToOriginalInvNo]
		  ,s.[PackSize]
        --having SUM(Qty) <> 0 
		--having
		--(
		--SUM
		--(
		--(case when transactiontypeid IN (5, 9, 20) then qty else qty * -1 end * rulecost)
		--+ISNULL(adjustment1, 0)
		--+ISNULL(adjustment2, 0)
		--+ISNULL(adjustment3, 0)
		--+ISNULL(adjustment4, 0)
		--+ISNULL(adjustment5, 0)
		--+ISNULL(adjustment6, 0)
		--+ISNULL(adjustment7, 0)
		--+ISNULL(adjustment8, 0)
		--) <> 0
		--)
		
		--INSERT CREDITS OF MAINTAIN EDI SEPARATION
		INSERT into InvoiceDetails
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
           ,SBTNumber
           ,[PaymentDueDate]
		  ,[Adjustment1]
		  ,[Adjustment2]
		  ,[Adjustment3]
		  ,[Adjustment4]
		  ,[Adjustment5]
		  ,[Adjustment6]
		  ,[Adjustment7]
		  ,[Adjustment8]
		  ,[VIN]
		  ,[RawStoreIdentifier]
		  ,[Route]
		  ,[SourceID]
		  ,[AccountCode]
		  ,[RecordType]
		  ,[ProcessID]
		  ,[RefIDToOriginalInvNo]
		  ,[PackSize]
		  ,[EDIRecordID]
		  )
     select s.ChainID
           ,s.StoreID
           ,s.ProductID
           ,s.BrandID
           ,s.SupplierID
           ,@invoicedetailtype
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) as TotalQty
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * (RuleCost))+ Sum(isnull(Adjustment1, 0))+Sum(isnull(Adjustment2, 0))+Sum(isnull(Adjustment3, 0))+Sum(isnull(Adjustment4, 0))+Sum(isnull(Adjustment5, 0))+Sum(isnull(Adjustment6, 0))+Sum(isnull(Adjustment7, 0))+Sum(isnull(Adjustment8, 0)) as TotalCost
           ,SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleRetail) as TotalRetail
           ,CASE WHEN SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) <> 0 THEN SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end * RuleCost)/SUM(case when Transactiontypeid in (5, 9, 20) then Qty else Qty * -1 end) ELSE MAX(RuleCost) END as UnitCost
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
		  ,SUM(isnull([Adjustment1],0))
		  ,SUM(isnull([Adjustment2],0))
		  ,SUM(isnull([Adjustment3],0))
		  ,SUM(isnull([Adjustment4],0))
		  ,SUM(isnull([Adjustment5],0))
		  ,SUM(isnull([Adjustment6],0))
		  ,SUM(isnull([Adjustment7],0))
		  ,SUM(isnull([Adjustment8],0))
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route   
		  ,[SourceID]  
		  ,s.[AccountCode] 
		  ,s.[RecordType]  
		  ,s.[ProcessID]  
		  ,s.[RefIDToOriginalInvNo]
		  ,s.[PackSize]
		  ,MAX(s.EDIRecordID)
		FROM [dbo].[StoreTransactions] AS s WITH (NOLOCK)
		inner join @tempStoreTransactions tmp
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
		AND (SELECT ISNULL(MaintainEDICreditSeparation, 0) FROM BillingControl bc INNER JOIN BillingControl_SUP bcs ON bc.BillingControlID = bcs.BillingControlID AND bc.BusinessTypeID = 2 WHERE bc.ChainID = s.ChainID AND bc.SupplierID = 0) =	1
		AND s.TransactionTypeID NOT IN (5, 9, 20)
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
		  --,isnull([Adjustment1],0)
		  --,isnull([Adjustment2],0)
		  --,isnull([Adjustment3],0)
		  --,isnull([Adjustment4],0)
		  --,isnull([Adjustment5],0)
		  --,isnull([Adjustment6],0)
		  --,isnull([Adjustment7],0)
		  --,isnull([Adjustment8] ,0) 
		  ,SupplierItemNumber
		  ,RawStoreIdentifier
		  ,Route 
		  ,[SourceID]     
		  ,s.[AccountCode]   
		  ,s.[RecordType]
		  ,s.[ProcessID]
		  ,s.[RefIDToOriginalInvNo]
		  ,s.[PackSize]
        --having SUM(Qty) <> 0 
		--having
		--(
		--SUM
		--(
		--(case when transactiontypeid IN (5, 9, 20) then qty else qty * -1 end * rulecost)
		--+ISNULL(adjustment1, 0)
		--+ISNULL(adjustment2, 0)
		--+ISNULL(adjustment3, 0)
		--+ISNULL(adjustment4, 0)
		--+ISNULL(adjustment5, 0)
		--+ISNULL(adjustment6, 0)
		--+ISNULL(adjustment7, 0)
		--+ISNULL(adjustment8, 0)
		--) <> 0
		--)


update t set TransactionStatus = case when transactionstatus = 800 then 810 else 811 end
,InvoiceBatchID = @batchid
from StoreTransactions t
inner join @tempStoreTransactions tmp
on t.StoreTransactionID = tmp.StoreTransactionID

/*--credits
update t set TransactionStatus = 810, InvoiceBatchID = @batchid
from StoreTransactions t
inner join #@tempStoreTransactions2 tmp2
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
			@job_name = 'Billing_Regulated_NewInvoiceData'

		--exec [msdb].[dbo].[sp_stop_job] 
		--	@job_name = 'Billing_Regulated'
			
		--Update 	DataTrue_Main.dbo.JobRunning
		--Set JobIsRunningNow = 0
		--Where JobName = 'DailyRegulatedBilling'		

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Billing_Regulated_NewInvoiceData Job Stopped'
			,'An exception occurred in prInvoiceDetail_SUP_Create_ACH.  Manual review, resolution, and re-start will be required for the job to continue.'
			,'DataTrue System', 0, 'edi@icucsolutions.com'--'datatrueit@icontroldsd.com;edi@icontroldsd.com'	
		
end catch

return
GO
