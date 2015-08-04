USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetUserAssignments]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetUserAssignments]
 @AttributeValue varchar(50),
 @VerticalID varchar(20),
 @RoleId varchar(50),
 @UserName varchar(50),
 @LoginName varchar(50)
 
as

Begin
Declare @sqlQuery varchar(4000)
set @sqlQuery = 'Select (P.FirstName + '' '' + P.lastname) as PersonName, L.Login, R.RoleName, V.AttributeValue, 
					isnull(C.ChainName, isnull(S.SupplierName, M.ManufacturerName)) as EntityName, A.UserId, vt.VerticalName
					from AssignUserRoles A
					inner join Logins L on L.OwnerEntityId=A.UserId
					inner join Persons P on P.PersonId=A.UserId
					inner join UserRoles R on R.RoleID=A.RoleID
					inner join AttributeValues V on V.OwnerEntityId=A.UserId and V.AttributeID=R.RoleTypeID
					Left Join Chains C on C.ChainId=V.AttributeValue
					Left Join Suppliers S on S.SupplierId = V.AttributeValue
					Left Join Manufacturers M on M.ManufacturerId=V.AttributeValue
					INNER JOIN Verticals vt ON vt.VerticalID=R.VerticalID
					where 1=1 '
		
	if(@UserName <>'' ) 
		set @sqlQuery = @sqlQuery + ' and (P.FirstName + '' '' + P.lastname) like ''%' + @UserName + '%'''

	if(@LoginName <>'') 
		set @sqlQuery  = @sqlQuery  + ' and L.Login like ''%' + @LoginName + '%''';

	if(@AttributeValue <> '-1') 
		set @sqlQuery = @sqlQuery + ' and V.AttributeValue = ''' + @AttributeValue + ''''
		
	if(@VerticalID <> '-1') 
		set @sqlQuery = @sqlQuery + ' and vt.VerticalID = ''' + @VerticalID + ''''	
		
	if(@RoleId <> '-1')
		set @sqlQuery = @sqlQuery + ' and A.RoleId= ' + @RoleId

	set @sqlQuery = @sqlQuery + ' order by P.FirstName + '' '' + P.LastName '
	
	exec(@sqlQuery); 

End
GO
