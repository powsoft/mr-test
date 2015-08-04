USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetSupplierAccessInfo]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetSupplierAccessInfo]
 @Name varchar(50),
 @LoginName varchar(50),
 @Supplier varchar(50),
 @Banner varchar(50),
 @Status varchar(20)
as

Begin
Declare @sqlQuery varchar(4000)
set @sqlQuery = 'select 
					(p.FirstName+'' ''+p.lastname) as PersonName,
					ss.SupplierName, l.Login, (sa.PersonId + ''-'' + sa.SupplierId) as ControlId,
					sa.EditRights, sa.BannerAccess, case when A.AttributeId IS NULL then '''' else ''Active'' end as Status
					from SupplierAccess sa
					inner join Persons p on sa.PersonId=p.PersonID
					inner join Suppliers ss on sa.SupplierId=ss.SupplierID
					inner join Logins l on sa.PersonId=l.OwnerEntityId
					left join AttributeValues A on A.OwnerEntityID=P.PersonID and A.AttributeValue=sa.SupplierId
					where 1=1 '
		
	if(@Name <>'' ) 
		set @sqlQuery = @sqlQuery + ' and (p.FirstName + '' '' + p.lastname) like ''%' + @Name + '%'''

	if(@LoginName <>'') 
		set @sqlQuery  = @sqlQuery  + ' and l.Login like ''%' + @LoginName + '%''';

	if(@Supplier <> '-1') 
		set @sqlQuery = @sqlQuery + ' and sa.SupplierID='''+@Supplier+''''
		
	if(@Banner<>'-1' and @Banner<>'FULL')
		set @sqlQuery = @sqlQuery + ' and sa.BannerAccess like ''%' +@Banner +'%'''
		
	if(@Status<>'ALL')
		set @sqlQuery = @sqlQuery + ' and sa.EditRights='''+@Status+''''	

	set @sqlQuery = @sqlQuery + ' order by p.FirstName+'' ''+p.lastname'
	
	exec(@sqlQuery); 

End
GO
