USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_ProductCategories]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPDI_PriceBook_Master_Automated_ProductCategories]
@chainid int
as

--declare @chainid int = 75130

update g set g.datatruechainid = chainid 
from datatrue_edi.dbo.Temp_PDI_ItemGrp g
inner join chains c
on LTRIM(rtrim(g.ChainIdentifier)) = LTRIM(rtrim(c.chainidentifier))
and g.DataTrueChainID is null

declare @countofcategories int=0

select @countofcategories = COUNT(*) from ProductCategories where OwnerEntityID = @chainid

if @countofcategories = 0
	begin

		select chainidentifier, cast(grouplevel as int) as grouplevel, cast(groupid as int) as groupid, vendorname, groupdescription as categoryidentifier, cast(ParentGroupID as int) as ParentGroupID,
		CAST(null as nvarchar(255)) as parentcategoryidentifier
		into #tempcategories
		--select *
		from datatrue_edi.dbo.Temp_PDI_ItemGrp
		where recordstatus = 0
		and DataTrueChainID = @chainid
		and CHARINDEX('peg', ParentGroupID) < 1
		and CHARINDEX('donuts', ParentGroupID) < 1
		and CHARINDEX('GroupDescription', GroupDescription) < 1
		order by cast(grouplevel as int), cast(groupid as int)

		update t set t.parentcategoryidentifier = g.GroupDescription
		--select g.grouplevel, t.grouplevel, *
		from #tempcategories t
		inner join datatrue_edi.dbo.Temp_PDI_ItemGrp g
		on t.ParentGroupID = g.groupid
		and g.vendorname = t.vendorname
		and g.ChainIdentifier = t.chainidentifier
		--and ISNUMERIC(g.grouplevel) > 0
		--and ISNUMERIC(t.grouplevel) > 0
		and g.GroupLevel = 1
		and t.grouplevel = 2
		--where CHARINDEX('GroupDescription', g.GroupDescription) < 1
		--and ISNUMERIC(g.grouplevel) > 0
		--and ISNUMERIC(t.grouplevel) > 0

		update t set t.parentcategoryidentifier = g.GroupDescription
		--select *
		from #tempcategories t
		inner join datatrue_edi.dbo.Temp_PDI_ItemGrp g
		on t.ParentGroupID = g.groupid
		and g.vendorname = t.vendorname
		and g.ChainIdentifier = t.chainidentifier
		and g.GroupLevel = 2
		and t.grouplevel = 3

		INSERT INTO [DataTrue_EDI].[dbo].[Load_ProductCategories]
				   ([ChainIdentifier]
				   ,[OwnerIdentifier]
				   ,[OwnerEntityTypeID]
				   ,[CategoryIdentifier]
				   ,[CategoryParentIdentifier]
				   ,[CategoryDescription]
				   ,[LoadStatus]
				   ,[Order]
				   ,[GroupLevelID]
				   ,[GroupID])
		select ChainIdentifier,ChainIdentifier, 2, categoryidentifier, parentcategoryidentifier, categoryidentifier, 0, grouplevel, grouplevel, groupid 
		--select * 
		from #tempcategories
		order by cast(grouplevel as int), cast(groupid as int)

--*******************************************************Run Util_LoadProductCategories*******************************************

		exec dbo.prUtil_Load_ProductCategories_PDI
	end

/*

select *
from [DataTrue_EDI].[dbo].[Load_ProductCategories]
where 1 = 1
and loadstatus = 0

select *
from chains
where chainidentifier = 'ONCUE'

select *
from datatrue_edi.dbo.Temp_PDI_ItemGrp
where datatruechainid is null

*/

return
GO
