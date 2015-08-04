USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReportPaymentReconciliation_Supplier_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[prMaintenanceRequest_Process_AllRecords_WithMaintenanceRequestStoresRecords_Type20_StoreSetupOnly_ActiveStartDate_Update]
CREATE procedure [dbo].[prReportPaymentReconciliation_Supplier_PRESYNC_20150415]--  24164
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
	select distinct h.PaymentID,d.CheckNo,d.DisbursementDate,p.PayeeEntityID as "SupplierID",d.DisbursementID 
	into #tempPaymentIDs 
	--select *
	from PaymentHistory h join Payments p
	on h.PaymentID=p.PaymentID
	and h.PaymentStatus=p.PaymentStatus
	join PaymentDisbursements d
	on h.DisbursementID=d.DisbursementID 
	and p.PaymentStatus=10
	and p.PayeeEntityID=@SupplierID and p.PayerEntityID<>60626 and VoidStatus is NULL
--	and COnvert(date,DisbursementDate)<'02/27/15'
--	and p.PayerEntityID in (40393,60634) and p.PaymentID in (77590,
--77570,
--77293,
--78349,
--77591,
--78401,
--77592,
--78436,
--78350,
--77571,
--78351,
--77301,
--78415,
--78455,
--78352,
--78353,
--78403,
--78404,
--77304,
--78354,
--78355,
--77302,
--78456,
--78463,
--78356,
--77593,
--78402,
--77572,
--78405,
--78357,
--78358,
--78486,
--78482,
--77589,
--78359,
--77596,
--78454,
--77597,
--77300,
--78437,
--78438,
--78452,
--77587,
--77573,
--78397,
--77588,
--78400,
--78394,
--78396,
--78360,
--78413,
--78407,
--78453,
--78414,
--78361,
--78398,
--77574,
--78399,
--78362,
--78363,
--78364,
--78485,
--78392,
--78365,
--78393,
--77575,
--78366,
--78451,
--78412,
--78367,
--78368,
--78391,
--78369,
--78461,
--78370,
--78410,
--77576,
--78395,
--77585,
--78411,
--78371,
--78372,
--77298,
--77584,
--78373,
--78390,
--78439,
--77586,
--77577,
--78449,
--78450,
--77294,
--78374,
--78375,
--77295,
--78448,
--78376,
--77582,
--78389,
--78483,
--78440,
--78377,
--78484,
--78378,
--78387,
--78441,
--78379,
--78380,
--78446,
--81060,
--80981,
--80982,
--81058,
--81059,
--81083,
--81063,
--80983,
--81064,
--81065,
--80984,
--80985,
--80986,
--80987,
--80988,
--80989,
--81076,
--81082,
--80990,
--81080,
--81053,
--81054,
--81055,
--80991,
--80992,
--80993,
--80994,
--81062,
--80995,
--80996,
--80997,
--81061,
--80998,
--80999,
--81000,
--81001,
--81002,
--81048,
--81049,
--81050,
--81051,
--81003,
--81004,
--81052,
--81005,
--81006,
--81056,
--81057,
--81007,
--81079,
--81008,
--81081,
--81046,
--81040,
--81009,
--81041,
--81043,
--81010,
--81042,
--81011,
--81012,
--81013,
--81044,
--81045,
--81014,
--81037,
--81015,
--81016,
--81017,
--81039,
--81018,
--81047,
--81035,
--81019,
--81020,
--81031,
--81033,
--81021,
--81022,
--81034,
--81023,
--81036,
--81024,
--81038,
--81030,
--81086,
--81085,
--81025,
--81077,
--81087,
--81026,
--81027,
--81028,
--81029,
--81078,
--81032,
--81084,
--81067,
--81068,
--81066,
--81069,
--81070,
--64758,
--66277,
--67328,
--68501,
--69773,
--70954,
--72993,
--74671,
--76991,
--78702,
--80458,
--82271,
--80459)
	----and P.PaymentID<>64446
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
	and p.PayeeEntityID=@SupplierID and p.PayerEntityID<>60626 and VoidStatus is NULL
