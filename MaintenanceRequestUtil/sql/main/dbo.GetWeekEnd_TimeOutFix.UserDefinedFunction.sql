USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[GetWeekEnd_TimeOutFix]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetWeekEnd_TimeOutFix] 
(
	-- Add the parameters for the function here select dbo.[GetWeekEnd1] ('09/22/2013', '62362', '24164')
	@DateVar DATETIME,
	@billControlDay int
	
)
RETURNS DATE  
AS
BEGIN

	--DECLARE @BillControlDay INT 
	DECLARE @Dated DATE
	--SELECT @billControlDay = BillingControlDay FROM BillingControl BC WHERE BC.ChainID = @ChainID AND BC.EntityIDToInvoice = @SupplierID

	IF @billControlDay = datepart (dw, (@DateVar))
		BEGIN 
			SET @BillControlDay = 0
			SET @Dated = @DateVar
		END
	ELSE 
		BEGIN
			SELECT @Dated =  dateadd(dd, @BillControlDay - (datepart (dw, @DateVar))+7, @DateVar)    
		END

	RETURN @dated
	
END
GO
