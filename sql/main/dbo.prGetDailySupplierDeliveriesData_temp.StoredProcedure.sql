USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetDailySupplierDeliveriesData_temp]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetDailySupplierDeliveriesData_temp]-- 24164,62362
	@SupplierID int,--=24178,
	@ChainID int-- =42501
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int=0

begin try

begin transaction

	--Declare @SupplierID int=26922;	Declare @ChainID int =62362

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
--drop table #temp
--drop table #tempInvoiceDetails

select ChainID,SupplierID,StoreID,ProductID,BrandID,IsNUll(RuleCost,0) as "RuleCost",
Qty,TransactionTypeID,--StoreName,
datename(W,SaleDateTime)+ 'Draw' as "wDay"
into #temp
--select *
from DataTrue_Main..Storetransactions_forward
where TransactionTypeID in (29)
and CAST(SaleDateTime as date) between Cast(@StartOfPrevWeek as date) and CAST(@EndOfPrevWeek as date)
and SupplierID=@SupplierID
and RuleCost is not null and RuleCost<>0

--Declare @SupplierID int=24164;	Declare @ChainID int =62362
select ChainID,SupplierID,StoreID,ProductID
,BrandID,datename(W,SaleDate)+ 'POS' as SaleDay,
SUM(TotalQty) as Qty
into #tempInvoiceDetails
from InvoiceDetails i
where SupplierID=@SupplierID
and ChainID=@ChainID
and Cast(SaleDate as date) between Cast(@StartOfPrevWeek as date) and CAST(@EndOfPrevWeek as date)
and InvoiceDetailTypeID in (1,7)
and RetailerInvoiceID is not null
and SupplierInvoiceID is not null
group by ChainID,SupplierID,StoreID
,ProductID
,BrandID,datename(W,SaleDate)+ 'POS' 


/*

drop table #tempInvoiceDetails
select * from #temp
order by ChainID, SupplierID,StoreID

select * from #tempInvoiceDetails
*/
----drop table #tempCost
--select * into #tempCost from #temp
--pivot(sum(RuleCost) for TransactionTypeID in ([5],[8])) as Perday
--order by ChainID, SupplierID,StoreID

--select * from #tempCost

--drop table #temp1
--drop table #tempFinalData

