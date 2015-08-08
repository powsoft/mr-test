USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_ReSettleDeniedItem]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_ReSettleDeniedItem] 
	-- Add the parameters for the stored procedure here
	(@SettlementID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update InventorySettlementRequests set settle='Pending' ,DenialReason=NULL
	where InventorySettlementRequestID=@SettlementID
	
END
GO
