USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ConcludingAnalysis]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC usp_ConcludingAnalysis '60620','40557','ZeroPOSReport'
--Select * from [ConcludingAnalysis]
CREATE PROC [dbo].[usp_ConcludingAnalysis]
@ChainID VARCHAR(20),
@SupplierID VARCHAR(20),
@ReportName VARCHAR(100)

AS
BEGIN
	SELECT ReportName,
		   Heading ,
		   HeadingColor,
		   Content,
		   ContentColor

	FROM [dbo].[ConcludingAnalysis]

	WHERE 1=1
		AND ChainID=@ChainID
		AND SupplierID=@SupplierID
		AND ReportName=@ReportName
		
	ORDER BY 
		CASE Heading
			WHEN 'Top Priorities' THEN 1
			WHEN 'Conclusion' THEN 2
			WHEN 'Additional Priorities' THEN 3
			WHEN 'Assessment' THEN 4
			WHEN 'Course of Action' THEN 5
		END
    
END
GO
