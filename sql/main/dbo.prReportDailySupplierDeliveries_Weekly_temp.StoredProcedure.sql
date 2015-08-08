USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReportDailySupplierDeliveries_Weekly_temp]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure  [dbo].[prReportDailySupplierDeliveries_Weekly_temp]-- 24636
	@SupplierID int--=35113
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int=0


begin try

begin transaction

	--declare @SupplierID int = 24636
DECLARE @TodayDayOfWeek INT
DECLARE @EndOfPrevWeek DateTime
DECLARE @CurrentDate DateTime =Getdate()
DECLARE @BillingControlDay INT

select @BillingControlDay=BillingControlDay from BillingControl
where EntityIDToInvoice=@SupplierID
--set @BillingControlDay=1
--get number of a current day (1-Sunday,2-Monday, 3-Tuesday... 7-Saturday)
SET @TodayDayOfWeek = datepart(dw, @CurrentDate)
--get the last day of the previous week (last Sunday)
SET @EndOfPrevWeek = DATEADD(dd, @BillingControlDay -@TodayDayOfWeek  , @CurrentDate)
print @EndOfPrevWeek
--Please Remove below 

print @BillingControlDay
--drop table #tempSalesData
	select * into #tempSalesData
	--select *
	FROM import.[dbo].[DailySupplierDeliveriesData]
	where SupplierID=@SupplierID and IsSend is null
	and Cast([WeekEndingDate] as date) = Cast(@EndOfPrevWeek as date);

	--select * from #temp
	
	update d set d.IsSend='True', d.ReportSendDate=getdate()
	from #tempSalesData t join Import.[dbo].[DailySupplierDeliveriesData] d
	on t.RecordID=d.RecordID

	SELECT Cast(Cast([WeekEndingDate] as date) as nvarchar(10)) as "Week Ending"
      ,[SupplierIdentifier] as "iControl ID"
      ,[StoreName] as "Store"
      ,[AccountNumber] as "Your Account #"
      ,[Title]
      ,[MondayDraw] as "Monday Draw"
      ,[MondayDraw]-[MondayPOS] as "Monday Returns"
      ,[TuesdayDraw] as "Tuesday Draw"
      ,[TuesdayDraw] - [TuesdayPOS] as "Tuesday Returns"
      ,[WednesdayDraw] as "Wednesday Draw"
      ,[WednesdayDraw] - [WednesdayPOS] as "Wednesday Returns"
      ,[ThursdayDraw] as "Thursday Draw"
      ,[ThursdayDraw]-[ThursdayPOS] as "Thursday Returns"
      ,[FridayDraw] as "Friday Draw"
      ,[FridayDraw]-[FridayPOS] as "Friday Returns"
      ,[SaturdayDraw] as "Saturday Draw"
      ,[SaturdayDraw]-[SaturdayPOS] as "Saturday Returns"
      ,[SundayDraw] as "Sunday Draw"
      ,[SundayDraw]-[SundayPOS] as "Sunday Returns"
      ,WeeklyDraws as "Weekly Draws"
      ,ISNULL(WeeklyDraws - WeeklyPOS,0) as "Weekly Returns"
      ,ISNULL(WeeklyPOS,0) as "Weekly Net"
      ,ISNULL([CostToStore],0) as "Cost to Store($)"
      ,ISNULL([CostToStore] * WeeklyPOS,0) as [Total$ (Extended)]
      ,ISNULL(LegacySystemStoreIdentifier,0)  as "StoreID"
      ,ChainIdentifier as [ChainID]
      ,[Bipad]
      ,[TitleID]
  from #tempSalesData


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
