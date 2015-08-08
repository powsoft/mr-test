USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[insert_usp_Memberships]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [insert_usp_Memberships]
CREATE PROCEDURE [dbo].[insert_usp_Memberships]
	
	@Type varchar(20),
	@ClusterID varchar(20),
	@StoreID varchar(20),
	@OldStoreId varchar(20),
	@OwnerEntityID  varchar(30),
	@membershipTypeID varchar(10)
AS
BEGIN
 
 if(@Type='Insert')
 BEGIN
		
		insert into Memberships
							(	
								MembershipTypeID
								,OrganizationEntityID
								,MemberEntityID 
								,ChainID
								,DateTimeCreated
								,LastUpdateUserID
								,DateTimeLastUpdate
								,ownerEntityID
							) 
						VALUES
							(
								 @membershipTypeID
								,@ClusterID
								,@StoreID
								,@OwnerEntityID
								,getdate()
								,@OwnerEntityID
								,getdate()
								,@OwnerEntityID
							)	
END
--ELSE iF(@Type='Update')
--BEGIN
--		Update Memberships
--		SET MemberEntityID=@StoreID,ChainID=@OwnerEntityID, LastUpdateUserID=@OwnerEntityID,DateTimeLastUpdate=getdate()
--		where MembershipTypeID=1  and OrganizationEntityID=@ClusterID and MemberEntityID=@OldStoreId
--END
END
GO
