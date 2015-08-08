USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplyCostRules_NewsPapers]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prApplyCostRules_NewsPapers]
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

update t set t.SetupCost = p.UnitPrice,
t.SetupRetail = p.UnitRetail,
t.ProductPriceTypeID = p.ProductPriceTypeID
--select t.*
from @temptable tmp
inner join [dbo].[StoreTransactions_Working] t
on tmp.StoreTransactionID = t.StoreTransactionID
inner join [dbo].[ProductPrices] p
on t.ProductID = p.ProductID 
and t.BrandID = p.BrandID
and t.ChainID = p.ChainID 
and t.StoreID = p.StoreID 
and t.SupplierID = p.SupplierID 
where 1 = 1
--and t.SetupCost is null
and p.ProductPriceTypeID = 3 --in 
--(Select ProductPriceTypeID from ProductPriceTypes where EntityTypeID = 2) --5 is Supplier Entity
and t.SaleDateTime between p.ActiveStartDate and p.ActiveLastDate

--update t set rulecost = UnitPrice, ruleretail = UnitRetail
--from [dbo].[StoreTransactions] t
--inner join ProductPrices p
--on t.ProductID = p.ProductID
--inner join ProductIdentifiers i
--on p.ProductID = i.ProductID
----and t.StoreID = p.StoreID
--and t.SupplierID = p.SupplierID
--and CAST(T.SaleDateTime as date) between p.ActiveStartDate AND P.ActiveLastDate
--AND P.ProductPriceTypeID = 3
--AND T.RuleCost IS NULL
--AND i.ProductIdentifierTypeID = 8

--update t set rulecost = UnitPrice, ruleretail = UnitRetail
--from [dbo].[StoreTransactions] t
--inner join ProductPrices p
--on t.ProductID = p.ProductID
--inner join ProductIdentifiers i
--on p.ProductID = i.ProductID
----and t.StoreID = p.StoreID
--and t.SupplierID = p.SupplierID
----and CAST(T.saledate as date) between p.ActiveStartDate AND P.ActiveLastDate
--AND P.ProductPriceTypeID = 3
--AND T.RuleCost IS NULL
--AND i.ProductIdentifierTypeID = 8

--update t set rulecost = UnitPrice, ruleretail = UnitRetail
--from [dbo].[StoreTransactions] t
--inner join ProductPrices p
--on t.ChainID = p.ChainID
--inner join ProductIdentifiers i
--on p.ProductID = i.ProductID
--and t.ProductID = p.ProductID
----and t.SupplierID = p.SupplierID
----and CAST(T.saledate as date) between p.ActiveStartDate AND P.ActiveLastDate
--AND P.ProductPriceTypeID = 3
--AND T.RuleCost IS NULL
--AND i.ProductIdentifierTypeID = 8


if @workflowtype = 1 --POS
	begin
		--If Type is Retailer and B is null, then F=D
		--If Type is Retailer and C is null, then G=E
		update t
		set RuleCost =
		case when SetupCost IS NULL then ReportedCost + IsNull(ReportedAllowance, 0)
				--when SetupCost is not null and ReportedCost > SetupCost then ReportedCost
		 else SetupCost end,
		 RuleRetail =
		case when SetupRetail IS NULL then ReportedRetail
				--when SetupRetail is not null and ReportedRetail > SetupRetail then ReportedRetail
		 else SetupRetail end
		 from [dbo].[StoreTransactions_Working] t
		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 Where t.RuleCost is null
	end

if @workflowtype = 2 --SUP
	begin
		--If Type is Supplier and Setup is null, then Reported
		--if Type is Supplier and Setup < Reported then Setup
		update t
		set RuleCost =
		case when SetupCost IS NULL then ReportedCost
				--when SetupCost is not null and ReportedCost > SetupCost then SetupCost
				--when SetupCost is not null and ReportedCost < SetupCost then ReportedCost		
		 --else ReportedCost end,
		 else SetupCost end,
		 RuleRetail =
		case when SetupRetail IS NULL then ReportedRetail
				--when SetupRetail is not null and ReportedRetail > SetupRetail then SetupRetail
				--when SetupRetail is not null and ReportedRetail < SetupRetail then ReportedRetail
		 --else ReportedRetail end
		 else SetupRetail end
		 from [dbo].[StoreTransactions_Working] t
		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 Where t.RuleCost is null
	end

if @workflowtype = 3 --INV
	begin
		--If Type is Retailer and B is null, then F=D
		--If Type is Retailer and C is null, then G=E
		update t
		set RuleCost =
		case when SetupCost IS NULL then ReportedCost
				--when SetupCost is not null and ReportedCost > SetupCost then ReportedCost
		 else SetupCost end,
		 RuleRetail =
		case when SetupRetail IS NULL then ReportedRetail
				--when SetupRetail is not null and ReportedRetail > SetupRetail then ReportedRetail
		 else SetupRetail end
		 from [dbo].[StoreTransactions_Working] t
		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 Where t.RuleCost is null
	end

	update t set CostMisMatch = 1
		 from [dbo].[StoreTransactions_Working] t
		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.SetupCost <> t.ReportedCost
		 
	update t set RetailMisMatch = 1
		 from [dbo].[StoreTransactions_Working] t
		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.SetupRetail <> t.ReportedRetail
		 

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
            ,[UPC]
			,[TransactionTypeID])
           
 SELECT 1 --ReportedCost <> SetupCost
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
      ,[UPC]
      ,[TransactionTypeID]
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working] t          
   		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.CostMisMatch = 1        

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
           ,[UPC]
           ,[TransactionTypeID])
           
 SELECT 3 --ReportedRetail <> SetupRetail
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
      ,[UPC]
      ,[TransactionTypeID]
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working] t          
   		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.RetailMisMatch = 1  
           
  update t set WorkingStatus = -25
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Management] m
  inner join [DataTrue_Main].[dbo].[StoreTransactions_Working] t  
  on m.chainid = t.ChainID
  and t.TransactionTypeID in (2, 6)
  and m.supplierid = t.SupplierID        
   		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.CostMisMatch = 1 
	where m.PendPOSRecordsWithReportedCostNotSetupCost = 1
	
	  update t set WorkingStatus = -25
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Management] m
  inner join [DataTrue_Main].[dbo].[StoreTransactions_Working] t  
  on m.chainid = t.ChainID
  and t.TransactionTypeID in (5, 8)
  and m.supplierid = t.SupplierID        
   		 inner join @temptable tmp
		 on t.StoreTransactionID = tmp.StoreTransactionID
		 and t.CostMisMatch = 1 
	where m.PendSUPRecordsWithReportedCostNotSetupCost = 1

		 		 
return
GO
