USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZHOLDbeforeDollarDiffDetailUpdate_prInvoiceDetail_DollarDifference_Create]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZHOLDbeforeDollarDiffDetailUpdate_prInvoiceDetail_DollarDifference_Create]
@saledate date
/*
[prInvoiceDetail_Retailer_DollarDifference_Create] '6/2/2011'
*/
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
declare @batchid bigint
declare @batchstring nvarchar(255)

set @MyID = 24130

begin try

begin transaction


select [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,CAST(SUM(TotalCost) as money) as POSTotalCost
           ,CAST(SUM(TotalRetail) as money) as POSTotalRetail
           ,CAST(0 as money) as SUPTotalCost
           ,CAST(0 as money) as SUPTotalRetail
into #tempdollardifferencePOS
from InvoiceDetails
where InvoiceDetailTypeID = 1
and Saledate = @saledate
group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]

if @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end

select [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,CAST(0 as money) as POSTotalCost
           ,CAST(0 as money) as POSTotalRetail
           ,CAST(SUM(TotalCost) as money) as SUPTotalCost
           ,CAST(sum(TotalRetail) as money) as SUPTotalRetail
into #tempdollardifferenceSUP
from InvoiceDetails
where InvoiceDetailTypeID = 2
and Saledate = @saledate
group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]     
           

if @batchid is null and @@ROWCOUNT > 0
	begin
	
		insert into Batch
		(ProcessEntityID)
		values(@MyID)
	
		set @batchid = SCOPE_IDENTITY()

		set @batchstring = CAST(@batchid as nvarchar(255))
	end
           
MERGE INTO #tempdollardifferencePOS t

USING (select [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,SUPTotalCost
           ,SUPTotalRetail
from #tempdollardifferenceSUP w) S
on t.ChainID = s.ChainID 
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID

WHEN MATCHED 
	Then update
			set t.SUPTotalCost =s.SUPTotalCost
			,t.SUPTotalRetail =s.SUPTotalRetail

WHEN NOT MATCHED 

        THEN INSERT     
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,POSTotalCost
           ,POSTotalRetail
           ,SUPTotalCost
           ,SUPTotalRetail)
     VALUES
			(s.[ChainID]
           ,s.[StoreID]
           ,s.[ProductID]
           ,s.[SupplierID]
           ,s.[BrandID]
           ,0
           ,0
           ,s.SUPTotalCost
           ,s.SUPTotalRetail);           
           
MERGE INTO InvoiceDetails t

USING (select [ChainID]
           ,[StoreID]
           ,ProductID
           ,SupplierID
           ,BrandID
           ,sum(SUPTotalCost) - sum(POSTotalCost) as TotalCost
           ,sum(SUPTotalRetail) - sum(POSTotalRetail) as TotalRetail
           ,@saledate as Saledate
from #tempdollardifferencePOS w
group by [ChainID],[StoreID],[ProductID],[BrandID],[SupplierID]
having sum(SUPTotalCost) - sum(POSTotalCost) <> 0) S
on t.ChainID = s.ChainID 
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.Saledate = s.Saledate
and t.InvoiceDetailTypeID = 4
and t.RetailerInvoiceID is null
and t.SupplierInvoiceID is null

WHEN MATCHED 
	Then update
			set t.TotalCost = s.TotalCost
			,t.TotalRetail = s.TotalRetail
			,t.UnitCost = s.TotalCost
			,t.UnitRetail = s.TotalRetail
		   ,[BatchID] = isnull([BatchID], '') + ' ' + @batchstring

WHEN NOT MATCHED 

        THEN INSERT     
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[InvoiceDetailTypeID]
           ,[TotalQty]
           ,[TotalCost]
           ,[TotalRetail]
           ,[UnitCost]
           ,[UnitRetail]
           ,[SaleDate]
           ,[LastUpdateUserID]
           ,[BatchID])
     VALUES
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,4--<InvoiceDetailTypeID, int,>
           ,1--<TotalQty, int,>
           ,s.TotalCost
           ,s.TotalRetail
           ,s.TotalCost
           ,s.TotalRetail
           ,s.SaleDate
           ,@MyID
           ,@batchid);       


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
