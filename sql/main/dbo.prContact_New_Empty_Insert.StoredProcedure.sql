USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prContact_New_Empty_Insert]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prContact_New_Empty_Insert]
@OwnerEntityID int,
@UpdateUserID int=null

as

if @UpdateUserID is null
	set @UpdateUserID = 2

--select top 100 * from addresses
insert into ContactInfo
(OwnerEntityID, LastUpdateUserID)
values(@OwnerEntityID, @UpdateUserID)

return
GO
