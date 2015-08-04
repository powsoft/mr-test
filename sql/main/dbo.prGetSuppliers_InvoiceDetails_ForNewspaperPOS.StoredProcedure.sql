USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetSuppliers_InvoiceDetails_ForNewspaperPOS]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetSuppliers_InvoiceDetails_ForNewspaperPOS]
	@ChainID int
	,@BillingControlDay INT=1
as
Begin
	
	--declare @BillingControlDay INT=1

	DECLARE @TodayDayOfWeek INT
	DECLARE @EndOfPrevWeek DateTime
	DECLARE @StartOfPrevWeek DateTime
	DECLARE @CurrentDate DateTime =Getdate()

	print @BillingControlDay

	--get number of a current day (1-Sunday,2-Monday, 3-Tuesday... 7-Saturday)
	SET @TodayDayOfWeek = datepart(dw, @CurrentDate)
	--get the last day of the previous week (last Sunday)
	SET @EndOfPrevWeek = DATEADD(dd, @BillingControlDay -@TodayDayOfWeek , @CurrentDate)
	--get the first day of the previous week (the Monday before last)
	SET @StartOfPrevWeek = DATEADD(dd,@BillingControlDay -(@TodayDayOfWeek+6), @CurrentDate)
print @EndOfPrevWeek
print @StartOfPrevWeek
	
	select distinct s.SupplierID,s.SupplierName,c.Email
	from DataTrue_Main..InvoiceDetails i join DataTrue_Main.dbo.Suppliers s
	on i.SupplierID=s.SupplierID
	join DataTrue_Main..ContactInfo c on s.SupplierID=c.OwnerEntityID
	where ChainID=@ChainID
	and i.SupplierID <>0
	and RetailerInvoiceID is not null
	and SupplierInvoiceID is not null
	and CAST(SaleDate as date) between @StartOfPrevWeek and @EndOfPrevWeek
	

End
GO
