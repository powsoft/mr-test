USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveAddNewRequest_PDI]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_SaveAddNewRequest_PDI]
     @MaintenanceRequestID int,
     @SubmitDateTime datetime,
     @RequestTypeID int,
     @ChainID int,
     @Banner varchar(50),
     @CostZoneID varchar(10),
     @AllStores int,
     @UPC varchar(50),
     @ItemDescription varchar(250),
     @CurrentSetupCost money,
     @Cost money,
     @SuggestedRetail money,
     @SlottingFees money,
     @AdFees money,
     @PromoTypeID int,
     @PromoAllowance money,
     @DealNumber varchar(50),
     @FromWebInterface varchar(20),
     @StartDateTime datetime,
     @EndDateTime datetime,
     @SkipPopulating879_889Records int,
     @SupplierLoginID int,
     @SupplierID int,
     @Stores varchar(2000),
     @OldUPC varchar(20),
     @OldUPCDescription varchar(20),
     @PrimaryGroupLevel int,
     @AlternateGroupLevel int,
     @ItemGroup varchar(50),
     @AlternateItemGroup varchar(50),
     @Size varchar(50),
     @ManufacturerIdentifier varchar(50),
     @SellPkgVINAllowReorder varchar(50),
     @SellPkgVINAllowReClaim varchar(50),
     @PrimarySellablePkgIdentifier varchar(50),
     @SellablePkgQty int,
     @VIN varchar(50),
     @VINDescription varchar(50),
     @PurchPackDescription varchar(50),
     @PurchPackQty int,
     @AltSellPackage1 varchar(50),
     @AltSellPackage1Qty int,
     @AltSellPackage1UPC varchar(50),
     @BrandIdentifier varchar(50),
     @Promo varchar(50),
     @AltSellPackage1Retail money,
     @ProductCategoryID int
     
as
begin

Declare @CostZoneCount as int
declare @sqlquery as varchar(1000)

select @CostZoneCount=count(CostZoneID) from CostZoneRelations where CostZoneID=@CostZoneID and SupplierID=@SupplierId and StoreID in (Select Distinct StoreId from Stores where Custom1='' + @Banner + '')

if(@CostZoneCount=0 or @CostZoneID='-1' or @CostZoneID='')
 set  @CostZoneID=NULL
 
if(@DealNumber='')
 set @DealNumber=null
 
if(@PrimaryGroupLevel='-1')
 set @PrimaryGroupLevel=null

if(@AlternateGroupLevel='-1')
 set @AlternateGroupLevel=null
 
if(@SellablePkgQty='-1')
 set @SellablePkgQty=null
 
if(@PurchPackQty='-1')
 set @PurchPackQty=null 
 
if(@AltSellPackage1Qty='-1')
 set @AltSellPackage1Qty=null
 
if(@AltSellPackage1Retail='-1')
 set @AltSellPackage1Retail=null  
 
 
if (@MaintenanceRequestID=0)
 begin
  INSERT INTO [dbo].[MaintenanceRequests]
       ([SubmitDateTime]
       ,[RequestTypeID]
       ,[ChainID]
       ,[Banner]
       ,[CostZoneID] 
       ,[AllStores]
       ,[UPC]
       ,[ItemDescription]
       ,[CurrentSetupCost]
       ,[Cost]
       ,[SuggestedRetail]
       ,[SlottingFees]
       ,[AdFees]
       ,[PromoTypeID]
       ,[PromoAllowance]
       ,[DealNumber]
       ,[FromWebInterface]
       ,[StartDateTime]
       ,[EndDateTime]
       ,[SkipPopulating879_889Records]
       ,[SupplierLoginID] 
       ,[SupplierID]
       ,[OldUPC]
       ,[OldUPCDescription]
       ,[PrimaryGroupLevel]
       ,[AlternateGroupLevel]
       ,[ItemGroup]
       ,[AlternateItemGroup]
       ,[Size]
       ,[ManufacturerIdentifier]
       ,[SellPkgVINAllowReorder]
       ,[SellPkgVINAllowReClaim]
       ,[PrimarySellablePkgIdentifier]
       ,[PrimarySellablePkgQty]
       ,[VIN]
       ,[VINDescription]
       ,[PurchPackDescription]
       ,[PurchPackQty]
       ,[AltSellPackage1]
       ,[AltSellPackage1Qty]
       ,[AltSellPackage1UPC]
       ,[BrandIdentifier]
       ,[AltSellPackage1Retail]
       ,[ProductCategoryID] )
    VALUES
    (
     @SubmitDateTime,
     @RequestTypeID,
     @ChainID,
     @Banner,
     @CostZoneID,
     @AllStores,
     @UPC,
     @ItemDescription,
     @CurrentSetupCost,
     @Cost,
     @SuggestedRetail,
     @SlottingFees,
     @AdFees,
     @PromoTypeID,
     @PromoAllowance,
     @DealNumber,
     @FromWebInterface,
     @StartDateTime,
     @EndDateTime,
     @SkipPopulating879_889Records,
     @SupplierLoginID,
     @SupplierID,
     @OldUPC,
     @OldUPCDescription,
     @PrimaryGroupLevel ,
     @AlternateGroupLevel ,
     @ItemGroup ,
     @AlternateItemGroup ,
     @Size,
     @ManufacturerIdentifier ,
     @SellPkgVINAllowReorder ,
     @SellPkgVINAllowReClaim ,
     @PrimarySellablePkgIdentifier ,
     @SellablePkgQty ,
     @VIN ,
     @VINDescription,
     @PurchPackDescription ,
     @PurchPackQty ,
     @AltSellPackage1 ,
     @AltSellPackage1Qty ,
     @AltSellPackage1UPC,
     @BrandIdentifier,
     -- @Promo,
     @AltSellPackage1Retail,
     @ProductCategoryID
    )

  Set @MaintenanceRequestID=@@IDENTITY
 end
