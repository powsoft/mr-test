USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prAddress_New_Empty_Insert]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prAddress_New_Empty_Insert]
@OwnerEntityID int,
@UpdateUserID int=null

as

if @UpdateUserID is null
	set @UpdateUserID = 2

--select top 100 * from addresses
insert into Addresses
(OwnerEntityID, LastUpdateUserID)
values(@OwnerEntityID, @UpdateUserID)

return
GO
