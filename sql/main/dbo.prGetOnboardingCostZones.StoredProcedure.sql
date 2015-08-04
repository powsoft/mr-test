USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetOnboardingCostZones]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetOnboardingCostZones]  
  
  
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
   --Start Updating the Cost Zone and CostZoneRelations table  
   set @recCostZone = CURSOR local fast_forward FOR  
        select CZID,CostZoneID, CostZoneName,  
        CostZoneDescription  
        from Onboarding..Onboarding_CostZones  
        where SupplierId=@SupplierID  
        --and CostZoneID=0  
        and RecordStatus=0  
     
   open @recCostZone  
  
   fetch next from @recCostZone into @RecordID,@CostZoneID, @CostZoneName,@CostZoneDescription  
  
   while @@FETCH_STATUS = 0  
    Begin  
     if(@CostZoneID=0)  
      Begin  
      --we need to put check if it exists or not  
       INSERT INTO [DataTrue_Main].[dbo].[CostZones]  
          ([CostZoneName]  
          ,[CostZoneDescription]  
          ,[SupplierId]  
          --,[OwnerEntityID]  
          --,[OwnerMarketID]  
          )  
       values  
        (@CostZoneName  
        ,@CostZoneDescription  
        ,@SupplierID  
        )  
         
       SELECT @NewCostZoneID = SCOPE_IDENTITY()  
         
       INSERT INTO [DataTrue_Main].[dbo].[CostZoneRelations]  
          ([StoreID]  
          ,[SupplierID]  
          ,[CostZoneID]  
          --,[OwnerEntityID]  
          )  
       select StoreID  
        ,@SupplierID  
        ,@NewCostZoneID  
       from Onboarding..Onboarding_CostZoneRelations  
       where CZID=@RecordID  
       and RecordStatus=0  
         
       update c set c.RecordStatus=1  
       from Onboarding..Onboarding_CostZoneRelations c  
       where CZID=@RecordID  
       and RecordStatus=0   
          
      End  
     Else  
      Begin  
         
       insert into import.dbo.CostZone_bkp  
       select * from DataTrue_Main.dbo.CostZones  
         
       UPDATE [DataTrue_Main].[dbo].[CostZones]  
          SET [CostZoneName] = @CostZoneName  
          ,[CostZoneDescription] = @CostZoneDescription  
        WHERE CostZoneID=@CostZoneID  
          
        insert into Import.dbo.CostZoneRelations_bkp  
        select * from DataTrue_Main.dbo.CostZoneRelations  
        where CostZoneID= @CostZoneID  
          
        delete from DataTrue_Main.dbo.CostZoneRelations  
        where CostZoneID= @CostZoneID  
          
         INSERT INTO [DataTrue_Main].[dbo].[CostZoneRelations]  
          ([StoreID]  
          ,[SupplierID]  
          ,[CostZoneID]  
          --,[OwnerEntityID]  
          )  
        select StoreID  
         ,@SupplierID  
         ,@NewCostZoneID  
        from Onboarding..Onboarding_CostZoneRelations  
        where CostZoneID=@CostZoneID  
        and RecordStatus=0  
          
          
        update c set c.RecordStatus=1  
        from Onboarding..Onboarding_CostZoneRelations c  
        where CostZoneID=@CostZoneID  
        and RecordStatus=0  
      End   
        
        
        
     fetch next from @recCostZone into @RecordID,@CostZoneID, @CostZoneName,@CostZoneDescription  
    end  
   close @recCostZone  
   deallocate @recCostZone  
     
   update c set c.RecordStatus=1  
   from Onboarding..Onboarding_CostZones c  
   where SupplierId=@SupplierID  
   and RecordStatus=0  
     
   --End Updating the Cost Zone and CostZoneRelations table  
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
