USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCValidate_Process]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCValidate_Process]

as

declare @errorsenderstring nvarchar(255)
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @loadstatus smallint
declare @MyID int
set @MyID = 0

begin try
--drop table  #tempTableCounts
select 0 as MainCount,0 as ReportCount into #tempTableCounts
select * from #tempTableCounts

alter table #tempTableCounts add TableName  nvarchar(250)
select * from #tempTableCounts

truncate table #tempTableCounts

insert into #tempTableCounts(TableName,MainCount,ReportCount) select 'StoreTransactions', COUNT(StoreTransactionID) ,(SELECT COUNT(StoreTransactionID) FROM  DataTrue_Report.dbo.StoreTransactions R)
from StoreTransactions [no lock]

insert into #tempTableCounts(TableName,MainCount,ReportCount) select 'StoresUniqueValues', COUNT(*) ,(SELECT COUNT(*) FROM  DataTrue_Report.dbo.StoresUniqueValues R)
from StoresUniqueValues S


insert into #tempTableCounts(TableName,MainCount,ReportCount) select 'InvoiceDetails', COUNT(InvoiceDetailId),(SELECT COUNT(InvoiceDetailId) FROM  DataTrue_Report.dbo.InvoiceDetails R)
from InvoiceDetails S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Addresses', COUNT(AddressID),(SELECT COUNT(AddressID) FROM  DataTrue_Report.dbo.Addresses R)
from Addresses S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'AttributeDefinitions', COUNT(AttributeID),(SELECT COUNT(AttributeID) 
FROM  DataTrue_Report.dbo.AttributeDefinitions R)
from AttributeDefinitions S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'AttributeValues', COUNT(AttributeValue),(SELECT COUNT(AttributeValue) 
FROM  DataTrue_Report.dbo.AttributeValues R)
from AttributeValues S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Brands', COUNT(BrandID),(SELECT COUNT(BrandID) 
FROM  DataTrue_Report.dbo.Brands R)
from Brands S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Chains', COUNT(ChainID),(SELECT COUNT(ChainID) 
FROM  DataTrue_Report.dbo.Chains R)
from Chains S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Clusters', COUNT(ClusterID),(SELECT COUNT(ClusterID) 
FROM  DataTrue_Report.dbo.Clusters R)
from Clusters S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ContactInfo', COUNT(ContactID),(SELECT COUNT(ContactID) 
FROM  DataTrue_Report.dbo.ContactInfo R)
from ContactInfo S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'CostZoneRelations', COUNT(CostZoneRelationID),(SELECT COUNT(CostZoneRelationID) 
FROM  DataTrue_Report.dbo.CostZoneRelations R)
from CostZoneRelations S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'CostZones', COUNT(CostZoneID),(SELECT COUNT(CostZoneID) 
FROM  DataTrue_Report.dbo.CostZones R)
from CostZones S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'EntityTypes', COUNT(EntityTypeID),(SELECT COUNT(EntityTypeID) 
FROM  DataTrue_Report.dbo.EntityTypes R)
from EntityTypes S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'InventoryPerpetual', COUNT(RecordID),(SELECT COUNT(RecordID) 
FROM  DataTrue_Report.dbo.InventoryPerpetual R)
from InventoryPerpetual S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'InventorySettlementRequests', COUNT(InventorySettlementRequestID),(SELECT COUNT(InventorySettlementRequestID) 
FROM  DataTrue_Report.dbo.InventorySettlementRequests R)
from InventorySettlementRequests S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'InvoiceDetailStatus', COUNT(StatusID),(SELECT COUNT(StatusID) 
FROM  DataTrue_Report.dbo.InvoiceDetailStatus R)
from InvoiceDetailStatus S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'InvoiceDetailTypes', COUNT(InvoiceDetailTypeID),(SELECT COUNT(InvoiceDetailTypeID) 
FROM  DataTrue_Report.dbo.InvoiceDetailTypes R)
from InvoiceDetailTypes S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'MaintenanceRequests', COUNT(MaintenanceRequestID),(SELECT COUNT(MaintenanceRequestID) 
FROM  DataTrue_Report.dbo.MaintenanceRequests R)
from MaintenanceRequests S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Manufacturers', COUNT(ManufacturerID),(SELECT COUNT(ManufacturerID) 
FROM  DataTrue_Report.dbo.Manufacturers R)
from Manufacturers S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'MembershipTypes', COUNT(MembershipTypeID),(SELECT COUNT(MembershipTypeID) 
FROM  DataTrue_Report.dbo.MembershipTypes R)
from MembershipTypes S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Memberships', COUNT(MembershipTypeID),(SELECT COUNT(MembershipTypeID) 
FROM  DataTrue_Report.dbo.Memberships R)
from Memberships S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Persons', COUNT(PersonID),(SELECT COUNT(PersonID) 
FROM  DataTrue_Report.dbo.Persons R)
from Persons S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ProductBrandAssignments', COUNT(ProductId),(SELECT COUNT(ProductId) 
FROM  DataTrue_Report.dbo.ProductBrandAssignments R)
from ProductBrandAssignments S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ProductCategories', COUNT(ProductCategoryID),(SELECT COUNT(ProductCategoryID)
FROM  DataTrue_Report.dbo.ProductCategories R)
from ProductCategories S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ProductCategoryAssignments', COUNT(ProductID),(SELECT COUNT(ProductID)
FROM  DataTrue_Report.dbo.ProductCategoryAssignments R)
from ProductCategoryAssignments S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ProductIdentifiers', COUNT(ProductID),(SELECT COUNT(ProductID)
FROM  DataTrue_Report.dbo.ProductIdentifiers R)
from ProductIdentifiers S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ProductIdentifierTypes', COUNT(ProductIdentifierTypeID),(SELECT COUNT(ProductIdentifierTypeID)
FROM  DataTrue_Report.dbo.ProductIdentifierTypes R)
from ProductIdentifierTypes S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ProductPrices', COUNT(ProductPriceID),(SELECT COUNT(ProductPriceID)
FROM  DataTrue_Report.dbo.ProductPrices R)
from ProductPrices S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'ProductPriceTypes', COUNT(ProductPriceTypeID),(SELECT COUNT(ProductPriceTypeID)
FROM  DataTrue_Report.dbo.ProductPriceTypes R)
from ProductPriceTypes S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Products', COUNT(ProductID),(SELECT COUNT(ProductID)
FROM  DataTrue_Report.dbo.Products R)
from Products S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Roles', COUNT(RoleID),(SELECT COUNT(RoleID)
FROM  DataTrue_Report.dbo.Roles R)
from Roles S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Source', COUNT(SourceID),(SELECT COUNT(SourceID)
FROM  DataTrue_Report.dbo.Source R)
from Source S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'SourceTypes', COUNT(SourceTypeID),(SELECT COUNT(SourceTypeID)
FROM  DataTrue_Report.dbo.SourceTypes R)
from SourceTypes S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Statuses', COUNT(StatusID),(SELECT COUNT(StatusID)
FROM  DataTrue_Report.dbo.Statuses R)
from Statuses S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'StatusTypes', COUNT(StatusTypeID),(SELECT COUNT(StatusTypeID)
FROM  DataTrue_Report.dbo.StatusTypes R)
from StatusTypes S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Stores', COUNT(StoreID),(SELECT COUNT(StoreID)
FROM  DataTrue_Report.dbo.Stores R)
from Stores S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'StoreSetup', COUNT(StoreSetupID),(SELECT COUNT(StoreSetupID)
FROM  DataTrue_Report.dbo.StoreSetup R)
from StoreSetup S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'Suppliers', COUNT(SupplierID),(SELECT COUNT(SupplierID)
FROM  DataTrue_Report.dbo.Suppliers R)
from Suppliers S

insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'SupplierBanners', COUNT(SupplierID),(SELECT COUNT(SupplierID)
FROM  DataTrue_Report.dbo.SupplierBanners R)
from SupplierBanners S


insert into #tempTableCounts(TableName,MainCount,ReportCount) 
select 'SystemEntities', COUNT(EntityId),(SELECT COUNT(EntityId)
FROM  DataTrue_Report.dbo.SystemEntities R)
from SystemEntities S


alter table #tempTableCounts add Difference int

update #tempTableCounts set Difference=MainCount-ReportCount

select * from #tempTableCounts where DIFFERENCE <> 0

declare @recCount int=0;

Select @recCount=COUNT(TableName)  from #tempTableCounts where DIFFERENCE <> 0

if (@recCount<>0) --or (1 = 0)
begin

	declare @body varchar(max)='Count in few table(s) are not matching';
	set @body=@body+'<table style=" border-collapse: collapse;text-align:left; font-family: ''Lucida Sans Unicode'',''Lucida Grande'',Sans-Serif;font-size: 12px;">';
	set @body=@body + '<tr><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Table Name</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Count(Datetrue_Main)</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Count(Datatrue_Report)</th><th style="border-bottom: 2px solid #6678B1;border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #003399;font-size: 14px;font-weight: normal;padding: 8px 2px;">Difference</th></tr>'
	
	select 
		--@body=@body + '<tr><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+ TableName +'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+CAST(MainCount as varchar)+'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+CAST(ReportCount as varchar)+'</td><td style=" border-left: 30px solid #FFFFFF;border-right: 30px solid #FFFFFF;color: #666699;padding: 12px 2px 0;">'+Cast(DIFFERENCE as varchar)+'</td></tr>'
		@body=@body + '<tr><td>'+ TableName +'</td><td>'+CAST(MainCount as varchar)+'</td><td>'+CAST(ReportCount as varchar)+'</td><td>'+Cast(DIFFERENCE as varchar)+'</td></tr>'
	from #tempTableCounts where DIFFERENCE<>0
	
	set @body=@body+'</table>';
		
		set @errormessage = @body;
		set @errorlocation = 'Data found during execution of prValidateCDC_Process'
		set @errorsenderstring = 'prCDCValidate_Process'
		
		--exec dbo.[prLogExceptionAndNotifySupport_HTML]
		--2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
	end
	
else
	Begin
		set @errormessage = 'All the tables have correct data.'
			set @errorlocation = 'Data found during execution of prValidateCDC_Process'
			set @errorsenderstring = 'prCDCValidate_Process'
			
			--exec dbo.prLogExceptionAndNotifySupport
			--2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
			--,@errorlocation
			--,@errormessage
			--,@errorsenderstring
			--,@MyID
	End
	
end try
	
begin catch

		
		--set @loadstatus = -9997
		
		--set @errormessage = error_message()
		--set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		--set @errorsenderstring = ERROR_PROCEDURE()
		
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
end catch
GO
