USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_CheckLoginDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_CheckLoginDetails] 
	-- Add the parameters for the stored procedure here
	(@AttributeVale varchar(50),@date varchar(50))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   
   select * from LoginDetails
   where AttributeID=@AttributeVale and convert(varchar(10),LoginDate, 101)=@date
   
   
END
GO
