USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prRemittanceReports_Insert]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prRemittanceReports_Insert]
	@WholesalerID nvarchar(50)
    ,@CheckNumber nvarchar(50)
    ,@ChainID nvarchar(50)
    ,@CheckCreated datetime
    ,@FileLocation nchar(200)
    ,@DetailReportFileLocation nchar(200)
as
Begin

INSERT INTO [DataTrue_Main].[dbo].[RemittanceReports]
           ([WholesalerID]
           ,[CheckNumber]
           ,[ChainID]
           ,[CheckCreated]
           ,[ReportCreated]
           ,[FileLocation]
           ,[DetailReportCreated]
           ,[DetailReportFileLocation])
     VALUES
           (@WholesalerID
           ,@CheckNumber
           ,@ChainID
           ,@CheckCreated
           ,getdate()
           ,@FileLocation
           ,GETDATE()
           ,@DetailReportFileLocation)
End
GO
