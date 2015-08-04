USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prPDI_PriceBook_Master_Automated_Product_Validation_Duplicates_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prPDI_PriceBook_Master_Automated_Product_Validation_Duplicates_PRESYNC_20150329]
@chainid int,
@supplierid int
as
declare @chainidentifier nvarchar(50)
declare @chainname nvarchar(255)
declare @suppliername nvarchar(255)
declare @supplierIdentifier nvarchar(50)
declare @errormessage nvarchar(max)
declare @errormessage_extarnal nvarchar(max)
declare @records_count int  = 0
declare @email_subject nvarchar(400)
declare @testmode varchar(1000) = '' -- THIS IS A TEST - '
declare @filedate date
declare @notcalidrecords varchar(MAX)


select @chainidentifier = chainidentifier,   
	@chainname = ChainName
from chains 
where ChainID = @chainid

select 	@suppliername = SupplierName
from Suppliers
where supplierid = @supplierid


select @supplierIdentifier = LTRIM(rtrim(TranslationValueOutside)) 
from [DataTrue_EDI].[dbo].[TranslationMaster] 
where isnumeric(TranslationCriteria1) > 0 
and TranslationTypeID = 26 
and CAST(TranslationCriteria1 as int) = @supplierid
and TranslationChainID = @chainid


set @errormessage = ''
set @email_subject = @testmode + 'PDI PriceBook Import Produce Duplicates  for chain name  ' + @chainname + '('+@chainidentifier+') and supplier name ' + @suppliername+'('+@supplierIdentifier+')'


			
--StoreSetup 
select ProductID, StoreID, COUNT(*)
from storesetup 
where chainid = @chainid 
	and supplierid = @supplierid
group by  ProductID, StoreID	
having COUNT(*) > 1
			
set @records_count = @@ROWCOUNT

if @records_count > 0 
begin

	set  @errormessage = @errormessage + '	### There are duplicates in StoreSetup. Please see query: 
	select ProductID, StoreID, COUNT(*)
	from storesetup 
	where chainid = '+cast(@chainid as nvarchar(15)) +'
		and supplierid = '+cast(@supplierid as nvarchar(15)) +'
	group by  ProductID, StoreID	
	having COUNT(*) > 1
	====================================================================	
	
	'
end 

--SupplierPackage
select  ProductID, VIN, OwnerPDIItemNo, OwnerPackageIdentifier, COUNT(*)
from SupplierPackages 
where ownerentityid = @chainid and supplierid = @supplierid
group  by ProductID, VIN, OwnerPDIItemNo, OwnerPackageIdentifier
having COUNT(*) > 1

set @records_count = @@ROWCOUNT

if @records_count > 0 
begin

	set  @errormessage = @errormessage + '	### There are duplicates in SupplierPackages. Please see query: 
	select  ProductID, VIN, OwnerPDIItemNo, OwnerPackageIdentifier, COUNT(*)
	from SupplierPackages 
	where ownerentityid = '+cast(@chainid as nvarchar(15)) +' and supplierid = '+cast(@supplierid as nvarchar(15)) +'
	group  by ProductID, VIN, OwnerPDIItemNo, OwnerPackageIdentifier
	having COUNT(*) > 1
	====================================================================	
	
	'
end 

--Product Prices
select  ProductPriceTypeID, ProductID,  supplierpackageid ,StoreID, ActiveStartDate, COUNT(*)
from ProductPrices where chainid = @chainid and supplierid = @supplierid
and ProductPriceTypeID in (8,11,3)
group by ProductPriceTypeID, ProductID,  supplierpackageid ,StoreID,ActiveStartDate
having COUNT(*) > 1 
order by  1

set @records_count = @@ROWCOUNT

if @records_count > 0 
begin

	set  @errormessage = @errormessage + '	### There are duplicates in ProductPrices. Please see query: 
	select  ProductPriceTypeID, ProductID,  supplierpackageid ,StoreID, ActiveStartDate, COUNT(*)
	from ProductPrices 
	where chainid = '+cast(@chainid as nvarchar(15)) +' and supplierid = '+cast(@supplierid as nvarchar(15)) +'
		and ProductPriceTypeID in (8,11,3)
	group by ProductPriceTypeID, ProductID,  supplierpackageid ,StoreID,ActiveStartDate
	having COUNT(*) > 1 
	order by  1
	====================================================================	
	
	'
end 




SET @errormessage = @testmode + @errormessage

if @errormessage <> ''
begin 
	--print @email_subject
	--print len(@errormessage)
	--print @errormessage
	exec dbo.prSendEmailNotification_PassEmailAddresses @email_subject
		,@errormessage
		--,'DataTrue System', 0, 'ezaslonkin@sphereconsultinginc.com;charlie.clark@icucsolutions.com'
		,'DataTrue System', 0, 'datatrueit@icucsolutions.com; gilad.keren@icucsolutions.com;vishal.gupta@icucsolutions.com;gagan.deep@icucsolutions.com'		
		
end 


return
GO
