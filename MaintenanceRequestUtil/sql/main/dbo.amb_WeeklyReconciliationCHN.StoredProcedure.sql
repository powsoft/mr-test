USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_WeeklyReconciliationCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC amb_WeeklyReconciliationCHN 40393
CREATE PROCEDURE [dbo].[amb_WeeklyReconciliationCHN]
    (
      @ChainID VARCHAR(20)
    )
AS 
  BEGIN

DECLARE @sqlQuery VARCHAR(8000)

	SET @sqlQuery = ' Select ID.ChainID,
					sum(P.AmountOriginallyBilled) as [Payment Files] ,
					sum(ID.totalcost) as	[Invoice],
					sum(AmountOriginallyBilled)-sum(ID.totalcost) as [Diff to Payment File],
					sum(Id.TotalQty*Id.UnitCost) as [POS (Monday Excel Files / Snapshot Sunday to Saturday Before real weekly closing)], 
					SUM(isnull(ID1.TotalQty,0)*ID1.UnitCost) as [DCR-ADJ (Thursday Files / Monday to Sunday)], 
					'''' as [DCR-ADJ (Thursday Files / Monday to Sunday)-Pending],
					'''' as [Sale Date],
					'''' as [Cost Updates (before Closing)],
					sum(Id.TotalQty*Id.UnitCost)+ SUM(isnull(ID1.TotalQty,0)*ID1.UnitCost) as [Total EDI Sales Details],

					(sum(Id.TotalQty*Id.UnitCost)+ SUM(isnull(ID1.TotalQty,0)*ID1.UnitCost))-(sum(P.AmountOriginallyBilled)) 
					as [Still Pending Payment(Distributors Flags)],
					'''' as [Service Fees (Part of Payment Issued, but not in regular EDI files)],
					(sum(Id.TotalQty*Id.UnitCost)+ SUM(isnull(ID1.TotalQty,0)*ID1.UnitCost))-(sum(P.AmountOriginallyBilled))+0 
					as [Diff to payment file (still was not queued to release) ],
                    '''' as [Variance]
                    
				 From DataTrue_Main.dbo.InvoiceDetails ID
					Inner JOIN DataTrue_Main.dbo.Payments P on P.PaymentID=Id.PaymentID
					inner join DataTrue_Main.dbo.InvoicesSupplier IR on IR.SupplierInvoiceID=ID.SupplierInvoiceID
					left join DataTrue_Main.dbo.InvoiceDetails Id1 on ID1.SupplierID=ID.SupplierID and ID1.ChainID=ID.ChainID 
					and ID1.StoreID=ID.StoreID and ID1.ProductID=ID.ProductID 
					and ID1.InvoiceDetailTypeID=5 and ID1.SupplierInvoiceId =Id.InvoiceNo
					left join DataTrue_Main.dbo.StoreTransactions_Forward SF on SF.SupplierID=ID.SupplierID 
					and SF.ChainID=ID.ChainID and SF.StoreID=ID.StoreID and SF.ProductID=ID.ProductID 
					and SF.SaleDateTime=ID.SaleDate and SF.TransactionTypeId=29
					where 1=1 
					--and ID.InvoiceDetailTypeId=1
					 
					group BY ID.ChainID,P.PayerEntityID
					HAVING ID.ChainID='+@ChainID
					
		EXEC(@sqlQuery);		
  END
GO
