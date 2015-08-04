USE [DataTrue_Main]
GO
/****** Object:  DdlTrigger [SqlHistorianEventTrigger]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [SqlHistorianEventTrigger]
				on database
				for DDL_DATABASE_LEVEL_EVENTS AS
				set nocount on 
				if SUSER_SNAME() not in ('icontroldsd\nbaskin','nt authority\system')
				begin
				declare @data xml
				set @data = EVENTDATA()
				--if CONVERT(varchar(max),@data) not like '%Into ChainsToBill%'
				  exec Tessik.dbo.SqlHistorianLogger @data;
				end
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
DISABLE TRIGGER [SqlHistorianEventTrigger] ON DATABASE
GO
Enable Trigger [SqlHistorianEventTrigger] ON Database
GO
