USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetJobDetailsByInstanceID]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[prGetJobDetailsByInstanceID]
	@JobInstanceID int
AS

Begin

	select 
	   i.[StoreProcedure]
      ,(select JobRelativePath from Jobs where JobId=(select JobId from JobInstances where JobInstanceId=@JobInstanceID)) as[JobRelativePath]
      ,i.[TotalParam]
      ,i.[Param1]
      ,i.[Param2]
      ,i.[Param3]
      ,i.[Param4]
      ,i.[Param5]
      ,i.[Param6]
      ,i.[Param7]
      ,i.[Param8]
      ,i.[Param9]
      ,i.[Param10]
      ,j.[JobInstanceID]
      ,j.[Param1] as Value1
      ,j.[Param2] as Value2
      ,j.[Param3] as Value3
      ,j.[Param4] as Value4
      ,j.[Param5] as Value5
      ,j.[Param6] as Value6
      ,j.[Param7] as Value7
      ,j.[Param8] as Value8
      ,j.[Param9] as Value9
      ,j.[Param10] as Value10
      ,i.SendEmail
      ,i.SendEmailUsingSMTP
      ,i.PassDataToNextStep
      ,i.OperationOnDataFromLastStep
      ,i.ColumnNameToOperate
      ,j.JobInstanceStepID
      ,j.[EmailSubject]
      ,j.[EmailBody]
	from JobInstanceSteps j join JobSteps i
	on j.JobStepId=i.JobstepID
	and j.JobInstanceID=@JobInstanceID
	order by i.OrderNo

End
GO
