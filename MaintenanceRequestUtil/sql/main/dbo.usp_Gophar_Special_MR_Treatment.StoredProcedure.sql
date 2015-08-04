USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Gophar_Special_MR_Treatment]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Gophar_Special_MR_Treatment]
as 
set nocount on

 declare @MaintenanceRequestID int, @UPC12 varchar(50), @MRStartDate datetime,@MREndDate datetime, @cost money, @ProductID int
			DECLARE report_cursor CURSOR FOR 
			
select MaintenanceRequestID,UPC12, StartDateTime,EndDatetime,Cost,Productid from MaintenanceRequests where chainid=40393 and RequestTypeID=2 and SupplierID = 40558 and MaintenanceRequestID=123706  and Skip_879_889_Conversion_ProcessCompleted  is null and productid is not null 
OPEN report_cursor;
FETCH NEXT FROM report_cursor 
INTO @MaintenanceRequestID,@UPC12,@MRStartDate,@MREndDate,@cost,@ProductID
			while @@FETCH_STATUS = 0
			begin
			declare @ProductPriceID int,@ProductPriceTypeID int,@SupplierID int, @ProductID2 int, @ChainID int, @UnitPrice money,@UnitRetail money,@PromoStartDate datetime,@PromoEndDate datetime
			declare Prices_Cursor Cursor For
			
			select distinct[ProductPriceTypeID],[SupplierID],productPrices.ProductID, ChainID,[UnitPrice],[UnitRetail],[ActiveStartDate],[ActiveLastDate] 
			from productPrices ,productIdentifiers 
			where productPrices.ProductID=productIdentifiers.productID and productprices.ProductPriceTypeID=8 and 
				productprices.supplierid=40558 and productprices.ProductID  = @ProductID  
				and  ((ProductPrices.ActiveStartDate between @MRStartDate and @MREndDate or ProductPrices.ActiveLastDate  between @MRStartDate and @MREndDate  ))
			order by ActiveLastDate 
				
			
			declare @InsertStartDate datetime
			declare @InsertEndDate datetime
			declare @price money
			 
			declare @NoRecordFound int
			Open Prices_Cursor;
			Fetch Next From Prices_Cursor
			into  @ProductPriceTypeID ,@SupplierID ,@ProductID2 , @ChainID , @UnitPrice ,@UnitRetail ,@PromoStartDate ,@PromoEndDate 
			declare @RowsCount int
			set @RowsCount = @@CURSOR_ROWS  
			set @NoRecordFound = 0
			while @@FETCH_STATUS = 0
			
			begin
			
			set @NoRecordFound = 1
			 
			if @PromoStartDate <= @MRStartDate 
			  begin
				if @PromoEndDate>=@MREndDate
				
				  Begin
print '#1'
				if @@cursor_rows >1 and @RowsCount  =1 and @PromoStartDate >@MRStartDate
							set @InsertStartDate= @PromoStartDate
						else	
							set @InsertStartDate= @MRStartDate

					set @InsertEndDate = @MREndDate
					insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost-@UnitPrice ,[SuggestedRetail],[PromoTypeID],[PromoAllowance],@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
				  End	
				
				else if @PromoEndDate < @MREndDate
					begin
print '#2'
						if @@cursor_rows >1 and @RowsCount  >1 and @PromoStartDate >@MRStartDate
							set @InsertStartDate= @PromoStartDate
						else	
							set @InsertStartDate= @MRStartDate
						
						set @InsertEndDate = @PromoEndDate
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
							Select  [SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost-@UnitPrice ,[SuggestedRetail],[PromoTypeID],[PromoAllowance],@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
						
					  if @RowsCount =1	
					   begin	
						if @PromoStartDate <@MRStartDate  
							set @InsertStartDate= dateadd(day,1,@PromoEndDate)
						
						if @@cursor_rows >1	
							set @InsertStartDate=@PromoStartDate--dateadd(day,1,@PromoEndDate)
							
						set @InsertEndDate = @MREndDate
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
							Select  [SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost ,[SuggestedRetail],[PromoTypeID],[PromoAllowance],@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					   End	

					end
				 end
			else if @PromoStartDate > @MRStartDate 	
				 Begin
					if @PromoEndDate>=@MREndDate
						Begin
		print '#3'
					if @@cursor_rows >1 and @RowsCount  =1 and @PromoStartDate >@MRStartDate
							set @InsertStartDate= @PromoStartDate
						else	
							set @InsertStartDate= @MRStartDate
							
							set @InsertEndDate = @MREndDate
							insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
								Select  [SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost-@UnitPrice ,[SuggestedRetail],[PromoTypeID],[PromoAllowance],@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
						end
											
					else if @PromoEndDate < @MREndDate 	
						begin
print '#4'
						if @@cursor_rows >1 and @RowsCount  >1 and @PromoStartDate >@MRStartDate
							set @InsertStartDate= @PromoStartDate
						else	
							set @InsertStartDate= @MRStartDate
							
							set @InsertEndDate = @PromoEndDate
							insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
								Select  [SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost-@UnitPrice ,[SuggestedRetail],[PromoTypeID],[PromoAllowance],@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 

						  if @RowsCount =1	
						   begin	
							if @PromoStartDate <@MRStartDate  
								set @InsertStartDate= dateadd(day,1,@PromoEndDate)
							
							if @@cursor_rows >1	
								set @InsertStartDate=@PromoStartDate--dateadd(day,1,@PromoEndDate)

							
							set @InsertEndDate = @MREndDate
							insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
								Select  [SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost ,[SuggestedRetail],[PromoTypeID],[PromoAllowance],@InsertStartDate ,@InsertEndDate ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE() ,0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
						  end 
				
						end
				   End
			
			set @RowsCount = @RowsCount -1
			set @InsertStartDate= null
			set @InsertEndDate = null
							
			
			
			Fetch Next From Prices_Cursor
			into  @ProductPriceTypeID ,@SupplierID,@ProductID2 , @ChainID ,@UnitPrice ,@UnitRetail ,@PromoStartDate ,@PromoEndDate 
			end
			if @NoRecordFound = 0 
			begin			
				insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
				Select  [SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost ,[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime] ,[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE(),0,@MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
			end 
		    update MaintenanceRequests set [Skip_879_889_Conversion_ProcessCompleted]=-1,SkipPopulating879_889Records =1  where MaintenanceRequestID = @MaintenanceRequestID 
			CLOSE Prices_Cursor;
			DEALLOCATE Prices_Cursor;
			
			
			FETCH NEXT FROM report_cursor 
			INTO @MaintenanceRequestID,@UPC12,@MRStartDate,@MREndDate, @Cost,@ProductID
END
 CLOSE report_cursor;
    DEALLOCATE report_cursor;
GO
