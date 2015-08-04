USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetServiceFeePercentOfRetail]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 1/24/2014
-- Description:	To pull in all the service fees associated with a specific chain
-- =============================================

CREATE FUNCTION [dbo].[fnGetServiceFeePercentOfRetail]
(	
	
	@chainID int /*,
	--@ServiceTypDesc nvarchar(50)*/
)
RETURNS Money
AS

Begin
Declare @ServiceFee money=null


Select @ServiceFee = (SELECT isnull(ServiceFeeFactorValue, 0.00)
						 FROM
						 ServiceFeeTypes ST
						 INNER JOIN ServiceFees SF
							 ON ST.ServiceFeeTypeID = SF.ServiceFeeTypeID

						 WHERE 1=1
						 and SF.ServiceFeeTypeID = 4
						 and ChainID=@ChainId)


 Return
	(
	Isnull(@ServiceFee, 0.00)
	)
	 
	
End
GO
