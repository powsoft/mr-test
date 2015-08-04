USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_ClusterMemberships]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_ClusterMemberships]
as
/*

select top 100 *  from Load_StoreClusterMemberships

truncate table Memberships

select distinct areanumber from Load_StoreClusterMemberships
6
*/

declare @MyID int
set @MyID = 7604

declare @rec cursor
declare @storeid int
declare @string varchar(50)

set @rec = CURSOR local fast_forward FOR
	select s.storeid, l.AreaNumber
	from DataTrue_EDI..Load_StoreClusterMemberships l
	inner join .Stores s
	on cast(l.StoreNumber as int) = cast(s.storeidentifier as int)
	where isnumeric(l.StoreNumber) > 0
	
open @rec

fetch next from @rec into @storeid, @string

while @@fetch_status = 0
	begin

		insert into Memberships 
		(OrganizationEntityID, MemberEntityID, MembershipName, LastUpdateUserID)
		Values(6, @storeid, @string, 2)

	fetch next from @rec into @storeid, @string
	end
	
close @rec
deallocate @rec

/*
select distinct region from Load_StoreClusterMemberships
9

declare @rec cursor
declare @storeid int
declare @string varchar(50)
*/

set @rec = CURSOR local fast_forward FOR
	select s.storeid, l.Region
	from DataTrue_EDI..Load_StoreClusterMemberships l
	inner join Stores s
	on cast(l.StoreNumber as int) = cast(s.storeidentifier as int)
	where isnumeric(l.StoreNumber) > 0
	
open @rec

fetch next from @rec into @storeid, @string

while @@fetch_status = 0
	begin

		insert into Memberships 
		(OrganizationEntityID, MemberEntityID, MembershipName, LastUpdateUserID)
		Values(9, @storeid, @string, 2)

	fetch next from @rec into @storeid, @string
	end
	
close @rec
deallocate @rec

/*
select distinct District from Load_StoreClusterMemberships
11

declare @rec cursor
declare @storeid int
declare @string varchar(50)
*/

set @rec = CURSOR local fast_forward FOR
	select s.storeid, l.District
	from DataTrue_EDI..Load_StoreClusterMemberships l
	inner join Stores s
	on cast(l.StoreNumber as int) = cast(s.storeidentifier as int)
	where isnumeric(l.StoreNumber) > 0
	
open @rec

fetch next from @rec into @storeid, @string

while @@fetch_status = 0
	begin

		insert into Memberships 
		(OrganizationEntityID, MemberEntityID, MembershipName, LastUpdateUserID)
		Values(11, @storeid, @string, 2)

	fetch next from @rec into @storeid, @string
	end
	
close @rec
deallocate @rec

return
GO
