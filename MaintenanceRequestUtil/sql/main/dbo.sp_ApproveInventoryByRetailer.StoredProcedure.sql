USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_ApproveInventoryByRetailer]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ApproveInventoryByRetailer]
	-- Add the parameters for the stored procedure here
	(@StoreID int,@settle varchar(50),@retailerApprovedPerson int,@settlementApprovedDate datetime,@settlementID varchar(50),@invDate datetime,@supplierId varchar(50))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Update statements for procedure here
    
    UPDATE DataTrue_Main.[dbo].[InventorySettlementRequests]
    SET ApprovingPersonID = @retailerApprovedPerson,ApprovedDate=@settlementApprovedDate,settle=@settle
    WHERE InventorySettlementRequestID=@settlementID and Settle='Pending';
    
    
    UPDATE DataTrue_Main.[dbo].[InvoiceDetails]
    SET [InventorySettlementId] = @settlementID
    WHERE storeID=@storeID and SaleDate=@invDate and supplierId=@supplierId and InvoiceDetailTypeID in(3,5,6,9,10);
    select storeID from [InvoiceDetails];
END
GO
