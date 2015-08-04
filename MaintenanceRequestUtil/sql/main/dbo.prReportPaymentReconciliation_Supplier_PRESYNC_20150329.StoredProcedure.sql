USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReportPaymentReconciliation_Supplier_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prReportPaymentReconciliation_Supplier_PRESYNC_20150329]--  24164
	@SupplierID int	
as
Begin

--select * from DataTrue_Main.Dbo.tempInvoiceDetailsFinal order by StoreID,[Week Ending] asc

--drop table DataTrue_Main.Dbo.tempInvoiceDetailsFinal

	Declare @MyID int =0;
	/*
	select * from Payments where PaymentID=33
	select * from PaymentHistory where disbursementID=7
select * from Suppliers where SupplierID=42520
	select * from PaymentDisbursements
	*/

	--drop table #tempPaymentIDs
	--declare @SupplierID int=24164
	select distinct h.PaymentID,d.CheckNo,d.DisbursementDate,p.PayeeEntityID as "SupplierID" 
	into #tempPaymentIDs 
	--select *
	from PaymentHistory h join Payments p
	on h.PaymentID=p.PaymentID
	and h.PaymentStatus=p.PaymentStatus
	join PaymentDisbursements d
	on h.DisbursementID=d.DisbursementID 
	and p.PaymentStatus=10
	and p.PayeeEntityID=@SupplierID
	
	--drop table #tempPendingPaymentIDs
	--declare @SupplierID int=24164
	select distinct h.PaymentID,d.CheckNo,d.DisbursementDate,@SupplierID as "SupplierID" 
	into #tempPendingPaymentIDs 
	--select *
	from PaymentHistory h join Payments p
	on h.PaymentID=p.PaymentID
	and h.PaymentStatus=p.PaymentStatus
	join PaymentDisbursements d
	on h.DisbursementID=d.DisbursementID 
	and p.PaymentStatus>=10
	and d.CheckNo not in (select distinct CheckNo from #tempPaymentIDs)
	and p.PayeeEntityID=@SupplierID

	--select * from #tempPaymentIDs
	--select * from InvoicesRetailer
	--drop table #tempInvoiceDetails
	select --StoreIdentifier,
	 i.StoreID,invoiceDetailTypeID,i.SupplierInvoiceID
	,cast(InvoicePeriodEnd as nvarchar) as "InvoicePeriodEnd",
	p.CheckNo,Cast(p.DisbursementDate as date) as "DisbursementDate",i.ChainID,i.SupplierID,p.PaymentID,
	Sum(TotalCost) as "TotalCost"
	into #tempInvoiceDetails
	--select *
	from InvoiceDetails i join #tempPaymentIDs p
	on i.PaymentID=p.PaymentID
	and InvoiceDetailTypeID in (1,3,7)
	and i.SupplierID=p.SupplierID
	join InvoicesSupplier ir
	on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())<=45
	group by --StoreIdentifier,
	i.StoreID,invoiceDetailTypeID,i.SupplierInvoiceID,InvoicePeriodEnd,p.CheckNo,Cast(p.DisbursementDate as date),i.ChainID
	,i.SupplierID,p.PaymentID
	
	--select * from #tempInvoiceDetails
	--drop table #tempInvoiceDetailsPending
	select --StoreIdentifier, 
	i.StoreID,i.SupplierInvoiceID,cast(InvoicePeriodEnd as nvarchar) as "InvoicePeriodEnd",
	p.CheckNo,Cast(p.DisbursementDate as date) as "DisbursementDate",i.ChainID,i.SupplierID,p.PaymentID,
	Sum(TotalCost) as "TotalCost"
	into #tempInvoiceDetailsPending
	--select *
	from InvoiceDetails i join #tempPendingPaymentIDs p
	on i.PaymentID=p.PaymentID
	and InvoiceDetailTypeID in (1,3,7)
	and i.SupplierID=p.SupplierID
	join InvoicesSupplier ir
	on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())<=45
	group by --StoreIdentifier,
	i.StoreID,i.SupplierInvoiceID,InvoicePeriodEnd,p.CheckNo,Cast(p.DisbursementDate as date),i.ChainID,i.SupplierID,p.PaymentID
	
	
	/*
		select * from #tempInvoiceDetails
		select * from #tempInvoiceDetailsPending
	*/
	
	
	
	--drop table #tempInvoiceDetailsOld
	select --StoreIdentifier, 
	i.StoreID,InvoiceDetailTypeID,CAST(Null as Int) as "SupplierInvoiceID"--i.RetailerInvoiceID
	,Cast('Older than 45 days' as nvarchar) as "InvoicePeriodEnd",
	p.CheckNo,Cast(p.DisbursementDate as date) as "DisbursementDate",
	i.ChainID,i.SupplierID,p.PaymentID,
	Sum(TotalCost) as "TotalCost"
	into #tempInvoiceDetailsOld
	--select *
	from InvoiceDetails i join #tempPaymentIDs p
	on i.PaymentID=p.PaymentID
	and i.SupplierID=p.SupplierID
	and InvoiceDetailTypeID in (1,3,7)
	join InvoicesSupplier ir
	on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())>45
	group by --StoreIdentifier,
	i.StoreID,invoiceDetailTypeID
	--,i.RetailerInvoiceID
	,p.CheckNo,Cast(p.DisbursementDate as date)
	,i.ChainID,i.SupplierID
	,p.PaymentID
	
	--select * from #tempInvoiceDetailsOld
	
	--drop table #tempInvoiceDetailsOldPending
	select --StoreIdentifier, 
	i.StoreID,InvoiceDetailTypeID,CAST(Null as int) as "SupplierInvoiceID"
	,Cast('Older than 45 days' as nvarchar) as "InvoicePeriodEnd",
	p.CheckNo,Cast(p.DisbursementDate as date) as "DisbursementDate",
	--Cast(NULL as int) as "CheckNo",
	--Cast(Null as date) as "DisbursementDate",
	i.ChainID,i.SupplierID,Cast(NULL as int) as "PaymentID",
	Sum(TotalCost) as "TotalCost"
	into #tempInvoiceDetailsOldPending
	--select *
	from InvoiceDetails i join #tempPendingPaymentIDs p
	on i.PaymentID=p.PaymentID
	and InvoiceDetailTypeID in (1,3,7)
	join InvoicesSupplier ir
	on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())>45
	group by --StoreIdentifier,
	i.StoreID,invoiceDetailTypeID,i.SupplierInvoiceID,p.CheckNo,Cast(p.DisbursementDate as date)
	,i.ChainID,i.SupplierID,p.PaymentID
	
	
	--17
	---select * from #tempInvoiceDetailsOld; select * from #tempInvoiceDetails
	
