USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_POS_Create_Newspapers_20130821]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_POS_Create_Newspapers_20130821]
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

if @saledate is null
	set @saledate = GETDATE()

set @MyID = 24126
set @invoicedetailtype = 1 --POSSource

begin try

begin transaction


select StoreTransactionID
into #tempStoreTransactions
--declare @saledate date set @saledate = getdate() select *
from StoreTransactions
where TransactionStatus in (800, 801)
and TransactionTypeID in (2,6)
and ChainID in (select EntityIDToInclude from ProcessStepEntities where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')
--and cast(SaleDateTime as date) <= cast(@saledate as date)
and Qty <> 0
and RuleRetail is not null
and RuleCost is not null

if @@ROWCOUNT > 0
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
		inner join #tempStoreTransactions tmp
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
/*
--********************Credits Begin**************************
select StoreTransactionID
into #tempStoreTransactions2
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
		inner join #tempStoreTransactions2 tmp
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
inner join #tempStoreTransactions2 tmp2
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
		
end catch

return
GO
