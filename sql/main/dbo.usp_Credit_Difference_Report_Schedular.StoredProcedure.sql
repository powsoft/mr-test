USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Credit_Difference_Report_Schedular]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Credit_Difference_Report_Schedular] 
as
Begin
	
	

	--The business problem this area is attempting to solve:
		--The supplier is invoicing the retailer for a 100 units, but could only deliver 80 units (did not have enough units on the truck). 
		--The Retailer is sending iControl a notification (TransactionType=36) that they are due credit from the supplier.
		--This process will search to confirm that a credit memo was created and had been transmitted by the supplier to icontrol for processing.
	
	Truncate table Credit_Difference_Report 	
	Insert into Credit_Difference_Report 	

    Select C.ChainID as [RetailerID], SP.SupplierID as [SupplierID], ST.Custom1 as Banner, 
        ST.StoreIdentifier as [StoreNumber], S.SaleDateTime as SaleDate, S.UPC, P.ProductName, 
        SC.SourceName
        , S.Qty as [QuantityRetailer]
        , isnull(S1.[Supplier Qty],0) as [QuantitySupplier]
        , S.ReportedCost as [CostRetailer]
        , isnull(S1.ReportedCost,0) as [CostSupplier]
        , (isnull(S1.[Supplier Qty],0) - S.Qty) as [DifferenceUnits]
        , (isnull(S1.ReportedCost,0) - S.ReportedCost) as [DifferenceCost]
        , NULL as RevertStatus
        
    from StoreTransactions S
    
    Inner Join Chains C on C.ChainID=S.ChainId
    Inner Join Suppliers SP on SP.SupplierID=S.SupplierId
    Inner Join Stores ST on ST.StoreId=S.StoreId
    Inner join Products P on P.ProductId=S.ProductId
    Inner join Source SC on SC.SourceID=S.SourceId
    
    Left Join (select S1.SupplierId, S1.ChainId, S1.StoreId, S1.ProductId, S1.SaleDateTime, 
                            sum(S1.Qty) as [Supplier Qty], S1.ReportedCost
               from StoreTransactions S1 
                            inner join TransactionTypes T on T.TransactionTypeId=S1.TransactionTypeId 
               where T.TransactionTypeID in (8,9,15,20,21,37)
                            group by S1.SupplierId, S1.ChainId, S1.StoreId, S1.ProductId, S1.SaleDateTime, S1.ReportedCost
                        ) as S1 on S1.SupplierId=S.SupplierId and S1.ChainId=S.ChainId and S1.StoreId=S.StoreId 
                            and S1.ProductId=S.ProductId and S1.SaleDateTime=S.SaleDateTime
    
    where 1=1 and S.TransactionTypeID =36 --Retailer notification 
		and (isnull(S1.[Supplier Qty],0) - S.Qty) <>0 --Show only records with difference (supplier either didnot submit credit at all, or a different qunatity)    
	    and cast(S.SaleDateTime as DATE) >=  cast(getdate()-365 as DATE)
    order by S.SaleDateTime desc    

End
GO
