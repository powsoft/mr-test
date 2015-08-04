USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetTopRows]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetTopRows]
(
	@Rows int = null
)
returns varchar(20)

as

begin
	declare @Qry varchar(2000)
	if (@Rows > 0 )
		set  @Qry =  ' Top ' + cast(@rows as varchar)
	else 
		set @Qry = ''
	return @qry 
end
GO
