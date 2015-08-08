USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prApplyCostRules_WHS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[prApplyCostRules_WHS]
@temptable WarehouseTransactionIDTable readonly,
@workflowtype tinyint --1=POS, 2=SUP, 3=INV

as



if @workflowtype = 1 --POS
	begin
		--If Type is Retailer and B is null, then F=D
		--If Type is Retailer and C is null, then G=E
		update t
		set RuleCost =
		case when SetupCost IS NULL then ReportedCost + ReportedAllowance
				--when SetupCost is not null and ReportedCost > SetupCost then ReportedCost
		 else SetupCost end,
		 RuleRetail =
		case when SetupRetail IS NULL then ReportedRetail
				--when SetupRetail is not null and ReportedRetail > SetupRetail then ReportedRetail
		 else SetupRetail end
		 from [dbo].[WarehouseTransactions_Working] t
		 inner join @temptable tmp
		 on t.WarehouseTransactionID = tmp.WarehouseTransactionID
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
		 from [dbo].[WarehouseTransactions_Working] t
		 inner join @temptable tmp
		 on t.WarehouseTransactionID = tmp.WarehouseTransactionID
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
		 from [dbo].[WarehouseTransactions_Working] t
		 inner join @temptable tmp
		 on t.WarehouseTransactionID = tmp.WarehouseTransactionID
	end
	
return
GO
