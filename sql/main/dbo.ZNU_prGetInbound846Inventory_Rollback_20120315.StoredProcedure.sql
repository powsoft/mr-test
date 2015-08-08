USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prGetInbound846Inventory_Rollback_20120315]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[ZNU_prGetInbound846Inventory_Rollback_20120315]
/*
truncate table StoreTransactions_Working
delete StoreTransactions
truncate table cdc.dbo_InventoryPerpetual_CT
truncate table DataTrue_Report..InventoryPerpetual
update DataTrue_EDI..Inbound846Inventory set Recordstatus = 0 where ChainName = 'Worldmart'
select * from DataTrue_EDI..Inbound846Inventory where recordstatus = 0
update DataTrue_EDI..Inbound846Inventory set EffectiveDate = '2011-12-01 00:00:00.000' where recordstatus = 0

--41340	5135
select * from inventoryperpetual where chainid = 40393
exec DataTrue_Report..prCDCGetINVStoreTransactions

select distinct EDIName from DataTrue_EDI..Inbound846Inventory
select distinct EDIName from DataTrue_EDI..Inbound846Inventory where recordstatus = 0 and purposecode = 'CNT'
select * from update DataTrue_EDI..Inbound846Inventory set recordstatus = 0 where recordstatus = 99
select distinct filename from DataTrue_EDI..Inbound846Inventory where effectivedate = '12/3/2011' and purposecode = 'CNT' and ediname = 'SAR'
select filename, count(recordid) from DataTrue_EDI..Inbound846Inventory where effectivedate = '12/3/2011' and purposecode = 'CNT' and ediname = 'SAR' group by filename
update DataTrue_EDI..Inbound846Inventory set recordstatus = 99 where effectivedate = '12/3/2011' and purposecode = 'CNT' and ediname = 'SAR' and filename in  
('66014_0_Split1.txt',
'66014_0_Split3.txt',
'66099_0_Split5.txt')
select distinct custom1 from stores where storeid in (select distinct storeid from storetransactions where supplierid = 40558 and transactiontypeid = 2)
select * from DataTrue_EDI..Inbound846Inventory where EDIName = 'PEP' and PurposeCode = 'CNT' and effectivedate = '2012-01-19 00:00:00.000'
select distinct PurposeCode from DataTrue_EDI..Inbound846Inventory where EDIName = 'GOP'
select distinct effectivedate from DataTrue_EDI..Inbound846Inventory where EDIName = 'BIM' and PurposeCode in ('CNT') and recordstatus = 0 order by effectivedate
BIM       
LWS       
PEP       
SAR       
SHM 
select max(saledatetime) from storetransactions where transactiontypeid = 11 and supplierid = 40557
select * from DataTrue_EDI..Inbound846Inventory where EDIName = 'BIM' and PurposeCode in ('CNT') and recordstatus = 0 and effectivedate = '2011-12-27 00:00:00.000'    
2011-11-28 00:00:00.000
2011-11-29 00:00:00.000
2011-12-26 00:00:00.000
2011-12-27 00:00:00.000
2012-01-16 00:00:00.000
2012-01-17 00:00:00.000
2012-01-23 00:00:00.000
2012-01-24 00:00:00.000
2012-01-30 00:00:00.000
2012-01-31 00:00:00.000
*/
As 

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 7593

begin try
/*
select ediname, purposecode, storenumber, ProductIdentifier, cast(EffectiveDate as date) as effdate, Qty
into #tempDupeCleanup
--select ediname, purposecode, storenumber, ProductIdentifier, cast(EffectiveDate as date), Qty
--select *
from DataTrue_EDI..Inbound846Inventory
WHERE 1 = 1
--and RecordStatus = 0
and PurposeCode = 'CNT'
and EdiName = 'BIM'
and cast(EffectiveDate as date) >= '12/5/2011'
--and cast(EffectiveDate as date) >= '12/25/2011'
group by ediname, purposecode, storenumber, ProductIdentifier, cast(EffectiveDate as date), Qty
having COUNT(recordid) > 1

if @@ROWCOUNT > 0
	begin
		declare @recdupeclean cursor
		declare @dupcheckrecordid int
		declare @dupcheckediname nvarchar(50)
		declare @purposecode nvarchar(50)
		declare @dupcheckstorenumber nvarchar(50)
		declare @dupcheckproductidentifier nvarchar(50)
		declare @dupcheckdate date
		declare @dupcheckqty int

		set @recdupeclean = cursor local fast_forward for
			select recordid, i.ediname, i.purposecode, i.storenumber, i.ProductIdentifier, cast(i.EffectiveDate as date), i.Qty
			from DataTrue_EDI..Inbound846Inventory i
			inner join #tempDupeCleanup t
			on ltrim(rtrim(i.EdiName)) = ltrim(rtrim(t.EdiName))
			and ltrim(rtrim(i.PurposeCode)) = ltrim(rtrim(t.PurposeCode))
			and ltrim(rtrim(i.StoreNumber)) = ltrim(rtrim(t.StoreNumber))
			and ltrim(rtrim(i.ProductIdentifier)) = ltrim(rtrim(t.ProductIdentifier))
			and cast(i.EffectiveDate as date) = cast(t.effdate as date)
			and i.Qty = t.qty
			WHERE 1 = 1
			and RecordStatus = 0    

		open @recdupeclean

		fetch next from @recdupeclean into
			@dupcheckrecordid
			,@dupcheckediname
			,@purposecode
			,@dupcheckstorenumber
			,@dupcheckproductidentifier
			,@dupcheckdate
			,@dupcheckqty
			
		while @@FETCH_STATUS = 0
			begin
			
				update i set RecordStatus = 99
				from DataTrue_EDI..Inbound846Inventory i
				where ltrim(rtrim(ediname)) = ltrim(rtrim(@dupcheckediname))
					and ltrim(rtrim(purposecode)) = ltrim(rtrim(@purposecode))
					and ltrim(rtrim(storenumber)) = ltrim(rtrim(@dupcheckstorenumber))
					and ltrim(rtrim(productidentifier)) = ltrim(rtrim(@dupcheckproductidentifier))
					and cast(effectivedate as date) = @dupcheckdate
					and qty = @dupcheckqty
					and RecordID <> @dupcheckrecordid
				
				fetch next from @recdupeclean into
					@dupcheckrecordid
					,@dupcheckediname
					,@purposecode
					,@dupcheckstorenumber
					,@dupcheckproductidentifier
					,@dupcheckdate
					,@dupcheckqty	
			
			end
			
		close @recdupeclean
		deallocate @recdupeclean
	end
	*/
	
