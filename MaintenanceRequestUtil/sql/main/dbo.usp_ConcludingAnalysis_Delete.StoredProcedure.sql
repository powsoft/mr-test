USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ConcludingAnalysis_Delete]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC usp_ConcludingAnalysis '','',''
Create PROC [dbo].[usp_ConcludingAnalysis_Delete]
@ID VARCHAR(20)

AS
BEGIN
	DELETE 	FROM [dbo].[ConcludingAnalysis]
	WHERE ID=@ID;
END
GO
