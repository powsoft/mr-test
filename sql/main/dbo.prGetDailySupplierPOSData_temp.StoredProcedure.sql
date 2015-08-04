USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetDailySupplierPOSData_temp]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetDailySupplierPOSData_temp] --24164,62362
	@SupplierID int--=24178,
	,@ChainID int--=42501
As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int=0


begin try

begin transaction


--Declare @SupplierID int=24164; Declare @ChainID int =62362

DECLARE @BillingControlDay INT


select @BillingControlDay=BillingControlDay from BillingControl
where ChainID=@ChainID
and EntityIDToInvoice=@SupplierID

/*
select * from BillingControl
where ChainID=35541 and EntityIDToInvoice=37803
*/

DECLARE @TodayDayOfWeek INT
DECLARE @EndOfPrevWeek DateTime
DECLARE @StartOfPrevWeek DateTime
DECLARE @CurrentDate DateTime =Getdate()

--Please Remove below 
--set @BillingControlDay=2;
print @BillingControlDay

--get number of a current day (1-Sunday,2-Monday, 3-Tuesday... 7-Saturday)
SET @TodayDayOfWeek = datepart(dw, @CurrentDate)
--get the last day of the previous week (last Sunday)
SET @EndOfPrevWeek = DATEADD(dd, @BillingControlDay -@TodayDayOfWeek , @CurrentDate)
--get the first day of the previous week (the Monday before last)
SET @StartOfPrevWeek = DATEADD(dd,@BillingControlDay -(@TodayDayOfWeek+6), @CurrentDate)

print @TodayDayOfWeek
print @EndOfPrevWeek
print @StartOfPrevWeek

declare @InvoiceType nvarchar(10);

select @InvoiceType=AttributeValue from AttributeValues where 
AttributeID = (select AttributeID from AttributeDefinitions where AttributeName='InvoiceIDtoSendSupplier')
and OwnerEntityID=@SupplierID

	Declare @ChainIdentifier nvarchar(50);
	
	select @ChainIdentifier=ChainIdentifier from Chains
	where ChainID=@ChainID
	--temp, please remove after discussing
	Set @InvoiceType='SUP';
if(@InvoiceType='RET')
Begin
	select i.SupplierID,s.SupplierIdentifier,RetailerInvoiceID as "InvoiceID",i.StoreID,
	i.StoreIdentifier,t.LegacySystemStoreIdentifier,InvoiceDetailTypeID,SUM(TotalCost-Adjustment1) as "TotalCost"
	into #tempinvoiceDetails1
	from InvoiceDetails i join Suppliers s
	on i.SupplierID=s.SupplierID
	join Stores t on
	i.StoreID = t.StoreID
	where 1=1
	and CAST(SaleDate as date) between Cast(@StartOfPrevWeek as date) and CAST(@EndOfPrevWeek as date)
	and i.SupplierID=@SupplierID 
	and RetailerInvoiceID is not null
	and SupplierInvoiceID is not null
	and InvoiceDetailTypeID in (1)--,7)
	group by i.SupplierID,s.SupplierIdentifier,RetailerInvoiceID,i.StoreID,i.StoreIdentifier,t.LegacySystemStoreIdentifier,InvoiceDetailTypeID
	

	
INSERT INTO Import.[dbo].[DailySupplierPOSData]
           ([ChainID]
           ,[ChainIdentifier]
           ,[SupplierId]
           ,[SupplierIdentifier]
           ,LegacySystemStoreIdentifier
           ,[WeekEndingDate]
           ,[InvoiceNo]
           ,[StoreID]
           ,[StoreIdentifier]
           ,[NetInvoiceAmount]
           ,[InvoiceTypeID]
           ,[DateTimeCreated]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedBy])
     select @ChainID
		   ,@ChainIdentifier
           ,@SupplierID
           ,SupplierIdentifier
           ,LegacySystemStoreIdentifier
           ,@EndOfPrevWeek
           ,InvoiceID
           ,StoreID
           ,StoreIdentifier
           ,TotalCost 
           ,InvoiceDetailTypeID
           ,GETDATE()
           ,GETDATE()
           ,@MyID
           from #tempinvoiceDetails1
end
Else
Begin
	select i.SupplierID,s.SupplierIdentifier,SupplierInvoiceID as "InvoiceID",i.StoreID,i.StoreIdentifier,
	t.LegacySystemStoreIdentifier,
	InvoiceDetailTypeID,SUM(TotalCost-Adjustment1) as "TotalCost"
	into #tempinvoiceDetails2
	from InvoiceDetails i join Suppliers s
	on i.SupplierID=s.SupplierID
	join Stores t on i.StoreID=t.StoreID
	where 1=1
	and CAST(SaleDate as date) between Cast(@StartOfPrevWeek as date) and CAST(@EndOfPrevWeek as date)
	and i.SupplierID=@SupplierID --and InvoiceNo is not null and ltrim(rtrim(InvoiceNo))<>''
	and RetailerInvoiceID is not null
	and SupplierInvoiceID is not null
	and InvoiceDetailTypeID in (1)--,3,7,9)
	group by i.SupplierID,s.SupplierIdentifier,SupplierInvoiceID,i.StoreID,i.StoreIdentifier,t.LegacySystemStoreIdentifier,InvoiceDetailTypeID
	
	
INSERT INTO import.dbo.[DailySupplierPOSData]
           ([ChainID]
           ,[ChainIdentifier]
           ,[SupplierId]
           ,[SupplierIdentifier]
           ,LegacySystemStoreIdentifier
           ,[WeekEndingDate]
           ,[InvoiceNo]
           ,[StoreID]
           ,[StoreIdentifier]
           ,[NetInvoiceAmount]
           ,[InvoiceTypeID]
           ,[DateTimeCreated]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedBy])
     select @ChainID
		   ,@ChainIdentifier
           ,@SupplierID
           ,SupplierIdentifier
           ,LegacySystemStoreIdentifier
           ,@EndOfPrevWeek
           ,InvoiceID
           ,StoreID
           ,StoreIdentifier
           ,TotalCost 
           ,InvoiceDetailTypeID
           ,GETDATE()
           ,GETDATE()
           ,@MyID
           from #tempinvoiceDetails2
End

--select * from #tempinvoiceDetails

exec [prReportDailySupplierPOS_Weekly_temp] @SupplierID


commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch

/*
truncate table import.dbo.[DailySupplierPOSData]

select * from import.dbo.[DailySupplierPOSData]
--select * 
--delete
from [DataTrue_Main].[dbo].[DailySupplierPOSData] where Cast(weekendingDate as date)='9/8/2013'

*/
GO
