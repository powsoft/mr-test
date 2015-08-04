USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdatecorrectAndReviewData]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[amb_UpdatecorrectAndReviewData]
	@MaintenanceRequestID int,
	@SubmitDateTime datetime,
	@RequestTypeID int,
	@ChainID int,
	@Banner varchar(50),
	@UPC varchar(50),
	@Cost money,
	@SuggestedRetail money,
	@StartDateTime  datetime,
	@EndDateTime  datetime,
	@SupplierID int,
	@StoreID varchar(2000),
	@mon int,
	@Tue int,
	@wed int,
	@Thur int,
	@Fri int,
	@Sat int,
	@Sun int
	 
as
begin
if (@MaintenanceRequestID=0)
	begin

	INSERT INTO [DataTrue_Main].[dbo].[MaintenanceRequests]
					   (
					   [SubmitDateTime]
					   ,[RequestTypeID]
					   ,[ChainID]
					   ,[Banner]
					   ,[UPC]
					   ,[Cost]
					   ,[SuggestedRetail]
					   ,[StartDateTime]
					   ,[EndDateTime]
					   ,[SupplierID]
					   ,[QtyOne]
					   ,[QtyTwo]
					   ,[QtyThree]
					   ,[QtyFour]
					   ,[QtyFive]
					   ,[QtySix]
					   ,[QtySeven]
					   ,[AllStores]
					   ,[ItemDescription]
					   ,[SupplierLoginID]
					  
					   )
				 VALUES
						( 
						 @SubmitDateTime,
						 @RequestTypeID,
						 @ChainID,
						 @Banner,
						 @UPC,
						 @Cost,
						 @SuggestedRetail,
						 @StartDateTime,
						 @EndDateTime,
						 @SupplierID,
						 @mon,
						 @Tue,
						 @wed,
						 @Thur,
						 @Fri,
						 @Sat,
						 @Sun,
						 0,
						 '',
						 0
						  
						 )
	set	@MaintenanceRequestID=SCOPE_IDENTITY()
	
end
else
	begin
	
	UPDATE [DataTrue_Main].[dbo].[MaintenanceRequests]
		   SET [SubmitDateTime] = @SubmitDateTime
			  ,[RequestTypeID] = @RequestTypeID
			  ,[ChainID] = @ChainID
			  ,[UPC] = @UPC
			  ,[Cost] = @Cost
			  ,[SuggestedRetail] = @SuggestedRetail
			  ,[StartDateTime] = @StartDateTime
			  ,[EndDateTime] = @EndDateTime
			  ,[SupplierID] = @SupplierID
			  --,[QtyOne]= @mon
			  -- ,[QtyTwo]= @Tue
			  -- ,[QtyThree]= @wed
			  -- ,[QtyFour]= @Thur
			  -- ,[QtyFive]= @Fri
			  -- ,[QtySix]= @Sat
			  -- ,[QtySeven]= @Sun
			   ,[AllStores]= 0
			   ,[ItemDescription]= ''
			   ,[SupplierLoginID]= 0
			  
		 WHERE  MaintenanceRequestID = @MaintenanceRequestID
	end
	end
GO
