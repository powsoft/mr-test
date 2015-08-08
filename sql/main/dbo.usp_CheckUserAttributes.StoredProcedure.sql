USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CheckUserAttributes]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CheckUserAttributes]
 @UserName varchar(200)
as
Begin
 
 
	SELECT L.Login FROM AttributeValues A
	inner join Logins L on L.OwnerEntityId=A.OwnerEntityId
	where L.Login=@UserName and AttributeID=9 and AttributeValue NOT IN(SELECT SupplierID FROM Suppliers)

	UNION 

	SELECT L.Login FROM AttributeValues A
	inner join Logins L on L.OwnerEntityId=A.OwnerEntityId
	where L.Login=@UserName and AttributeID=17 and AttributeValue NOT IN(SELECT ChainID FROM Chains)

End
GO
