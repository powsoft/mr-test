USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[spSQLPerf]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[spSQLPerf] 
AS 
DBCC SQLPERF(logspace)
GO
