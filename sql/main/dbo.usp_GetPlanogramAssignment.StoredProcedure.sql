USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPlanogramAssignment]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_GetPlanogramAssignment '-1','-1'

CREATE procedure [dbo].[usp_GetPlanogramAssignment]

 @PlanogramID varchar(50),
 @StoreId varchar(10),
 @PlanogramTypeId varchar(10),
 @Status varchar(10),
 @ChainId varchar(10)
 
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
		
		set @sqlQuery = ' Select Distinct S.StoreIdentifier as [Store Number], PN.PlanogramName,''' + @listStr + ''' as ProductCategoryName, 
							PA.PLASSIGN_ID, PT.PlanogramTypeName, PA.Active, C.ChainName,
							case when (PA.Active=1 and PN.Active=1) then ''True'' else ''False'' end as ShowEdit
							From  PlanogramAssignments PA
							Inner Join PlanogramNames PN on PN.PlanogramID=PA.PlanogramID
							Inner Join Stores S on S.StoreId=PA.StoreID 
							Inner Join Chains C on C.ChainId=PN.RetailerId
							Inner Join  PlanogramTypes PT ON PT.PlanogramTypeId=PN.PlanogramTypeId 
							WHERE 1=1 '
		
	 if(@StoreId <> '' ) 
		set @sqlQuery = @sqlQuery + ' and S.StoreIdentifier like ''%' + @StoreId + '%'''  

     if(@PlanogramID <> '-1' ) 
		set @sqlQuery = @sqlQuery + ' and PN.PlanogramID = ''' + @PlanogramID +'''' 
		
	 if(@PlanogramTypeId <> '-1' ) 
		set @sqlQuery = @sqlQuery + ' and PT.PlanogramTypeID = ' + @PlanogramTypeId 
		
	 if(@Status <> '-1' ) 
		set @sqlQuery = @sqlQuery + ' and PA.Active = ''' + @Status + '''' 
		
	 if(@ChainId <> '-1' ) 
		set @sqlQuery = @sqlQuery + ' and PN.RetailerID = ' + @ChainId 			
		   
    set @sqlQuery = @sqlQuery + ' order by 1,2,3 asc '

	exec(@sqlQuery); 

End
GO
