USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Supplier_Add]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Supplier_Add]
as

Declare @chainid int
Declare @supplierid int
Declare @suppliername nvarchar(50) = 'Executive Wine of Michigan' --60653
declare @supplieridentifier nvarchar(50) = 'EXECWINE'
declare @supplieruniqueediname nvarchar(50) = 'EXECWINE'

/*

*/

insert into SystemEntities
(EntityTypeID, LastUpdateUserID)
values(5, 0)

set @supplierid = SCOPE_IDENTITY()

print @suppliername
print @supplierid

insert into Suppliers
(SupplierID, SupplierName, SupplierIdentifier, EDIName, SupplierDescription, ActiveStartDate, ActiveLastDate, LastUpdateUserID, InventoryIsActive)
values(@supplierid, @suppliername, @supplieridentifier, @supplieruniqueediname, @suppliername, '1/1/2013', '12/31/2025', 0, 1)



select * from Suppliers where SupplierID = 62413

select *
from supplierbanners
order by supplierid

select *
from stores
where ChainID = 50964

select distinct LTRIM(RTRIM(custom1))
from stores
where ChainID = 50964

declare @rec cursor
--Declare @supplierid int= 62413
--declare @chainid int= 50964
declare @banner nvarchar(50)

set @rec = CURSOR local fast_forward FOR
select distinct LTRIM(RTRIM(custom1))
from stores
where ChainID = @chainid

open @rec

fetch next from @rec into @banner

while @@FETCH_STATUS = 0
	begin
		select *
		from SupplierBanners
		where SupplierId = @supplierid
		and Banner = @banner
		
		if @@ROWCOUNT < 1
			begin
				INSERT INTO [DataTrue_Main].[dbo].[SupplierBanners]
					   ([ChainID]
					   ,[SupplierId]
					   ,[Banner]
					   ,[Status])
				 VALUES
					   (@chainid --<ChainID, int,>
					   ,@supplierid --<SupplierId, int,>
					   ,@banner --<Banner, nvarchar(50),>
					   ,'Active') --<Status, varchar(8),>)


			end
		fetch next from @rec into @banner	
	end
	
close @rec
deallocate @rec

select *
from storesetup
where SupplierID = 62413

select storeid from stores
where ChainID = 50964
and Custom2 in 
('1400',
'1570',
'1571',
'1572',
'1573',
'1574',
'1575',
'1576',
'1577',
'1588',
'1591')













insert storesetup
SELECT [ChainID]
      , 50990--[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[BrandID]
      ,[InventoryRuleID]
      ,[InventoryCostMethod]
      ,[SunLimitQty]
      ,[SunFrequency]
      ,[MonLimitQty]
      ,[MonFrequency]
      ,[TueLimitQty]
      ,[TueFrequency]
      ,[WedLimitQty]
      ,[WedFrequency]
      ,[ThuLimitQty]
      ,[ThuFrequency]
      ,[FriLimitQty]
      ,[FriFrequency]
      ,[SatLimitQty]
      ,[SatFrequency]
      ,[RetailerShrinkPercent]
      ,[SupplierShrinkPercent]
      ,[ManufacturerShrinkPercent]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[SetupReportedToRetailerDate]
      ,[FileName]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[IncludeInForwardTransactions]
      ,[PDIParticipant]
      --select *
  FROM [DataTrue_Main].[dbo].[StoreSetup]
where SupplierID = 62413
and StoreID = 0



select distinct 'MRTable' as TableName, Banner from MaintenanceRequests where SupplierId=44270
 union all
select distinct 'StoreSetup' as TableName, Custom1 as Banner from Stores S inner join StoreSetup SS on SS.StoreId=S.StoreId where SS.SupplierId=44270
union all
select distinct 'SupplierBanner' as TableName, Banner from SupplierBanners where SupplierId=44270
 union all
select distinct 'ProductPrices' as TableName, Custom1 as Banner from Stores S inner join ProductPrices SS on SS.StoreId=S.StoreId where SS.SupplierId=44270
union all
select distinct 'InvoiceDetails' as TableName, Custom1 as Banner from Stores S inner join InvoiceDetails SS on SS.StoreId=S.StoreId where SS.SupplierId=44270
 
/*

47
select * from chains 
select * from stores where chainid = 50964
select distinct custom1 from stores where chainid = 50964

select * from datatrue_main.dbo.suppliers order by supplierid desc
select * from datatrue_edi.dbo.suppliers order by supplierid desc
select * from datatrue_report.dbo.suppliers order by supplierid desc

select *
from storesetup
where storeid = 0
and productid = 0
50964 spartan
51068 Paw Paw

1. Suppliers 
2. StoreSetup
3. SupplierBanners
4. SupplierFormat
5. Stores Table (with ActiveStatus = 'Active')

select * from stores where chainid = 42491
select * from  chains
select * from suppliers order by supplierid desc

6. If you are adding records to ProductPrices table then make sure to run the job named 'Generate_Data_For_Default_Cost_List' to update the temp tables.


--select *
--from storesetup
--where StoreID = 0

·         iControl 50726

·         Coca Cola 50724

·         Frito Lay 50725

INSERT INTO [DataTrue_EDI].[dbo].[Suppliers]
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[SupplierDescription]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[RegistrationDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[DunsNumber]
           ,[EDIName])
SELECT [SupplierID]
      ,[SupplierName]
      ,[SupplierIdentifier]
      ,[SupplierDescription]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[RegistrationDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[DunsNumber]
      ,[EDIName]
  FROM [DataTrue_Main].[dbo].[Suppliers]
where SupplierID not in 
(select SupplierID from [DataTrue_EDI].[dbo].[Suppliers])


INSERT INTO [DataTrue_Report].[dbo].[Suppliers]
           ([SupplierID]
           ,[SupplierName]
           ,[SupplierIdentifier]
           ,[SupplierDescription]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[RegistrationDate]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[DunsNumber]
           ,[EDIName])
SELECT [SupplierID]
      ,[SupplierName]
      ,[SupplierIdentifier]
      ,[SupplierDescription]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[RegistrationDate]
      ,[Comments]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[DunsNumber]
      ,[EDIName]
  FROM [DataTrue_Main].[dbo].[Suppliers]
where SupplierID not in 
(select SupplierID from [DataTrue_Report].[dbo].[Suppliers])
*/

return
GO
