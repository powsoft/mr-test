USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Supplier_Create_StoreSetup_Banners]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prUtil_Supplier_Create_StoreSetup_Banners]
	-- Add the parameters for the stored procedure here
	@SupplierEDIName VARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert DataTrue_Main..StoresUniqueValues (StoreID,SupplierID,SupplierAccountNumber,LastUpdateUserID)

	select StoreID,SupplierID,CustomerStoreNumber,0
	from EDI_StoreCrossReference
	where SupplierEDIName=@SupplierEDIName


	insert DataTrue_Main.. storesetup 
	(ChainID,StoreID,ProductID,SupplierID,BrandID,InventoryRuleID,
	InventoryCostMethod,RetailerShrinkPercent,SupplierShrinkPercent,
	ManufacturerShrinkPercent,ActiveStartDate,ActiveLastDate,LastUpdateUserID,DateTimeCreated,DateTimeLastUpdate)
	select b.ChainID,b.StoreID,0,a.SupplierID,0,0,
			'FIFO',100,0,0,'2013-01-01','2025-12-31',0,GETDATE(),GETDATE()
		   from DataTrue_EDI.. EDI_StoreCrossReference a
		   join stores b on a.StoreID=b.StoreID
		   where SupplierEDIName=@SupplierEDIName



	insert DataTrue_Main.. SupplierBanners
	select distinct ChainId,SupplierID,custom1,'Active' from stores a
	join datatrue_edi..EDI_StoreCrossReference b on a.StoreID=b.StoreID
	where SupplierEDIName=@SupplierEDIName

END
GO
