USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_DenyRequest]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_DenyRequest]
	-- Add the parameters for the stored procedure here
	(@SettlementID int, @DenialReason varchar(1000),@denierPerson int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update InventorySettlementRequests set settle='Denied' ,DenialReason=@DenialReason,ApprovingPersonID=@denierPerson,ApprovedDate=getdate()
	where InventorySettlementRequestID=@SettlementID
	
END
GO
