USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateUserInformation_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[usp_UpdateUserInformation_PRESYNC_20150415]
     @UserType varchar(50),
     @AttributeId varchar(50),
     @PersonId varchar(50)
as
begin
	
	if(@UserType='Supplier')
	begin
		Update AttributeValues Set AttributeValue=@AttributeId where AttributeId=9 and OwnerEntityId=@PersonId

		Update A set A.AttributeValue=RTRIM(S.EditRights)
		from AttributeValues A
		inner join  SupplierAccess S on A.OwnerEntityID=S.PersonId 
		Where S.PersonId=@PersonId and S.SupplierId=@AttributeId and A.AttributeID=22

		Update A set A.AttributeValue=RTRIM(S.BannerAccess)
		from AttributeValues A
		inner join  SupplierAccess S on A.OwnerEntityID=S.PersonId 
		Where S.PersonId=@PersonId and S.SupplierId=@AttributeId and A.AttributeID=20

	end
	else if(@UserType='Chain')
	begin
		Update AttributeValues Set AttributeValue=@AttributeId where AttributeId=17 and OwnerEntityId=@PersonId

		Update A set A.AttributeValue=RTRIM(S.EditRights)
		from AttributeValues A
		inner join  RetailerAccess S on A.OwnerEntityID=S.PersonId 
		Where S.PersonId=@PersonId and S.ChainId=@AttributeId and A.AttributeID=22

		Update A set A.AttributeValue=RTRIM(S.BannerAccess)
		from AttributeValues A
		inner join  RetailerAccess S on A.OwnerEntityID=S.PersonId 
		Where S.PersonId=@PersonId and S.ChainId=@AttributeId and A.AttributeID=20

	end

end
GO
