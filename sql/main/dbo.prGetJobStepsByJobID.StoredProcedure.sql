USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetJobStepsByJobID]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[prGetJobStepsByJobID]
@JobId int
as
Begin
	select * from JobSteps where jobId=@JobId
End
GO
