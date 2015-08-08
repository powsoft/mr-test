USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CustomColumnsSave]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[usp_CustomColumnsSave]
	-- Add the parameters for the stored procedure here
	@PersonId int,
	@FormName int,
	@Columns varchar(5000),
	@SupplierView varchar(50),
	@ChainView varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if (Exists(select personid from CustomColumns where personid=@PersonId and formname =@FormName))
	begin
		update customColumns set  columnNames=@Columns,SupplierView= @SupplierView , ChainView=@ChainView where personid=@PersonId and formname =@FormName 
	end
else 
	begin
		insert into customColumns (personid,formName,columnnames,Supplierview,ChainView) values(@PersonId,@FormName,@Columns,@SupplierView,@ChainView )
	end
END
GO
