USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPlanogramTypeDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_GetPlanogramNameDetails '-1','-1','-1'

Create procedure [dbo].[usp_GetPlanogramTypeDetails]

 @PlaogramTypeName varchar(50)
 
as

Begin
Declare @sqlQuery varchar(4000)

	set @sqlQuery = ' Select PT.PlanogramTypeName,PT.PlanogramTypeID
						
					  From  PlanogramTypes PT  '

	set @sqlQuery  = @sqlQuery  + ' WHERE 1=1 ' 
		
	if(@PlaogramTypeName <> '-1') 
		set @sqlQuery = @sqlQuery + ' and PN.PlanogramTypeID = ' + @PlaogramTypeName 
		   
    set @sqlQuery = @sqlQuery + ' order by 1,2 asc '

	exec(@sqlQuery); 
End
GO
