USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_RemovePendingSettlement]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_RemovePendingSettlement]
	-- Add the parameters for the stored procedure here
	(@settlementID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE from InventorySettlementRequests where InventorySettlementRequestID=@settlementID;
END
GO
