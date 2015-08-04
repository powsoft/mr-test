USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetInboundPOSTransactions_ForJEWELandSHAWS_Debug20130922]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetInboundPOSTransactions_ForJEWELandSHAWS_Debug20130922]
/*
RoleID 7415
update DataTrue_EDI..Inbound852Sales set RecordStatus = 0
select * from DataTrue_EDI..Inbound852Sales where RecordStatus = 0 and banner = 'SS' SVEC.20111115121330_SPLIT7
select * from DataTrue_EDI..Inbound852Sales where RecordStatus = 0 and filename = 'SVEC.20111117133423_SPLIT86'
select distinct banner from DataTrue_EDI..Inbound852Sales where RecordStatus = 0
update DataTrue_EDI..Inbound852Sales set recordstatus = -7 where RecordStatus = 0 and Banner = 'SS'
select top 100 * from  DataTrue_EDI..Inbound852Sales
select distinct workingstatus from StoreTransactions_Working
select *  from StoreTransactions_Working where workingstatus = 0
update StoreTransactions_Working set workingstatus = 11 where workingstatus = 0
ABS.20111123065255_SPLIT4
SVEC.20111123121147_SPLIT7
SVEC.20111123121147_SPLIT8
select * from suppliers where ediname in ('DSW', 'TTT')
*/
As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @continue bit=1
set @MyID = 7415 


declare @rec cursor
declare @date date
declare @SBTNO nvarchar(50)
declare @banner nvarchar(100)
declare @storeid int

select OwnerEntityId into #livesuppliers from AttributeValues where AttributeID = 25 and CAST(attributevalue as date) <= dateadd(day, -3, getdate())

--Specal DSW and TTT Go-Live UPC code
drop table import.dbo.DSWandTTTUPCsGoingLiveAtJewel
--select * from suppliers where supplierid in (41746,42148,40578,44188)
select distinct identifiervalue as UPC into import.dbo.DSWandTTTUPCsGoingLiveAtJewel
from ProductIdentifiers i
inner join storesetup s
on i.ProductID = s.ProductID
and s.SupplierID in (Select OwnerEntityId from #livesuppliers)
--and s.SupplierID in (select OwnerEntityId from AttributeValues where AttributeID = 25 and CAST(attributevalue as date) <= dateadd(day, -3, getdate()))
--and s.SupplierID in (41746,42148,40578,44188)
where StoreID in
	(
	select distinct storeid 
	from storesetup
	where 1 = 1
	and s.SupplierID in (Select OwnerEntityId from #livesuppliers)
	--and s.SupplierID in (select OwnerEntityId from AttributeValues where AttributeID = 25 and CAST(attributevalue as date) <= dateadd(day, -3, getdate()))
	--and SupplierID in (41746,42148,40578,44188)
	and cast(dateadd(day, -3, getdate()) as date) between ActiveStartDate and ActiveLastDate
	--and '10/8/2012' between ActiveStartDate and ActiveLastDate
	and StoreID in
		(
		select storeid
		from stores 
		where Custom3 = 'SV_JWL'
		)
	)
--Special Source Interlink Go-Live UPC code
set @rec = cursor local fast_forward for
	select Banner, SBTNo, StartDate
	--select *
	from Import.dbo.SI_JWL
	--where Banner = 'FARM FRESH MARKETS'
	--where Banner = 'SHOPPERS FOOD AND PHARMACY'
	order by StartDate

open @rec 
	
fetch next from @rec into @banner, @SBTNO, @date

while @@FETCH_STATUS = 0
	begin
	
		set @storeid = 0
		select @storeid = storeid from stores where custom2 = @SBTNO and custom1 = @banner
		
		if @@ROWCOUNT < 1
			print @SBTNO
		
		update s set s.ActiveStartDate = @date, s.ActiveLastDate = '12/31/2099'
		--select *
		from storesetup s
		where supplierid = 41440
		and storeid = @storeid
		
		--select *
		--from storesetup s
		--where supplierid = 41440
		--and storeid = @storeid
	
		fetch next from @rec into @banner, @SBTNO, @date
	
	end
	
	
close @rec
deallocate @rec

drop table import.dbo.SourceUPCsGoingLiveAtJewel_20121011

select distinct identifiervalue as UPC into import.dbo.SourceUPCsGoingLiveAtJewel_20121011
from ProductIdentifiers i
inner join storesetup s
on i.ProductID = s.ProductID
and s.SupplierID = 41440
where StoreID in
	(
	select distinct storeid 
	from storesetup
	where SupplierID = 41440
	and cast(dateadd(day, -3, getdate()) as date) between ActiveStartDate and ActiveLastDate
	and StoreID in
		(
		select storeid
		from stores 
		where Custom3 = 'SV_JWL'
		)
	)

--select distinct filename delete from DataTrue_EDI..Inbound852Sales  where recordstatus = 0
select RecordID 
into #tempInboundTransactions
--select *  
--select distinct filename
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -4, getdate()) as date) --in ('8/18/2012')
--and CAST(saledate as date) in ('6/18/2012','6/19/2012','6/20/2012','6/21/2012','6/22/2012','6/23/2012','6/24/2012','6/25/2012','6/26/2012','6/27/2012','6/28/2012','6/29/2012','6/30/2012','7/1/2012','7/2/2012','7/3/2012','7/4/2012','7/5/2012','7/6/2012','7/7/2012','7/8/2012','7/9/2012','7/10/2012','7/11/2012','7/12/2012','7/13/2012','7/14/2012','7/15/2012','7/16/2012','7/17/2012','7/18/2012','7/19/2012','7/20/2012','7/21/2012','7/22/2012','7/23/2012','7/24/2012','7/25/2012','7/26/2012','7/27/2012','7/28/2012','7/29/2012','7/30/2012','7/31/2012','8/1/2012','8/2/2012','8/3/2012','8/4/2012','8/5/2012','8/6/2012')
--and Saledate in ('8/25/2012')
--and ChainIdentifier = 'SV'
--and Banner in ('ABS','SV')
--and banner = 'SS'
and banner in ('SV_JWL')
--order by StoreIdentifier, ProductIdentifier
--and CAST(saledate as date) in ('5/5/2012', '5/6/2012')
and recordtype = 1
--and Banner <> 'SYNC'
--and FileName = 'opdssbtjewelshawsdel.dat.04012013.190248'
--and filename = 'SVEC.20111123121147_SPLIT8'
--opdssbtjewelshawsdel.dat.03312013.192855
--opdssbtjewelshawsdel.dat.04012013.190248
--and Qty <> 0
--order by StoreIdentifier, productidentifier
--and ProductIdentifier in ('041130212376',
--'071091055071',
--'811782005844',
--'811782022292')
--select CAST(getdate() as DATE)