select RecordID 
into #tempInboundTransactions  
--select *
from DataTrue_EDI..Inbound846Inventory
--INNER JOIN dbo.ProductIdentifiers AS p 
--ON Inbound846Inventory.ProductIdentifier = p.IdentifierValue
WHERE 1 = 1
and RecordStatus = 0
--and EdiName in ('SHM', 'PEP', 'GOP', 'BIM', 'LWS')
and EdiName = 'SHM'
--and EdiName = 'GOP'
and PurposeCode = 'CNT'
--and PurposeCode = '00'
--and CAST(effectivedate as date) = '1/2/2012'
--and p.ProductIdentifierTypeID = 2 --UPC
--and isnumeric(StoreNumber) > 0
and cast(EffectiveDate as date) in ('2012-02-27','2012-03-05')
--and EffectiveDate >= '2011-12-05 00:00:00.000'
--and EffectiveDate > '2011-12-02 00:00:00.000'
order by EffectiveDate
/*
2012-02-27
2012-03-05
*/
begin transaction

set @loadstatus = 1


INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[SupplierIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[BrandIdentifier]
           --,[SupplierInvoiceNumber]
           --,[ReportedUnitPrice]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[CorporateIdentifier]
           ,[EDIName]
           ,[RecordID_EDI_852])
           --,[DateTimeSourceReceived])
     select distinct
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(isnull(SupplierIdentifier, 'DEFAULT')))
           ,Qty
           ,EffectiveDate
           ,ProductIdentifier
           ,BrandIdentifier
           --,InvoiceNumber
           ,Cost
           ,Retail
           ,'INV'
           ,@MyID
           ,isnull(FileName, 'DEFAULT')
           ,StoreDuns
           ,EDIName
           ,s.recordid
           --,TimeStamp
     from DataTrue_EDI..Inbound846Inventory s
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId

           
/*
INSERT INTO [dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[SupplierIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[BrandIdentifier]
           --,[SupplierInvoiceNumber]
           --,[ReportedUnitPrice]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[WorkingSource]
           ,[LastUpdateUserID]
           ,[SourceIdentifier]
           ,[CorporateIdentifier]
           ,[EDIName])
           --,[DateTimeSourceReceived])
     select distinct
           ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(isnull(SupplierIdentifier, 'DEFAULT')))
           ,sum(Qty)
           ,EffectiveDate
           ,ProductIdentifier
           ,BrandIdentifier
           --,InvoiceNumber
           ,isnull(max(Cost), 0.00)
           ,isnull(max(Retail), 0.00)
           ,'INV'
           ,@MyID
           ,isnull(FileName, 'DEFAULT')
           ,StoreDuns
           ,EDIName
           --,TimeStamp
     from DataTrue_EDI..Inbound846Inventory s
     inner join #tempInboundTransactions t
     on s.RecordID = t.RecordId

	group by ltrim(rtrim(ChainName))
           ,ltrim(rtrim(StoreNumber))
           ,ltrim(rtrim(isnull(SupplierIdentifier, 'DEFAULT')))
           ,EffectiveDate
           ,ProductIdentifier
           ,BrandIdentifier
           ,isnull(FileName, 'DEFAULT')
           ,StoreDuns
           ,EDIName
*/
           
	commit transaction
	
end try
	
begin catch

		rollback transaction
		
		set @loadstatus = -9997
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch
	

update s set RecordStatus = @loadstatus
--from DataTrue_EDI..InBoundSuppliers s
from DataTrue_EDI..Inbound846Inventory s
inner join #tempInboundTransactions t
on s.RecordID = t.RecordID
and s.RecordStatus = 0

/*
select distinct TransactionType from DataTrue_EDI..InBoundSuppliers
select StoreTransactionID into #tmpInboundPOS
from StoreTransactions_Working t
where t.WorkingStatus = 0
and WorkingSource = 'POS'

--Retailer's reported cost is iControl's ReportedSalePrice

update t
set t.ReportedUnitPrice = Case when t.ReportedUnitPrice < 0.0001 then t.ReportedUnitCost else t.ReportedUnitPrice end
from #tmpInboundPOS tmp
inner join StoreTransactions_Working t
on tmp.StoreTransactionID = t.StoreTransactionID

*/



return
GO
