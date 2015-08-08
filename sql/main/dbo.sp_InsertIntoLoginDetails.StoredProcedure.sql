USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_InsertIntoLoginDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_InsertIntoLoginDetails]
	-- Add the parameters for the stored procedure here
	(@personID int,@AttributeValue nvarchar(255),@LoginDate datetime)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [LoginDetails]
           (PersonID,
           AttributeID,
           LoginDate
           )
           
     VALUES
          (@personID ,@AttributeValue ,@LoginDate);
          
          
          delete from LoginDetails where convert(varchar(10),LoginDate, 101) <> convert(varchar(10),GETDATE(), 101) 
	
END
GO
