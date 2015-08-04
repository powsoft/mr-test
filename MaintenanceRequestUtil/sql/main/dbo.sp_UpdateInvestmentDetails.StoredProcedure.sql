USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateInvestmentDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateInvestmentDetails]
	-- Add the parameters for the stored procedure here
	(@settlementID int,@StoreID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [InvoiceDetails]
   SET [InventorySettlementId] = @settlementID
   WHERE storeID=@storeID;
	SELECT storeid from InvoiceDetails;
END
GO