--if CAST(getdate() as DATE) <> '11/19/2012'
--	begin
		if @@rowcount < 350
			begin

				exec dbo.prSendEmailNotification_PassEmailAddresses 'Jewel Deletion @@rowcount <> 364'
				,'Jewel Deletion @@rowcount < 360. Processing of the Jewel records will be held for manual review.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'

				set @continue = 0
			end
	--end

if @continue = 1
	begin
begin try

begin transaction

set @loadstatus = 1



INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           --,[ReportedUnitRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[SupplierIdentifier]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,RecordID_EDI_852
           ,Banner
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[RecordType]
           ,[workingstatus])
     select
           ltrim(rtrim(ChainIdentifier))
           ,cast(cast(StoreIdentifier as int) as nvarchar)
           ,Qty
           ,SaleDate
           ,ltrim(rtrim(ProductIdentifier))
           ,ltrim(rtrim(ProductQualifier))
           ,ltrim(rtrim(ProductCategoryIdentifier))
           ,ltrim(rtrim(BrandIdentifier))
           ,ltrim(rtrim(InvoiceNo))
           ,Cost
           ,Retail
           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
           --,Retail
           ,'POS'
           ,@MyID
           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
           ,DateTimeReceived
           ,ltrim(rtrim([SupplierIdentifier]))
           ,Allowance
           ,PromotionPrice
           ,s.RecordID
           ,isnull(Banner, '')
		  ,isnull([StoreName], '')
		  ,isnull([ProductQualifier] , '')     
		  ,isnull([RawProductIdentifier], '')
		  ,isnull([SupplierName], '')           
		  ,isnull([DivisionIdentifier], '')           
		   ,isnull([UnitMeasure], '')          
		  ,isnull([SalePrice], 0.0)         
		   ,isnull([InvoiceNo], '')          
		   ,isnull([PONo], '')          
		  ,isnull([CorporateName], '')
		  ,isnull([CorporateIdentifier], '')
		  ,[RecordType]
		  ,11
     from DataTrue_EDI..Inbound852Sales s
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId
     order by s.RecordID
     
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		

end catch
	

update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound852Sales s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID

end

