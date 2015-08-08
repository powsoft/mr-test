USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Gophar_Special_MR_Treatment_2nd Step_Find_NewPromos_Convert_to_Type2]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_Gophar_Special_MR_Treatment_2nd Step_Find_NewPromos_Convert_to_Type2]
as 
set nocount on

declare @MaintenanceRequestID int, @UPC12 varchar(50), @MRPromoStartDate datetime,@MRPromoEndDate datetime, @cost money, @ProductID int
			DECLARE report_cursor CURSOR FOR 
			
select MaintenanceRequestID,UPC12, StartDateTime,EndDatetime,PromoAllowance,Productid 
from MaintenanceRequests 
where chainid=40393 and RequestTypeID=3 and SupplierID = 40558 and Skip_879_889_Conversion_ProcessCompleted  is null and productid is not null 
and (MaintenanceRequestID > 11289)


OPEN report_cursor;
FETCH NEXT FROM report_cursor 
INTO @MaintenanceRequestID,@UPC12,@MRPromoStartDate,@MRPromoEndDate,@cost,@ProductID
			while @@FETCH_STATUS = 0
			begin
			declare @ProductPriceID int,@ProductPriceTypeID int,@SupplierID int, @ProductID2 int, @ChainID int, @UnitPrice money,@UnitRetail money,@MRCostStartDate datetime,@MRCostEndDate datetime
			declare Prices_Cursor Cursor For
			
			select distinct[ProductPriceTypeID],[SupplierID],productPrices.ProductID, ChainID,[UnitPrice],[UnitRetail],[ActiveStartDate],[ActiveLastDate] 
			from productPrices ,productIdentifiers 
			where productPrices.ProductID=productIdentifiers.productID and productprices.ProductPriceTypeID=3 and 
				productprices.supplierid=40558 and productprices.ProductID  = @ProductID  
				and  ((ProductPrices.ActiveStartDate between @MRPromoStartDate and @MRPromoEndDate or ProductPrices.ActiveLastDate  between @MRPromoStartDate and @MRPromoEndDate  ))
			order by ActiveLastDate 
				
			
			declare @InsertStartDate datetime
			declare @InsertEndDate datetime
			declare @price money
			 
			declare @NoRecordFound int
			Open Prices_Cursor;
			Fetch Next From Prices_Cursor
			into  @ProductPriceTypeID ,@SupplierID ,@ProductID2 , @ChainID , @UnitPrice ,@UnitRetail ,@MRCostStartDate ,@MRCostEndDate 
			declare @RowsCount int
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
	
					insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
				
				if @MRCostEndDate <=@MRPromoEndDate 
					 begin	
						set @InsertStartDate= @MRPromoStartDate 
						set @InsertEndDate = @MRCostEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					end
				else	 
					begin
					 if  @MRCostEndDate> @MRPromoEndDate
						set @InsertStartDate= @MRPromoStartDate 
						set @InsertEndDate = @MRPromoEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					  
					    set @InsertStartDate= dateadd(day,1,@MRPromoEndDate ) 
						set @InsertEndDate = @MRCostEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					end  
					
					
				end
		else
		 begin	
			if  @MRCostEndDate  <=@MRPromoendDate	
			
				begin
					    set @InsertStartDate= @MRCoststartDate 
						set @InsertEndDate = @MRCostEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
				end
			
			else
			
				begin
			 			set @InsertStartDate= @MRCoststartDate 
						set @InsertEndDate = @MRPromoEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice -@cost ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					  
					    set @InsertStartDate= dateadd(day,1,@MRPromoEndDate ) 
						set @InsertEndDate = @MRCostEndDate 
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],'2',[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@UnitPrice ,[SuggestedRetail],'0','0',@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
			
						
					
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
			INTO @MaintenanceRequestID,@UPC12,@MRPromoStartDate,@MRPromoEndDate, @Cost,@ProductID
END
 CLOSE report_cursor;
    DEALLOCATE report_cursor;
GO
