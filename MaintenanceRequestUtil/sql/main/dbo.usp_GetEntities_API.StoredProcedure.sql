USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetEntities_API]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetEntities_API]
@EntityTypeId as varchar(2),
@EntityId as varchar(10)
-- exec usp_GetEntities_API 2,40393
as
Begin
	if(@EntityTypeId=2)
		select EntityId, LEFT(C.ChainName, 5) as EntityName   
		from SystemEntities S
		inner join Chains  C on C.ChainId=S.EntityId
		where EntityTypeID =2 and LEN(EntityId)>3 and EntityId like case when @EntityId='-1' then '%' else @EntityId end
		order by 1
	
	else if (@EntityTypeId=3)

		select EntityId,LEFT(SP.FirstName + ' ' + SP.LastName, 5) as EntityName
		from SystemEntities S
		inner join Persons SP on SP.PersonId=S.EntityId
		where EntityTypeID =3 and LEN(EntityId)>3 and EntityId like case when @EntityId='-1' then '%' else @EntityId end
		order by 1
		
	else if (@EntityTypeId=5)

		select EntityId,LEFT(SP.SupplierName, 5) as EntityName
		from SystemEntities S
		inner join Suppliers SP on SP.SupplierID=S.EntityId
		where EntityTypeID =5 and LEN(EntityId)>3 and EntityId like case when @EntityId='-1' then '%' else @EntityId end
		order by 1

	else if (@EntityTypeId=11)

		select EntityId, LEFT(M.ManufacturerName, 5) as EntityName  from SystemEntities S
		inner join Manufacturers M on M.ManufacturerID=S.EntityId
		where EntityTypeID=11 and LEN(EntityId)>3 and EntityId like case when @EntityId='-1' then '%' else @EntityId end
		order by 1
end
GO
