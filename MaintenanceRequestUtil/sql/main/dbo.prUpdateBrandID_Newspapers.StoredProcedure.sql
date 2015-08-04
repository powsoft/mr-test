USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUpdateBrandID_Newspapers]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 11/11/2014
-- Description:	Update Brand ID for Newspaper
-- =============================================
CREATE PROCEDURE [dbo].[prUpdateBrandID_Newspapers]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update st set st.BrandID = ba.BrandID
	--Select *
	from storetransactions st with(nolock)
	inner join productbrandassignments ba with (nolock)
	on st.productid = ba.productid
	and st.productid in (select productid from productidentifiers where productidentifiertypeid = 8)
	and st.BrandID = 0
	and st.TransactionStatus in (811, 810, 3, 813)
	and ba.brandid <> 0

END
GO
