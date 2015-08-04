USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GetEntityInformationFromEntityID]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GetEntityInformationFromEntityID]
@entityid int
/*
prUtil_GetEntityInformationFromEntityID 7 --24117
*/
as

select *
from SystemEntities s
inner join EntityTypes t
on s.EntityTypeID = t.EntityTypeID
where s.EntityId = @entityid

return
GO
