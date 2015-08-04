USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Special_MR_Treatment]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_Special_MR_Treatment]
as 

/*
Remember to comment out and maintenancerequestid = 203929
Skip_879_889_Conversion_ProcessCompleted  is null
*/



set nocount on
declare @SubmitDtTime datetime
set @SubmitDtTime = '8/23/2012'
 declare @MaintenanceRequestID int, @MRID int, @SupplierID int, @ChainId int, @Banner varchar(50),  @UPC12 varchar(50), 
		@CostStartDate datetime, @CostEndDate datetime, @PromoStartDate datetime, @PromoEndDate datetime, 
		@cost money, @PromoAllowance money, @ProductID int, @ProductId2 int,@JustInserted int 
			
	 	
		--IF RequestTypeId is "2" and there is no promo exists in MR Table
		DECLARE report_cursor_promo2 CURSOR FOR
			--declare @SubmitDtTime datetime = '1/1/2013' 
			select distinct MaintenanceRequestID, StartDateTime, EndDatetime,cost , productid, Banner, SupplierID, ChainID 
			from MaintenanceRequests 
			where MaintenanceRequestID in (
			Select M1.MaintenanceRequestID from MaintenanceRequests M1
			left join MaintenanceRequests M2 on M1.SupplierID=M2.SupplierID
			and M1.ChainID=M2.ChainID and M1.productid=M2.productid and M1.Banner=M2.Banner
			and M2.Skip_879_889_Conversion_ProcessCompleted  is null and M2.productid is not null
			
			
			where M1.RequestTypeID =2 and M1.PDIParticipant = 1 and isnull(m1.MarkDeleted, 0) <> 1 and m1.approved=1 
			and M1.Skip_879_889_Conversion_ProcessCompleted  is null and M1.productid is not null and m1.SubmitDateTime>@SubmitDtTime 
			--and  not
			--(M1.StartDateTime  between m2.StartDateTime  and m2.EndDateTime  or M1.EndDateTime  between m2.StartDateTime  and m2.EndDateTime )
			 )	and approved=1	and isnull(MarkDeleted, 0)<> 1 and maintenancerequestid = 203932
			declare @rowcount int
			set @rowcount = 0
			OPEN report_cursor_promo2;
			FETCH NEXT FROM report_cursor_promo2
				INTO @MaintenanceRequestID, @PromoStartDate, @PromoEndDate, @Cost, @ProductID, @Banner, @supplierid, @chainid
			
			while @@FETCH_STATUS = 0
			begin
			
			--IF RequestTypeId is "2" and checking in productprices table 
				set @rowcount = 0
					declare Promo_Prices_Cursor2 Cursor For
						select distinct P.SupplierID, P.ProductID, P.ChainID, P.[UnitPrice]
						from ProductPrices P
						where  P.ProductPriceTypeID=8 and 
							P.SupplierID=@SupplierID and P.ChainID=@Chainid and P.ProductID  = @ProductID  
							and  ((@PromoStartDate between  P.ActiveStartDate and P.ActiveLastDate or @PromoEndDate between P.ActiveStartDate and P.ActiveLastDate ))
						
						Open Promo_Prices_Cursor2;
						Fetch Next From Promo_Prices_Cursor2
						into  @SupplierID, @ProductID2, @ChainID, @PromoAllowance
					
							while @@FETCH_STATUS = 0
								begin
								set @rowcount = @rowcount  +1
								--IF RequestTypeId is "2" inserting record with same values in MR Table
										-- Q: Shall SkipPopulating879_889Records go as 0 for Net Prices?
										-- Q: We are storing the MRID of Cost Record in [Skip_879_889_Conversion_ProcessCompleted] column, do we also need to store the MRID of Promo Record Somewhere ?
										insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
										Select  [SubmitDateTime],2,[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost-abs(@PromoAllowance), [SuggestedRetail], 0, 0, @PromoStartDate, @PromoEndDate, [SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE(), 0, @MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
										print 'First ' + cast( @JustInserted as varchar)
										set @JustInserted = @@IDENTITY 
										Fetch Next From Promo_Prices_Cursor2
										into  @SupplierID, @ProductID2, @ChainID, @PromoAllowance
								end
						--Updating maintenance request table and changing flags.			
						update MaintenanceRequests set [Skip_879_889_Conversion_ProcessCompleted]=@JustInserted   ,SkipPopulating879_889Records =-1 where MaintenanceRequestID = @MaintenanceRequestID 
					
					CLOSE Promo_Prices_Cursor2;
					DEALLOCATE Promo_Prices_Cursor2;
				
				--If there is no record in product prices table... inserting the same values from MR
				if  @rowcount = 0
					begin
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],2,[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],cost, [SuggestedRetail], 0, 0, @PromoStartDate, @PromoEndDate, [SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE(), 0, @MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 						
						set @JustInserted = @@IDENTITY 
						update MaintenanceRequests set [Skip_879_889_Conversion_ProcessCompleted]=@JustInserted   ,SkipPopulating879_889Records =-1 where MaintenanceRequestID = @MaintenanceRequestID 
											
				End
				
					
				
				
				FETCH NEXT FROM report_cursor_promo2 
				INTO @MaintenanceRequestID, @PromoStartDate, @PromoEndDate, @cost, @ProductID, @Banner, @supplierid, @chainid
			end
			
		 
		
					CLOSE report_cursor_promo2;
					DEALLOCATE report_cursor_promo2;
		
				

			--Step 2: 
			print 'Step 2'
			--If requesttypeid="3" and no cost in MR Table
			DECLARE report_cursor_promo CURSOR FOR 
			--declare @SubmitDtTime datetime = '8/23/2012' 
			select distinct MaintenanceRequestID, StartDateTime, EndDatetime, PromoAllowance, productid, Banner, SupplierID, ChainID
			from MaintenanceRequests 
			where MaintenanceRequestID in (
			Select M1.MaintenanceRequestID from MaintenanceRequests M1
			left join MaintenanceRequests M2 on M1.SupplierID=M2.SupplierID
			and M1.ChainID=M2.ChainID and M1.productid=M2.productid and M1.Banner=M2.Banner
			and M2.productid is not null
			where M1.RequestTypeID=3 and M1.PDIParticipant = 1 and m1.approved=1	and isnull(m1.MarkDeleted, 0)<> 1 and  m1.SubmitDateTime >=@SubmitDtTime 
			and M1.Skip_879_889_Conversion_ProcessCompleted  is null and M1.productid is not null
			--and  not
			--(M1.StartDateTime  between m2.StartDateTime  and m2.EndDateTime  or M1.EndDateTime  between m2.StartDateTime  and m2.EndDateTime )
			 )		and approved=1	and isnull(MarkDeleted, 0)<> 1 and maintenancerequestid = 203932
			print @@Rowcount
			OPEN report_cursor_promo;
			FETCH NEXT FROM report_cursor_promo 
				INTO @MaintenanceRequestID, @PromoStartDate, @PromoEndDate, @PromoAllowance, @ProductID, @Banner, @SupplierID, @ChainID
			
			while @@FETCH_STATUS = 0
			begin
				
				declare @multiple_costs int
				
	
				-- Check if multiple costs exist in ProductPrices for the same Supplier, Chain and Product
				
				select  @multiple_costs =COUNT(distinct P.[UnitPrice])
				from ProductPrices P
				where  P.ProductPriceTypeID=3 and 
					P.SupplierID=@supplierid and P.ChainID=@chainid and P.ProductID  = @ProductID  
					and  ((@PromoStartDate between  P.ActiveStartDate and P.ActiveLastDate or @PromoEndDate between P.ActiveStartDate and P.ActiveLastDate ))
					print 'Print Multiple Cost ' + cast( @multiple_costs as varchar )
				if (@multiple_costs=1)
				--if No Multiple cost...
				begin
				
					declare Promo_Prices_Cursor Cursor For
					select distinct P.SupplierID, P.ProductID, P.ChainID, P.[UnitPrice]
					from ProductPrices P
					where  P.ProductPriceTypeID=3 and 
						P.SupplierID=@supplierid and P.ChainID=@chainid and P.ProductID  = @ProductID  
						and  ((@PromoStartDate between  P.ActiveStartDate and P.ActiveLastDate or @PromoEndDate between P.ActiveStartDate and P.ActiveLastDate ))
						
					Open Promo_Prices_Cursor;
					Fetch Next From Promo_Prices_Cursor
					into  @SupplierID, @ProductID2, @ChainID, @Cost
				
					while @@FETCH_STATUS = 0
					begin
						-- Q: Shall SkipPopulating879_889Records go as 0 for Net Prices?
						-- Q: We are storing the MRID of Cost Record in [Skip_879_889_Conversion_ProcessCompleted] column, do we also need to store the MRID of Promo Record Somewhere ?
						insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
						Select  [SubmitDateTime],2,[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost-abs(@PromoAllowance), [SuggestedRetail], 0, 0, @PromoStartDate, @PromoEndDate, [SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE(), 0, @MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					print 'First ' + cast( @JustInserted as varchar)
					set @JustInserted = @@IDENTITY 
						Fetch Next From Promo_Prices_Cursor
						into  @SupplierID, @ProductID2, @ChainID, @Cost
					end
					
					update MaintenanceRequests set [Skip_879_889_Conversion_ProcessCompleted]=@JustInserted   ,SkipPopulating879_889Records =-1 where MaintenanceRequestID = @MaintenanceRequestID 
					
					CLOSE Promo_Prices_Cursor;
					DEALLOCATE Promo_Prices_Cursor;
				end	
				else if (@multiple_costs > 1)
				--If Multiple cost exists in product prices.. Alert to admin
				begin
			--Scenario 2 (Multiple costs exist for the Supplier and Product with different dates ranges)
					declare @multiple_dates int
					declare @RC int
					select @RC = count (P.[UnitPrice])
					from ProductPrices P, ProductIdentifiers PD 
					where P.ProductID=PD.productID and P.ProductPriceTypeID=3 and
						P.SupplierID=@supplierid and P.ChainID=@chainid and P.ProductID  = @ProductID  
						and  ((@PromoStartDate between  P.ActiveStartDate and P.ActiveLastDate or @PromoEndDate between P.ActiveStartDate and P.ActiveLastDate ))
						
					print 'Row ' + cast ( @rc  as varchar)
					if (@RC > 1)
						begin 
						print 'Rcv : ' + cast(@rowcount as varchar)
						declare @mailtxt varchar(2000)
						set @mailtxt = 'Multiple cost exist in product prices table, Please correct .. <br>MRID : ' +  CAST(@MaintenanceRequestID as varchar) + '<br> Promo Start Date : ' + convert(varchar, @PromoStartDate, 101) + ' to ' + convert(varchar,@PromoEndDate, 101) + '<br>' + 'Product ID : ' + CAST( @ProductID as varchar) + '<br>'
						 print 'Send Email : MRID#' + CAST(@MaintenanceRequestID as varchar)
							EXEC msdb.dbo.sp_send_dbmail
								@recipients='charlie.clark@icontroldsd.com'  ,
								@subject = 'PDI sp item maintenance alert.',
								@body = @mailtxt ,
								@body_format = 'HTML';
						end 
					
				end
				else 
				begin
				--if No Cost exists... Alert to admin
				
				declare @mailtxt1 varchar(2000)
				print 'Send Email'
						set @mailtxt1 = 'Cost does not exist in product prices table.. Please correct  <br>MRID : ' +  CAST(@MaintenanceRequestID as varchar) + '<br> Promo Start Date : ' + convert(varchar, @PromoStartDate , 101)+ ' to ' + convert(varchar,@PromoEndDate,101) + '<br>Product ID : ' + CAST( @ProductID as varchar) + '<br>Banner : ' + @Banner  
							EXEC msdb.dbo.sp_send_dbmail
								@recipients='charlie.clark@icontroldsd.com'  ,
								@subject = 'PDI sp item maintenance alert.'   ,
								@body = @mailtxt1 ,
								@body_format = 'HTML';
				
				end
				
			
				FETCH NEXT FROM report_cursor_promo 
				INTO @MaintenanceRequestID, @PromoStartDate, @PromoEndDate, @PromoAllowance, @ProductID, @Banner, @supplierid, @chainid
			END
			
			---------csc here now-----------------
		 CLOSE report_cursor_promo;
		 DEALLOCATE report_cursor_promo;
		 
			
--Step 3:			
					set @rowcount = 0
	print 'Step 3'
	--if RequestTypeID = 3 and RequestTypeId=2 with Start nad End date overlapped...
		DECLARE report_cursor CURSOR FOR 
		
		select MaintenanceRequestID, StartDateTime, EndDatetime, Cost, Productid, Banner, SupplierID, ChainID from MaintenanceRequests 
		where MaintenanceRequestID in (
			Select M1.MaintenanceRequestID from MaintenanceRequests M1
			inner join MaintenanceRequests M2 on M1.SupplierID=M2.SupplierID
			and M1.ChainID=M2.ChainID and M1.productid=M2.productid and M1.Banner=M2.Banner
			and M2.Skip_879_889_Conversion_ProcessCompleted  is null and M2.productid is not null
			and M2.RequestTypeID=3
			
			where M1.PDIParticipant = 1 and  M1.RequestTypeID =2 and isnull(m1.MarkDeleted, 0)<> 1 and m1.SubmitDateTime >=@SubmitDtTime  and m1.approved=1 and 
			(M1.StartDateTime between m2.StartDateTime  and m2.EndDateTime  or M1.EndDateTime between m2.StartDateTime  and m2.EndDateTime )
			and M1.Skip_879_889_Conversion_ProcessCompleted  is null and M1.productid is not null) and approved=1 and isnull(MarkDeleted, 0)<> 1
			 and maintenancerequestid = 203932
		OPEN report_cursor;
			FETCH NEXT FROM report_cursor 
				INTO @MaintenanceRequestID, @CostStartDate, @CostEndDate, @Cost, @ProductID, @Banner, @SupplierID, @ChainID
			set @rowcount = 0
			while @@FETCH_STATUS = 0
			begin
			set @rowcount = @rowcount +1
			print 'Step 3 : Fetch Status'
				declare Prices_Cursor Cursor For
			
				select MaintenanceRequestID, PromoAllowance, StartDateTime, EndDatetime  from MaintenanceRequests M1 			
				where M1.SupplierID=@SupplierID 
					and M1.ChainID=@ChainID and M1.productid=@ProductID and isnull(m1.MarkDeleted, 0)<> 1 and M1.Banner=@Banner
					
					and (@CostStartDate between M1.StartDateTime and M1.EndDateTime or  @CostEndDate between M1.StartDateTime and M1.EndDateTime)
					and M1.Skip_879_889_Conversion_ProcessCompleted  is null and M1.productid is not null
					and M1.RequestTypeID=3
				order by EndDatetime 
			 	
				Open Prices_Cursor;
				Fetch Next From Prices_Cursor
				into  @MRID, @PromoAllowance, @PromoStartDate, @PromoEndDate 
			
				while @@FETCH_STATUS = 0
				begin
				 
					-- Q: Shall SkipPopulating879_889Records go as 0 for Net Prices?
					-- Q: We are storing the MRID of Cost Record in [Skip_879_889_Conversion_ProcessCompleted] column, do we also need to store the MRID of Promo Record Somewhere ?
					insert into MaintenanceRequests ([SubmitDateTime],[RequestTypeID],[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],[Cost],[SuggestedRetail],[PromoTypeID],[PromoAllowance],[StartDateTime],[EndDateTime],[SupplierLoginID],[ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],[datetimecreated],[SkipPopulating879_889Records],[Skip_879_889_Conversion_ProcessCompleted])
					Select  [SubmitDateTime],2,[ChainID],[SupplierID],[Banner],[AllStores],[UPC],[BrandIdentifier],[ItemDescription],[CurrentSetupCost],@cost-abs(@PromoAllowance) ,[SuggestedRetail],[PromoTypeID],@PromoAllowance , @PromoStartDate, @PromoEndDate, [SupplierLoginID], [ChainLoginID],[Approved],[ApprovalDateTime],[DenialReason],[EmailGeneratedToSupplier],[EmailGeneratedToSupplierDateTime],[RequestStatus],[CostZoneID],[productid],[brandid],[upc12],[datatrue_edi_costs_recordid],[datatrue_edi_promotions_recordid],[dtstorecontexttypeid],[TradingPartnerPromotionIdentifier],[MarkDeleted],[DeleteLoginId],[DeleteReason],[DeleteDateTime],GETDATE(), 0, @MaintenanceRequestID FROM [DataTrue_Main].[dbo].[MaintenanceRequests] where MaintenanceRequestID = @MaintenanceRequestID 
					set @JustInserted = @@IDENTITY 
					print 'Second ' + cast(@JustInserted as varchar) + ' ' + cast(@mrid as varchar)
					update MaintenanceRequests set [Skip_879_889_Conversion_ProcessCompleted]=@JustInserted,SkipPopulating879_889Records =-1   where MaintenanceRequestID = @MRID   
					update MaintenanceRequests set [Skip_879_889_Conversion_ProcessCompleted]=@JustInserted,SkipPopulating879_889Records =-1   where MaintenanceRequestID = @MaintenanceRequestID    
					Fetch Next From Prices_Cursor
					into  @MRID, @PromoAllowance, @PromoStartDate, @PromoEndDate 
			
				end
				
				
				
				CLOSE Prices_Cursor;
				DEALLOCATE Prices_Cursor;
			
				FETCH NEXT FROM report_cursor 
				INTO @MaintenanceRequestID, @CostStartDate, @CostEndDate, @Cost, @ProductID, @Banner
			end
			
		 CLOSE report_cursor;
		 DEALLOCATE report_cursor;
GO
