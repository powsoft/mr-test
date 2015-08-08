USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Reorder_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_Reorder_All]
    @ChainId varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
as
-- exec [usp_Report_Reorder_all] '40393','41713','All','','26643,28034,27891,63986,27712,41468,28731,26809,24716,64418,26673,29132,60184,26936,25749,25284,24155,60021,65720,27731,25465,26290,27398,40557,27030,60120,25369,73522,26857,25574,27197,60544,33501,79301,34980,60290,34873,26882,40578,24947,26714,35193,25216,27664,35232,24443,74225,25006,41348,24472,27143,25003,33797,28807,40569,79182,60555,60188,27729,24166,26813,34940,27874,60221,26789,40572,28815,34904,34796,34494,29257,26749,40571,35160,34456,29284,28967,65590,25399,77805,60166,60198,27228,60216,24724,24170,35202,41342,28819,28303,60213,24172,60210,28154,41343,41746,28207,26953,60228,28245,60178,60453,60060,28161,28781,28881,27315,29710,26966,25516,27717,40567,60187,27275,27801,60222,60209,60249,28628,25832,40558,34758,25666,60196,25193,28795,26246,25295,76819,26122,30227,28942,25277,30246,26709,29136,60081,28010,24194,26292,26261,25627,44109,60246,27799,24195,27593,60171,26263,34752,27552,25250,30434,24489,26827,28878,28518,24509,28011,26015,25174,28218,26565,60217,26871,27124,60080,25291,28504,24537,41464,25391,60119,24209,28158,60115,60527,26575,75148,24214,27492,28446,34224,32737,60410,60208,24910,63992,28248,60088,28444,40563,27790,27108,26316,60248,31027,24547,27895,26424,26578,28029,60193,60534,60212,60157,24645,35137,25380,41461,40559,28822,31295,25951,60234,25223,24256,24401,26188,25230,34458,26541,27645,28689,63972,28821,26848,26414,79591,28538,60101,26289,27426,28835,60183,60283,25372,28644,27680,40562,29163,27986,34757,26456,60204,25345,26800,60201,60192,34844,27274,40568,25194,27293,28285,24215,32104,60165,24222,24217,26086,60155,26042,25494,34170,24594,60225,60185,40560,60176,27900,26473,31514,26579,26573,24540,27567,25296,41465,65662,40561,26758,25548,28914,26020,63956,60223,32414,25642,73542,25682,27765,28863,75146,26831,26330,40570,41440,28956,28152,26797,60174,28910,26591,60189,34304,27192,27372,34913,26896,29102,32711,60479,24875,34840,60179,28676,25365,35060,35069,27657,60089,60232,60211,24465,31541,25530,28107,25198,25176,25177,60575,34680,25588,28877,24304,60215,60463,25976,40573,60197,28244,26381,74813,60162,34558,26691,34477,27869,60267,42148,33075,26832,27917,60170,40566,27053,25780,26341,60194,26208,40564,29114,28237,25707,33194,28944,25926,60207,60168,60566,26851,24269,33429,60266,25371,27517,44188,34851,73515,60206','','530','1900-01-01','1900-01-01'
Begin
	
	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Max(SaleDateTime) as LastCountDate
	into #tmpLastCountDate
		From StoreTransactions S with(nolock)
		where TransactionTypeId in (10,11) and cast(S.SupplierId as varchar) in( @SupplierId) and cast(S.ChainId as varchar) in (@ChainId)
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId
		
	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Sum(Qty) as LastCountUnits
	into #tmpLastCountUnits
		From StoreTransactions S with(nolock)
		inner join #tmpLastCountDate T on T.ChainId=S.ChainID and T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId and S.SaleDateTime=T.LastCountDate
		where S.TransactionTypeId in (10,11) and cast(S.SupplierId as varchar) in (@SupplierId) and cast(S.ChainId as varchar) =@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId

	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as SaleUnits
	into #tmpSales
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.ChainId=S.ChainID and T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId 
		and S.SaleDateTime> case when S.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=1 and  cast(S.SupplierId as varchar) in (@SupplierId) and cast(S.ChainId as varchar) =@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId

	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, Sum(Qty*QtySign) as DeliveryUnits
	into #tmpDeliveries
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		inner join #tmpLastCountDate T on T.ChainId=S.ChainID and T.SupplierId=S.SupplierId and T.StoreId=S.StoreId and T.ProductId=S.ProductId 
		and S.SaleDateTime> case when S.TransactionTypeId=10 then T.LastCountDate else dateadd(d,-1,T.LastCountDate) end
		where BucketType=2 and cast(S.SupplierId as varchar) in (@SupplierId) and cast(S.ChainId as varchar) =@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId 

	Select distinct S.ChainId, S.SupplierId, S.StoreId, S.ProductId, max(SaleDateTime) as LastDeliveryDate
	into #tmpDeliveryDates
		From StoreTransactions S with(nolock)
		inner join TransactionTypes TT with(nolock) on TT.TransactionTypeId=S.TransactionTypeId
		where BucketType=2 and cast(S.SupplierId as varchar) in (@SupplierId) and cast(S.ChainId as varchar) =@ChainId 
		group by S.ChainId, S.SupplierId, S.StoreId, S.ProductId 
	
	select C.ChainId, SP.SupplierId, ST.StoreID, P.ProductID, C.ChainName, SP.SupplierName, ST.StoreIdentifier,PD.IdentifierValue, P.Description,
	(isnull(LastCountUnits,0)- isnull(SaleUnits,0)+ isnull(DeliveryUnits,0)) as StockUnits
	into #tmpPerpetualInventory
		from #tmpLastCountUnits A
		inner join Suppliers SP with(nolock) on SP.SupplierId=A.SupplierId
		inner join Stores ST with(nolock) on ST.StoreId=A.StoreId
		inner join Chains C with(nolock) on C.ChainID=ST.ChainID
		inner join Products P with(nolock) on P.ProductId=A.ProductId
		inner join ProductIdentifiers PD with(nolock) on PD.ProductId=A.ProductId and PD.ProductIdentifierTypeId in (2,8)
		inner join StoreSetup SS with(nolock) on SS.SupplierId=A.SupplierId and SS.ChainId=ST.ChainId and SS.StoreId=A.StoreId and SS.ProductId=A.ProductId
		inner join #tmpLastCountDate T on T.ChainId=C.ChainID and T.SupplierId=A.SupplierId and T.StoreId=A.StoreId and T.ProductId=A.ProductId
		left join #tmpSales S on S.ChainId=C.ChainID and A.SupplierId=S.SupplierId and A.StoreId=S.StoreId and A.ProductId=S.ProductId
		left join #tmpDeliveries D on D.ChainId=C.ChainID and D.SupplierId=A.SupplierId and D.StoreId=A.StoreId and D.ProductId=A.ProductId
		left join #tmpDeliveryDates D1 on D1.ChainId=C.ChainID and D1.SupplierId=A.SupplierId and D1.StoreId=A.StoreId and D1.ProductId=A.ProductId
		left join ProductIdentifiers PD1 with(nolock) on PD1.ProductId=A.ProductId and PD1.ProductIdentifierTypeId =8 
		where D1.LastDeliveryDate is not null	
		
	select P.ChainName as [Retailer Name],
		   P.SupplierName as [Supplier Name],
		   P.StoreIdentifier as [Store Number],
		   P.IdentifierValue as UPC,
		   P.Description as [Product Desc],
		   convert(varchar(10),getdate(),101) as Date,
		   P.StockUnits as [Perpetual Qty],
		   A.MinStockLevel as [Trigger Qty],
		   A.ReorderQuantity as [Reorder Qty]
		from  #tmpPerpetualInventory P
		INNER JOIN StockAlerts A ON P.ChainId=A.ChainID and P.SupplierId=A.SupplierId 
		and P.StoreId like CASE WHEN A.StoreId ='-1' then '%' else A.StoreId end AND P.ProductId=A.ProductId
		where cast(StockUnits as numeric) < A.MinStockLevel         
end
GO
