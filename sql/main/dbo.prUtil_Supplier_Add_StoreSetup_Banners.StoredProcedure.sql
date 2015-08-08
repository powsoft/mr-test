USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Supplier_Add_StoreSetup_Banners]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prUtil_Supplier_Add_StoreSetup_Banners]
	-- Add the parameters for the stored procedure here
	@ChainID INT,
	@SupplierEDIName VARCHAR(100),
	@GoLiveDate DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --delete from DataTrue_Main..StoresUniqueValues
    --where StoreID in (select distinct StoreID from DataTrue_Main..stores where ChainID = @ChainID)
    --and SupplierID = (select SupplierID from DataTrue_Main..Suppliers where EDIName = @SupplierEDIName)
    
    --delete from DataTrue_Report..StoresUniqueValues
    --where StoreID in (select distinct StoreID from DataTrue_Main..stores where ChainID = @ChainID)
    --and SupplierID = (select SupplierID from DataTrue_Main..Suppliers where EDIName = @SupplierEDIName)
    
	insert DataTrue_Main..StoresUniqueValues (StoreID,SupplierID,SupplierAccountNumber,LastUpdateUserID)
	select distinct edi.StoreID,edi.SupplierID,edi.CustomerStoreNumber,0
	from DataTrue_EDI..EDI_StoreCrossReference edi
	left outer join DataTrue_Main.dbo.StoresUniqueValues s
	on edi.StoreID = s.StoreID
	and edi.SupplierID = s.SupplierID
	where SupplierEDIName = @SupplierEDIName and ChainIdentifier = (SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains WHERE ChainID = @ChainID)
	and s.SupplierAccountNumber is null

	--insert DataTrue_Report..StoresUniqueValues (StoreID,SupplierID,SupplierAccountNumber,LastUpdateUserID)
	--select distinct StoreID,SupplierID,CustomerStoreNumber,0
	--from DataTrue_EDI..EDI_StoreCrossReference
	--where SupplierEDIName = @SupplierEDIName and ChainIdentifier = (SELECT ChainIdentifier FROM DataTrue_Main.dbo.Chains WHERE ChainID = @ChainID)

	
	--delete from DataTrue_Main..storesetup where ChainID = @ChainID and SupplierID = (select SupplierID from DataTrue_Main..Suppliers where EDIName = @SupplierEDIName)
	--delete from [IC-HQSQL1REPORT].DataTrue_Report.dbo.storesetup where ChainID = @ChainID and SupplierID = (select SupplierID from DataTrue_Main..Suppliers where EDIName = @SupplierEDIName)
	
	insert into DataTrue_Main..storesetup 
	(ChainID,StoreID,ProductID,SupplierID,BrandID,InventoryRuleID,
	InventoryCostMethod,RetailerShrinkPercent,SupplierShrinkPercent,
	ManufacturerShrinkPercent,ActiveStartDate,ActiveLastDate,LastUpdateUserID,DateTimeCreated,DateTimeLastUpdate)
	select distinct b.ChainID,b.StoreID,0,a.SupplierID,0,0,
			'FIFO',100,0,0,@GoLiveDATE,'2025-12-31',0,GETDATE(),GETDATE()
		   from DataTrue_EDI.. EDI_StoreCrossReference a
		   join stores b on a.StoreID=b.StoreID
		   where SupplierEDIName=@SupplierEDIName and ChainID = @ChainID
		   and NOT EXISTS 
				(Select * from DataTrue_Main..StoreSetup ss where ss.StoreID=b.StoreID and a.SupplierID=ss.SupplierID and ss.ChainID=b.ChainID and ss.ProductID=0)

	--insert into [IC-HQSQL1REPORT].DataTrue_report.dbo.storesetup 
	--(ChainID,StoreID,ProductID,SupplierID,BrandID,InventoryRuleID,
	--InventoryCostMethod,RetailerShrinkPercent,SupplierShrinkPercent,
	--ManufacturerShrinkPercent,ActiveStartDate,ActiveLastDate,LastUpdateUserID,DateTimeCreated,DateTimeLastUpdate)
	--select distinct b.ChainID,b.StoreID,0,a.SupplierID,0,0,
	--		'FIFO',100,0,0,@GoLiveDATE,'2025-12-31',0,GETDATE(),GETDATE()
	--	   from DataTrue_EDI.. EDI_StoreCrossReference a
	--	   join stores b on a.StoreID=b.StoreID
	--	   where SupplierEDIName=@SupplierEDIName and ChainID = @ChainID

	
	delete from DataTrue_Main..SupplierBanners where ChainID = @ChainID and SupplierId = (select SupplierID from DataTrue_Main..Suppliers where EDIName = @SupplierEDIName)
	--delete from [IC-HQSQL1REPORT].DataTrue_Report.dbo.SupplierBanners where ChainID = @ChainID and SupplierId = (select SupplierID from DataTrue_Main..Suppliers where EDIName = @SupplierEDIName)
	
	insert into DataTrue_Main..SupplierBanners
	select distinct ChainId,SupplierID,custom1,'Active' from stores a
	join datatrue_edi..EDI_StoreCrossReference b on a.StoreID=b.StoreID
	where SupplierEDIName=@SupplierEDIName and ChainID = @ChainID

	--insert into [IC-HQSQL1REPORT].DataTrue_Report.dbo.SupplierBanners
	--select distinct ChainId,SupplierID,custom1,'Active' from stores a
	--join datatrue_edi..EDI_StoreCrossReference b on a.StoreID=b.StoreID
	--where SupplierEDIName=@SupplierEDIName and ChainID = @ChainID
	
END
GO
