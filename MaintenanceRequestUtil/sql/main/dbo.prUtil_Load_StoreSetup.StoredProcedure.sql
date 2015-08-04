USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_StoreSetup]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_StoreSetup]
as

declare @MyID int
set @MyID = 7641

declare @rec cursor
declare @chainidentifier nvarchar(50)
declare @storeidentifier nvarchar(50)
declare @supplieridentifier nvarchar(50)
declare @productidentifier nvarchar(50)
declare @brandidentifier nvarchar(50)
declare @supplierdescription nvarchar(500)
declare @startdate datetime
declare @enddate datetime
declare @loadstatus int
declare @recordid int
declare @supplierid int
declare @chainid int
declare @storeid int
declare @productid int
declare @brandid int
declare @filename nvarchar(50)
declare @SunLimitQty int
declare @SunFrequency int
declare @MonLimitQty int
declare @MonFrequency int
declare @TueLimitQty int
declare @TueFrequency int
declare @WedLimitQty int
declare @WedFrequency int
declare @ThuLimitQty int
declare @ThuFrequency int
declare @FriLimitQty int
declare @FriFrequency int
declare @SatLimitQty int
declare @SatFrequency int
declare @InventoryRuleID int

set @rec = CURSOR local fast_forward FOR
SELECT [ChainIdentifier]
      ,[StoreIdentifier]
      ,[ProductIdentifier]
      ,[BrandIdentifier]
      ,[SupplierIdentifier]
      ,[SunLimitQty]
      ,[SunFrequency]
      ,[MonLimitQty]
      ,[MonFrequency]
      ,[TueLimitQty]
      ,[TueFrequency]
      ,[WedLimitQty]
      ,[WedFrequency]
      ,[ThuLimitQty]
      ,[ThuFrequency]
      ,[FriLimitQty]
      ,[FriFrequency]
      ,[SatLimitQty]
      ,[SatFrequency]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[FileName]
      ,[RecordID]
      ,[InventoryRuleID]
  FROM [DataTrue_EDI].[dbo].[Load_StoreSetup]
  where LoadStatus = 0

open @rec

fetch next from @rec into 
@chainidentifier
,@storeidentifier
,@productidentifier
,@brandidentifier
,@supplieridentifier
,@SunLimitQty
,@SunFrequency
,@MonLimitQty
,@MonFrequency
,@TueLimitQty
,@TueFrequency
,@WedLimitQty
,@WedFrequency
,@ThuLimitQty
,@ThuFrequency
,@FriLimitQty
,@FriFrequency
,@SatLimitQty
,@SatFrequency
,@startdate
,@enddate
,@filename
,@recordid
,@InventoryRuleID

while @@FETCH_STATUS = 0
	begin
	
	begin try
	
		begin transaction
	
		set @loadstatus = 1
		
		select @chainid = ChainID 
		from Chains 
		where ChainName = @chainidentifier
		
		if @@ROWCOUNT < 1
			set @loadstatus = -2
	
		select @storeid = StoreID from Stores 
		where StoreIdentifier = @storeidentifier
		and ChainID = @chainid
		
		if @@ROWCOUNT < 1
			set @loadstatus = -2
			
		select @productid = ProductID 
		from ProductIdentifiers 
		where IdentifierValue = @productidentifier and ProductIdentifierTypeID = 2
		
		if @@ROWCOUNT < 1
			set @loadstatus = -2
			
		select @brandid = BrandID 
		from Brands 
		where BrandName = @brandidentifier
		
		if @@ROWCOUNT < 1
			set @loadstatus = -2
			
		select @supplierid = SupplierID 
		from Suppliers 
		where SupplierName = @supplieridentifier
		
		if @@ROWCOUNT < 1
			set @loadstatus = -2

		if @loadstatus = 1
			begin
			
				select StoreSetupID from StoreSetup
				where ChainID = @chainid
				and StoreID = @storeid
				and SupplierID = @supplierid
				and ProductID = @productid
				and BrandID = @brandid
				
				if @@ROWCOUNT > 0
					begin
						set @loadstatus = -1
					end
				else
					begin
				INSERT INTO [dbo].[StoreSetup]
						   ([ChainID]
						   ,[StoreID]
						   ,[ProductID]
						   ,[SupplierID]
						   ,[BrandID]
						  ,[SunLimitQty]
						  ,[SunFrequency]
						  ,[MonLimitQty]
						  ,[MonFrequency]
						  ,[TueLimitQty]
						  ,[TueFrequency]
						  ,[WedLimitQty]
						  ,[WedFrequency]
						  ,[ThuLimitQty]
						  ,[ThuFrequency]
						  ,[FriLimitQty]
						  ,[FriFrequency]
						  ,[SatLimitQty]
						  ,[SatFrequency]
						   ,[ActiveStartDate]
						   ,[ActiveLastDate]
						   ,[FileName]
						   ,[LastUpdateUserID]
						   ,[InventoryRuleID])
					 VALUES
						   (@chainid
						   ,@storeid
						   ,@productid
						   ,@supplierid
						   ,@brandid
						   ,@SunLimitQty
						   ,@SunFrequency
							,@MonLimitQty
							,@MonFrequency
							,@TueLimitQty
							,@TueFrequency
							,@WedLimitQty
							,@WedFrequency
							,@ThuLimitQty
							,@ThuFrequency
							,@FriLimitQty
							,@FriFrequency
							,@SatLimitQty
							,@SatFrequency
						   ,@startdate
						   ,@enddate
						   ,@filename
						   ,@MyID
						   ,@InventoryRuleID)
					end
			end

	COMMIT TRANSACTION

end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -3
		
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification
		@errorlocation,
		@errormessage,
		@errorlocation,
		@MyID
end catch

		update [DataTrue_EDI].[dbo].[Load_StoreSetup] 
		set LoadStatus = @loadstatus 
		where RecordID = @recordid


	
fetch next from @rec into 
@chainidentifier
,@storeidentifier
,@productidentifier
,@brandidentifier
,@supplieridentifier
,@SunLimitQty
,@SunFrequency
,@MonLimitQty
,@MonFrequency
,@TueLimitQty
,@TueFrequency
,@WedLimitQty
,@WedFrequency
,@ThuLimitQty
,@ThuFrequency
,@FriLimitQty
,@FriFrequency
,@SatLimitQty
,@SatFrequency
,@startdate
,@enddate
,@filename
,@recordid
,@InventoryRuleID

	end
	
close @rec
deallocate @rec


	
return
GO
