USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNUprMaintenanceRequest_ConvertAllRecordsToCostType_Step2]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNUprMaintenanceRequest_ConvertAllRecordsToCostType_Step2]
as 
set nocount on

declare @MaintenanceRequestID int, @UPC12 varchar(50), @MRPromoStartDate datetime,@MRPromoEndDate datetime, @cost money, @ProductID int, @supplierID int
			DECLARE report_cursor CURSOR FOR 
			
select MaintenanceRequestID,UPC12, StartDateTime,EndDatetime,PromoAllowance,Productid, SupplierID
from MaintenanceRequests 
where PDIParticipant = 1 and RequestTypeID=3 and Skip_879_889_Conversion_ProcessCompleted  is null and productid is not null 
and StartDateTime >= '5/1/2013' and RequestStatus not in (17, 18, -30, -25, -26, -27, -333, -334)



OPEN report_cursor;
FETCH NEXT FROM report_cursor 
INTO @MaintenanceRequestID,@UPC12,@MRPromoStartDate,@MRPromoEndDate,@cost,@ProductID,@supplierID
			while @@FETCH_STATUS = 0
			begin
			declare @ProductPriceID int,@ProductPriceTypeID int,@ProductID2 int, @ChainID int, @UnitPrice money,@UnitRetail money,@MRCostStartDate datetime,@MRCostEndDate datetime
			declare Prices_Cursor Cursor For
			
			select distinct[ProductPriceTypeID],[SupplierID],productPrices.ProductID, ChainID,[UnitPrice],[UnitRetail],[ActiveStartDate],[ActiveLastDate] 
			from productPrices ,productIdentifiers 
			where productPrices.ProductID=productIdentifiers.productID and productprices.ProductPriceTypeID=3 and 
				productprices.supplierid=@supplierID and productprices.ProductID  = @ProductID  
				and  ((ProductPrices.ActiveStartDate <= @MRPromoStartDate and ProductPrices.ActiveLastDate  >= @MRPromoEndDate  ))
			order by ActiveLastDate 
				
			
			declare @InsertStartDate datetime
			declare @InsertEndDate datetime
			declare @price money
			 
			declare @NoRecordFound int
			declare @RowsCount int
			
			Open Prices_Cursor;
			Fetch Next From Prices_Cursor
			into  @ProductPriceTypeID ,@SupplierID ,@ProductID2 , @ChainID , @UnitPrice ,@UnitRetail ,@MRCostStartDate ,@MRCostEndDate 
			set @RowsCount = @@CURSOR_ROWS  
			set @NoRecordFound = 0
			while @@FETCH_STATUS = 0
			
			begin
			
			set @NoRecordFound = 1
			 
			
print '#1'
			if  @MRCostStartDate <=@MRPromoStartDate
				 begin
					set @InsertStartDate= @MRCostStartDate
					set @InsertEndDate = dateadd(day,-1,@MRPromoStartDate )
	
					insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted],[PDIParticipant])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID,1 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
				
				if @MRCostEndDate <=@MRPromoEndDate 
					 begin	
						set @InsertStartDate= @MRPromoStartDate 
						set @InsertEndDate = @MRCostEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted],[PDIParticipant])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID, 1 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					end
				else	 
					begin
					 if  @MRCostEndDate> @MRPromoEndDate
						set @InsertStartDate= @MRPromoStartDate 
						set @InsertEndDate = @MRPromoEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted],[PDIParticipant])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],0,[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID,1 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					  
					 --   set @InsertStartDate= dateadd(day,1,@MRPromoEndDate ) 
						--set @InsertEndDate = @MRCostEndDate 
						--insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted],[PDIParticipant])
						--Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID,1 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					end  
					
					
				end
		else
		 begin	
			if  @MRCostEndDate  <=@MRPromoendDate	
			
				begin
					    set @InsertStartDate= @MRCoststartDate 
						set @InsertEndDate = @MRCostEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted],[PDIParticipant])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID,1 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
				end
			
			else
			
				begin
			 			set @InsertStartDate= @MRCoststartDate 
						set @InsertEndDate = @MRPromoEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted],[PDIParticipant])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID,1 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					  
					    set @InsertStartDate= dateadd(day,1,@MRPromoEndDate ) 
						set @InsertEndDate = @MRCostEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted],[PDIParticipant])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID,1 FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
			
						
					
				end

		end		


			set @InsertStartDate= null
			set @InsertEndDate = null
							
			
			
			Fetch Next From Prices_Cursor
			into  @ProductPriceTypeID ,@SupplierID,@ProductID2 , @ChainID ,@UnitPrice ,@UnitRetail ,@MRCostStartDate ,@MRCostEndDate 
			end
			--if @NoRecordFound = 0 
						
				--insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
				--Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice-@cost ,[SuggestedRetail],'0','0',[StartDateTime],[EndDateTime] ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE(),0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
			
		    update MaintenanceRequests set [Skip_879_889_Conversion_ProcessCompleted]=-1,SkipPopulating879_889Records =1  where MaintenanceRequestID = @MaintenanceRequestID 
			CLOSE Prices_Cursor;
			DEALLOCATE Prices_Cursor;
			
			
			FETCH NEXT FROM report_cursor 
			INTO @MaintenanceRequestID,@UPC12,@MRPromoStartDate,@MRPromoEndDate, @Cost,@ProductID,@supplierID
END
 CLOSE report_cursor;
    DEALLOCATE report_cursor;
GO
