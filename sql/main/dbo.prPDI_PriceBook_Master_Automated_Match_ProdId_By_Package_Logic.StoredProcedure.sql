USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_Match_ProdId_By_Package_Logic]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prPDI_PriceBook_Master_Automated_Match_ProdId_By_Package_Logic]
@chainid int,
@supplierid int,
@use_upc_source tinyint  = 0
as

if @use_upc_source = 0 
begin 
	--Apply  logic  for Temp_PDI_ItemPKG and use Temp_PDI_ItemPKG as a source

	---Try to get  prodid for using Package logic
	update u2 set u2.DataTrueProductID = u.DataTrueProductID
	--select *
	from datatrue_edi.dbo.Temp_PDI_ItemPKG u
	inner join datatrue_edi.dbo.Temp_PDI_ItemPKG u2
	on ltrim(rtrim(u.PDIItemNumber)) = ltrim(rtrim(u2.PDIItemNumber))
	and u.DataTrueProductID is not null
	and u2.DataTrueProductID is null
	and CAST(u.datetimereceived as date) = CAST(u2.datetimereceived as date)
	--EZaslonkin: join PackageCodeCompare table instead condiotions below 
	--and 
	--(
	--ltrim(rtrim(u2.PackageCode_Scrubbed)) in ('PPK20','PPK24','PPK6','PPK18','PPK3','PPK28','PPK10','PPK15', 'PPK12','PPK8','PPK500','PPK1000') and ltrim(rtrim(u.PackageCode_Scrubbed)) = 'Single'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) in ('PPK20','PPK24','PPK6','PPK18','PPK3','PPK28','PPK10','PPK15', 'PPK12','PPK8','PPK500','PPK1000') and ltrim(rtrim(u.PackageCode_Scrubbed)) = 'EACH'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK3-8' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '8PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK6-4' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '4PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK4-6' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '6PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK2-12' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '12PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK2-9' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '9PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK24' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '24PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK30' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '30PK'
	--)  
		and u.DataTrueChainID = @chainid and u.DataTrueSupplierID = @supplierid and u2.DataTrueChainID = @chainid and u2.DataTrueSupplierID = @supplierid
	inner join  datatrue_edi.dbo.PackageCodeCompare pcg_com 
		on  ltrim(rtrim(u2.PackageCode_Scrubbed)) = pcg_com.MasterPackageCode
			and case when ltrim(rtrim(u.PackageCode_Scrubbed)) = 'EA' then 'EACH' else ltrim(rtrim(u.PackageCode_Scrubbed)) end  
				= pcg_com.DetailPackageCode
end
else 
begin
	--Apply  logic  for Temp_PDI_ItemPKG and use Temp_PDI_UPC as a source
	---Try to get  prodid for using Package logic
	update u2 set u2.DataTrueProductID = u.DataTrueProductID
	--select *
	from datatrue_edi.dbo.temp_PDI_UPC u
	inner join datatrue_edi.dbo.Temp_PDI_ItemPKG u2
	on ltrim(rtrim(u.PDIItemNumber)) = ltrim(rtrim(u2.PDIItemNumber))
	and u.DataTrueProductID is not null
	and u2.DataTrueProductID is null
	and CAST(u.DateTimeCreated as date) = CAST(u2.datetimereceived as date)
	--EZaslonkin: join PackageCodeCompare table instead condiotions below 
	--and 
	--(
	--ltrim(rtrim(u2.PackageCode_Scrubbed)) in ('PPK20','PPK24','PPK6','PPK18','PPK3','PPK28','PPK10','PPK15', 'PPK12','PPK8','PPK500','PPK1000') and ltrim(rtrim(u.PackageCode_Scrubbed)) = 'Single'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) in ('PPK20','PPK24','PPK6','PPK18','PPK3','PPK28','PPK10','PPK15', 'PPK12','PPK8','PPK500','PPK1000') and ltrim(rtrim(u.PackageCode_Scrubbed)) = 'EACH'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK3-8' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '8PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK6-4' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '4PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK4-6' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '6PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK2-12' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '12PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK2-9' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '9PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK24' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '24PK'
	--or ltrim(rtrim(u2.PackageCode_Scrubbed)) = 'PPK30' and ltrim(rtrim(u.PackageCode_Scrubbed)) = '30PK'
	--)  
		and u.DataTrueChainID = @chainid and u.DataTrueSupplierID = @supplierid and u2.DataTrueChainID = @chainid and u2.DataTrueSupplierID = @supplierid
	inner join  datatrue_edi.dbo.PackageCodeCompare pcg_com 
		on  ltrim(rtrim(u2.PackageCode_Scrubbed)) = pcg_com.MasterPackageCode
			and case when ltrim(rtrim(u.PackageCode_Scrubbed)) = 'EA' then 'EACH' else ltrim(rtrim(u.PackageCode_Scrubbed)) end  
				= pcg_com.DetailPackageCode

	
end

return
GO
