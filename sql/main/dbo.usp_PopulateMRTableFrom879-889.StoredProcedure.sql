USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PopulateMRTableFrom879-889]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[usp_PopulateMRTableFrom879-889]
as
begin try

 Declare @RecordsAffected int
	
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[#tmpMaintenanceRequests]') AND type in (N'U'))
    DROP TABLE #tmpMaintenanceRequests
    
	Select  GETDATE() AS [SubmitDateTime],
	Case when CostFlag=1 then 6 when PromoFlag=1 then 7 end as RequestTypeId,
	ChainId, SupplierId, Banner, 1 as AllStores, UPC, NULL as BrandIdentifier,
	P.Description as ItemDescription, 0 as CurrentSetupCost,

	(Select top 1 isnull(UnitPrice,0) from ProductPrices where ProductPriceTypeID in (3)
	and ProductID=R.ProductID and SupplierID=R.SupplierId and ChainID=R.ChainId
	and ActiveStartDate<=GETDATE() and ActiveLastDate-2 >=GETDATE()) as Cost,
	0 as SuggestedRetail, 
	Case when CostFlag=1 then 0 when PromoFlag=1 then 1 end as PromoTypeId,

	(Select top 1 isnull(UnitPrice,0) from ProductPrices where ProductPriceTypeID in (8)
	and ProductID=R.ProductID and SupplierID=R.SupplierId and ChainID=R.ChainId
	and ActiveStartDate<=GETDATE() and ActiveLastDate-2 >=GETDATE()) as PromoAllowance, 

	(Select top 1 ActiveStartDate from ProductPrices where ProductPriceTypeID in (3)
	and ProductID=R.ProductID and SupplierID=R.SupplierId and ChainID=R.ChainId
	and ActiveStartDate<=GETDATE() and ActiveLastDate-2 >=GETDATE()) as StartDateTime,

	(Select top 1 ActiveLastDate from ProductPrices where ProductPriceTypeID in (3)
	and ProductID=R.ProductID and SupplierID=R.SupplierId and ChainID=R.ChainId
	and ActiveStartDate<=GETDATE() and ActiveLastDate-2 >=GETDATE()) as EndDateTime, 
	0 as SupplierLoginId, R.PersonId as ChainLoginId, 0 as RequestStatus, 1 as Approved

	into #tmpMaintenanceRequests
	from [Retailer879-889Requests] R inner join Products P on R.ProductId=P.ProductID 
	where Processed='N'
	
	begin transaction
 
	Insert Into MaintenanceRequests (SubmitDateTime,
	RequestTypeID,ChainID,SupplierID,Banner,AllStores,UPC,BrandIdentifier, ItemDescription, CurrentSetupCost, Cost,
	SuggestedRetail, PromoTypeID, PromoAllowance, StartDateTime,EndDateTime, SupplierLoginID,ChainLoginID, RequestStatus, Approved)

	select SubmitDateTime,
	RequestTypeID,ChainID,SupplierID,Banner,AllStores,UPC,BrandIdentifier, ItemDescription, CurrentSetupCost,isnull(Cost,0),
	SuggestedRetail, PromoTypeID, isnull(PromoAllowance,0), StartDateTime,EndDateTime, SupplierLoginID,ChainLoginID, RequestStatus, Approved from #tmpMaintenanceRequests

	 set @RecordsAffected=@@rowcount
	commit transaction
	
	Update [Retailer879-889Requests] set Processed = 'Y'
 
end try
	
begin catch
	rollback transaction
end catch

return @RecordsAffected
GO
