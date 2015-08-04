USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_SaveAddNewRequest]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_SaveAddNewRequest '0','12/06/2012','1',
CREATE  Procedure [dbo].[amb_SaveAddNewRequest]
     @MaintenanceRequestID int,
     @SubmitDateTime datetime,
     @RequestTypeID int,
     @ChainID int,
     @Banner varchar(50),
     @CostZoneID int,
     @AllStores int,
     @UPC varchar(50),
     @ItemDescription varchar(250),
     @CurrentSetupCost money,
     @Cost money,
     @SuggestedRetail money,
     @Bipad varchar(50),
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
     @Stores varchar(2000)
     
as
begin

Declare @CostZoneCount as int

select @CostZoneCount=count(CostZoneID) from CostZoneRelations where CostZoneID=@CostZoneID and SupplierID=@SupplierId and StoreID in (Select Distinct StoreId from Stores where Custom1='' + @Banner + '')

if(@CostZoneCount=0 or @CostZoneID='-1' or @CostZoneID='')
	set  @CostZoneID=NULL
	
	
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
					   ,[Bipad]
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
					   ,[SupplierID])
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
						 @Bipad,
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
						 @SupplierID)

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
			  ,[ItemDescription] = @ItemDescription
			  ,[CurrentSetupCost] = @CurrentSetupCost
			  ,[Cost] = @Cost
			  ,[SuggestedRetail] = @SuggestedRetail
			  ,[Bipad]=@Bipad
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
				Insert into MaintenanceRequestStores(MaintenanceRequestID,StoreID,Included) 
				select @MaintenanceRequestID, @NextString, 1 from Stores where Custom1=@Banner and StoreID=@NextString
				
				SET @Stores = substring(@Stores,@pos+1,len(@Stores))
				SET @pos = charindex(@Delimiter,@Stores)
			END 	
	IF(@CostZoneID is not NULL)
		Delete from MaintenanceRequestStores where MaintenanceRequestID = @MaintenanceRequestID 
		and StoreID not in (Select distinct StoreID from		CostZoneRelations C where SupplierID=@SupplierID and CostZoneID=@CostZoneID)
	
	EXEC usp_UpdateMaintenanceRequestStores
end
GO
