USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prStoreSetup_Manage]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prStoreSetup_Manage]
@chainid int=0
,@storeid int=0
,@productid int=0
,@brandid int=0
,@supplierid int=0


as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 0
declare @recprices cursor
declare @priceid int
declare @startdate date
declare @enddate date
declare @setuprecordcount int

begin try

begin transaction


	set @setuprecordcount = 0
	
	select @setuprecordcount = COUNT(StoreSetupID)
	from storesetup
	where StoreID = @storeid
	and ProductID = @productid
	and BrandID = @brandid
	and SupplierID = @supplierid

	if @setuprecordcount < 1
		begin
			INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]
					   ([ChainID]
					   ,[StoreID]
					   ,[ProductID]
					   ,[SupplierID]
					   ,[BrandID]
					   ,[ActiveStartDate]
					   ,[ActiveLastDate]
					   ,[LastUpdateUserID])
				 VALUES
					   (@chainid --<ChainID, int,>
					   ,@storeid --<StoreID, int,>
					   ,@productid --<ProductID, int,>
					   ,@supplierid --<SupplierID, int,>
					   ,@brandid --<BrandID, int,>
					   ,'11/1/2011' --<ActiveStartDate, datetime,>
					   ,'12/31/2099' --<ActiveLastDate, datetime,>
					   ,@MyID)

		end
commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch

return
GO
