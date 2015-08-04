USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SuperValu_Inventory_Count_Import_20111205]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_SuperValu_Inventory_Count_Import_20111205]
as


select * from import.dbo.SVINVCOUNT20111205

select distinct LEN(materialnumber) from import.dbo.SVINVCOUNT20111205

select *

from import.dbo.SVINVCOUNT20111205 c
inner join ProductIdentifiers i
on SUBSTRING(LTRIM(rtrim(materialnumber)), 2, 10) = SUBSTRING(LTRIM(rtrim(IdentifierValue)), 2, 10)
--on right(LTRIM(rtrim(materialnumber)),11) = right(LTRIM(rtrim(IdentifierValue)),11)

alter table import.dbo.SVINVCOUNT20111205
add storeid int,
productid int,
dtbanner nvarchar(50)

select distinct Name from import.dbo.SVINVCOUNT20111205

select *

from import.dbo.SVINVCOUNT20111205 c
inner join stores s
on CAST(c.storenumber as int) = CAST(s.StoreIdentifier as int)
and s.ChainID = 40393

select *

from import.dbo.SVINVCOUNT20111205 c
inner join stores s
on CAST(c.storenumber as int) = CAST(s.custom2 as int)
and s.ChainID = 40393



return
GO
