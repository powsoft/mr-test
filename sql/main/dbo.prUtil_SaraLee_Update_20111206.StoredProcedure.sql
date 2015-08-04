USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SaraLee_Update_20111206]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_SaraLee_Update_20111206]
as

select * from import.dbo.SaraLeeUpdate20111206

select * from SuppliersSetupData where [12DigitUPC] = '050400435452'

alter table import.dbo.SaraLeeUpdate20111206
add upc12 nvarchar(50),
dtstoreid int,
dtproductid int,
dtbanner nvarchar(50)


--STORES

select distinct custom1 from stores

update import.dbo.SaraLeeUpdate20111206 set dtbanner = 'Shop N Save Warehouse Foods Inc'

select *
--update c set c.dtstoreid  = s.storeid
from import.dbo.SaraLeeUpdate20111206 c
inner join stores s
on cast(c.storenumber as int) = cast(s.StoreIdentifier as int)
and LTRIM(rtrim(c.dtbanner)) = LTRIM(rtrim(s.Custom1))


--PRODUCTS
--*************************************************************************
select * from  import.dbo.SaraLeeUpdate20111206
select distinct ltrim(rtrim(UPC)) from  import.dbo.SaraLeeUpdate20111206
update import.dbo.SaraLeeUpdate20111206 set  upc12 = upc where LEN(upc) = 12

declare @rec cursor
declare @upc nvarchar(50)
declare @upc11 nvarchar(50)
declare @upc12 nvarchar(50)
declare @recordid int
declare @checkdigit char(1)

set @rec = CURSOR local fast_forward FOR
	select distinct Left(ltrim(rtrim(UPC)), 11) from  import.dbo.SaraLeeUpdate20111206 where LEN(ltrim(rtrim(UPC))) = 12
	--select distinct ltrim(rtrim(UPC)) from  import.dbo.SaraLeeUpdate20111206 where LEN(ltrim(rtrim(UPC))) = 11
open @rec

fetch next from @rec into @upc
--fetch next from @rec into @recordid, @upc

while @@FETCH_STATUS = 0
	begin

	set @checkdigit = ''
	set @upc11 = @UPC
	
	exec datatrue_main.[dbo].[prUtil_UPC_GetCheckDigit]
	 @upc11,
	 @CheckDigit OUT
	 
	 update import.dbo.SaraLeeUpdate20111206 set upc12 = @upc11 + @CheckDigit
	 where upc = @upc
	
		fetch next from @rec into @upc
--fetch next from @rec into @recordid, @upc
	end
	
close @rec
deallocate @rec
--*************************************************************************


select *
--update c set c.dtproductid = s.productid
from import.dbo.SaraLeeUpdate20111206 c
inner join productidentifiers s
on LTRIM(rtrim(c.upc12)) = LTRIM(rtrim(s.identifiervalue))


select * into import.dbo.productprices_20111206b_BeforeSaraLeeUpdate from productprices

declare @rec2 cursor
declare @storeid int
declare @productid int
declare @supplierid int = 41465
declare @brandid int = 0
declare @cost money
declare @retail money
declare @allowance money
declare @startdate date
declare @enddate date

set @rec2 = CURSOR local fast_forward FOR
	select dtstoreid, dtproductid, Cost, Retail, Allowance, startDate, Enddate
	from import.dbo.SaraLeeUpdate20111206

open @rec2



	fetch next from @rec2 into
	@storeid
	,@productid
	,@cost
	,@retail
	,@allowance
	,@startdate
	,@enddate
	
while @@FETCH_STATUS = 0
	begin

	delete from ProductPrices
	where StoreID = @storeid
	and ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid
--/*	
	INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
     VALUES
           (3
           ,@productid
           ,40393
           ,@storeid
           ,@brandid
           ,@supplierid
           ,@cost
           ,@retail
           ,'11/1/2011'
           ,'12/31/2025'
           ,2)
 	INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
     VALUES
           (5
           ,@productid
           ,40393
           ,@storeid
           ,@brandid
           ,@supplierid
           ,@cost
           ,@retail
           ,'11/1/2011'
           ,'12/31/2025'
           ,2)          
           
	INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
     VALUES
           (8
           ,@productid
           ,40393
           ,@storeid
           ,@brandid
           ,@supplierid
           ,@allowance
           ,@retail
           ,@startdate
           ,@enddate
           ,2)

--*/


	
	fetch next from @rec2 into
	@storeid
	,@productid
	,@cost
	,@retail
	,@allowance
	,@startdate
	,@enddate
	
	end

close @rec2
deallocate @rec2


--verify
select *
from import.dbo.SaraLeeUpdate20111206
order by dtProductID, dtstoreid

select p.*
from import.dbo.SaraLeeUpdate20111206 c
inner join ProductPrices p
on c.dtstoreid = p.StoreID
and c.dtproductid = p.ProductID
order by ProductID, storeid

return
GO
