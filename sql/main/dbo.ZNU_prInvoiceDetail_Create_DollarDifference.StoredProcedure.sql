USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prInvoiceDetail_Create_DollarDifference]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prInvoiceDetail_Create_DollarDifference]
@saledate date

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int

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
from InvoiceDetail
where InvoiceDetailTypeID = 1
and Saledate = @saledate
group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]


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
from InvoiceDetail
where InvoiceDetailTypeID = 2
and Saledate = @saledate
group by [ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]     
           
           
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
           
MERGE INTO InvoiceDetail t

USING (select [ChainID]
           ,[StoreID]
           ,1 as ProductID
           ,0 as SupplierID
           ,0 as BrandID
           ,sum(POSTotalCost) - sum(SUPTotalCost) as TotalCost
           ,sum(POSTotalRetail) - sum(SUPTotalRetail) as TotalRetail
           ,@saledate as Saledate
from #tempdollardifferencePOS w
group by [ChainID],[StoreID]) S
on t.ChainID = s.ChainID 
and t.StoreID = s.StoreID 
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SupplierID = s.SupplierID
and t.Saledate = s.Saledate

WHEN MATCHED 
	Then update
			set t.TotalCost = s.POSTotalCost - s.SUPTotalCost
			,t.TotalRetail = s.POSTotalRetail - s.SUPTotalRetail

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
           ,[SaleDate]
           ,[LastUpdateUserID])
     VALUES
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,4--<InvoiceDetailTypeID, int,>
           ,1--<TotalQty, int,>
           ,s.POSTotalCost - s.SUPTotalCost
           ,s.POSTotalRetail - s.SUPTotalRetail
           ,s.SaleDate
           ,@MyID);       


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
