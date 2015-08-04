USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddSBTServiceFees_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddSBTServiceFees_PRESYNC_20150524]
	@ChainID int,
	@SupplierID int,
	@Fees decimal(10,2),
	@FeeMode varchar(100),
	@CalculateOn varchar(20),
	@ActiveStartDate varchar(20),
	@ActiveEndDate varchar(20),
	@ActiveStartDate_Old varchar(20),
	@ActiveEndDate_Old varchar(20),
	@ID int
AS
BEGIN
	if(@ID=0)
		begin
			INSERT INTO SBTServiceFees
			(
				ChainId, 
				SupplierId, 
				Fees, 
				FeeMode, 
				CalculateOn, 
				ActiveStartDate, 
				ActiveEndDate
			)
			VALUES
			(
				@ChainID,
				@SupplierID,
				@Fees,
				@FeeMode,
				@CalculateOn,
				@ActiveStartDate,
				@ActiveEndDate
			)
		end
	else
		begin
			UPDATE [SBTServiceFees]
			   SET [Fees] = @Fees
				  ,[FeeMode] = @FeeMode
				  ,[CalculateOn] = @CalculateOn
				  ,[ActiveStartDate] = @ActiveStartDate
				  ,[ActiveEndDate] = @ActiveEndDate
			 WHERE ChainId=@ChainID
			 and isnull(SupplierId,0) = isnull(@SupplierID,0)
			 and ActiveStartDate=@ActiveStartDate_Old
			 and ActiveEndDate=@ActiveEndDate_Old
		end
END
GO
