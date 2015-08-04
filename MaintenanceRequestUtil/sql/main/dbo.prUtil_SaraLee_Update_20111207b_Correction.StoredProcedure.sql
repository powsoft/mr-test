USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_SaraLee_Update_20111207b_Correction]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_SaraLee_Update_20111207b_Correction]
as

select * into Import.dbo.productprices_20111207BeforeFewProductCleanupForSaraLee from productprices

select * from import.dbo.SaraLeeUpdate20111206

select * from SuppliersSetupData where [12DigitUPC] = '050400435452'
select * from SuppliersSetupData where [UPC] = '07294561178' --07294560153'

select * from import.dbo.SaraLeeUpdate20111206 
where [UPC]= '07294560153'

select distinct PriceZone from SuppliersSetupData
where 1 = 1
and SupplierID = 41465
--05040043545 16950
select storeid 
from SuppliersSetupData 
where ProductID =16950
--and PriceZone =

select RuleCost - Isnull(PromoAllowance,0), ReportedCost, *
from StoreTransactions
where ProductID = 16950
and SupplierID = 41465
and StoreID in
(select distinct StoreID from SuppliersSetupData where PriceZone = 'St. Louis') --Springfield/Peoria')
and CAST(saledatetime as date) = '12/5/2011'

select RuleCost - Isnull(PromoAllowance,0), ReportedCost, *
from StoreTransactions
where ProductID =16417
and SupplierID = 41465
and StoreID in
(select distinct StoreID from SuppliersSetupData where PriceZone = 'St. Louis') --Springfield/Peoria')
and CAST(saledatetime as date) = '12/5/2011'

select RuleCost - Isnull(PromoAllowance,0), ReportedCost, *
from StoreTransactions
where ProductID =16709
and SupplierID = 41465
and CAST(saledatetime as date) = '12/5/2011'
and StoreID in
(select distinct StoreID from SuppliersSetupData where PriceZone = 'St. Louis') --Springfield/Peoria')



--************************************************************************************************
select * from SuppliersSetupData where [12DigitUPC] = '050400435452'
select * from SuppliersSetupData where [UPC] = '05040043545' --16950
select * from SuppliersSetupData where [UPC] = '07294560153' --16417
select * from SuppliersSetupData where [UPC] = '07294561178' --16709

select * 
--delete
from ProductPrices
where ProductID = 16950
and StoreID in
(select distinct StoreID from SuppliersSetupData where PriceZone = 'St. Louis') 
and ProductPriceTypeID = 8
and ActiveStartDate = '2011-12-05 00:00:00.000'

select * 
--delete
from ProductPrices
where ProductID = 16417
and StoreID in
(select distinct StoreID from SuppliersSetupData where PriceZone = 'St. Louis') --Springfield/Peoria')
and ProductPriceTypeID = 8
and ActiveStartDate = '2011-12-05 00:00:00.000'

--6063 select * from stores where storeidentifier = '6063'
select * 
--update p set UnitPrice = .29
from ProductPrices p
where ProductID = 16709
and StoreID = 40999
and ProductPriceTypeID = 8
and ActiveStartDate = '2011-12-05 00:00:00.000'

select * 
--delete
from ProductPrices
where ProductID = 16709
and StoreID in
(select distinct StoreID from SuppliersSetupData where PriceZone = 'Springfield/Peoria')
and ProductPriceTypeID = 8
and ActiveStartDate = '2011-12-05 00:00:00.000'


INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
	select distinct 8
	,16709
	,40393
	,StoreID
	,0
	,41465
	,.29
	,'12/5/2011'
	,'12/25/2011'
	,2
	from SuppliersSetupData where PriceZone = 'Springfield/Peoria'
	
select distinct storeid	from SuppliersSetupData where PriceZone = 'Springfield/Peoria'

--same as last product at store 40999

select Saledatetime, RuleCost - Isnull(PromoAllowance,0), ReportedCost, *
from StoreTransactions
where ProductID =16709
and CAST(saledatetime as date) >= '12/4/2011'
and SupplierID = 41465
and storeid = 40999
and StoreID in
(select distinct StoreID from SuppliersSetupData where PriceZone = 'Springfield/Peoria')
and CAST(saledatetime as date) = '12/5/2011'




INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
	select distinct 8
	,16709
	,40393
	,40999
	,0
	,41465
	,.29
	,'12/5/2011'
	,'12/25/2011'
	,2
	
--***************************************************************************************
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
and ProductPriceTypeID = 8
order by ProductID, storeid




/*
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
*/
declare @allowancetoadd money
declare @startdatetoadd date
declare @enddatetoadd date

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
--/*
	select *  from ProductPrices
	where StoreID = @storeid
	and ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid
	and productpricetypeid = 8
--*/	
/*	
	--select @allowancetoadd = UnitPrice, @startdatetoadd = ActiveStartDate, @enddatetoadd = ActiveLastDate
	select *  
	from import.dbo.productprices_20111206b_BeforeSaraLeeUpdate
	where StoreID = @storeid
	and ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid
	and productpricetypeid = 8
	and cast(ActivelastDate as date) <> CAST('12/4/2011' as date)
	and cast(ActiveStartDate as date) <> CAST('12/5/2011' as date)
*/	
/*     
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
           ,@allowancetoadd
           ,@retail
           ,@startdatetoadd
           ,@enddatetoadd
           ,2)

*/


	
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


alter table import.dbo.SARALEE104BannerPromos
add dtproductid int
--upc12 nvarchar(50)

select distinct LEN(upc11) from import.dbo.SARALEE104BannerPromos

select * from import.dbo.SARALEE104BannerPromos

/*
declare @rec cursor
declare @upc nvarchar(50)
declare @upc11 nvarchar(50)
declare @upc12 nvarchar(50)
declare @recordid int
declare @checkdigit char(1)
*/

set @rec = CURSOR local fast_forward FOR
	select distinct ltrim(rtrim(UPC11)) from  import.dbo.SARALEE104BannerPromos
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
	 
	 update import.dbo.SARALEE104BannerPromos set upc12 = @upc11 + @CheckDigit
	 where upc11 = @upc
	
		fetch next from @rec into @upc
--fetch next from @rec into @recordid, @upc
	end
	
close @rec
deallocate @rec

select *
--update p set dtproductid = i.productid
from import.dbo.SARALEE104BannerPromos p
inner join ProductIdentifiers i
on LTRIM(rtrim(upc12)) = LTRIM(rtrim(IdentifierValue))

select * from import.dbo.SARALEE104BannerPromos order by dtproductid

/*
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
declare @allowancetoadd money
declare @startdatetoadd date
declare @enddatetoadd date
declare @upc11 nvarchar(50)
*/

set @rec2 = CURSOR local fast_forward FOR
	select dtproductid, upc11 from import.dbo.SARALEE104BannerPromos where dtProductId is not null

open @rec2



	fetch next from @rec2 into
	@productid, @upc11

	
while @@FETCH_STATUS = 0
	begin
--/*
	select @upc11, *  from ProductPrices
	where ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid
	and productpricetypeid = 8
	order by storeid
--*/	
	
	fetch next from @rec2 into
	@productid, @upc11

	
	end

close @rec2
deallocate @rec2



/*
'07294560153','
05040021531','
07294560136','
05040043445','
05040043556','
07294561177','
07294561178','
07294560153','
07294560136','
05040021531','
07294561177','
07294561178','
07294560136','
07294560154','
07294560136','
07294560154','
07294570544','
07294560134','
05040021531','
07294561177','
07294561178','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
07294560154','
07294570544','
07294560134','
05040021531','
07294561177','
07294561178','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
07294560154','
07294570544','
07294560134','
05040021531','
07294561177','
07294561178','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
07294570544','
07294560134','
05040021531','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
07294570544','
05040021531','
07294560134','
07294560154','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
07294561177','
07294561178','
07294570544','
05040021531','
07294560134','
07294560154','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
07294561177','
07294561178','
07294570544','
05040021531','
07294560134','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
07294561177','
07294561178','
07294570544','
05040021531','
07294560134','
07294571706','
07294571589','
07294571588','
07294535066','
07294535069','
07294535070','
*/


return
GO