--select * from #tempInvoiceDetails2
	--drop table #tempInvoiceDetails2	
	select * into #tempInvoiceDetails2 from #tempInvoiceDetailsOld 
	union 
	select * from #tempInvoiceDetails

	--drop table #tempInvoiceDetails1
	select * into #tempInvoiceDetails1 from #tempInvoiceDetails2
	pivot(sum(TotalCost) for InvoiceDetailTypeID in ([1],[3],[7])) as Total
	order by  StoreID,SupplierInvoiceID,InvoicePeriodEnd

	--select * from #tempInvoiceDetails1
	--drop table #tempInvoiceDetailsFinal
	select StoreID,
	--StoreIdentifier,
	CAST(Null as nvarchar(50)) as "Vendor Account #",
	Case when InvoicePeriodEnd = 'Older than 45 days' then InvoicePeriodEnd
		else CAST( CAST(InvoicePeriodEnd as date) as nvarchar(20))
	end
	as "Week Ending",SupplierInvoiceID as "INV No",
	IsNull([1],0)+ISNull([3],0)+ISNull([7],0) as "Net Paid This Check",
	ISNULL([1],0) as "Scanned",
	ISNULL([3],0) as "Not Scanned",
	ISNULL([7],0) as "Billing Adjustments",
	CAST(Null as money) as "StillPending",
	CAST(Null as money) as "Rejected By Retailer",
	CAST(Null as money) as "Total Payment For Store and Week",
	DisbursementDate as "Check Date",
	CheckNo as "Check Number",
	CAST(Null as nvarchar(50)) as "Vendor ID",
	CAST(Null as nvarchar(50)) as "Vendor Name",
	ChainID,
	CAST(Null as nvarchar(50)) as "Retailer ID",
	SupplierID,
	PaymentID,
	Cast('' as nvarchar(50)) as "ChainName"
	into #tempInvoiceDetailsFinal
	--select * 
	from #tempInvoiceDetails1
	
	--select * from #tempInvoiceDetailsFinal
	--select * from #tempInvoiceDetailsPending
	--drop table #tempInvoiceDetailsFinal
	update t set t.ChainName=c.ChainName 
	from #tempInvoiceDetailsFinal t join Chains c
	on t.ChainID=c.ChainID
	
	update t set t.StillPending=ISNULL(p.TotalCost,0)
	from #tempInvoiceDetailsFinal t join #tempInvoiceDetailsPending p
	on t.ChainID=p.ChainID and t.StoreID=p.StoreID and t.SupplierID=p.SupplierID 
	and CAST(t.[Week Ending] as date)=CAST(p.InvoicePeriodEnd as date)
	and t.[Week Ending]<>'Older than 45 days'
	
	--select * from #tempInvoiceDetailsOldPending
	
	update t set t.StillPending=ISNULL(p.TotalCost,0)
	from #tempInvoiceDetailsFinal t join #tempInvoiceDetailsOldPending p
	on t.ChainID=p.ChainID and t.StoreID=p.StoreID and t.SupplierID=p.SupplierID 
	and t.[Week Ending]='Older than 45 days'
	
	
	update t set t.[Vendor Account #]=s.SupplierStoreValue
	--select
	from #tempInvoiceDetailsFinal t join DataTrue_EDI.dbo.NewspapersMapping_Stores s
	on t.SupplierID=s.DataTrueSupplierID
	and t.StoreID=s.DataTrueStoreID
	
	--select * from DataTrue_EDI.dbo.NewspapersMapping_Stores
	--select * from DataTrue_EDI.dbo.NewspapersMapping_Stores s where DatatrueSupplierID= 42520 and DataTrueStoreID=40551
	
	update t set t.[Vendor ID]=s.SupplierIdentifier,t.[Vendor Name]=ISNULL(s.SupplierName,' ')
	from #tempInvoiceDetailsFinal t join Suppliers s
	on t.SupplierID=s.SupplierID
	
	
	update t set t.[Retailer ID]=c.ChainIdentifier
	from #tempInvoiceDetailsFinal t join Chains c
	on t.ChainID=c.ChainID
	
	
	Select i.StoreID,i.PaymentID,InvoicePeriodEnd,SUM(TotalCost) as "TotalCost" into #tempWeekPayments 
	from InvoiceDetails i join InvoicesSupplier r
	on i.SupplierInvoiceID=r.SupplierInvoiceID
	and i.StoreID in(select distinct StoreID from #tempInvoiceDetailsFinal)
	and CAST(SaleDate as date) between CAST((select distinct min([Week Ending]) from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID and [Week Ending]<>'Older than 45 days' ) as date) and CAST( (select distinct max([Week Ending]) from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID and [Week Ending]<>'Older than 45 days' ) as date)
	and i.PaymentID not in(select distinct PaymentID from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID)
	group by i.StoreID,i.PaymentID,InvoicePeriodEnd
	
	Select i.StoreID,i.PaymentID,SUM(TotalCost) as "TotalCost" into #tempWeekPayments1 
	from InvoiceDetails i join InvoicesSupplier r
	on i.SupplierInvoiceID=r.SupplierInvoiceID
	and i.StoreID in(select distinct StoreID from #tempInvoiceDetailsFinal)
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())>45
	and i.PaymentID not in(select distinct PaymentID from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID)
	group by i.StoreID,i.PaymentID
	
	update t set t.[Total Payment For Store and Week]=ISNull(p.TotalCost,0)
	from #tempInvoiceDetailsFinal t join #tempWeekPayments p
	on t.StoreID=p.StoreID
	and t.[Week Ending]=p.InvoicePeriodEnd
	and t.PaymentID<>p.PaymentID
	and t.[Week Ending]<>'Older than 45 days'
	
	
	update t set t.[Total Payment For Store and Week]=ISNull(p.TotalCost,0)
	from #tempInvoiceDetailsFinal t join #tempWeekPayments1 p
	on t.StoreID=p.StoreID
	and t.PaymentID<>p.PaymentID
	and t.[Week Ending]='Older than 45 days'
	
	
	
	update #tempInvoiceDetailsFinal set [Total Payment For Store and Week]= ISNULL([Total Payment For Store and Week],0) + IsNull([Net Paid This Check],0)
	
	--declare @SupplierID int=24164
	update #tempInvoiceDetailsFinal set [Rejected By Retailer]=(select ISNULL(SUM(RuleCost),0)
	from StoreTransactions_Forward f 
	where f.SupplierID=#tempInvoiceDetailsFinal.SupplierID and f.ChainID=#tempInvoiceDetailsFinal.ChainID 
	and f.StoreID=#tempInvoiceDetailsFinal.StoreID
	and f.TransactionTypeID=17 and f.SupplierID=@SupplierID
	and f.TransactionStatus=-800
	and CAST(SaleDateTime as date) between Cast(#tempInvoiceDetailsFinal.[Week Ending] as date) and DATEADD(dd,-6,#tempInvoiceDetailsFinal.[Week Ending])
	group by f.ChainID,f.SupplierID,f.StoreID)
	
	--select * from #tempPaymentIDs
	
	INSERT INTO [PaymentHistory]
           ([PaymentID]
           ,[LastUpdateUserID]
           ,[PaymentStatus]
           ,[PaymentStatusChangeDateTime]
           ,[AmountPaid]
           ,[CheckNoReceived]
           ,[DatePaymentReceived]
           ,[Comments])
     select t.PaymentID
           ,@MyID
           ,11
           ,GETDATE()
           ,AmountOriginallyBilled
           ,CheckNo
           ,DisbursementDate
           ,'Report send'
           from #tempPaymentIDs t join Payments p
           on t.PaymentID=p.PaymentID
           
           update p set p.PaymentStatus=11
			--select * 
			from Payments p join #tempPaymentIDs t
			on t.PaymentID=p.PaymentID


	
	--select * --into DataTrue_Main.Dbo.tempInvoiceDetailsFinal 
	select s.LegacySystemStoreIdentifier as StoreID,ISNull([Vendor Account #],'') AS [Vendor Account #],[Week Ending],[INV No]
	,ISNull([Net Paid This Check],0) AS [Net Paid This Check],ISnull(Scanned,0) AS Scanned,
	ISNull([Not Scanned],0) AS [Not Scanned],ISnull([Billing Adjustments],0) AS [Billing Adjustments],
	ISNull(StillPending,0) AS StillPending,ISnull([Rejected By Retailer],0) AS [Rejected By Retailer],
	ISnull([Total Payment For Store and Week],0) AS [Total Payment For Store and Week],
	[Check Date],[Check Number],[Vendor ID],[Vendor Name],t.ChainID,[Retailer ID],SupplierID,PaymentID,
	ChainName
	--select *
	from #tempInvoiceDetailsFinal t
	join Stores s on t.StoreId=s.StoreID
	order by StoreID
	
	/*
	update t set t.[Rejected By Retailer]=
	from #tempInvoiceDetailsFinal t join StoreTransactions s
	on Cast(t.[Week Ending] as date)=CAST(s.SaleDateTime as date)
	and s.TransactionTypeID=17 
	--and s.TransactionStatus=850
	and t.StoreID=s.StoreID
	group by StoreID,Cast(SaleDateTime as date)
	
	select * from StoreTransactions
	where TransactionTypeID=17
	and TransactionStatus=850
	*/
	--select * from DataTrue_EDI.dbo.NewspapersMapping_RetailerID
	--select * from DataTrue_EDI.dbo.NewspapersMapping_Stores
	--select * from DataTrue_EDI.dbo.NewspapersMapping_RetailerID
	--select * from #tempInvoiceDetailsFinal
	
--Sum(TotalCost)
--invoicedetailtypeId
--POS-1, Shrink-3,adj-7
--Sum(TotalCost)
End
GO
