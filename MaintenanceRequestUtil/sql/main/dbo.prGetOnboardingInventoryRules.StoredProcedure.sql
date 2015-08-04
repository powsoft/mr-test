USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetOnboardingInventoryRules]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetOnboardingInventoryRules]  
 @iControlSupplierID int,  
 @OnboardingSupplierID int  
as  
Begin

declare @MyID int

	set @MyID = 0

	 begin try

	begin transaction
	  
 INSERT INTO [DataTrue_Main].[dbo].[InventoryRulesTimesBySupplierID]  
      ([SupplierID]  
      ,[InventoryTakenBeginOfDay]  
      ,[ChainID]  
      ,[InventoryTakenBeforeDeliveries]  
      --,[InventoryUnitCostRule]  
      --,[InitialCountDate]  
      )  
    select   
    @iControlSupplierID  
    ,Case r.CountSales when 'Before sales' then 'true' else 'false' end --<InventoryTakenBeginOfDay, bit,>  
    ,v.Value--<ChainID, int,>  
    ,Case r.CountDelivery when 'Before delivery' then 'true' else 'false' end --<InventoryTakenBeforeDeliveries, bit,>  
    --,<InventoryUnitCostRule, nvarchar(50),>  
    --,<InitialCountDate, date,>  
    --select *  
   from Onboarding..Onboarding_Suppliers s join Onboarding.dbo.Onboarding_Survey_Result r  
   on s.SupplierID=r.SupplierID  
   join Onboarding.dbo.Onboarding_Type_Values v on r.TempSupplierID=v.TempSupplierID  
   where LEN(r.AcceptTerms)>0  
   and s.SupplierID=@OnboardingSupplierID  
   and v.RecordStatus=0 and ltrim(rtrim(v.Types))='PDI Customers'  
   and s.RecordStatus=0  
     
     
   update v set v.RecordStatus=1  
   from Onboarding..Onboarding_Suppliers s join Onboarding.dbo.Onboarding_Survey_Result r  
   on s.SupplierID=r.SupplierID  
   join Onboarding.dbo.Onboarding_Type_Values v on r.TempSupplierID=v.TempSupplierID  
   where LEN(r.AcceptTerms)>0  
   and s.SupplierID=@OnboardingSupplierID  
   and v.RecordStatus=0 and ltrim(rtrim(v.Types))='PDI Customers'  
   and s.RecordStatus=0  

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
