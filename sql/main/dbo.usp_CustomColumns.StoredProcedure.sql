USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CustomColumns]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_CustomColumns]
	-- Add the parameters for the stored procedure here
	@PersonId int,
	@FormName int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 select ColumnNames from CustomColumns where personid=@PersonId and formname =@FormName 
 end
GO
