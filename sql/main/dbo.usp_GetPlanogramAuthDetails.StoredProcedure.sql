USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPlanogramAuthDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_GetPlanogramAuthDetails] '44199', '-1', '','-1'
CREATE procedure [dbo].[usp_GetPlanogramAuthDetails]
 @ChainId varchar(20),
 @PlanogramID varchar(50),
 @UPC varchar(20),
 @Status varchar (10)
 
as

Begin
Declare @sqlQuery varchar(4000)
DECLARE @listStr VARCHAR(MAX)
	
	select @listStr =COALESCE(@listStr+' | ' ,'') + PC.ProductCategoryName
	From  productCategories PC
	Inner Join ProductCategoryAssignments PA on PC.ProductCategoryId=PA.ProductCategoryId and PC.ProductCategoryParentID=0
	Inner join PlanogramAuthorizedList PL on PA.ProductID=PL.ProductID
	where ProductCategoryName is not null
	group by PC.ProductCategoryName
		
	if(@listStr IS NULL)
		set @listStr = ''
		
	set @sqlQuery = 'SELECT PL.PAL_ID as PID, C.ChainName, PN.PlanogramName,''' + @listStr + ''' as ProductCategoryName, P.ProductName, PID.IdentifierValue as [UPC],
					PL.Active, case when (PN.Active=1 and PL.Active=1) then ''True'' else ''False'' end as ShowEdit, '''' as MinCapacity, '''' as MaxCapacity
				    From PlanogramAuthorizedList PL
						INNER JOIN PlanogramNames PN ON PN.PlanogramID=PL.PlanogramID
						Inner Join Chains C on C.ChainId=PN.RetailerID
						INNER JOIN Products P ON P.ProductID=PL.ProductID
						INNER JOIN ProductIdentifiers PID ON PID.ProductID=P.ProductID and PID.ProductIdentifierTypeID in (2,8)
						where 1=1 '

	if(@ChainId<>'-1')
		set @sqlQuery += ' and PN.RetailerID = ' + @ChainId

	if(@PlanogramID<>'-1' and @PlanogramID<>'')
		set @sqlQuery += ' and PN.PlanogramID = ' + @PlanogramID
		
	if(@UPC <> '')
		set @sqlQuery += ' and PID.IdentifierValue like ''%' + @UPC	+ '%'''	
		
	if(@Status<>'-1')
		set @sqlQuery += ' and PL.Active = ''' + @Status + ''''

    exec (@sqlQuery)
  
End
GO
