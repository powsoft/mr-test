USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[SP_Save_UploadLog]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[SP_Save_UploadLog]
	-- Add the parameters for the stored procedure here
	
	@PersonID varchar(20),
	@FileType varchar(10),
	@FileName varchar(100)
AS
BEGIN
	
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	Insert into TB_UploadLog(DateOfUpload,PersonID,FileType,FileName)
	values(getdate(),@PersonID,@FileType,@FileName)


END
GO
