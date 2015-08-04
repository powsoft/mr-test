USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGetSharedShrinkValuesLSN]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prCDCGetSharedShrinkValuesLSN]
as

declare @MyID int
declare @startlsn binary(10)
declare @endlsn binary(10)
declare @count int
declare @from_lsn binary(10)
declare @to_lsn binary(10)

set @MyID = 0

begin try

begin transaction



SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_SharedShrinkValues');
SET @to_lsn = sys.fn_cdc_get_max_lsn();


--print @from_lsn

--print @to_lsn

--Archive all CDC records

--/*

insert into DataTrue_Archive..dbo_SharedShrinkValues_CT 
select *  from cdc.dbo_SharedShrinkValues_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
--*/

MERGE INTO [DataTrue_Report].[dbo].SharedShrinkValues t

USING (SELECT __$operation, [SharedShrinkID]
      ,[ChainID]
      ,[SupplierID]
      ,[SupplierShrinkRatio]
      ,[RetailerShrinkRatio]
      ,[FromShrinkUnitsDIVPOSUnits]
      ,[ToShrinkUnitsDIVPOSUnits]
      ,[ShrinkPercentRangeAggregationMethod]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[CalculationMethod]
      	FROM cdc.fn_cdc_get_net_changes_dbo_SharedShrinkValues(@from_lsn, @to_lsn, 'all')
		where 1 = 1
		) s
		on t.[SharedShrinkID] = s.[SharedShrinkID]

WHEN MATCHED AND s.__$operation = 1 THEN
	Delete
	
WHEN MATCHED THEN

	UPDATE 
	SET [ChainID] = s.ChainID
      ,[SupplierID] = s.SupplierID
      ,[SupplierShrinkRatio] = s.SupplierShrinkRatio
      ,[RetailerShrinkRatio] = s.RetailerShrinkRatio
      ,[FromShrinkUnitsDIVPOSUnits] = s.FromShrinkUnitsDIVPOSUnits
      ,[ToShrinkUnitsDIVPOSUnits] = s.ToShrinkUnitsDIVPOSUnits
      ,[ShrinkPercentRangeAggregationMethod] = s.ShrinkPercentRangeAggregationMethod
      ,[ActiveStartDate] = s.ActiveStartDate
      ,[ActiveLastDate] = s.ActiveLastDate
      ,[CalculationMethod] = s.CalculationMethod


	
WHEN NOT MATCHED 

THEN INSERT 
           ([SharedShrinkID]
           ,[ChainID]
           ,[SupplierID]
           ,[SupplierShrinkRatio]
           ,[RetailerShrinkRatio]
           ,[FromShrinkUnitsDIVPOSUnits]
           ,[ToShrinkUnitsDIVPOSUnits]
           ,[ShrinkPercentRangeAggregationMethod]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[CalculationMethod])
     VALUES
           ([SharedShrinkID]
           ,s.ChainID
           ,s.SupplierID
           ,s.SupplierShrinkRatio
           ,s.RetailerShrinkRatio
           ,s.FromShrinkUnitsDIVPOSUnits
           ,s.ToShrinkUnitsDIVPOSUnits
           ,s.ShrinkPercentRangeAggregationMethod
           ,s.ActiveStartDate
           ,s.ActiveLastDate
           ,s.CalculationMethod);	


	delete cdc.dbo_SharedShrinkValues_CT
	where __$start_lsn >= @from_lsn
	and __$start_lsn <= @to_lsn
	
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)
		declare @errorsenderstring nvarchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring =  ERROR_PROCEDURE()
		--print @errormessage;
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
end catch
	

return
GO
