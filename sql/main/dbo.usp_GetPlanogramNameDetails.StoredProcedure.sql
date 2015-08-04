USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPlanogramNameDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_GetPlanogramNameDetails '-1','-1','-1','-1'

CREATE procedure [dbo].[usp_GetPlanogramNameDetails]
 @ChainId varchar(20),
 @PlanogramName varchar(50),
 @PlaogramTypeName varchar(50),
 @Status varchar (10)
 
as

Begin
Declare @sqlQuery varchar(4000)
DECLARE @listStr VARCHAR(MAX)
	
	select @listStr =COALESCE(@listStr+' | ' ,'') + PC.ProductCategoryName
	From  productCategories PC
	Inner Join ProductCategoryAssignments PA on PC.ProductCategoryId=PA.ProductCategoryId and PC.ProductCategoryParentID=0
	Inner join (Select distinct ProductID from PlanogramAuthorizedList
		  union Select distinct ProductID from PlanogramReplenishment) 
	PL on PA.ProductID=PL.ProductID
	where ProductCategoryName is not null
	group by PC.ProductCategoryName
	
	IF(@listStr is null)
		set @listStr=''

	set @sqlQuery = ' Select distinct PN.PlanogramID, C.ChainName as [Retailer Name],''' + @listStr + ''' as ProductCategoryName, 
					PN.PlanogramName, PT.PlanogramTypeName, PN.Active
					From  PlanogramNames PN
					Inner Join PlanogramTypes PT on PN.PlanogramTypeID=PT.PlanogramTypeID
					Inner Join Chains C on C.ChainId=PN.RetailerID 
					WHERE 1=1'
		
	if(@ChainId <>'-1' ) 
		set @sqlQuery = @sqlQuery + ' and C.ChainID = ' + @ChainId  

    if(@PlanogramName <>'' ) 
		set @sqlQuery = @sqlQuery + ' and PN.PlanogramName like ''%' + @PlanogramName + '%''' 
		
	if(@PlaogramTypeName <> '-1') 
		set @sqlQuery = @sqlQuery + ' and PN.PlanogramTypeID = ' + @PlaogramTypeName 
		
	if(@Status<>'-1')
		set @sqlQuery += ' and PN.Active = ''' + @Status + ''''
			   
    set @sqlQuery = @sqlQuery + ' order by 1,2,3 asc '

	exec(@sqlQuery); 
End
GO
