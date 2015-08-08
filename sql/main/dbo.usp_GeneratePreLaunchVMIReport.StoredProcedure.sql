USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GeneratePreLaunchVMIReport]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[usp_GeneratePreLaunchVMIReport] 44246
CREATE procedure [dbo].[usp_GeneratePreLaunchVMIReport]
 @SupplierId varchar(20)
as

Begin
 	
		
select distinct S.StoreId, S.StoreIdentifier as [Store #], COUNT(SS.ProductId) as [No of UPCs managed],
COUNT(SS.ProductId)-isnull(T1.UPCCount, 0) as [# of UPCs missing -Last Count Date (within last 13 days)] ,
isnull(T6.UPCCount, 0) as [# of UPCs having last count units = 0],
COUNT(SS.ProductId)-isnull(T2.UPCCount, 0) as [No of UPC with no instance of POS History records in last 30 days],
isnull(T3.UPCCount, 0) as [No of UPC with <10 instances of POS History records in last 30 days],
COUNT(SS.ProductId)-isnull(T4.UPCCount, 0) as [No of UPC Missing Pending (intermediate) Delivery Records after today],
COUNT(SS.ProductId)-isnull(T5.UPCCount, 0) as [No. of UPCs  missing Delivery Records in Last 30 days],
COUNT(SS.ProductId)-isnull(T7.UPCCount, 0) as [No. of UPCs  missing Delivery Records after Last Count],
isnull(T8.SaleInstances,0) as [POS Instances in Last 30 Days (Store Wise)]
from Stores S
inner join StoreSetup SS on S.StoreId=SS.StoreID
inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
left  join (
				select distinct StoreId, COUNT(ProductId) as UPCCount from 
				(
					select distinct S.StoreId, S.ProductId, max(S.SaleDateTime) as SaleInstances
					from StoreTransactions S
					inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
					inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
					where S.SupplierId=@SupplierId and TransactionTypeID in (10,11) and SaleDateTime>=GETDATE()-13
					group by S.StoreId, S.ProductID 
				) T group by StoreId
				
			) as T1 on T1.StoreId =S.StoreId 
left  join (
				select distinct StoreId, COUNT(ProductId) as UPCCount from 
				(
					select distinct S.StoreId, S.ProductId, max(S.SaleDateTime) as SaleInstances, Qty as LastCountUnits
					from StoreTransactions S
					inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
					inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
					where S.SupplierId=44246 and TransactionTypeID in (10,11) 
					group by S.StoreId, S.ProductID ,Qty
				) T where LastCountUnits=0 group by StoreId, LastCountUnits
				
			) as T6 on T6.StoreId =S.StoreId 
			
left  join (
				select StoreId, COUNT(ProductId) as UPCCount from 
				(
					select S.StoreId, S.ProductId, COUNT(S.SaleDateTime) as SaleInstances
					from StoreTransactions S
					inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
					inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
					inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
					where S.SupplierId=@SupplierId and BucketType=1 and SaleDateTime>=GETDATE()-30
					group by S.StoreId, S.ProductID having COUNT(S.SaleDateTime)> 0
				) T group by StoreId
			) as T2 on T2.StoreId =S.StoreId
left  join (
				select StoreId, COUNT(ProductId) as UPCCount from 
				(
					select S.StoreId, S.ProductId, COUNT(S.SaleDateTime) as SaleInstances
					from StoreTransactions S
					inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
					inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
					inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
					where S.SupplierId=@SupplierId and BucketType=1 and SaleDateTime>=GETDATE()-30
					group by S.StoreId, S.ProductID having COUNT(S.SaleDateTime)< 10
				) T group by StoreId
			) as T3 on T3.StoreId =S.StoreId			
left  join (
			select distinct StoreId, COUNT(ProductId) as UPCCount from 
				(
					select distinct S.StoreId, S.ProductId, max(S.SaleDateTime) as SaleInstances
					from StoreTransactions S
					inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
					inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
					where S.SupplierId=@SupplierId and TransactionTypeID in (39) and SaleDateTime>GETDATE()
					group by S.StoreId, S.ProductID 
				) T group by StoreId
			) as T4 on T4.StoreId =S.StoreId
		
left  join (
				select StoreId, COUNT(ProductId) as UPCCount from 
				(
					select S.StoreId, S.ProductId, COUNT(S.SaleDateTime) as SaleInstances
					from StoreTransactions S
					inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
					inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
					inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
					where S.SupplierId=@SupplierId and BucketType=2 and SaleDateTime>=GETDATE()-14
					group by S.StoreId, S.ProductID having COUNT(S.SaleDateTime)> 0
				) T group by StoreId
			) as T5 on T5.StoreId =S.StoreId	
left  join (
				select StoreId, COUNT(ProductId) as UPCCount from 
				(
					select S.StoreId, S.ProductId, COUNT(S.SaleDateTime) as SaleInstances
					from StoreTransactions S
					inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
					inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
					inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
					where S.SupplierId=@SupplierId and BucketType=2 and SaleDateTime>=(select max(SaleDateTime) from StoreTransactions ST where ST.SupplierID=@SupplierId and ST.StoreId=S.StoreID and St.ProductID=S.ProductID and ST.TransactionTypeID in (10,11))
					group by S.StoreId, S.ProductID having COUNT(S.SaleDateTime)> 0
				) T group by StoreId
			) as T7 on T7.StoreId =S.StoreId	
left join (
				--POS Instances in Last 30 Days (Store Wise)
				select S.StoreId, count(distinct S.SaleDateTime) as SaleInstances
				from StoreTransactions S
				inner join TransactionTypes T on T.TransactionTypeID=S.TransactionTypeID
				inner join StoreSetup SS on S.StoreId=SS.StoreID and SS.SupplierID=S.SupplierID and SS.ProductID=S.ProductID
				inner join  PO_Criteria P on SS.StoreSetupID =P.StoreSetupID
				where S.SupplierId=44246 and BucketType=1 and SaleDateTime>=GETDATE()-30
				group by S.StoreId
			) as T8 on T8.StoreID=S.StoreId							
where SS.SupplierID=@SupplierId
group by S.StoreId, S.StoreIdentifier, T1.UPCCount, T2.UPCCount, T3.UPCCount, T4.UPCCount, T5.UPCCount, T6.UPCCount, T7.UPCCount, T8.SaleInstances
order by S.StoreIdentifier


End
GO
