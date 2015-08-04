USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_ProductPrice_CostMatch_Lookup]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequest_ProductPrice_CostMatch_Lookup]
@chainid int=0
,@storeid int=0
,@productid int=0
,@brandid int=0
,@supplierid int=0
,@productpricetypeid int=0
,@productprice money=0.00
,@pricestartdate datetime='1/1/2000'
,@priceenddate datetime='12/31/2025'
,@exactmatchfound bit output

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 7610
declare @recprices cursor
declare @priceid int
declare @startdate date
declare @enddate date
declare @rowcount int


	set @rowcount = 0

	select @rowcount = COUNT(productpriceid)
	from productprices
	where StoreID = @storeid
	and ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid
	and ProductPriceTypeID = @productpricetypeid
	and cast(ActiveStartDate as date) <= cast(@pricestartdate as date)
	and cast(ActiveLastDate as date) >= cast(@priceenddate as date)
	and UnitPrice = @productprice

	if @rowcount is null
		set @rowcount = 0
		
	if @rowcount > 0
		set @exactmatchfound = 1

return
GO
