USE [DataTrue_EDI]
GO
/****** Object:  DdlTrigger [tr_sps]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER [tr_sps] ON DATABASE 
	FOR create_procedure, ALTER_procedure
AS 
begin
set nocount on
declare @ev xml = eventdata()
declare @text varchar(max) = @ev.value('(//CommandText/text())[1]','varchar(max)')
insert eventdata
select convert(varchar(max),@ev)
set @text=replace(REPLACE (@text,'_DEV',''),'CREATE PROCEDURE','ALTER PROCEDURE')

exec (@text)

END
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
DISABLE TRIGGER [tr_sps] ON DATABASE
GO
