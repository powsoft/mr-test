USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[FDateTime]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FDateTime] 
(
	-- Add the parameters for the function here
	@DateVar datetime
)
RETURNS date  
AS
BEGIN
	
return	  convert(varchar(10),@DateVar,101) 
	 

END
GO
