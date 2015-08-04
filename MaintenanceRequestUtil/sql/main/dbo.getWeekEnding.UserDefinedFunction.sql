USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[getWeekEnding]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[getWeekEnding]
(	
	@chainID varchar(20),
	@SaleDate varchar(20)
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT DISTINCT dateadd(dd, BillingControlDay - (datepart (dw, (ID.SaleDate))), ID.SaleDate) AS EndWeek
						, BC.ChainID
 FROM
	 BillingControl BC
	 INNER JOIN invoiceDetails ID
		 ON id.chainid = bc.chainid
 WHERE
	 BC.ChainID = @chainID and id.SaleDate=@SaleDate
)
GO
