USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetProductPricesLSN_New]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetProductPricesLSN_New]
as
--sp_columns ProductPrices
declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

--begin transaction


exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_ProductPrices',@from_lsn output

exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();

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
       from [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ProductPrices_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn


MERGE INTO [DataTrue_Report].[dbo].ProductPrices t

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
      --,[IncludeInAdjustments]
      	FROM [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ProductPrices_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	and __$operation<>3
    order by __$start_lsn
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
      --,[IncludeInAdjustments]=s.IncludeInAdjustments

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
      --,[IncludeInAdjustments]
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
      --,s.IncludeInAdjustments
           );

	delete [IC-HQSQL1\DataTrue].DataTrue_Main.cdc.dbo_ProductPrices_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	*/
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
		
		exec [IC-HQSQL1\DataTrue].DataTrue_Main.dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
		--print(@errormessage)
end catch
	

return
GO
