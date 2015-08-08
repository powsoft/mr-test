USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ConcludingAnalysis_Select]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC usp_ConcludingAnalysis_Select '','ZeroPOSReport','',''
CREATE PROC [dbo].[usp_ConcludingAnalysis_Select]
@ID nvarchar(20),
@ReportName nvarchar(250),
@ChainID nvarchar(50),
@SupplierID nvarchar(50)

AS
BEGIN
	DECLARE @Query VARCHAR(1000)

	SET @Query = ' SELECT [ID]
					  ,[ReportName]
					  ,[ChainID]
					  ,[SupplierID]
					  ,[Heading]
					  ,[Content]
					  ,[HeadingColor]
					  ,[ContentColor]
				  FROM [dbo].[ConcludingAnalysis]
				  WHERE 1=1 '
	
	IF(len(LTRIM(RTRIM(@ID))) > 0)
		SET @Query += ' AND ID = ' + @ID
	
	IF(len(LTRIM(RTRIM(@ReportName))) > 0)
		SET @Query += ' AND ReportName = ''' + @ReportName + ''''

	IF(len(LTRIM(RTRIM(@ChainID))) > 0)
		SET @Query += ' AND ChainID = ' + @ChainID

	IF(len(LTRIM(RTRIM(@SupplierID))) > 0)
		SET @Query += ' AND SupplierID = ' + @SupplierID
	
	SET @Query += ' ORDER BY CASE Heading
								WHEN ''Top Priorities'' THEN 1
								WHEN ''Conclusion'' THEN 2
								WHEN ''Additional Priorities'' THEN 3
								WHEN ''Assessment'' THEN 4
								WHEN ''Course of Action'' THEN 5
							END '

	EXEC(@Query);

END
GO
