USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetServiceFeePercentOfRetail_SBT]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fnGetServiceFeePercentOfRetail_SBT]
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
						 and SF.ServiceFeeTypeID = 11
						 and ChainID=@ChainId)


 Return
	(
	Isnull(@ServiceFee, 0.00)
	)
	 
	
End
GO
