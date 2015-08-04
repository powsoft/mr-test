USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GeneratePreLaunchVMIReportDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_GeneratePreLaunchVMIReportDetails] 44246, 1
CREATE procedure [dbo].[usp_GeneratePreLaunchVMIReportDetails]
 @SupplierId varchar(20),
 @ReportId varchar(2)
as

Begin
	--# of UPCs missing -Last Count Date (within last 13 days)
	if (@ReportId='1')
	Begin
		select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
		from StoreSetup SS
		inner join Stores S on S.Storeid=SS.storeid
		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
		left join
		(
			select distinct S.SupplierID, S.StoreId, S.ProductId
			from StoreTransactions S
			inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
			inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
			where S.SupplierId=@SupplierId and TransactionTypeID in (10,11) and SaleDateTime>=GETDATE()-13
		) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
		where SS.SupplierID=@SupplierId and T.ProductID is null 
		order by SS.StoreId
	End
	
	--	# of UPCs having last count = 0
	else if (@ReportId='2')
	Begin
		select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
		from StoreSetup SS
		inner join Stores S on S.Storeid=SS.storeid
		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
		left join
		(
			select distinct S.SupplierID, S.StoreId, S.ProductId, max(S.SaleDateTime) as LastCountDate, Qty as LastCountUnits
			from StoreTransactions S
			inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
			inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
			where S.SupplierId=@SupplierId and TransactionTypeID in (10,11) 
			group by S.SupplierID, S.StoreId, S.ProductId, Qty
		) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
		where SS.SupplierID=@SupplierId and LastCountUnits=0
		order by SS.StoreId
	End
	
	--No of UPC with no instance of POS History records in last 30 days
	else if (@ReportId='3')
	Begin
	
		select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
		from StoreSetup SS
		inner join Stores S on S.Storeid=SS.storeid
		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
		left join
		(
			select distinct S.SupplierID, S.StoreId, S.ProductId
			from StoreTransactions S
			inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
			inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
			inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
			where S.SupplierId=@SupplierId and BucketType=1 and SaleDateTime>=GETDATE()-30
		) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
		where SS.SupplierID=@SupplierId and T.ProductID is null 
		order by SS.StoreId
	End
	
	--No of UPC with <10 instances of POS History records in last 30 days
	else if (@ReportId='4')
	Begin
		select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
		from StoreSetup SS
		inner join Stores S on S.Storeid=SS.storeid
		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
		left join
		(
			select distinct S.SupplierID, S.StoreId, S.ProductId
			from StoreTransactions S
			inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
			inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
			inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
			where S.SupplierId=@SupplierId and BucketType=1 and SaleDateTime>=GETDATE()-30
			group by S.SupplierID,S.StoreId, S.ProductID having COUNT(S.SaleDateTime)< 10
		) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
		where SS.SupplierID=@SupplierId and T.ProductID is not null 
		order by SS.StoreId
	End
	
	--No of UPC Missing Pending (intermediate) Delivery Records after today
	else if (@ReportId='5')
	Begin
		select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
		from StoreSetup SS
		inner join Stores S on S.Storeid=SS.storeid
		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
		left join
		(
			select distinct S.SupplierID, S.StoreId, S.ProductId
			from StoreTransactions S
			inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
			inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
			where S.SupplierId=@SupplierId and TransactionTypeID in (39) and SaleDateTime>GETDATE()
		) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
		where SS.SupplierID=@SupplierId and T.ProductID is null 
		order by SS.StoreId
	End
	
	----No of UPC Missing Pending (intermediate) Delivery Records in last 14 days
	--else if (@ReportId='5')
	--Begin
	--	select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
	--	from StoreSetup SS
	--	inner join Stores S on S.Storeid=SS.storeid
	--	inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
	--	left join
	--	(
	--		select distinct S.SupplierID, S.StoreId, S.ProductId
	--		from StoreTransactions S
	--		inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
	--		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
	--		where S.SupplierId=@SupplierId and TransactionTypeID in (39) and SaleDateTime>GETDATE()-14
	--	) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
	--	where SS.SupplierID=@SupplierId and T.ProductID is null 
	--	order by SS.StoreId
	--end
	
	--No. of UPCs  missing Delivery Records in Last 14 days
	else if (@ReportId='6')
	Begin
		select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
		from StoreSetup SS
		inner join Stores S on S.Storeid=SS.storeid
		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
		left join
		(
			select distinct SS.SupplierID, S.StoreId, S.ProductId
			from StoreTransactions S
			inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
			inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
			inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
			where S.SupplierId=@SupplierId and BucketType=2 and SaleDateTime>=GETDATE()-14 --and S.StoreId=44200
		) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
		where SS.SupplierID=@SupplierId and T.ProductID is null --and SS.StoreId=44200
		order by SS.StoreId
	End

	--No. of UPCs  missing Delivery Records after Last Count
	else if (@ReportId='7')
	Begin
		select distinct SS.StoreId,S.StoreIdentifier, SS.ProductId
		from StoreSetup SS
		inner join Stores S on S.Storeid=SS.storeid
		inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
		left join
		(
				select distinct S.SupplierID, S.StoreId, S.ProductId
				from StoreTransactions S
				inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
				inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
				inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
				where S.SupplierId=@SupplierId and BucketType=2 and SaleDateTime>=(select max(SaleDateTime) from StoreTransactions ST where ST.SupplierID=S.SupplierID and ST.StoreId=S.StoreID and St.ProductID=S.ProductID and ST.TransactionTypeID in (10,11))
			) T on T.SupplierID=SS.SupplierID and T.StoreID=SS.StoreID and T.ProductID=SS.ProductID
		where SS.SupplierID=@SupplierId and T.ProductID is null 
		order by SS.StoreId
	End
End
GO
