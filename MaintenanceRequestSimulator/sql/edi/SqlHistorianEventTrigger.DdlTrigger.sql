USE [DataTrue_EDI]
GO
/****** Object:  DdlTrigger [SqlHistorianEventTrigger]    Script Date: 06/25/2015 16:58:52 ******/
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
				if CONVERT(varchar(max),@data) not like '%alter table Test_WorkingTable%'
				 and CONVERT(varchar(max),@data) not like '%Create table TEST_workingtable%'
				 and CONVERT(varchar(max),@data) not like '%exec sp_Rename @ColumnName%'
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
