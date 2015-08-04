USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetProductPricesLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetProductPricesLSN]
	@from_lsn binary(10),
	@to_lsn binary(10)
as
--sp_columns ProductPrices
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int


set @MyID = 0

begin try

--begin transaction



--SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_ProductPrices');
--SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

/*

insert into [IC-HQSQL1INST2].DataTrue_Archive.dbo.dbo_ProductPrices_CT 
([__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[ProductPriceID]
      ,[ProductPriceTypeID]
      ,[ProductID]
      ,[ChainID]
      ,[StoreID]
      ,[BrandID]
      ,[SupplierID]
      ,[UnitPrice]
      ,[UnitRetail]
      ,[PricePriority]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[PriceReportedToRetailerDate]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BaseCost]
      ,[Allowance]
      ,[NewActiveStartDateNeeded]
      ,[NewActiveLastDateNeeded]
      ,[OldStartDate]
      ,[OldEndDate]
      ,[TradingPartnerPromotionIdentifier]
      --,[SupplierPackageID]
      --,[IncludeInAdjustments]
)
select [__$start_lsn]
      ,[__$end_lsn]
      ,[__$seqval]
      ,[__$operation]
      ,[__$update_mask]
      ,[ProductPriceID]
      ,[ProductPriceTypeID]
      ,[ProductID]
      ,[ChainID]
      ,[StoreID]
      ,[BrandID]
      ,[SupplierID]
      ,[UnitPrice]
      ,[UnitRetail]
      ,[PricePriority]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[PriceReportedToRetailerDate]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BaseCost]
      ,[Allowance]
      ,[NewActiveStartDateNeeded]
      ,[NewActiveLastDateNeeded]
      ,[OldStartDate]
      ,[OldEndDate]
      ,[TradingPartnerPromotionIdentifier]
      --,[SupplierPackageID]
      --,[IncludeInAdjustments]
       from cdc.dbo_ProductPrices_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
*/

MERGE INTO [DataTrue_EDI].[dbo].ProductPrices t

USING (SELECT __$operation
	   ,[ProductPriceID]
      ,[ProductPriceTypeID]
      ,[ProductID]
      ,[ChainID]
      ,[StoreID]
      ,[BrandID]
      ,[SupplierID]
      ,[UnitPrice]
      ,[UnitRetail]
      ,[PricePriority]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[PriceReportedToRetailerDate]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BaseCost]
      ,[Allowance]
      ,[NewActiveStartDateNeeded]
      ,[NewActiveLastDateNeeded]
      ,[OldStartDate]
      ,[OldEndDate]
      ,[TradingPartnerPromotionIdentifier]
      ,[SupplierPackageID]
      ,[IncludeInAdjustments]
      	FROM cdc.fn_cdc_get_net_changes_dbo_ProductPrices(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[ProductPriceID] = s.[ProductPriceID]
		
WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
WHEN MATCHED THEN

   UPDATE 
   SET 
      [ProductPriceTypeID]=s.ProductPriceTypeID
      ,[ProductID]=s.ProductID
      ,[ChainID]=s.ChainID
      ,[StoreID]=s.StoreID
      ,[BrandID]=s.BrandID
      ,[SupplierID]=s.SupplierID
      ,[UnitPrice]=s.UnitPrice
      ,[UnitRetail]=s.UnitRetail
      ,[PricePriority]=s.PricePriority
      ,[ActiveStartDate]=s.ActiveStartDate
      ,[ActiveLastDate]=s.ActiveLastDate
      ,[PriceReportedToRetailerDate]=s.PriceReportedToRetailerDate
      ,[DateTimeCreated]=s.DateTimeCreated
      ,[LastUpdateUserID]=s.LastUpdateUserID
      ,[DateTimeLastUpdate]=s.DateTimeLastUpdate
      ,[BaseCost]=s.BaseCost
      ,[Allowance]=s.Allowance
      ,[NewActiveStartDateNeeded]=s.NewActiveStartDateNeeded
      ,[NewActiveLastDateNeeded]=s.NewActiveLastDateNeeded
      ,[OldStartDate]=s.OldStartDate
      ,[OldEndDate]=s.OldEndDate
      ,[TradingPartnerPromotionIdentifier]=s.TradingPartnerPromotionIdentifier
      ,[SupplierPackageID]=s.SupplierPackageID
      ,[IncludeInAdjustments]=s.IncludeInAdjustments

WHEN NOT MATCHED 

THEN INSERT 
           ([ProductPriceID]
      ,[ProductPriceTypeID]
      ,[ProductID]
      ,[ChainID]
      ,[StoreID]
      ,[BrandID]
      ,[SupplierID]
      ,[UnitPrice]
      ,[UnitRetail]
      ,[PricePriority]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[PriceReportedToRetailerDate]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[BaseCost]
      ,[Allowance]
      ,[NewActiveStartDateNeeded]
      ,[NewActiveLastDateNeeded]
      ,[OldStartDate]
      ,[OldEndDate]
      ,[TradingPartnerPromotionIdentifier]
      ,[SupplierPackageID]
      ,[IncludeInAdjustments]
           )
     VALUES
           (s.ProductPriceID
      ,s.ProductPriceTypeID
      ,s.ProductID
      ,s.ChainID
      ,s.StoreID
      ,s.BrandID
      ,s.SupplierID
      ,s.UnitPrice
      ,s.UnitRetail
      ,s.PricePriority
      ,s.ActiveStartDate
      ,s.ActiveLastDate
      ,s.PriceReportedToRetailerDate
      ,s.DateTimeCreated
      ,s.LastUpdateUserID
      ,s.DateTimeLastUpdate
      ,s.BaseCost
      ,s.Allowance
      ,s.NewActiveStartDateNeeded
      ,s.NewActiveLastDateNeeded
      ,s.OldStartDate
      ,s.OldEndDate
      ,s.TradingPartnerPromotionIdentifier
      ,s.SupplierPackageID
      ,s.IncludeInAdjustments
           );

	delete cdc.dbo_ProductPrices_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
--commit transaction
	
end try
	
begin catch

		--rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring =  ERROR_PROCEDURE()
--		print @errormessage
		exec dbo.prSendEmailNotification_PassEmailAddresses 
		@errorlocation
		,@errormessage
		,'DataTrue System'
		, 0
		,'mandeep@amebasoftwares.com'
		
		--exec dbo.prLogExceptionAndNotifySupport
		--1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		--,@errorlocation
		--,@errormessage
		--,@errorsenderstring
		--,@MyID
		
		--print(@errormessage)
end catch
	

return
GO
