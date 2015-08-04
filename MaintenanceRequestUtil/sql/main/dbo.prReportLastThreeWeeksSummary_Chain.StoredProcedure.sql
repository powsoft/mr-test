USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReportLastThreeWeeksSummary_Chain]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prReportLastThreeWeeksSummary_Chain]

As

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int=0

begin try

begin transaction



DECLARE @TodayDayOfWeek INT
DECLARE @EndOfPrevWeek DateTime
DECLARE @EndOfPrevWeek1 DateTime
DECLARE @EndOfPrevWeek2 DateTime
DECLARE @StartOfPrevWeek DateTime
DECLARE @StartOfPrevWeek1 DateTime
DECLARE @StartOfPrevWeek2 DateTime
DECLARE @CurrentDate DateTime ='9/12/2013'--Getdate()

--get number of a current day (1-Sunday,2-Monday, 3-Tuesday... 7-Saturday)
SET @TodayDayOfWeek = datepart(dw, @CurrentDate)
--get the last day of the previous week (last Sunday)
SET @EndOfPrevWeek = DATEADD(dd, 1-@TodayDayOfWeek , @CurrentDate)
SET @EndOfPrevWeek1 = DATEADD(dd, -7, @EndOfPrevWeek)
SET @EndOfPrevWeek2 = DATEADD(dd, -7, @EndOfPrevWeek1)
SET @StartOfPrevWeek = DATEADD(dd, -6, @EndOfPrevWeek)
SET @StartOfPrevWeek1 = DATEADD(dd, -6, @EndOfPrevWeek1)
SET @StartOfPrevWeek2 = DATEADD(dd, -6, @EndOfPrevWeek2)

print @TodayDayOfWeek
print @EndOfPrevWeek
print @EndOfPrevWeek1
print @EndOfPrevWeek2
print @StartOfPrevWeek
print @StartOfPrevWeek1
print @StartOfPrevWeek2

	--drop table #tempinvoiceDetails1

	select InvoiceDetailTypeID,ChainID,cast(SaleDate as date) as SaleDate,Cast(Null as date) as WeekEnding,SUM(TotalCost) as "TotalCost"
	into #tempinvoiceDetails
	--select *
	from InvoiceDetails i 
	where 1=1
	and CAST(SaleDate as date) between Cast(@StartOfPrevWeek2 as date) and CAST(@EndOfPrevWeek as date)
	and InvoiceDetailTypeID in (1,7)
	group by InvoiceDetailTypeID,ChainID,cast(SaleDate as date)
	
	update #tempinvoiceDetails set WeekEnding = Case 
		when CAST(SaleDate as date) between CAST(@StartOfPrevWeek as date) and CAST(@EndOfPrevWeek as date) then @EndOfPrevWeek
		when CAST(SaleDate as date) between CAST(@StartOfPrevWeek1 as date) and CAST(@EndOfPrevWeek1 as date) then @EndOfPrevWeek1
		when CAST(SaleDate as date) between CAST(@StartOfPrevWeek2 as date) and CAST(@EndOfPrevWeek2 as date) then @EndOfPrevWeek2
	end
	
	
	--select *	from #tempinvoiceDetails order by ChainID
	
	select InvoiceDetailTypeID,ChainID,WeekEnding,SUM(TotalCost) as "NetCost" into #tempinvoiceDetails1
	from #tempinvoiceDetails
	group by InvoiceDetailTypeID,ChainID,WeekEnding
	
	--select *	from #tempinvoiceDetails1
	
--drop table #tempWeeklyComparison
--drop table #tempWeeklyComparison1
	
		select Case [InvoiceDetailTypeID] 
				when 1 then 'POS' 
				when 7 then 'ADJ POS' 
				End
				as "InvType"
				,ChainID as iControlChainID
				,CAST(NULL as nvarchar(50)) as "Chain ID"
				,WeekEnding as "Week Ending Date"
				,NetCost as "Sum of Net Invoices"
				,CAST(null as money) as "VarianceTolerancePercent"
				,CAST(' ' as nvarchar) as "VarianceToleranceViolated"
				,ROW_NUMBER() over (order by ChainID,WeekEnding desc,[InvoiceDetailTypeID]) as "TempId"
				into #tempWeeklyComparison
			FROM #tempinvoiceDetails1

--select * from #tempWeeklyComparison

		update t set t.VarianceTolerancePercent=v.AttributeValue
		from #tempWeeklyComparison t join AttributeValues v
		on t.iControlChainID=v.OwnerEntityID
		and v.IsActive='True'
		and v.AttributeID in (select AttributeID from AttributeDefinitions
		where AttributeName ='ChainSalesVarianceTolerancePercent')

--drop table #tempWeeklyComparison1
		
		select t1.TempId, t1.[Chain ID],t1.[Week Ending Date],
		(t2.[Sum of Net Invoices] * t2.VarianceTolerancePercent) as "Variance1",
		(t3.[Sum of Net Invoices] * t3.VarianceTolerancePercent) as "Variance2",
		(t1.[Sum of Net Invoices] - t2.[Sum of Net Invoices]) as "Difference1",
		t1.[Sum of Net Invoices] - t3.[Sum of Net Invoices] as "Difference2"
		into #tempWeeklyComparison1
		from #tempWeeklyComparison  t1
		join #tempWeeklyComparison  t2
		on t1.tempid = t2.tempid - 1
		and t1.[iControlChainID]=t2.[iControlChainID]
		join #tempWeeklyComparison  t3
		on t1.tempid = t3.tempid - 2
		and t1.[iControlChainID]=t3.[iControlChainID]
		
		--select * from #tempWeeklyComparison
		--select * from #tempWeeklyComparison1
		
		update t set t.VarianceToleranceViolated='X'
		from #tempWeeklyComparison t join #tempWeeklyComparison1 t1
		on t.TempId=t1.TempId
		where t1.Variance1<ABS(t1.Difference1)
		OR t1.Variance2<ABS(t1.Difference2)
		
		
		update t set t.[Chain ID] = c.ChainIdentifier
		from #tempWeeklyComparison t  join Chains c 
		on t.iControlChainID=c.ChainID
		
		select InvType,[Chain ID],Cast([Week Ending Date] as date) as "Week Ending Date",[Sum of Net Invoices],VarianceTolerancePercent,VarianceToleranceViolated
		--select *
		from #tempWeeklyComparison
		where VarianceTolerancePercent is not null
		order by [Chain ID], [Week Ending Date]
		


commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		print @errormessage
		--exec DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
end catch
GO
