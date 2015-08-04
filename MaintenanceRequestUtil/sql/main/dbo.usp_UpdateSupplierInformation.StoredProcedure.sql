USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateSupplierInformation]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  Procedure [dbo].[usp_UpdateSupplierInformation]
     @SupplierId varchar(50),
     @PersonId varchar(50)
as
begin
	
	Update AttributeValues Set AttributeValue=@SupplierId where AttributeId=9 and OwnerEntityId=@PersonId

	Update A set A.AttributeValue=RTRIM(S.EditRights)
	from AttributeValues A
	inner join  SupplierAccess S on A.OwnerEntityID=S.PersonId and A.AttributeID=22
	Where S.PersonId=@PersonId and S.SupplierId=@SupplierId

	Update A set A.AttributeValue=RTRIM(S.BannerAccess)
	from AttributeValues A
	inner join  SupplierAccess S on A.OwnerEntityID=S.PersonId and A.AttributeID=20
	Where S.PersonId=@PersonId and S.SupplierId=@SupplierId

end
GO