--Take care of insertions-------------------------------------------------------------------------------
--begin try
--select distinct filename delete from DataTrue_EDI..Inbound852Sales  where recordstatus = 0
select RecordID 
into #tempInboundTransactions2
--select *  
--select distinct
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -4, getdate()) as date) --in ('8/18/2012')
--and CAST(saledate as date) in ('6/18/2012','6/19/2012','6/20/2012','6/21/2012','6/22/2012','6/23/2012','6/24/2012','6/25/2012','6/26/2012','6/27/2012','6/28/2012','6/29/2012','6/30/2012','7/1/2012','7/2/2012','7/3/2012','7/4/2012','7/5/2012','7/6/2012','7/7/2012','7/8/2012','7/9/2012','7/10/2012','7/11/2012','7/12/2012','7/13/2012','7/14/2012','7/15/2012','7/16/2012','7/17/2012','7/18/2012','7/19/2012','7/20/2012','7/21/2012','7/22/2012','7/23/2012','7/24/2012','7/25/2012','7/26/2012','7/27/2012','7/28/2012','7/29/2012','7/30/2012','7/31/2012','8/1/2012','8/2/2012','8/3/2012','8/4/2012','8/5/2012','8/6/2012')
--and Saledate in ('11/30/2011','12/2/2011')
--and ChainIdentifier = 'SV'
--and Banner in ('ABS','SV')
--and banner = 'SS'
and banner in ('SV_JWL')
--and charindex(case when len(cast(Month(dateadd(day, 0, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, 0, getdate())) As nvarchar) else cast(Month(dateadd(day, 0, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, 0, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, 0, getdate())) As nvarchar) else cast(Day(dateadd(day, 0, getdate())) As nvarchar) end + cast(Year(dateadd(day, 0, getdate())) as nvarchar), FileName)>0
--and charindex(case when len(cast(Month(dateadd(day, -1, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -1, getdate())) As nvarchar) else cast(Month(dateadd(day, -1, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -1, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -1, getdate())) As nvarchar) else cast(Day(dateadd(day, -1, getdate())) As nvarchar) end + cast(Year(dateadd(day, -1, getdate())) as nvarchar), FileName)>0
--and charindex(case when len(cast(Month(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -2, getdate())) As nvarchar) else cast(Month(dateadd(day, -2, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -2, getdate())) As nvarchar) else cast(Day(dateadd(day, -2, getdate())) As nvarchar) end + cast(Year(dateadd(day, -2, getdate())) as nvarchar), FileName)>0
and charindex(case when len(cast(Month(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -3, getdate())) As nvarchar) else cast(Month(dateadd(day, -3, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -3, getdate())) As nvarchar) else cast(Day(dateadd(day, -3, getdate())) As nvarchar) end + cast(Year(dateadd(day, -3, getdate())) as nvarchar), FileName)>0
--order by StoreIdentifier, ProductIdentifier
--and CAST(saledate as date) in ('5/5/2012', '5/6/2012')
and recordtype = 0
--and Banner <> 'SYNC'
--and FileName = 'opdssbtjewelshawsins.dat.08172012.192922'
--and filename = 'SVEC.20111123121147_SPLIT8'
--and Qty <> 0
--order by StoreIdentifier, productidentifier
and (ProductIdentifier in (select upc from import.dbo.DSWandTTTUPCsGoingLiveAtJewel) or ProductIdentifier in (select upc from import.dbo.SourceUPCsGoingLiveAtJewel_20121011))

/* These UPC's have been received for dsw and ttt
'041130212376',
'071091055071',
'811782005844',
'811782022292'
*/


if @@rowcount = 0
	begin

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Jewel Isertions @@rowcount = 0'
		,'Jewel Isertions @@rowcount = 0. Processing of the Jewel records will be held for manual review.'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'

		set @continue = 0
	end


If @continue = 1
	begin
begin try


begin transaction

set @loadstatus = 1



INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           --,[ReportedUnitRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[SupplierIdentifier]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,RecordID_EDI_852
           ,Banner
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[RecordType]
           ,[workingstatus])
     select
           ltrim(rtrim(ChainIdentifier))
           ,cast(cast(StoreIdentifier as int) as nvarchar)
           ,Qty
           ,SaleDate
           ,ltrim(rtrim(ProductIdentifier))
           ,ltrim(rtrim(ProductQualifier))
           ,ltrim(rtrim(ProductCategoryIdentifier))
           ,ltrim(rtrim(BrandIdentifier))
           ,ltrim(rtrim(InvoiceNo))
           ,Cost
           ,Retail
           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
           --,Retail
           ,'POS'
           ,@MyID
           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
           ,DateTimeReceived
           ,ltrim(rtrim([SupplierIdentifier]))
           ,Allowance
           ,PromotionPrice
           ,s.RecordID
           ,isnull(Banner, '')
		  ,isnull([StoreName], '')
		  ,isnull([ProductQualifier] , '')     
		  ,isnull([RawProductIdentifier], '')
		  ,isnull([SupplierName], '')           
		  ,isnull([DivisionIdentifier], '')           
		   ,isnull([UnitMeasure], '')          
		  ,isnull([SalePrice], 0.0)         
		   ,isnull([InvoiceNo], '')          
		   ,isnull([PONo], '')          
		  ,isnull([CorporateName], '')
		  ,isnull([CorporateIdentifier], '')
		  ,[RecordType]
		  ,0
     from DataTrue_EDI..Inbound852Sales s
     inner join #tempInboundTransactions2 t
     on s.RecordID = t.RecordId
     order by s.RecordID
     
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID

		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	

update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound852Sales s
inner join #tempInboundTransactions2 t
on s.RecordID = t.RecordID

end
----------------------------------------------------------------------------------

if @continue = 1
	begin

--Take care of deletions
begin try
--select distinct filename delete from DataTrue_EDI..Inbound852Sales  where recordstatus = 0
select RecordID 
into #tempInboundTransactions3
--select *  
--select distinct
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -4, getdate()) as date) --in ('8/18/2012')
--and CAST(saledate as date) in ('6/18/2012','6/19/2012','6/20/2012','6/21/2012','6/22/2012','6/23/2012','6/24/2012','6/25/2012','6/26/2012','6/27/2012','6/28/2012','6/29/2012','6/30/2012','7/1/2012','7/2/2012','7/3/2012','7/4/2012','7/5/2012','7/6/2012','7/7/2012','7/8/2012','7/9/2012','7/10/2012','7/11/2012','7/12/2012','7/13/2012','7/14/2012','7/15/2012','7/16/2012','7/17/2012','7/18/2012','7/19/2012','7/20/2012','7/21/2012','7/22/2012','7/23/2012','7/24/2012','7/25/2012','7/26/2012','7/27/2012','7/28/2012','7/29/2012','7/30/2012','7/31/2012','8/1/2012','8/2/2012','8/3/2012','8/4/2012','8/5/2012','8/6/2012')
--and Saledate in ('11/30/2011','12/2/2011')
--and ChainIdentifier = 'SV'
--and Banner in ('ABS','SV')
--and banner = 'SS'
and banner in ('SV_JWL')
--and (charindex(case when len(cast(Month(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -2, getdate())) As nvarchar) else cast(Month(dateadd(day, -2, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -2, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -2, getdate())) As nvarchar) else cast(Day(dateadd(day, -2, getdate())) As nvarchar) end + cast(Year(dateadd(day, -2, getdate())) as nvarchar), FileName)>0 or charindex(case when len(cast(Month(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -3, getdate())) As nvarchar) else cast(Month(dateadd(day, -3, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -3, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -3, getdate())) As nvarchar) else cast(Day(dateadd(day, -3, getdate())) As nvarchar) end + cast(Year(dateadd(day, -3, getdate())) as nvarchar), FileName)>0)
and charindex(case when len(cast(Month(dateadd(day, -4, getdate())) As nvarchar)) = 1 then '0' + cast(Month(dateadd(day, -4, getdate())) As nvarchar) else cast(Month(dateadd(day, -4, getdate())) As nvarchar) end + case when len(cast(Day(dateadd(day, -4, getdate())) As nvarchar)) = 1 then '0' + cast(Day(dateadd(day, -4, getdate())) As nvarchar) else cast(Day(dateadd(day, -4, getdate())) As nvarchar) end + cast(Year(dateadd(day, -4, getdate())) as nvarchar), FileName)>0
--order by StoreIdentifier, ProductIdentifier
--and CAST(saledate as date) in ('5/5/2012', '5/6/2012')
and recordtype = 0
--and Banner <> 'SYNC'
--and FileName = 'opdssbtjewelshawsins.dat.08172012.192922'
--and filename = 'SVEC.20111123121147_SPLIT8'
--and Qty <> 0
--order by StoreIdentifier, productidentifier
and (ProductIdentifier in (select upc from import.dbo.DSWandTTTUPCsGoingLiveAtJewel) or ProductIdentifier in (select upc from import.dbo.SourceUPCsGoingLiveAtJewel_20121011))

