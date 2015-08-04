USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetLoginInformation]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetLoginInformation '35510','barbara','',23,'Active','-1',1
-- exec usp_GetLoginInformation '-1','','gedas@matthewsbooks.com',9,'Active','-1',0
CREATE procedure [dbo].[usp_GetLoginInformation]
 @OrgId varchar(20),
 @Name varchar(50),
 @Login varchar(50),
 @AttributeId int,
 @AccountStatus varchar(20),
 @RoleID varchar(50),
 @PDIAdmin varchar(10)
as

Begin
Declare @sqlQuery varchar(4000)
	if (@AttributeId=9)
	begin
		set @sqlQuery = 'Select S.SupplierId as [Organization Id], L.PersonID, 
		L.FirstName, L.LastName, 
		L.Login as [Login Name], L.Password, S.SupplierName as Organization,
		isnull(SA.BannerAccess, AV.AttributeValue) as [Banner Access], 
		UR.RoleName AS [Role Name],
		case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
		when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
		when (IsLockedOut=0) Then ''Active'' end as [Account Status], 
		ISNULL(AV1.AttributeValue,isnull(SA.EditRights,''NA'')) as [Access Rights],
		L.PDIPartner, case when L.PDIPartner = 0 then ''No'' else ''Yes'' end as [PDI Partner]
		from [Login Info-Supplier Users] L with(NOLOCK)
		inner join Suppliers S with(NOLOCK)  on S.SupplierID = L.SupplierID
		inner join ASPNETDB.dbo.aspnet_Membership M with(NOLOCK) on M.Email = L.Login 
		inner JOIN AssignUserRoles_New A with(NOLOCK) ON A.UserID = L.PersonID
		inner JOIN UserRoles_New UR with(NOLOCK) ON UR.RoleID = A.RoleID and UR.RoleTypeID=9
		left join supplierAccess SA with(NOLOCK) on SA.personid = l.PersonID and SA.SupplierId=S.SupplierId
		Left join AttributeValues AV with(NOLOCK) on AV.AttributeID=20 and AV.OwnerEntityID=L.PersonID
		Left join AttributeValues AV1 with(NOLOCK) on AV1.AttributeID=22 and AV1.OwnerEntityID=L.PersonID
		where 1=1 '
		 
		if(@OrgId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and cast(S.SupplierId as varchar)=''' + @OrgId + ''''
		
	end    

	else if (@AttributeId=17)

	begin
		set @sqlQuery = 'Select  C.ChainID as [Organization Id], L.PersonID, 
		L.FirstName, L.LastName, 
		L.Login as [Login Name], L.Password, C.ChainName as Organization,
		isnull(SA.BannerAccess, AV.AttributeValue) as [Banner Access],
		UR.RoleName AS [Role Name],
		case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
		when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
		when (IsLockedOut=0) Then ''Active'' end as [Account Status], 
		ISNULL(AV1.AttributeValue,isnull(SA.EditRights,''NA'')) as [Access Rights],
		L.PDIPartner, case when L.PDIPartner = 0 then ''No'' else ''Yes'' end as [PDI Partner]
		from [Login Info-Chain Users] L with(NOLOCK)
		inner join Chains C with(NOLOCK)  on C.ChainID = L.ChainID
		inner join ASPNETDB.dbo.aspnet_Membership M with(NOLOCK) on M.Email = L.Login 
		inner join AttributeValues AV2 with(NOLOCK) on AV2.AttributeID=17 and AV2.OwnerEntityID=L.PersonID 
		inner JOIN AssignUserRoles_New A with(NOLOCK) ON A.UserID = L.PersonID
		inner JOIN UserRoles_New UR with(NOLOCK) ON UR.RoleID = A.RoleID and UR.RoleTypeID=17
		left join RetailerAccess SA with(NOLOCK) on SA.personid = l.PersonID and SA.ChainId=C.ChainId
		Left join AttributeValues AV with(NOLOCK) on AV.AttributeID=20 and AV.OwnerEntityID=L.PersonID
		Left join AttributeValues AV1 with(NOLOCK) on AV1.AttributeID=22 and AV1.OwnerEntityID=L.PersonID
		where 1=1 
		'

		if(@OrgId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and cast(C.ChainId as varchar)=''' + @OrgId + ''''
		
		
	end  

	else if (@AttributeId=18)

	begin
		set @sqlQuery = 'Select C.ChainId as [Organization Id], L.PersonID, 
		L.FirstName, L.LastName, 
		L.Login as [Login Name], L.Password, C.ChainName as Organization, 
		isnull(SA.BannerAccess, AV.AttributeValue) as [Banner Access],
		UR.RoleName AS [Role Name],
		case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
		when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
		when (IsLockedOut=0) Then ''Active'' end as [Account Status], 
		ISNULL(AV1.AttributeValue,isnull(SA.EditRights,''NA'')) as [Access Rights],
		L.PDIPartner, case when L.PDIPartner = 0 then ''No'' else ''Yes'' end as [PDI Partner]
		from [Login Info-Chain Users] L with(NOLOCK)
		inner join Chains C with(NOLOCK) on C.ChainID = L.ChainID
		inner join ASPNETDB.dbo.aspnet_Membership M with(NOLOCK) on M.Email = L.Login
		inner JOIN AssignUserRoles_New A with(NOLOCK) ON A.UserID = L.PersonID
		inner JOIN UserRoles_New UR with(NOLOCK) ON UR.RoleID = A.RoleID and UR.RoleTypeID=17
		inner join AttributeValues AV2 with(NOLOCK) on AV2.AttributeID=18 and AV2.OwnerEntityID=L.PersonID 
		Left join AttributeValues AV with(NOLOCK) on AV.AttributeID=20 and AV.OwnerEntityID=L.PersonID
		--INner JOIN [ir_system33].[dbo].[Users] U with(NOLOCK) on U.login_name=L.Login
		Left join AttributeValues AV1 with(NOLOCK) on AV1.AttributeID=22 and AV1.OwnerEntityID=L.PersonID
		left join RetailerAccess SA with(NOLOCK) on SA.personid = l.PersonID and SA.ChainId=C.ChainId
		where 1=1 --and U.custom1 = ''Admin''
		'

		if(@OrgId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and cast(C.ChainId as varchar)=''' + @OrgId + ''''
	end  
	
	else if (@AttributeId=23)

	begin
		set @sqlQuery = 'Select  Mn.ManufacturerID as [Organization Id],
							P.PersonID, 
							P.FirstName, 
							P.LastName, 
							L.Login as [Login Name],
							L.Password, 
							Mn.ManufacturerName as Organization, 
							AV1.AttributeValue as [Banner Access],
							UR.RoleName AS [Role Name],
							case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
							when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
							when (IsLockedOut=0) Then ''Active''
							end as [Account Status], 
							ISNULL(AV.AttributeValue,''NA'') as [Access Rights],
							L.PDIPartner, case when L.PDIPartner = 0 then ''No'' else ''Yes'' end as [PDI Partner]
						from Persons P with(NOLOCK)
						inner join Logins L with(NOLOCK) on L.OwnerEntityID=P.PersonID
						inner join AttributeValues AV with(NOLOCK) on AV.AttributeID=23 and AV.OwnerEntityID=P.PersonID
						inner join AttributeValues AV1 with(NOLOCK) on AV1.AttributeID=20 and AV1.OwnerEntityID=P.PersonID
						inner join Manufacturers Mn with(NOLOCK) on Mn.ManufacturerId=AV.AttributeValue
						inner join ASPNETDB.dbo.aspnet_Membership M with(NOLOCK) on M.Email = L.Login
						inner JOIN AssignUserRoles_New A with(NOLOCK) ON A.UserID = AV.OwnerEntityID
						inner JOIN UserRoles_New UR with(NOLOCK) ON UR.RoleID = A.RoleID and UR.RoleTypeID=23 
						where 1=1'

		if(@OrgId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and cast(Mn.ManufacturerID as varchar)=''' + @OrgId + ''''
	end  
	
	if(@Name <>'') 
		set @sqlQuery  = @sqlQuery  + ' and (FirstName like ''%' + @Name + '%'' or LastName like ''%' + @Name + '%'')';

	if(@Login <> '') 
		set @sqlQuery = @sqlQuery + ' and L.Login like ''%' + @Login + '%''';
		
	if(@AccountStatus='Active')
		set @sqlQuery = @sqlQuery + ' and M.IsLockedOut = 0';
		
	else if(@AccountStatus='Locked')
		set @sqlQuery = @sqlQuery + ' and M.IsLockedOut=1 and M.FailedPasswordAttemptCount>0';
		
	else if(@AccountStatus='Deleted')
		set @sqlQuery = @sqlQuery + ' and M.IsLockedOut=1 and M.FailedPasswordAttemptCount=0 ';
	
	if(@RoleID <>'-1' ) 
		set @sqlQuery = @sqlQuery + ' and UR.RoleID='''+@RoleID+''''

	if(@PDIAdmin <> '0' ) 
		set @sqlQuery = @sqlQuery + ' and L.PDIPartner = 1 and UR.RoleName like ''%pdi%'''
	
	exec(@sqlQuery); 
	print @sqlQuery

End
GO
