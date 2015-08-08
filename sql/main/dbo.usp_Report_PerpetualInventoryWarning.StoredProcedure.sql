USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_PerpetualInventoryWarning]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_PerpetualInventoryWarning]
    @ChainId varchar(500),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(500),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
as
-- exec [usp_Report_PerpetualInventoryWarning] 60620,'','','','40567','','','',''
Begin
	
	--Average Weekly Sale for Last 4 Weeks
	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign)/4 as AvgWeeklySaleUnits
	into #tmpAvgWeeklySales
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		where BucketType=1 
		and S.SupplierId=@SupplierId 
		and S.ChainId=@ChainId
		and S.SaleDateTime>=getdate()-28 AND SaleDateTime<getdate()
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId
		
	select P.*, A.AvgWeeklySaleUnits 
		from  TempPerpetualInventory P
		INNER JOIN #tmpAvgWeeklySales A ON P.ChainId=A.ChainID and P.SupplierId=A.SupplierId and P.StoreId=A.StoreId AND P.ProductId=A.ProductId
		where cast(StockUnits as numeric) < A.AvgWeeklySaleUnits and P.[Last Delivery Date] is not null
           
end
GO