Select a.*,b.MondayPOS,b.TuesdayPOS,b.WednesdayPOS,b.ThursdayPOS,b.FridayPOS,b.SaturdayPOS,b.SundayPOS,
CAST(NULL as nvarchar(50)) as "StoreName",CAST(NULL as nvarchar(50)) as "ProductName",
CAST(NULL as nvarchar(50)) as "SupplierStoreValue",
CAST(NULL as nvarchar(50)) as "BiPad",
CAST(NULL as nvarchar(50)) as "TitleID",
CAST(NULL as nvarchar(50)) as "SupplierIdentifier",
CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier"
into #tempFinalData 
from 
(select * 
from #temp
pivot(sum(Qty) for wDay in ([MondayDraw],TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
--order by ChainID, SupplierID,StoreID,ProductID
) a
join 
(select * from #tempInvoiceDetails
pivot (sum(Qty) for SaleDay in (MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)) as POS_eachday
--order by ChainID,SupplierID,StoreID,ProductID
)b on
a.ChainID=b.ChainID and a.SupplierID=b.SupplierID and a.StoreID=b.StoreID 
and a.ProductID=b.ProductID
and a.BrandID=b.BrandID

declare @rowCount int;
declare @rowCount1 int;

select * into #tempMissingRows from #tempInvoiceDetails
pivot (sum(Qty) for SaleDay in (MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)) as POS_eachday

select @rowCount1=COUNT(*) from #tempMissingRows
select @rowCount=COUNT(*) from #tempFinalData

if(@rowCount1 > @rowCount)
Begin

	insert into #tempFinalData (ChainID,SupplierID,StoreID,ProductID,BrandID,MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,
	SaturdayPOS,SundayPOS,RuleCost,TransactionTypeID )
	select m.ChainID,m.SupplierID,m.StoreID,m.ProductID,m.BrandID,m.MondayPOS,m.TuesdayPOS,m.WednesdayPOS,m.ThursdayPOS,m.FridayPOS,
	m.SaturdayPOS ,m.SundayPOS,0,29
	from #tempMissingRows m left join #tempFinalData f
	on m.ChainID=f.ChainID
	and m.SupplierID=f.SupplierID
	and m.StoreID=f.StoreID
	and m.ProductID=f.ProductID
	where f.ChainID is null
	
	
	update t set t.RuleCost=i.UnitCost
	from #tempFinalData t join InvoiceDetails i
	on t.ChainID=i.ChainID and t.SupplierID=i.SupplierID and t.StoreID=i.StoreID
	and t.ProductID=i.ProductID	
	where RuleCost=0
	and Cast(SaleDate as date) between Cast(@StartOfPrevWeek as date) and CAST(@EndOfPrevWeek as date)
	and InvoiceDetailTypeID in (1,7)
	
	
End


--select * from #tempFinalData


update f set f.ProductName=(select ProductName from Products where ProductID=f.ProductID)
from #tempFinalData f

--Declare @SupplierID int=24164;	Declare @ChainID int =62362
update f set f.SupplierStoreValue=(select top 1 SupplierStoreValue 
from DataTrue_EDI.dbo.NewspapersMapping_Stores s
where s.DataTrueSupplierId = @SupplierID and s.DataTrueStoreID=f.StoreID),
f.Bipad=(select distinct Bipad from ProductIdentifiers
where ProductIdentifierTypeID=8
and ProductID=f.ProductID)
--select *
from #tempFinalData f

alter table #tempFinalData add UPC nvarchar(50)

update f set UPC=i.IdentifierValue
from #tempFinalData f join ProductIdentifiers i
on f.ProductID=i.ProductID

update f set f.Bipad=i.Bipad
from #tempFinalData f join ProductIdentifiers i
on f.UPC=i.IdentifierValue 
and i.Bipad is not null



--Declare @SupplierID int=24164;	Declare @ChainID int =62362
update f set f.TitleID=(Select distinct top 1 SupplierProductValue 
from DataTrue_EDI.dbo.NewspapersMapping_Products
where DataTrueSupplierID=@SupplierID and icontrolBipadWeekDays=f.BiPad)
from #tempFinalData f


--Declare @SupplierID int=24164;	Declare @ChainID int =62362
update f set f.SupplierIdentifier=(Select distinct top 1 SupplierIdentifier
from Suppliers
where SupplierID=@SupplierID),
f.LegacySystemStoreIdentifier =(Select distinct top 1 LegacySystemStoreIdentifier
from Stores
where CAST(StoreID as nvarchar)= CAST(f.StoreID as nvarchar))
from #tempFinalData f

--select * from #tempFinalData f
update f set f.StoreName=s.StoreName
from #tempFinalData f join Stores s
on f.StoreID=s.StoreID

declare @ChainIdentifier nvarchar(50);

select @ChainIdentifier=ChainIdentifier from DataTrue_Main.dbo.Chains where ChainID=@ChainID

INSERT INTO import.dbo.[DailySupplierDeliveriesData]
           ([WeekEndingDate]
           ,[SupplierIdentifier]
           ,LegacySystemStoreIdentifier
           ,[SupplierID]
           ,[StoreID]
           ,[StoreName]
           ,[AccountNumber]
           ,[Title]
           ,[MondayDraw]
           ,[MondayPOS]
           ,[TuesdayDraw]
           ,[TuesdayPOS]
           ,[WednesdayDraw]
           ,[WednesdayPOS]
           ,[ThursdayDraw]
           ,[ThursdayPOS]
           ,[FridayDraw]
           ,[FridayPOS]
           ,[SaturdayDraw]
           ,[SaturdayPOS]
           ,[SundayDraw]
           ,[SundayPOS]
           ,[WeeklyDraws]
           ,[WeeklyPOS]
           ,[CostToStore]
           ,[ChainID]
           ,ChainIdentifier
           ,[Bipad]
           ,[TitleID]
           )
     Select
           @EndOfPrevWeek
           ,SupplierIdentifier
           ,LegacySystemStoreIdentifier
           ,@SupplierID
           ,StoreID
           ,StoreName
           ,SupplierStoreValue
           ,ProductName
           ,ISNull([MondayDraw],0)
           ,ISNull([MondayPOS],0)
           ,ISNull([TuesdayDraw],0)
           ,ISNull([TuesdayPOS],0)
           ,ISNull([WednesdayDraw],0)
           ,ISNull([WednesdayPOS],0)
           ,ISNull([ThursdayDraw],0)
           ,ISNull([ThursdayPOS],0)
           ,ISNull([FridayDraw],0)
           ,ISNull([FridayPOS],0)
           ,ISNull([SaturdayDraw],0)
           ,ISNull([SaturdayPOS],0)
           ,ISNull([SundayDraw],0)
           ,ISNull([SundayPOS],0)
           ,ISNull([MondayDraw],0)+ISNull([TuesdayDraw],0)+ISNull([WednesdayDraw],0)+ISNull([ThursdayDraw],0)+ISNull([FridayDraw],0)+ISNull([SaturdayDraw],0)+ISNull([SundayDraw],0)
           ,ISNull([MondayPOS],0)+ISNull([TuesdayPOS],0)+ISNull([WednesdayPOS],0)+ISNull([ThursdayPOS],0)+ISNull([FridayPOS],0)+ISNull([SaturdayPOS],0)+ISNull([SundayPOS],0)
           ,[RuleCost]
           ,@ChainID
           ,@ChainIdentifier
           ,Bipad
           ,TitleID
			from #tempFinalData



exec DataTrue_Main..[prReportDailySupplierDeliveries_Weekly_temp] @SupplierID

commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		print @errormessage
		exec DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch

/*
--select * 
--delete
from [DataTrue_Main].[dbo].[DailySupplierDeliveriesData] 
where Cast(weekEndingDate as date)='9/8/2013'
select * from import.dbo.[DailySupplierDeliveriesData]
truncate table import.dbo.[DailySupplierDeliveriesData]
select *
--update f set f.RuleCost=i.UnitCost,f.RuleRetail=i.UnitRetail
--update f set f.RuleCost=null,f.RuleRetail=null
from DataTrue_Main..Storetransactions_forward f
join invoicedetails i on f.StoreID=i.StoreID
and f.ChainID=i.ChainID
and f.SupplierID=i.SupplierID
and CAST(f.SaleDateTime as date)=CAST(i.SaleDate as date)
and f.ProductID=i.ProductID

*/
GO