begin transaction

set @loadstatus = 1



INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           --,[ReportedUnitRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[SupplierIdentifier]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,RecordID_EDI_852
           ,Banner
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[RecordType]
           ,[workingstatus])
     select
           ltrim(rtrim(ChainIdentifier))
           ,cast(cast(StoreIdentifier as int) as nvarchar)
           ,Qty
           ,SaleDate
           ,ltrim(rtrim(ProductIdentifier))
           ,ltrim(rtrim(ProductQualifier))
           ,ltrim(rtrim(ProductCategoryIdentifier))
           ,ltrim(rtrim(BrandIdentifier))
           ,ltrim(rtrim(InvoiceNo))
           ,Cost
           ,Retail
           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
           --,Retail
           ,'POS'
           ,@MyID
           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
           ,DateTimeReceived
           ,ltrim(rtrim([SupplierIdentifier]))
           ,Allowance
           ,PromotionPrice
           ,s.RecordID
           ,isnull(Banner, '')
		  ,isnull([StoreName], '')
		  ,isnull([ProductQualifier] , '')     
		  ,isnull([RawProductIdentifier], '')
		  ,isnull([SupplierName], '')           
		  ,isnull([DivisionIdentifier], '')           
		   ,isnull([UnitMeasure], '')          
		  ,isnull([SalePrice], 0.0)         
		   ,isnull([InvoiceNo], '')          
		   ,isnull([PONo], '')          
		  ,isnull([CorporateName], '')
		  ,isnull([CorporateIdentifier], '')
		  ,[RecordType]
		  ,12
     from DataTrue_EDI..Inbound852Sales s
     inner join #tempInboundTransactions3 t
     on s.RecordID = t.RecordId
     order by s.RecordID
     
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -9999
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID

		exec [msdb].[dbo].[sp_stop_job] 
			@job_name = 'DailyPOSBilling_THIS_IS_CURRENT_ONE'

		exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Stopped'
				,'Retailer and supplier invoicing has been stopped due to an exception.  Manual review, resolution, and re-start will be required for the job to continue.'
				,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;edi@icontroldsd.com'		
		
end catch
	

update s set RecordStatus = @loadstatus
from DataTrue_EDI..Inbound852Sales s
inner join #tempInboundTransactions3 t
on s.RecordID = t.RecordID


