USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequests_ProductPrice_Overlap_Existing_Remove]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMaintenanceRequests_ProductPrice_Overlap_Existing_Remove]
@maintenancerequestid int
,@storeid int
,@productid int
,@brandid int
,@supplierid int
,@productpricetypeid int
,@pricestartdate datetime
,@priceenddate datetime
,@storecontextid int
,@banner nvarchar(50)
,@costzoneid int
,@allstores bit
,@upc nvarchar(50)

as
						insert dbo.OverlappingProductPricesRecordsDeleted
						select @maintenancerequestid, @storecontextid, @banner, @costzoneid, *, GETDATE(), 0, @allstores, @upc
						--delete
						from productprices
						where 1 = 1
						and StoreID in (@storeid)
						and ProductID = @productid
						and BrandID = @brandid
						and SupplierID = @supplierid
						and ProductPriceTypeID = @productpricetypeid
						and (( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @pricestartdate) 
							or ( ActiveStartDate <= @priceenddate and ActiveLastDate >= @priceenddate) 
							or ( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @priceenddate) 
							or ( ActiveStartDate >= @pricestartdate and ActiveLastDate <= @priceenddate))
	
	
						delete
						from productprices
						where 1 = 1
						and StoreID in (@storeid)
						and ProductID = @productid
						and BrandID = @brandid
						and SupplierID = @supplierid
						and ProductPriceTypeID = @productpricetypeid
						and (( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @pricestartdate) 
							or ( ActiveStartDate <= @priceenddate and ActiveLastDate >= @priceenddate) 
							or ( ActiveStartDate <= @pricestartdate and ActiveLastDate >= @priceenddate) 
							or ( ActiveStartDate >= @pricestartdate and ActiveLastDate <= @priceenddate))	
							
return
GO