else
 begin
  UPDATE [dbo].[MaintenanceRequests]
     SET [SubmitDateTime] = @SubmitDateTime
    ,[RequestTypeID] = @RequestTypeID
    ,[ChainID] = @ChainID
    ,[Banner] = @Banner
    ,[CostZoneID] = @CostZoneID
    ,[AllStores] = @AllStores
    ,[UPC] = @UPC
    ,[OldUPC] = @OldUPC
    ,[OldUPCDescription] = @OldUPCDescription
    ,[ItemDescription] = @ItemDescription
    ,[CurrentSetupCost] = @CurrentSetupCost
    ,[Cost] = @Cost
    ,[SuggestedRetail] = @SuggestedRetail
    ,[SlottingFees] = @SlottingFees
    ,[AdFees] = @AdFees
    ,[PromoTypeID] = @PromoTypeID
    ,[PromoAllowance] = @PromoAllowance
    ,[DealNumber] = @DealNumber
    ,[FromWebInterface] = @FromWebInterface
    ,[StartDateTime] = @StartDateTime
    ,[EndDateTime] = @EndDateTime
    ,[SkipPopulating879_889Records] = @SkipPopulating879_889Records
    ,[SupplierLoginID] = @SupplierLoginID
    ,[SupplierID] = @SupplierID
    ,[PrimaryGroupLevel]=@PrimaryGroupLevel
    ,[AlternateGroupLevel]=@AlternateGroupLevel
       ,[ItemGroup]=@ItemGroup
       ,[AlternateItemGroup]=@AlternateItemGroup
    ,[Size]=@Size
       ,[ManufacturerIdentifier]=@ManufacturerIdentifier
    ,[SellPkgVINAllowReorder]=@SellPkgVINAllowReorder
    ,[SellPkgVINAllowReClaim]=@SellPkgVINAllowReClaim
    ,[PrimarySellablePkgIdentifier]=@PrimarySellablePkgIdentifier
    ,[PrimarySellablePkgQty]=@SellablePkgQty
    ,[VIN]=@VIN
    ,[VINDescription]=@VINDescription
    ,[PurchPackDescription]=@PurchPackDescription
    ,[PurchPackQty]=@PurchPackQty 
       ,[AltSellPackage1]=@AltSellPackage1 
       ,[AltSellPackage1Qty]=@AltSellPackage1Qty 
       ,[AltSellPackage1UPC]=@AltSellPackage1UPC
       ,[BrandIdentifier]=@BrandIdentifier
       ,[AltSellPackage1Retail]=@AltSellPackage1Retail
       ,[ProductCategoryID]=@ProductCategoryID
   WHERE  MaintenanceRequestID = @MaintenanceRequestID
 end     
 
 Delete from MaintenanceRequestStores where MaintenanceRequestID = @MaintenanceRequestID
 DECLARE @NextString NVARCHAR(40)
   DECLARE @Pos INT
   DECLARE @NextPos INT
   DECLARE @Delimiter NVARCHAR(40)
   SET @Delimiter = ','
   SET @Pos = charindex(@Delimiter,@Stores)

   WHILE (@pos <> 0)
   BEGIN
    SET @NextString = substring(@Stores,1,@Pos - 1)
    Insert into MaintenanceRequestStores 
    select @MaintenanceRequestID, @NextString, 1, GETDATE() from Stores where Custom1=@Banner and StoreID=@NextString
    
    SET @Stores = substring(@Stores,@pos+1,len(@Stores))
    SET @pos = charindex(@Delimiter,@Stores)
   END  
 
 if(@CostZoneID is not null)
  Delete from MaintenanceRequestStores where MaintenanceRequestID = @MaintenanceRequestID and StoreID not in (Select distinct StoreID from CostZoneRelations C where SupplierID=@SupplierID and CostZoneID=@CostZoneID)
 
 EXEC usp_UpdateMaintenanceRequestStores
end
GO
