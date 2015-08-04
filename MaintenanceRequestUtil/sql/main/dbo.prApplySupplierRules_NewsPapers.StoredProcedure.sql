USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplySupplierRules_NewsPapers]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplySupplierRules_NewsPapers]
@temptable StoreTransactionIDTable readonly,
@workflowtype tinyint --1=POS, 2=SUP, 3=INV

as

declare @MyID int = 0

update t set TransactionTypeID =
case when CHARINDEX('POS', workingsource)>0 then 2
	when CHARINDEX('SUP-S', workingsource)>0 then 5
	when CHARINDEX('SUP-U', workingsource)>0 then 8
else null
end
from @temptable tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID

--select * from StoreTransactions_Management
update t set t.WorkingStatus = -26
from @temptable tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID	
and t.TransactionTypeID in (2,6)
inner join storesetup s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate
and t.SupplierID <> s.supplierid
inner join StoreTransactions_Management m
on s.ChainID = m.ChainID
and m.StoreID = 0
and m.ProductID = 0	
and m.BrandID = 0 
and m.PendPOSRecordsWithReportedSupplerNotSetupSupplier = 1

update t set t.WorkingStatus = -26
from @temptable tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID	
and t.TransactionTypeID in (5,8)
inner join storesetup s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate
and t.SupplierID <> s.supplierid
inner join StoreTransactions_Management m
on s.ChainID = m.ChainID
and m.StoreID = 0
and m.ProductID = 0	
and m.BrandID = 0 
and m.PendSUPRecordsWithReportedSupplerNotSetupSupplier = 1

INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Exceptions]
           ([StoreTransactionExceptionTypeID]
           ,[StoreTransactionID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[SaleDateTime]
           ,[LastUpdateUserID]
           ,[ChainID]
           ,[StoreId]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[TransactionTypeID])
           
 SELECT 2 --ReportedSupplier <> SetupSupplier
	  ,t.[StoreTransactionID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[SaleDateTime]
      ,@MyID
      ,[ChainID]
      ,[StoreId]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      ,[TransactionTypeID]
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working] t          
   		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.WorkingStatus = -26    
		     
--CHECK FOR CONTEXT WITH NO SUPPLIER AND 0 COST         
update t set t.WorkingStatus = -28
from @temptable tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID	
and t.TransactionTypeID in (2,6)
inner join StoreTransactions_Management m
on t.ChainID = m.ChainID
and m.StoreID = 0
and m.ProductID = 0	
and m.BrandID = 0 
and m.PendSUPRecordsWithReportedContextNoSupplierZeroCost = 1
left join storesetup s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate
where s.SupplierID IS NULL
and ISNULL(t.RuleCost, 0) = 0

update t set t.WorkingStatus = -28
from @temptable tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID	
and t.TransactionTypeID in (5,8)
inner join StoreTransactions_Management m
on t.ChainID = m.ChainID
and m.StoreID = 0
and m.ProductID = 0	
and m.BrandID = 0 
and m.PendSUPRecordsWithReportedContextNoSupplierZeroCost = 1
left join storesetup s
on t.StoreID = s.StoreID
and t.ProductID = s.ProductID
and t.BrandID = s.BrandID
and t.SaleDateTime between s.ActiveStartDate and s.ActiveLastDate
where s.SupplierID IS NULL
and ISNULL(t.RuleCost, 0) = 0

INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Exceptions]
           ([StoreTransactionExceptionTypeID]
           ,[StoreTransactionID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[SaleDateTime]
           ,[LastUpdateUserID]
           ,[ChainID]
           ,[StoreId]
           ,[ProductID]
           ,[BrandID]
           ,[SupplierID]
           ,[TransactionTypeID])
           
 SELECT 6 --ReportedSupplier <> SetupSupplier
	  ,t.[StoreTransactionID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[SaleDateTime]
      ,@MyID
      ,[ChainID]
      ,[StoreId]
      ,[ProductID]
      ,[BrandID]
      ,[SupplierID]
      ,[TransactionTypeID]
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working] t          
   		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.WorkingStatus = -28       
		 		 
return
GO
