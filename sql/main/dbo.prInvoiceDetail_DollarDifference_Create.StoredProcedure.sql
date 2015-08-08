USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prInvoiceDetail_DollarDifference_Create]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prInvoiceDetail_DollarDifference_Create]
--@saledate date
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
declare @saledate date
declare @startdate date
declare @enddate date

set @MyID = 24130

begin try

begin transaction

set @startdate = '7/1/2011'
set @enddate = '11/1/2011'

set @saledate = @startdate


While @saledate < @enddate
	begin
		select d.[ChainID]
				   ,d.[StoreID]
				   ,case when f.[IncludeDollarDiffDetails] = 1 then d.[ProductID] else 1 end as ProductID
				   ,case when f.[IncludeDollarDiffDetails] = 1 then d.[SupplierID] else 0 end as SupplierID
				   ,case when f.[IncludeDollarDiffDetails] = 1 then d.[BrandID] else 0 end as BrandID
				   --,d.[SupplierID]
				   --,d.[BrandID]
				   ,CAST(SUM(TotalQty) as int) as POSTotalQty
				   ,CAST(SUM(TotalCost) as money) as POSTotalCost
				   ,CAST(SUM(TotalRetail) as money) as POSTotalRetail
				   ,CAST(0 as int) as SUPTotalQty
				   ,CAST(0 as money) as SUPTotalCost
				   ,CAST(0 as money) as SUPTotalRetail
		into #tempdollardifferencePOS
		from InvoiceDetails d
		inner join chainproductfactors f
		on d.[ChainID] = f.[ChainID] and d.[ProductID] = f.[ProductID] and d.[BrandID] = f.[BrandID]
		where InvoiceDetailTypeID = 1
		and Saledate = @saledate
		group by d.[ChainID]
				   ,d.[StoreID]
				   ,d.[ProductID]
				   ,d.[SupplierID]
				   ,d.[BrandID]
				   ,f.[IncludeDollarDiffDetails]

		if @@ROWCOUNT > 0
			begin
			
				insert into Batch
				(ProcessEntityID)
				values(@MyID)
			
				set @batchid = SCOPE_IDENTITY()

				set @batchstring = CAST(@batchid as nvarchar(255))
			end

		select d.[ChainID]
				   ,d.[StoreID]
				   ,case when f.[IncludeDollarDiffDetails] = 1 then d.[ProductID] else 1 end as ProductID
				   ,case when f.[IncludeDollarDiffDetails] = 1 then d.[SupplierID] else 0 end as SupplierID
				   ,case when f.[IncludeDollarDiffDetails] = 1 then d.[BrandID] else 0 end as BrandID
				   --,[ProductID]
				   --,[SupplierID]
				   --,[BrandID]
				   ,CAST(0 as int) as POSTotalQty
				   ,CAST(0 as money) as POSTotalCost
				   ,CAST(0 as money) as POSTotalRetail
				   ,CAST(SUM(TotalQty) as int) as SUPTotalQty
				   ,CAST(SUM(TotalCost) as money) as SUPTotalCost
				   ,CAST(sum(TotalRetail) as money) as SUPTotalRetail
		into #tempdollardifferenceSUP
		from InvoiceDetails d
		inner join chainproductfactors f
		on d.[ChainID] = f.[ChainID] and d.[ProductID] = f.[ProductID] and d.[BrandID] = f.[BrandID]
		where InvoiceDetailTypeID = 2
		and Saledate = @saledate
		group by d.[ChainID]
				   ,d.[StoreID]
				   ,d.[ProductID]
				   ,d.[SupplierID]
				   ,d.[BrandID]     
				   ,f.[IncludeDollarDiffDetails]
		           

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
				   ,SUPTotalQty
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
					set t.SUPTotalQty = s.SUPTotalQty, t.SUPTotalCost =s.SUPTotalCost
					,t.SUPTotalRetail =s.SUPTotalRetail

		WHEN NOT MATCHED 

				THEN INSERT     
				   ([ChainID]
				   ,[StoreID]
				   ,[ProductID]
				   ,[SupplierID]
				   ,[BrandID]
				   ,POSTotalQty
				   ,POSTotalCost
				   ,POSTotalRetail
				   ,SUPTotalQty
				   ,SUPTotalCost
				   ,SUPTotalRetail)
			 VALUES
					(s.[ChainID]
				   ,s.[StoreID]
				   ,s.[ProductID]
				   ,s.[SupplierID]
				   ,s.[BrandID]
				   ,0 --s.[POSTotalQty]
				   ,0
				   ,0
				   ,s.[SUPTotalQty]
				   ,s.SUPTotalCost
				   ,s.SUPTotalRetail);           
		           
		MERGE INTO InvoiceDetails t

		USING (select w.[ChainID]
				   ,w.[StoreID]
				   ,w.[ProductID]
				   ,w.SupplierID
				   ,w.BrandID
				   ,case when w.[ProductID] = 1 then 1 else sum(SUPTotalQty) - sum(POSTotalQty) end as TotalQty 
				   ,sum(SUPTotalCost) - sum(POSTotalCost) as TotalCost
				   ,sum(SUPTotalRetail) - sum(POSTotalRetail) as TotalRetail
				   ,@saledate as Saledate
		from #tempdollardifferencePOS w
		group by w.[ChainID],w.[StoreID],w.[ProductID],w.[BrandID],w.[SupplierID]
		having sum(SUPTotalQty) - sum(POSTotalQty) <> 0 and sum(SUPTotalCost) - sum(POSTotalCost) <> 0) S
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
					,t.totalQty = case when s.TotalCost < 0 then -1 * abs(s.TotalQty) else abs(s.TotalQty) end
					,t.UnitCost = case when s.productid <> 1 then abs(s.TotalCost/s.TotalQty) else abs(s.TotalCost) end
					,t.UnitRetail = case when s.productid <> 1 then abs(s.TotalRetail/s.TotalQty) else abs(s.TotalRetail) end
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
					,case when s.TotalCost < 0 then -1 * abs(s.TotalQty) else abs(s.TotalQty) end
				   ,s.TotalCost
				   ,s.TotalRetail
					,case when s.productid <> 1 then abs(s.TotalCost/s.TotalQty) else abs(s.TotalCost) end
					,case when s.productid <> 1 then abs(s.TotalRetail/s.TotalQty) else abs(s.TotalRetail) end
				   ,s.SaleDate
				   ,@MyID
				   ,@batchid);
           
		set @saledate = dateadd(day,1,@saledate)
		
		drop table #tempdollardifferencePOS 
		drop table #tempdollardifferenceSUP
		      
	end

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
