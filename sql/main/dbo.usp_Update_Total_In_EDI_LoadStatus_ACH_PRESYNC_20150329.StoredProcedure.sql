USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Update_Total_In_EDI_LoadStatus_ACH_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC usp_Update_Total_In_EDI_LoadStatus_ACH '20141124_10734_000065138_000073521_iControl.TXT','SPN','WOOD'
CREATE PROC [dbo].[usp_Update_Total_In_EDI_LoadStatus_ACH_PRESYNC_20150329]
(
	@FileName VARCHAR(500),
	@ChainIdentifier VARCHAR(50),
	@SupplierIdentifier VARCHAR(50)
)
AS 

BEGIN
		DECLARE @TotalAmt Numeric(18,9)
		/** Calculate Total Amt from Inbound846Inventory_ACH table **/
		SELECT @TotalAmt = CONVERT(NUMERIC(18, 9), SUM(CAST(Approval.Qty AS Numeric(18,9))*(cast(Approval.Cost aS numeric(18,9)))) 
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount1, 0)AS Numeric(18,9)))
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount2, 0)AS Numeric(18,9)))
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount3, 0)AS Numeric(18,9)))
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount4, 0)AS Numeric(18,9)))
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount5, 0)AS Numeric(18,9)))
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount6, 0)AS Numeric(18,9)))
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount7, 0)AS Numeric(18,9)))
								+SUM(CAST(ISNULL(Approval.AlllowanceChargeAmount8, 0) AS Numeric(18,9)))
								)
		FROM DataTrue_EDI..Inbound846Inventory_ACH AS Approval
		
		WHERE Approval.Filename = @FileName
			AND Approval.ChainName = @ChainIdentifier
			AND Approval.EDIName = @SupplierIdentifier;
		
		--PRINT @TotalAmt
		/** Update Totla Amt in  EDI_LoadStatus_ACH table **/
		UPDATE DataTrue_EDI.. EDI_LoadStatus_ACH
			SET TotalAmt = @TotalAmt,
				UpdatedTimeStamp=GETDATE()
		
		WHERE Chain=@ChainIdentifier
			AND PartnerID=@SupplierIdentifier
			AND FileName=@FileName;
			
END
GO