--	and COnvert(date,DisbursementDate)<'02/27/15'
--	and p.PayerEntityID in (40393,60634) and p.PaymentID in (77590,
--77570,
--77293,
--78349,
--77591,
--78401,
--77592,
--78436,
--78350,
--77571,
--78351,
--77301,
--78415,
--78455,
--78352,
--78353,
--78403,
--78404,
--77304,
--78354,
--78355,
--77302,
--78456,
--78463,
--78356,
--77593,
--78402,
--77572,
--78405,
--78357,
--78358,
--78486,
--78482,
--77589,
--78359,
--77596,
--78454,
--77597,
--77300,
--78437,
--78438,
--78452,
--77587,
--77573,
--78397,
--77588,
--78400,
--78394,
--78396,
--78360,
--78413,
--78407,
--78453,
--78414,
--78361,
--78398,
--77574,
--78399,
--78362,
--78363,
--78364,
--78485,
--78392,
--78365,
--78393,
--77575,
--78366,
--78451,
--78412,
--78367,
--78368,
--78391,
--78369,
--78461,
--78370,
--78410,
--77576,
--78395,
--77585,
--78411,
--78371,
--78372,
--77298,
--77584,
--78373,
--78390,
--78439,
--77586,
--77577,
--78449,
--78450,
--77294,
--78374,
--78375,
--77295,
--78448,
--78376,
--77582,
--78389,
--78483,
--78440,
--78377,
--78484,
--78378,
--78387,
--78441,
--78379,
--78380,
--78446,
--81060,
--80981,
--80982,
--81058,
--81059,
--81083,
--81063,
--80983,
--81064,
--81065,
--80984,
--80985,
--80986,
--80987,
--80988,
--80989,
--81076,
--81082,
--80990,
--81080,
--81053,
--81054,
--81055,
--80991,
--80992,
--80993,
--80994,
--81062,
--80995,
--80996,
--80997,
--81061,
--80998,
--80999,
--81000,
--81001,
--81002,
--81048,
--81049,
--81050,
--81051,
--81003,
--81004,
--81052,
--81005,
--81006,
--81056,
--81057,
--81007,
--81079,
--81008,
--81081,
--81046,
--81040,
--81009,
--81041,
--81043,
--81010,
--81042,
--81011,
--81012,
--81013,
--81044,
--81045,
--81014,
--81037,
--81015,
--81016,
--81017,
--81039,
--81018,
--81047,
--81035,
--81019,
--81020,
--81031,
--81033,
--81021,
--81022,
--81034,
--81023,
--81036,
--81024,
--81038,
--81030,
--81086,
--81085,
--81025,
--81077,
--81087,
--81026,
--81027,
--81028,
--81029,
--81078,
--81032,
--81084,
--81067,
--81068,
--81066,
--81069,
--81070,
--64758,
--66277,
--67328,
--68501,
--69773,
--70954,
--72993,
--74671,
--76991,
--78702,
--80458,
--82271,
--80459)

	--select * from #tempPaymentIDs
	--select * from InvoicesRetailer
	--drop table #tempInvoiceDetails
	select --StoreIdentifier,
	 i.StoreID,invoiceDetailTypeID,i.SupplierInvoiceID
	,cast(InvoicePeriodEnd as nvarchar) as "InvoicePeriodEnd",
	p.CheckNo,Cast(p.DisbursementDate as date) as "DisbursementDate",i.ChainID,i.SupplierID,p.PaymentID,
	Sum(ISNULL(TotalCost,0)-ISNULL(Adjustment1,0)) as "TotalCost"
	into #tempInvoiceDetails
	--select *
	from InvoiceDetails i with (nolock) join #tempPaymentIDs p
	on i.PaymentID=p.PaymentID
	and InvoiceDetailTypeID in (1,3,7,9,16)
	and i.SupplierID=p.SupplierID
	join InvoicesSupplier ir on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())<=45
	where  I.ChainID<>60626 
	group by --StoreIdentifier,
	i.StoreID,invoiceDetailTypeID,i.SupplierInvoiceID,InvoicePeriodEnd,p.CheckNo,Cast(p.DisbursementDate as date),i.ChainID
	,i.SupplierID,p.PaymentID
	
	
	--select * from #tempInvoiceDetails
	--drop table #tempInvoiceDetailsPending
	select --StoreIdentifier, 
	i.StoreID,i.SupplierInvoiceID,cast(InvoicePeriodEnd as nvarchar) as "InvoicePeriodEnd",
	p.CheckNo,Cast(p.DisbursementDate as date) as "DisbursementDate",i.ChainID,i.SupplierID,p.PaymentID,
	Sum(ISNULL(TotalCost,0)-ISNULL(Adjustment1,0)) as "TotalCost"
	into #tempInvoiceDetailsPending
	--select *
	from InvoiceDetails i with (nolock) join #tempPendingPaymentIDs p
	on i.PaymentID=p.PaymentID
	and InvoiceDetailTypeID in (1,3,7,16,9)
	and i.SupplierID=p.SupplierID
	join InvoicesSupplier ir
	on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())<=45
	where  I.ChainID<>60626
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
	Sum(ISNULL(TotalCost,0)-ISNULL(Adjustment1,0)) as "TotalCost"
	into #tempInvoiceDetailsOld
	--select *
	from InvoiceDetails i join #tempPaymentIDs p
	on i.PaymentID=p.PaymentID
	and i.SupplierID=p.SupplierID
	and InvoiceDetailTypeID in (1,3,7,9,16)
	join InvoicesSupplier ir
	on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())>45
	where  I.ChainID<>60626
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
	Sum(ISNULL(TotalCost,0)-ISNULL(Adjustment1,0)) as "TotalCost"
	into #tempInvoiceDetailsOldPending
	--select *
	from InvoiceDetails i join #tempPendingPaymentIDs p
	on i.PaymentID=p.PaymentID
	and InvoiceDetailTypeID in (1,3,7,16,9)
	join InvoicesSupplier ir
	on i.SupplierInvoiceID=ir.SupplierInvoiceID
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())>45
	where  I.ChainID<>60626
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
	pivot(sum(TotalCost) for InvoiceDetailTypeID in ([1],[3],[7],[16],[9])) as Total
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
	IsNull([1],0)+ISNull([3],0)+ISNull([7],0)+ISNull([16],0)+ISNull([9],0) as "Net Paid This Check",
	ISNULL([1],0) as "Scanned",
	ISNULL([3],0) as "Not Scanned",
	ISNULL([7],0)+ISNULL([9],0) as "Billing Adjustments",
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
	
	
	--update t set t.[Vendor Account #]=s.SupplierStoreValue
	----select
	--from #tempInvoiceDetailsFinal t join DataTrue_EDI.dbo.NewspapersMapping_Stores s
	--on t.SupplierID=s.DataTrueSupplierID
	--and t.StoreID=s.DataTrueStoreID
	
	update t set t.[Vendor Account #] = s.SupplierAccountNumber 
	from DataTrue_Main..StoresUniqueValues s
	inner join #tempInvoiceDetailsFinal t on  t.StoreID = s.StoreID and t.SupplierID= s.SupplierID

	
	
	Alter table #tempInvoiceDetailsFinal Alter Column [Vendor Name] NVArchar (150)
	--select * from DataTrue_EDI.dbo.NewspapersMapping_Stores
	--select * from DataTrue_EDI.dbo.NewspapersMapping_Stores s where DatatrueSupplierID= 42520 and DataTrueStoreID=40551
	
	update t set t.[Vendor ID]=s.SupplierIdentifier,t.[Vendor Name]=ISNULL(s.SupplierName,' ')
	from #tempInvoiceDetailsFinal t join Suppliers s
	on t.SupplierID=s.SupplierID
	
	
	update t set t.[Retailer ID]=c.ChainIdentifier
	from #tempInvoiceDetailsFinal t join Chains c
	on t.ChainID=c.ChainID
	
	
	Select i.StoreID,i.PaymentID,InvoicePeriodEnd,SUM(IsNULL(TotalCost,0)-ISNULL(Adjustment1,0)) as "TotalCost" into #tempWeekPayments 
	from InvoiceDetails i join InvoicesSupplier r
	on i.SupplierInvoiceID=r.SupplierInvoiceID
	and i.StoreID in(select distinct StoreID from #tempInvoiceDetailsFinal)
	and CAST(SaleDate as date) between CAST((select distinct min([Week Ending]) from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID and [Week Ending]<>'Older than 45 days' ) as date) and CAST( (select distinct max([Week Ending]) from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID and [Week Ending]<>'Older than 45 days' ) as date)
	and i.PaymentID not in(select distinct PaymentID from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID)
	group by i.StoreID,i.PaymentID,InvoicePeriodEnd
	
	Select i.StoreID,i.PaymentID,SUM(ISNULL(TotalCost,0)-ISNULL(Adjustment1,0)) as "TotalCost" into #tempWeekPayments1 
	from InvoiceDetails i join InvoicesSupplier r
	on i.SupplierInvoiceID=r.SupplierInvoiceID
	and i.StoreID in(select distinct StoreID from #tempInvoiceDetailsFinal)
	and DATEDIFF(d,InvoicePeriodEnd,GETDATE())>45
	and i.PaymentID not in(select distinct PaymentID from #tempInvoiceDetailsFinal t where t.StoreID=i.StoreID)
	group by i.StoreID,i.PaymentID
	
	/*
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
	*/
	
	
	update #tempInvoiceDetailsFinal set [Total Payment For Store and Week]= ISNULL([Total Payment For Store and Week],0) + IsNull([Net Paid This Check],0)
	
	--declare @SupplierID int=24164
	update #tempInvoiceDetailsFinal set [Rejected By Retailer]=(select SUM(ISNULL(RuleCost,0))
	from StoreTransactions_Forward f 
	where f.SupplierID=#tempInvoiceDetailsFinal.SupplierID and f.ChainID=#tempInvoiceDetailsFinal.ChainID 
	and f.StoreID=#tempInvoiceDetailsFinal.StoreID
	and f.TransactionTypeID=17 and f.SupplierID=@SupplierID
	and f.TransactionStatus=-800
	and CAST(SaleDateTime as date) between Cast(#tempInvoiceDetailsFinal.[Week Ending] as date) and DATEADD(dd,-6,#tempInvoiceDetailsFinal.[Week Ending])
	group by f.ChainID,f.SupplierID,f.StoreID)
	----------ADDDDDDDDD-----------
	------select * from #tempPaymentIDs
	
	INSERT INTO [PaymentHistory]
           ([PaymentID]
           ,[LastUpdateUserID]
           ,[PaymentStatus]
           ,[PaymentStatusChangeDateTime]
           ,[AmountPaid]
           ,[CheckNoReceived]
           ,[DatePaymentReceived]
           ,[Comments]
           ,DisbursementID)
     select t.PaymentID
           ,@MyID
           ,11
           ,GETDATE()
           ,AmountOriginallyBilled
           ,CheckNo
           ,DisbursementDate
           ,'Report send'
           ,DisbursementID
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
