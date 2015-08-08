USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateCostandAdjustments_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UpdateCostandAdjustments_PRESYNC_20150329]
 @Cost decimal,
 @Adjustment1 decimal,
 @Adjustment2 decimal,
 @RecordID INT
as
-- exec [usp_InvoicesRetailerConfirmation] '50964','50731','-1','','1900-01-01','1900-01-01','-1'
Begin

		Update [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH] 
			SET [Cost]=@Cost,  
				AlllowanceChargeAmount1 = @Adjustment1 ,  
				AlllowanceChargeAmount2 = @Adjustment2 
			WHERE RecordId=@RecordID
End
GO
