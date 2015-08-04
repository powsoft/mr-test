USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetOnboardingStoreSetup]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetOnboardingStoreSetup]  
  
as  
  
Begin  
  
 declare @SupplierID int;  
 declare @rec cursor;  
 declare @recCostZone cursor;  
 declare @RecordID int;  
 declare @CostZoneID int;  
 declare @NewCostZoneID int;  
 declare @CostZoneName nvarchar(50)  
 declare @CostZoneDescription nvarchar(50)  
 declare @MyID int

	set @MyID = 0

	 begin try

	begin transaction

   
 set @rec = CURSOR local fast_forward FOR  
    select distinct SupplierID from Onboarding..Onboarding_Survey_Result  
    where LEN(AcceptTerms)>0  
    and RecordStatus=0  
   
 open @rec  
  
 fetch next from @rec into  @SupplierID  
  
 while @@FETCH_STATUS = 0  
  Begin  
    
   insert into import.dbo.StoreSetup_bkp  
   select *  
   from DataTrue_Main.dbo.StoreSetup  
   where SupplierID=@SupplierID  
     
   delete from DataTrue_Main.dbo.StoreSetup  
   where SupplierID=@SupplierID  
     
   --Start Updating the StoreSetUp table  
   INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]  
           ([ChainID],[StoreID],[ProductID],[SupplierID],[BrandID])  
   select ChainID,StoreID,ProductID,@SupplierID,BrandID   
   from Onboarding..Onboarding_StoreSetup  
   where SupplierID=@SupplierID  
   and SurveyAction='Added' and ProductAction='Added'  
   and RecordStatus=0  
     
   fetch next from @rec into  @SupplierID  
  End  
 close @rec  
 deallocate @rec  
   

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
			
			exec dbo.prLogExceptionAndNotifySupport
			1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
			,@errorlocation
			,@errormessage
			,@errorsenderstring
			,@MyID
	end catch
		

	end
GO
