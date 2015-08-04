USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ConcludingAnalysis_Insert]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_ConcludingAnalysis_Insert]
@ID int,
@ReportName nvarchar(100),
@ChainID nvarchar(50),
@SupplierID nvarchar(50),
@Heading nvarchar(250),
@Content nvarchar(max),
@HeadingColor nvarchar(50),
@ContentColor nvarchar(50)

AS
BEGIN
	IF(@ID = 0)
		BEGIN
			INSERT INTO [dbo].[ConcludingAnalysis]
					   ([ReportName]
					   ,[ChainID]
					   ,[SupplierID]
					   ,[Heading]
					   ,[Content]
					   ,[HeadingColor]
					   ,[ContentColor])
				 VALUES
					   (@ReportName
						,@ChainID
						,@SupplierID
						,@Heading 
						,@Content
						,@HeadingColor
						,@ContentColor)
		END
	ELSE 
		BEGIN
			UPDATE [dbo].[ConcludingAnalysis]
			   SET [ReportName] = @ReportName
				  ,[ChainID] = @ChainID
				  ,[SupplierID] = @SupplierID
				  ,[Heading] = @Heading
				  ,[Content] = @Content
				  ,[HeadingColor] = @HeadingColor
				  ,[ContentColor] = @ContentColor
			 WHERE [ID]=@ID;
		END
	
	UPDATE [dbo].[ConcludingAnalysis]
		SET [HeadingColor] = @HeadingColor
		WHERE [ChainID]=@ChainID
			AND [SupplierID] = @SupplierID
			AND [ReportName] = @ReportName
			AND [Heading] = @Heading;

END
GO
