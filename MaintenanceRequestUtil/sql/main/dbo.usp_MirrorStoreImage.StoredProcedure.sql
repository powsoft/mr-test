USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_MirrorStoreImage]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_MirrorStoreImage 40742, 12565, 40560, 40384
Create Procedure [dbo].[usp_MirrorStoreImage]
     @FromStoreId varchar(20),
     @ToStoreId varchar(20),
     @SupplierId varchar(500),
     @UserId varchar(20),
     @ChainId varchar(20)
as
begin
   
   Declare @strSQL varchar(4000)
   Declare @StartDate varchar(20)
   
   select @StartDate = ActiveFromDate from Stores where StoreID=@ToStoreId

   set @strSQL = 'Insert into StoreSetup (ChainID, StoreID, ProductID, SupplierID, BrandID, InventoryRuleID, InventoryCostMethod, 
							SunLimitQty, SunFrequency, MonLimitQty, MonFrequency, TueLimitQty, TueFrequency, WedLimitQty, WedFrequency, 
							ThuLimitQty, ThuFrequency, FriLimitQty, FriFrequency, SatLimitQty, SatFrequency, 
							RetailerShrinkPercent, SupplierShrinkPercent, ManufacturerShrinkPercent, ActiveStartDate, ActiveLastDate, 
							SetupReportedToRetailerDate, FileName, Comments, DateTimeCreated, LastUpdateUserID, DateTimeLastUpdate)
							
	Select ChainID, ' + @ToStoreId  + ', ProductID, SupplierID, BrandID, InventoryRuleID, InventoryCostMethod, 
							SunLimitQty, SunFrequency, MonLimitQty, MonFrequency, TueLimitQty, TueFrequency, WedLimitQty, WedFrequency, 
							ThuLimitQty, ThuFrequency, FriLimitQty, FriFrequency, SatLimitQty, SatFrequency, 
							RetailerShrinkPercent, SupplierShrinkPercent, ManufacturerShrinkPercent,''' + @StartDate + ''', ActiveLastDate, 
							SetupReportedToRetailerDate, FileName, Comments, getdate(), ' + @UserId  + ', DateTimeLastUpdate 
	from StoreSetup where StoreID = ' + @FromStoreId  + ' and SupplierID =' + @SupplierId + ' and ChainId=' + @ChainId
   
   exec (@strSQL)
    
   set @strSQL = 'Insert into ProductPrices (ProductPriceTypeID, ProductID, ChainID, StoreID, BrandID, SupplierID, UnitPrice, 
					UnitRetail, PricePriority, ActiveStartDate, ActiveLastDate, PriceReportedToRetailerDate, DateTimeCreated, 
					LastUpdateUserID, DateTimeLastUpdate, BaseCost, Allowance)
							
	Select ProductPriceTypeID, ProductID, ChainID,' + @ToStoreId  + ', BrandID, SupplierID, UnitPrice, 
					UnitRetail, PricePriority, ActiveStartDate, ActiveLastDate, PriceReportedToRetailerDate, getdate(), 
					' + @UserId + ', getdate(), BaseCost, Allowance 
	from ProductPrices where StoreID = ' + @FromStoreId  + ' and SupplierID =' + @SupplierId + ' and ChainId=' + @ChainId
   
   exec (@strSQL)
end
GO
