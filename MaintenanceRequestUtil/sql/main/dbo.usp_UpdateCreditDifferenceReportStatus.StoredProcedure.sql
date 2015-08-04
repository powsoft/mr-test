USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateCreditDifferenceReportStatus]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_UpdateCreditDifferenceReportStatus]
     @ApproveStatus int,
     @RecordID int
as --exec [usp_UpdateCreditDifferenceReportStatus] '1',''
begin
		update Credit_Difference_Report set 
		Revertstatus=@ApproveStatus
		where Revertstatus is Null and 
		RecordID=@RecordID
		

end
GO