end
/*
Notes
	5/27 had third deletion with one store 1422 but no third insertion
	5/28 had third deletion with one store 1422 but no third insertion


select  filename, COUNT(recordid)
--into #tempFilecount
--select *
from DataTrue_EDI..Inbound852Sales [No Lock]
where 1 = 1
and CAST(saledate as date) = '8/17/2013'
and banner in ('SV_JWL')
and recordtype = 0
--and storeidentifier = '1422'
--and filename = 'opdssbtjewelshawsdel.dat.05302013.192558'
group by filename




select storeidentifier
from DataTrue_EDI..Inbound852Sales [No Lock]
where filename = 'opdssbtjewelshawsdel.dat.06242013.203716'
and CAST(saledate as date) = '6/24/2013'
and recordtype = 1
and storeidentifier not in
(
select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales [No Lock]
where filename = 'opdssbtjewelshawsdel.dat.06252013.222243'
and recordtype = 1
and CAST(saledate as date) = '6/24/2013'
)

opdssbtjewelshawsdel.dat.06142013.222152	178
opdssbtjewelshawsdel.dat.06152013.190114	177

5/27 deletions
opdssbtjewelshawsdel.dat.05272013.195412	178
opdssbtjewelshawsdel.dat.05282013.204947	178
opdssbtjewelshawsdel.dat.05292013.200148	1
5/27 insertions
opdssbtjewelshawsins.dat.05272013.195229	4351
opdssbtjewelshawsins.dat.05282013.204813	5446

4/22 deletions
opdssbtjewelshawsdel.dat.04222013.194959	178
opdssbtjewelshawsdel.dat.04232013.185819	178
opdssbtjewelshawsdel.dat.04242013.185808	1
4/22 insertions
opdssbtjewelshawsins.dat.04222013.194822	3986
opdssbtjewelshawsins.dat.04232013.185655	5425
opdssbtjewelshawsins.dat.04242013.185647	31

--second deletion not complete

select *  
--select distinct filename
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
--and FileName = 'opdssbtjewelshawsdel.dat.04012013.190248'
--opdssbtjewelshawsdel.dat.04182013.190806
--opdssbtjewelshawsdel.dat.04192013.190205


opdssbtjewelshawsins.dat.04182013.190640
opdssbtjewelshawsins.dat.04192013.190039


opdssbtjewelshawsdel.dat.06142013.222152	178
opdssbtjewelshawsdel.dat.06152013.190114	177

select StoreIdentifier  
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
and FileName = 'opdssbtjewelshawsdel.dat.06142013.222152'
and StoreIdentifier not in
(
select StoreIdentifier  
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
and FileName = 'opdssbtjewelshawsdel.dat.06152013.190114'
)


opdssbtjewelshawsins.dat.06142013.222016	4893
opdssbtjewelshawsins.dat.06152013.185934	6047

select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
and storeidentifier = '3471'
and FileName = 'opdssbtjewelshawsins.dat.06142013.222016'

3/31 insertions
opdssbtjewelshawsins.dat.03312013.192706	4492
opdssbtjewelshawsins.dat.04012013.190111	4645




select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
and FileName = 'opdssbtjewelshawsdel.dat.04242013.185808'
and storeidentifier in
(
'1469',
'3043',
'3114',
'3471',
'3282',
'1422',
'3176',
'3236')

3/13 deletions
opdssbtjewelshawsdel.dat.03132013.184718	179
opdssbtjewelshawsdel.dat.03142013.184648	178
opdssbtjewelshawsdel.dat.03152013.203740	2	3479, 3283
3/13 insertions
opdssbtjewelshawsins.dat.03132013.184558	3118
opdssbtjewelshawsins.dat.03142013.184521	4929
opdssbtjewelshawsins.dat.03152013.203603	82


4/22 deletions
opdssbtjewelshawsdel.dat.04222013.194959	178
opdssbtjewelshawsdel.dat.04232013.185819	178
opdssbtjewelshawsdel.dat.04242013.185808	1 --3720
4/22 insertions
opdssbtjewelshawsins.dat.04222013.194822	3986
opdssbtjewelshawsins.dat.04232013.185655	5425
opdssbtjewelshawsins.dat.04242013.185647	31

select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and cast(saledate as date) = '4/22/2013'
and storeidentifier in ('3720')
and filename = 'opdssbtjewelshawsins.dat.04232013.185655'
order by ltrim(rtrim(productidentifier))

select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and cast(saledate as date) = '4/22/2013'
and storeidentifier in ('3720')
and filename = 'opdssbtjewelshawsdel.dat.04242013.185808' --opdssbtjewelshawsins.dat.04232013.185655'
order by ltrim(rtrim(productidentifier))


select one.qty, two.qty, *
--update two set two.recordstatus = 1
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on ltrim(rtrim(one.storeidentifier)) = ltrim(rtrim(two.storeidentifier))
and ltrim(rtrim(one.productidentifier)) = ltrim(rtrim(two.productidentifier))
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '4/22/2013'
and ltrim(rtrim(one.storeidentifier)) = '3720'
and ltrim(rtrim(one.filename)) = 'opdssbtjewelshawsins.dat.04232013.185655'
and ltrim(rtrim(two.filename)) = 'opdssbtjewelshawsins.dat.04242013.185647'
and one.recordtype = 0
and two.recordtype = 0
and two.recordstatus = 0
and one.qty <> two.qty

select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and CAST(saledate as date) = '1/29/2013'
and banner in ('SV_JWL')
and recordtype = 0
and filename = ''


select invoicebatchid as ibid, *
from storetransactions
where 1 = 1
and CAST(saledatetime as date) = '1/29/2013'
and banner in ('SV_JWL')
--and invoicebatchid is not null
order by invoicebatchid


dbo.Inbound852Sales_JWLSHW_Unmatched
dbo.Inbound852Sales_JWLSHW_Unmatched_2012



--check for more than two deletions
Currently there are 2 4's and 18 3's on 1/23/2013

drop table #tempFilecount
declare @filecount int

select CAST(saledate as date) as date, COUNT(distinct filename) as FileCount
into #tempFilecount
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and CAST(saledate as date) = '2/19/2013'
and banner in ('SV_JWL')
and recordtype = 1
group by CAST(saledate as date)
having COUNT(distinct filename) > 2
order by CAST(saledate as date)

select  sum(filecount) from #tempFilecount

select * from #tempFilecount

if @filecount > 62
	begin
	
	
	
	end

select CAST(saledate as date), COUNT(distinct filename)
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and CAST(saledate as date) > '11/15/2012'
and banner in ('SV_JWL')
and recordtype = 0
group by CAST(saledate as date)
having COUNT(distinct filename) > 2
order by CAST(saledate as date)

select StoreTransactionID into #tmpInboundPOS
from StoreTransactions_Working t
where t.WorkingStatus = 0
and WorkingSource = 'POS'

select max(saledatetime)
from storetransactions
where banner = 'SV_JWL'

--Retailer's reported cost is iControl's ReportedSalePrice

update t
set t.ReportedUnitPrice = Case when t.ReportedUnitPrice < 0.0001 then t.ReportedUnitCost else t.ReportedUnitPrice end
from #tmpInboundPOS tmp
inner join StoreTransactions_Working t
on tmp.StoreTransactionID = t.StoreTransactionID

select distinct recordstatus
from DataTrue_EDI..Inbound852Sales
order by recordstatus

select filename 
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
group by filename

select filename, count(recordid)
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 0
and CAST(saledate as date) = '1/21/2013'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
group by filename
order by filename


--1/21/2013
insertions
opdssbtjewelshawsins.dat.01212013.185913	2861
opdssbtjewelshawsins.dat.01222013.190322	3977
opdssbtjewelshawsins.dat.01252013.191352	21
deletions
opdssbtjewelshawsdel.dat.01212013.190052	181
opdssbtjewelshawsdel.dat.01222013.190446	181
opdssbtjewelshawsdel.dat.01252013.191519	1 (3264)

--12/1/2012
Insertions
Excel Sheet	459
opdssbtjewelshawsins.dat.12012012.184658	3982
opdssbtjewelshawsins.dat.12022012.185846	4892
opdssbtjewelshawsins.dat.12052012.193325	4916


Deletions
opdssbtjewelshawsdel.dat.12012012.184840	181
opdssbtjewelshawsdel.dat.12022012.190035	181
opdssbtjewelshawsdel.dat.12052012.193624	179

2/23 Deletions
opdssbtjewelshawsdel.dat.02232013.185123	180
opdssbtjewelshawsdel.dat.02242013.185730	180
opdssbtjewelshawsdel.dat.02262013.193310	47

2/23 Insertions
opdssbtjewelshawsins.dat.02232013.184942	5264
opdssbtjewelshawsins.dat.02242013.185543	6201
opdssbtjewelshawsins.dat.02262013.193127	1861


3/5 Deletions
opdssbtjewelshawsdel.dat.03052013.192850	180
opdssbtjewelshawsdel.dat.03062013.184756	179
3/5 Insertions
opdssbtjewelshawsins.dat.03052013.192715	2952
opdssbtjewelshawsins.dat.03062013.184635	3400


3/6 deletions
opdssbtjewelshawsdel.dat.03062013.184756	179
opdssbtjewelshawsdel.dat.03072013.191018	179
3/6 insertions
opdssbtjewelshawsins.dat.03062013.184635	3041
opdssbtjewelshawsins.dat.03072013.190849	4165

3/22 deletions
opdssbtjewelshawsdel.dat.03222013.190848	178
opdssbtjewelshawsdel.dat.03232013.185841	178
opdssbtjewelshawsdel.dat.03252013.191639	1
3/22 insertions
opdssbtjewelshawsins.dat.03222013.190717	5166
opdssbtjewelshawsins.dat.03232013.185657	6481
opdssbtjewelshawsins.dat.03252013.191458	37

3/14 deletions
opdssbtjewelshawsdel.dat.03142013.184648	178
opdssbtjewelshawsdel.dat.03152013.203740	178
opdssbtjewelshawsdel.dat.03252013.191639	1

3/14 insertions
opdssbtjewelshawsins.dat.03142013.184521	4417
opdssbtjewelshawsins.dat.03152013.203603	5800
opdssbtjewelshawsins.dat.03252013.191458	27
--find store not in second insertion


8/17 
deletions
opdssbtjewelshawsdel.dat.08172013.173404	178
opdssbtjewelshawsdel.dat.08182013.184807	178
opdssbtjewelshawsdel.dat.08192013.184449	1
insertions
opdssbtjewelshawsins.dat.08182013.184620	5878
opdssbtjewelshawsins.dat.08192013.184311	34 3074
opdssbtjewelshawsins.dat.08172013.173227	4587

select distinct ltrim(rtrim(storeidentifier)) --as number into #storesinfirst
--select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and recordtype = 1
and ltrim(rtrim(storeidentifier)) = '3074'
and cast(saledate as date) = '8/17/2013'
and filename = 'opdssbtjewelshawsdel.dat.08192013.184449'

select distinct ltrim(rtrim(storeidentifier)) as number into #storesinsecond
from DataTrue_EDI.dbo.Inbound852Sales
where 1 = 1
and recordtype = 0
and cast(saledate as date) = '3/12/2013'
and filename = 'opdssbtjewelshawsins.dat.03142013.184521'


select one.qty, two.qty, *
--update two set two.recordstatus = 1
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '8/17/2013'
and one.storeidentifier = '3074'
and one.filename = 'opdssbtjewelshawsins.dat.08182013.184620'
and two.filename = 'opdssbtjewelshawsins.dat.08192013.184311'
and one.recordtype = 0
and two.recordtype = 0
and two.recordstatus = 0
and one.qty <> two.qty


select *
from #storesinfirst
where ltrim(rtrim(number)) not in
(
select ltrim(rtrim(number)) from  #storesinsecond
)


3/7 Deletions
opdssbtjewelshawsdel.dat.03072013.191018	179
opdssbtjewelshawsdel.dat.03082013.190406	179
opdssbtjewelshawsdel.dat.03112013.190636	1
3/7 insertions
opdssbtjewelshawsins.dat.03072013.190849	4235
opdssbtjewelshawsins.dat.03082013.190234	5283
opdssbtjewelshawsins.dat.03112013.190455	22

store 3154
3/12 deletions
opdssbtjewelshawsdel.dat.03122013.185748	179
opdssbtjewelshawsdel.dat.03132013.184718	179
opdssbtjewelshawsdel.dat.03142013.184648	1
3/12 insertion
opdssbtjewelshawsins.dat.03122013.185621	3381
opdssbtjewelshawsins.dat.03132013.184558	4433
opdssbtjewelshawsins.dat.03142013.184521	46

select *
--update s set recordstatus = 1
from DataTrue_EDI.dbo.Inbound852Sales s
where 1 = 1
and cast(saledate as date) = '3/12/2013'
and storeidentifier = '3154'
and filename = 'opdssbtjewelshawsdel.dat.03142013.184648'


select one.qty, two.qty, *
--update two set two.recordstatus = 1
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '3/12/2013'
and one.storeidentifier = '3154'
and one.filename = 'opdssbtjewelshawsins.dat.03132013.184558'
and two.filename = 'opdssbtjewelshawsins.dat.03142013.184521'
and one.recordtype = 0
and two.recordtype = 0
and two.recordstatus = 0
and one.qty <> two.qty

42995084
42991469
42991670

--this next query sets last insertion as one and original as two to find records missing from original
select one.qty, two.qty
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
left join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and cast(one.saledate as date) = '2/23/2013'
and one.filename = 'opdssbtjewelshawsins.dat.02262013.193127'
and one.recordtype = 0
and two.filename = 'opdssbtjewelshawsins.dat.02242013.185543'
--and one.qty <> isnull(two.qty, 0)
where 
and two.recordtype = 0

order by two.qty

select * into #tempnew
from DataTrue_EDI.dbo.Inbound852Sales
where filename = 'opdssbtjewelshawsins.dat.02262013.193127'
and cast(saledate as date) = '2/23/2013'
and storeidentifier in
(
select distinct storeidentifier
from DataTrue_EDI.dbo.Inbound852Sales
where cast(saledate as date) = '2/23/2013'
and recordtype = 1
and filename = 'opdssbtjewelshawsdel.dat.02262013.193310'
)

select n.*, o.*
--update n set recordstatus = -3
from #temporiginal o
right join #tempnew n
on o.storeidentifier = n.storeidentifier
and o.productidentifier = n.productidentifier
where o.storeidentifier is null
order by o.storeidentifier

select *
--update s set s.recordstatus = -3
from DataTrue_EDI.dbo.Inbound852Sales s
inner join #tempnew n
on s.recordid = n.recordid
and n.recordstatus = -3

select distinct cast(datetimecreated as date)
from storetransactions
where cast(saledatetime as date) = '12/1/2012'
and banner = 'SV_JWL'
and transactiontypeid in (2, 6)
order by cast(datetimecreated as date)

2012-12-04
2012-12-12
2013-01-03

select *
from storetransactions
where cast(saledatetime as date) = '12/1/2012'
and cast(datetimecreated as date) = '1/3/2013'
and banner = 'SV_JWL'
and transactiontypeid in (2, 6)

select distinct cast(saledatetime as date), cast(datetimecreated as date)
from storetransactions
where banner = 'SV_JWL'
and cast(saledatetime as date) <> cast(dateadd(day, -3, datetimecreated) as date)
order by cast(saledatetime as date)

--select top 1000 * from DataTrue_EDI..Inbound852Sales

select *
--update s set recordstatus = 1
from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and filename = 'opdssbtjewelshawsins.dat.01252013.191352'
and cast(saledate as date) = '1/21/2013'
and recordstatus = 0
and storeidentifier = '3264'

select *
from DataTrue_EDI..Inbound852Sales one
inner join DataTrue_EDI..Inbound852Sales two
on cast(ltrim(rtrim(one.storeidentifier)) as int) = cast(ltrim(rtrim(two.storeidentifier)) as int)
and ltrim(rtrim(one.productidentifier)) = ltrim(rtrim(two.productidentifier))
and cast(one.saledate as date) = cast(two.saledate as date)
and one.filename = 'opdssbtjewelshawsins.dat.12312012.195717'
and two.filename = 'Excel Sheet 2 (Mark)'

select * --into import.dbo.Inbound852Sales_JWL_MissingUPCs_BeforeFilenameChange_20130103
--update s set s.filename = 'opdssbtjewelshawsins.dat.01012013.193904'
from DataTrue_EDI..Inbound852Sales s
where filename = 'Excel Sheet 2 (Mark)'
--and productidentifier = '009128461571'
and cast(saledate as date) = '12/31/2012'
order by  productidentifier


select *
from DataTrue_EDI..Inbound852Sales
where filename = 'opdssbtjewelshawsins.dat.01012013.193904'
--and productidentifier = '009128461571'
and cast(saledate as date) = '12/31/2012'
order by productidentifier

Excel Sheet 2 (Mark)
opdssbtjewelshawsins.dat.01012013.193904

select CAST(saledate as date), COUNT(distinct filename)
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and CAST(saledate as date) > '11/15/2012'
and banner in ('SV_JWL')
and recordtype = 1
group by CAST(saledate as date)
having COUNT(distinct filename) > 2
order by CAST(saledate as date)

select filename, COUNT(*)
--select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 1
and CAST(saledate as date) = '12/25/2012'
--and filename = 'opdssbtjewelshawsdel.dat.12142012.185351'
--and storeidentifier = '3425'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
group by filename
order by filename

select filename, COUNT(*)
--select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 1
and CAST(saledate as date) = '1/21/2013'
and filename = 'opdssbtjewelshawsdel.dat.01252013.191519'
--and storeidentifier = '3348'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
group by filename
order by filename

3348


select *
from DataTrue_EDI.dbo.Inbound852Sales one
where 1 = 1
and one.storeidentifier = '3741'
and one.filename = 'opdssbtjewelshawsins.dat.01222013.190322'
and one.recordtype = 0
and saledate = '2013-01-17 00:00:00.000'

--compare qty's in second and third insertion

select one.qty, two.qty
--select *
from DataTrue_EDI.dbo.Inbound852Sales one
inner join DataTrue_EDI.dbo.Inbound852Sales two
on one.storeidentifier = two.storeidentifier
and one.productidentifier = two.productidentifier
and cast(one.saledate as date) = cast(two.saledate as date)
and one.storeidentifier = '3741'
and one.filename = 'opdssbtjewelshawsins.dat.01182013.190259'
and two.filename = 'opdssbtjewelshawsins.dat.01222013.190322'
and one.recordtype = 0
and two.recordtype = 0
and one.qty <> two.qty

select distinct filename 
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0

1/17/2013
deletions
opdssbtjewelshawsdel.dat.01172013.185312	181
opdssbtjewelshawsdel.dat.01182013.190432	181
opdssbtjewelshawsdel.dat.01222013.190446	1 (3741)

insertions
opdssbtjewelshawsins.dat.01172013.185151	3434
opdssbtjewelshawsins.dat.01182013.190259	4813
opdssbtjewelshawsins.dat.01222013.190322	20


12/1/2012
deletions


insertions


--find stores to remove from second insertion

select distinct storeidentifier
--select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = '1/17/2013'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 1
and filename = 'opdssbtjewelshawsdel.dat.01222013.190446'

--find records in second insertion that will be pended
select *
--update s set recordstatus = 1107
from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.01182013.190259'
and storeidentifier in
(
select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 1
and filename = 'opdssbtjewelshawsdel.dat.12042012.190716'
)

--find records in third insertion
select *
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.12042012.190504'

--pull records in third insertion into working table

INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           --,[ReportedUnitRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[DateTimeSourceReceived]
           ,[SupplierIdentifier]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,RecordID_EDI_852
           ,Banner
           ,[StoreName]
           ,[ProductQualifier]
           ,[RawProductIdentifier]
           ,[SupplierName]
           ,[DivisionIdentifier]
           ,[UOM]
           ,[SalePrice]
           ,[InvoiceNo]
           ,[PONo]
           ,[CorporateName]
           ,[CorporateIdentifier]
           ,[RecordType]
           ,[workingstatus])
     select
           ltrim(rtrim(ChainIdentifier))
           ,cast(cast(StoreIdentifier as int) as nvarchar)
           ,Qty
           ,SaleDate
           ,ltrim(rtrim(ProductIdentifier))
           ,ltrim(rtrim(ProductQualifier))
           ,ltrim(rtrim(ProductCategoryIdentifier))
           ,ltrim(rtrim(BrandIdentifier))
           ,ltrim(rtrim(InvoiceNo))
           ,Cost
           ,Retail
           --,SalePrice --CHANGE THIS BACK TO COST -----------------Cost
           --,SalePrice * 1.15--CHANGE THIS BACK TO RETAIL-------------------------Retail
           --,Retail
           ,'POS'
           ,0 --@MyID
           ,isnull(ltrim(rtrim(FileName)), 'DEFAULT')
           ,DateTimeReceived
           ,ltrim(rtrim([SupplierIdentifier]))
           ,Allowance
           ,PromotionPrice
           ,s.RecordID
           ,isnull(Banner, '')
		  ,isnull([StoreName], '')
		  ,isnull([ProductQualifier] , '')     
		  ,isnull([RawProductIdentifier], '')
		  ,isnull([SupplierName], '')           
		  ,isnull([DivisionIdentifier], '')           
		   ,isnull([UnitMeasure], '')          
		  ,isnull([SalePrice], 0.0)         
		   ,isnull([InvoiceNo], '')          
		   ,isnull([PONo], '')          
		  ,isnull([CorporateName], '')
		  ,isnull([CorporateIdentifier], '')
		  ,[RecordType]
		  ,0
		  --select *
		  --update s set s.recordstatus = 1
     from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
and FileName = 'opdssbtjewelshawsins.dat.06242013.203548'
and storeidentifier in
(
'1422','3107')

delete
opdssbtjewelshawsdel.dat.06242013.203716	178
opdssbtjewelshawsdel.dat.06252013.222243	176
1422
3107
insert
opdssbtjewelshawsins.dat.06242013.203548	3599
opdssbtjewelshawsins.dat.06252013.222113	4474


and (ProductIdentifier in (select upc from import.dbo.DSWandTTTUPCsGoingLiveAtJewel) or ProductIdentifier in (select upc from import.dbo.SourceUPCsGoingLiveAtJewel_20121011))

--update recordstatus in third insertion records already pulled.
update s set s.recordstatus = 1
--select *
 from DataTrue_EDI..Inbound852Sales s
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.03152013.203603'
and (ProductIdentifier in (select upc from import.dbo.DSWandTTTUPCsGoingLiveAtJewel) or ProductIdentifier in (select upc from import.dbo.SourceUPCsGoingLiveAtJewel_20121011))

--check second insertion file for correct recordstatus
select recordstatus as stat, *
from DataTrue_EDI..Inbound852Sales s
where 1 = 1
--and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date)
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.12032012.185234'
order by recordstatus desc

--check working table for correct records
select *
from storetransactions_working 
where workingsource = 'POS'
and workingstatus = 0




--362 deletions not received

select storeidentifier, count(*)  
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and RecordStatus = 0
and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 1
group by storeidentifier
order by count(*)



select filename, COUNT(*)
--select *
--select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales
where 1 = 1
--and RecordStatus = 1
and CAST(saledate as date) = '11/16/2012'
--and CAST(saledate as date) = cast(dateadd(day, -3, getdate()) as date) --in ('8/18/2012')
and banner in ('SV_JWL')
and recordtype = 0
--and filename = 'opdssbtjewelshawsins.dat.11162012.191802'
group by filename
order by filename

3156
3376
3302
3114
3471
3490
3288
3139


select distinct storeidentifier
from DataTrue_EDI..Inbound852Sales
where 1 = 1
and CAST(saledate as date) = '11/16/2012'
and banner in ('SV_JWL')
and recordtype = 0
and filename = 'opdssbtjewelshawsins.dat.11162012.191802'


*/
GO
