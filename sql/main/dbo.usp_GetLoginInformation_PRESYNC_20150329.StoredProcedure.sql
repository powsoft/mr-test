USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetLoginInformation_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_GetLoginInformation '-1','','',9,'Active'
CREATE procedure [dbo].[usp_GetLoginInformation_PRESYNC_20150329]
 @OrgId varchar(20),
 @Name varchar(50),
 @Login varchar(50),
 @AttributeId int,
 @AccountStatus varchar(20)
as

Begin
Declare @sqlQuery varchar(4000)
 
	if (@AttributeId=9)
	begin
		set @sqlQuery = 'Select S.SupplierId as [Organization Id], L.PersonID, 
		L.FirstName, L.LastName, 
		L.Login as [Login Name], L.Password, S.SupplierName as Organization,
		isnull(SA.BannerAccess, AV.AttributeValue) as [Banner Access], 
		case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
		when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
		when (IsLockedOut=0) Then ''Active'' end as [Account Status], 
		ISNULL(SA.EditRights,isnull(AV1.AttributeValue,''NA'')) as [Access Rights]
		from [Login Info-Supplier Users] L
		inner join Suppliers S  on S.SupplierID = L.SupplierID
		inner join ASPNETDB.dbo.aspnet_Membership M on M.Email = L.Login 
		left join supplierAccess SA on SA.personid = l.PersonID and SA.SupplierId=S.SupplierId
		Left join AttributeValues AV on AV.AttributeID=20 and AV.OwnerEntityID=L.PersonID
		Left join AttributeValues AV1 on AV1.AttributeID=22 and AV1.OwnerEntityID=L.PersonID
		where 1=1'
		 
		if(@OrgId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and cast(S.SupplierId as varchar)=''' + @OrgId + ''''
	end    

	else if (@AttributeId=17)

	begin
		set @sqlQuery = 'Select  C.ChainID as [Organization Id], L.PersonID, 
		L.FirstName, L.LastName, 
		L.Login as [Login Name], L.Password, C.ChainName as Organization,
		isnull(SA.BannerAccess, AV.AttributeValue) as [Banner Access],
		case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
		when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
		when (IsLockedOut=0) Then ''Active'' end as [Account Status], 
		ISNULL(SA.EditRights,isnull(AV1.AttributeValue,''NA'')) as [Access Rights]
		from [Login Info-Chain Users] L
		inner join Chains C  on C.ChainID = L.ChainID
		inner join ASPNETDB.dbo.aspnet_Membership M on M.Email = L.Login 
		inner join AttributeValues AV2 on AV2.AttributeID=17 and AV2.OwnerEntityID=L.PersonID 
		INner JOIN [ir_system33].[dbo].[Users] U on U.login_name=L.Login
		left join RetailerAccess SA on SA.personid = l.PersonID and SA.ChainId=C.ChainId
		Left join AttributeValues AV on AV.AttributeID=20 and AV.OwnerEntityID=L.PersonID
		Left join AttributeValues AV1 on AV1.AttributeID=22 and AV1.OwnerEntityID=L.PersonID
		where 1=1 and U.custom1 = ''Chain'''

		if(@OrgId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and cast(C.ChainId as varchar)=''' + @OrgId + ''''
	end  

	else if (@AttributeId=18)

	begin
		set @sqlQuery = 'Select C.ChainId as [Organization Id], L.PersonID, 
		L.FirstName, L.LastName, 
		L.Login as [Login Name], L.Password, C.ChainName as Organization, 
		isnull(SA.BannerAccess, AV.AttributeValue) as [Banner Access],
		case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
		when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
		when (IsLockedOut=0) Then ''Active'' end as [Account Status], 
		ISNULL(SA.EditRights,isnull(AV1.AttributeValue,''NA'')) as [Access Rights]
		from [Login Info-Chain Users] L
		inner join Chains C  on C.ChainID = L.ChainID
		inner join ASPNETDB.dbo.aspnet_Membership M on M.Email = L.Login
		inner join AttributeValues AV2 on AV2.AttributeID=18 and AV2.OwnerEntityID=L.PersonID 
		Left join AttributeValues AV on AV.AttributeID=20 and AV.OwnerEntityID=L.PersonID
		INner JOIN [ir_system33].[dbo].[Users] U on U.login_name=L.Login
		Left join AttributeValues AV1 on AV1.AttributeID=22 and AV1.OwnerEntityID=L.PersonID
		left join RetailerAccess SA on SA.personid = l.PersonID and SA.ChainId=C.ChainId
		where 1=1 and U.custom1 = ''Admin'''

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
							case when (IsLockedOut=1 and FailedPasswordAttemptCount=0)  Then ''Deleted''
							when (IsLockedOut=1 and FailedPasswordAttemptCount>0) Then ''Locked''
							when (IsLockedOut=0) Then ''Active''
							end as [Account Status], 
							ISNULL(AV.AttributeValue,''NA'') as [Access Rights]
						from Persons P
						inner join Logins L on L.OwnerEntityID=P.PersonID
						inner join AttributeValues AV on AV.AttributeID=23 and AV.OwnerEntityID=P.PersonID
						inner join AttributeValues AV1 on AV1.AttributeID=20 and AV1.OwnerEntityID=P.PersonID
						inner join Manufacturers Mn on Mn.ManufacturerId=AV.AttributeValue
						inner join ASPNETDB.dbo.aspnet_Membership M on M.Email = L.Login 
						where 1=1'

		if(@OrgId <>'-1' ) 
			set @sqlQuery = @sqlQuery + ' and cast(M.ManufacturerID as varchar)=''' + @OrgId + ''''
	end  
	
	if(@Name <>'') 
		set @sqlQuery  = @sqlQuery  + ' and (L.FirstName like ''%' + @Name + '%'' or L.LastName like ''%' + @Name + '%'')';

	if(@Login <> '') 
		set @sqlQuery = @sqlQuery + ' and L.Login like ''%' + @Login + '%''';
		
	if(@AccountStatus='Active')
		set @sqlQuery = @sqlQuery + ' and M.IsLockedOut = 0';
		
	else if(@AccountStatus='Locked')
		set @sqlQuery = @sqlQuery + ' and M.IsLockedOut=1 and M.FailedPasswordAttemptCount>0';
		
	else if(@AccountStatus='Deleted')
		set @sqlQuery = @sqlQuery + ' and M.IsLockedOut=1 and M.FailedPasswordAttemptCount=0 ';
	
	exec(@sqlQuery); 
	print @sqlQuery

End
GO
