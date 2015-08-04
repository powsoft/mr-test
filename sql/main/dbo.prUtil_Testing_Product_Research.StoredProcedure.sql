USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Product_Research]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Testing_Product_Research]
as

select LTRIM(rtrim(identifiervalue)), COUNT(productid)
from ProductIdentifiers
group by LTRIM(rtrim(identifiervalue))
having COUNT(productid) > 1
order by COUNT(productid) desc


select *
from Products
where ProductID in
(
select productid from ProductIdentifiers where LTRIM(rtrim(identifiervalue)) in

	(
	select LTRIM(rtrim(identifiervalue))
	from ProductIdentifiers
	group by LTRIM(rtrim(identifiervalue))
	having COUNT(productid) > 1
	)
)
order by ProductID desc

return
GO
