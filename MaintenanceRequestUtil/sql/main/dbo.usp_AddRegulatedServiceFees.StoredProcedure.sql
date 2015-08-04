USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddRegulatedServiceFees]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddRegulatedServiceFees]
	@ChainID int,
	@SupplierID int,
	@ServiceFeeFactorValue money,
	@ActiveStartDate varchar(20),
	@ActiveEndDate varchar(20),
	@UserId varchar(20),
	@ServiceFeeID int
AS
BEGIN
 if(@ServiceFeeID=0)
    begin
		INSERT INTO ServiceFees
		(
			ServiceFeeTypeID, 
			ChainID, 
			SupplierID, 
			ServiceFeeFactorValue, 
			ActiveStartDate, 
			ActiveLastDate, 
			DateTimeCreated, 
			LastUpdateUserID, 
			DateTimeLastUpdate
		)
		VALUES
			(
				2,
				@ChainID,
				@SupplierID,
				@ServiceFeeFactorValue,
				@ActiveStartDate,
				@ActiveEndDate,
				getdate(),
				@UserId,
				getdate()
			)
	end
 else
   begin	
		UPDATE ServiceFees
		   SET [ServiceFeeFactorValue] = @ServiceFeeFactorValue
			  ,[ActiveStartDate] = @ActiveStartDate
			  ,[ActiveLastDate] = @ActiveEndDate
		 WHERE [ServiceFeeID] = @ServiceFeeID
	end	 
END
GO
