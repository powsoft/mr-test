USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReportDailySupplierPOS_Weekly_temp]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure  [dbo].[prReportDailySupplierPOS_Weekly_temp] --24164
	@SupplierID int
as
declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int=0
begin try

begin transaction

--declare @SupplierID int = 24164
DECLARE @TodayDayOfWeek INT
DECLARE @EndOfPrevWeek DateTime
DECLARE @CurrentDate DateTime =Getdate()
DECLARE @BillingControlDay INT

select @BillingControlDay=BillingControlDay from BillingControl
where EntityIDToInvoice=@SupplierID

--get number of a current day (1-Sunday,2-Monday, 3-Tuesday... 7-Saturday)
SET @TodayDayOfWeek = datepart(dw, @CurrentDate)
--get the last day of the previous week (last Sunday)
SET @EndOfPrevWeek = DATEADD(dd, @BillingControlDay -@TodayDayOfWeek  , @CurrentDate)
print @EndOfPrevWeek
--Please Remove below 

print @BillingControlDay

	SELECT [SupplierIdentifier] as "Wholesaler ID"
      ,Cast(Cast([WeekEndingDate] as date) as nvarchar(10)) as "Week Ending"
      ,[InvoiceNo] as "Invoice No"
      ,LegacySystemStoreIdentifier as "Store ID"
      ,[StoreIdentifier] as "WHLS_StoreID"
      ,[NetInvoiceAmount] as "NetInvoice"
      ,Case [InvoiceTypeID] 
		when 1 then 'POS' 
		when 3 then 'RET Shrink' 
		when 7 then 'ADJ POS' 
		when 9 then 'ADJ RET Shrink' 
		End
		as "InvType"
  FROM Import.[dbo].[DailySupplierPOSData]
	where SupplierID=@SupplierID
	and Cast([WeekEndingDate] as date) = Cast(@EndOfPrevWeek as date);


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
GO
