USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prGetOnbaordingSuppliers]    Script Date: 06/25/2015 18:26:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prGetOnbaordingSuppliers]  
	  
	As  
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
		select SupplierID from Onboarding..Onboarding_Survey_Result  
		where LEN(AcceptTerms)>0  
		and RecordStatus=0  
	 open @rec  
	  
	 fetch next from @rec into  @SupplierID      
	  
	 while @@FETCH_STATUS = 0  
	 Begin  
	  select * from DataTrue_Main.dbo.Suppliers  
	  where ltrim(rtrim(SupplierName)) = (select ltrim(rtrim(SupplierName)) from Onboarding..Onboarding_Suppliers  
	  where SupplierID=@SupplierID and RecordStatus=0)  
	  
	  if(@@ROWCOUNT=0)  
	  Begin  
	   INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]  
		  ([EntityTypeID]  
		  ,[DateTimeCreated]  
		  ,[LastUpdateUserID]  
		  ,[DateTimeLastUpdate]  
		  --,[APIKey]  
		  --,[PDIPartner]  
		  )  
	   VALUES  
		  (5  
		  ,GETDATE()   
		  ,0  
		  ,GETDATE()  
		  --,<APIKey, nvarchar(50),>  
		  --,<PDIPartner, bit,>  
		  )  
	   declare @NewSupplierID as bigint;  
	   SELECT @NewSupplierID = SCOPE_IDENTITY()  
	           
	      
	   INSERT INTO [DataTrue_Main].[dbo].[Suppliers]  
		  ([SupplierID]  
		,[SupplierName]  
		,[SupplierIdentifier]  
		,[SupplierDescription]  
		--,[ActiveStartDate]  
		--,[ActiveLastDate]  
		--,[RegistrationDate]  
		--,[Comments]  
		,[DateTimeCreated]  
		,[LastUpdateUserID]  
		,[DateTimeLastUpdate]  
		,[DunsNumber]  
		,[EDIName]  
		--,[SupplierDeliveryIdentifier]  
		--,[CreateZeroCountRecordsForMissingProductCounts]  
		,[StoreProductContextMethod]  
		,[InventoryIsActive]  
		--,[PromotionOverwriteAllowed]  
		,[PDITradingPartner]  
		--,[IsRegulated]  
		  )  
	   select    
		@NewSupplierID -- will come from System Entity table  
		  ,s.[SupplierName]  
		  ,Case SupplierFederalID when null then @NewSupplierID else SupplierFederalID end--[SupplierIdentifier]  
		  ,SupplierName --[SupplierDescription]  
		  --,[ActiveStartDate]  
		  --,[ActiveLastDate]  
		  --,[RegistrationDate]  
		  --,[Comments]  
		  ,GETDATE()--,[DateTimeCreated]  
		  ,0--,[LastUpdateUserID]  
		  ,GETDATE()--,[DateTimeLastUpdate]  
		  ,DUNS  
		  ,Case SupplierFederalID when null then @NewSupplierID else SupplierFederalID end--,[EDIName]  
		  --,[SupplierDeliveryIdentifier]  
		  --,[CreateZeroCountRecordsForMissingProductCounts]  
		  ,Case CostZoneUsed when 'true' then 'COSTZONE' else 'BANNER' end--[StoreProductContextMethod]  
		  ,Inventory--[InventoryIsActive]  
		  --,[PromotionOverwriteAllowed]  
		  ,SuppPDITradingPartner  
		  --select *  
	   from Onboarding..Onboarding_Suppliers s join Onboarding.dbo.Onboarding_Survey_Result r  
	   on s.SupplierID=r.SupplierID  
	   where LEN(AcceptTerms)>0  
	   and s.SupplierID=@SupplierID  
	   and s.RecordStatus=0  
	   --select * from [DataTrue_Main].[dbo].[Addresses]  
	     
	     
	     
	   INSERT INTO [DataTrue_Main].[dbo].[Addresses]  
		  ([OwnerEntityID]  
		 -- ,[AddressDescription]  
		  ,[Address1]  
		  --,[Address2]  
		  ,[City]  
		  --,[CountyName]  
		  ,[State]  
		  ,[PostalCode]  
		  --,[Country]  
		  --,[Comments]  
		  ,[DateTimeCreated]  
		  ,[LastUpdateUserID]  
		  ,[DateTimeLastUpdate]  
		  ,[AddressTypeID]  
		  )  
	   select  
		  @NewSupplierID  
		  --,<AddressDescription, nvarchar(255),>  
		  ,SupplierAddress  
		  --,<Address2, nvarchar(100),>  
		  ,SupplierCity  
		  --,<CountyName, nvarchar(50),>  
		  ,SupplierState  
		  ,SupplierZipCode  
		  --,<Country, nvarchar(50),>  
		  --,<Comments, nvarchar(500),>  
		  ,GETDATE()  
		  ,0--<LastUpdateUserID, nvarchar(50),>  
		  ,GETDATE()--<DateTimeLastUpdate, datetime,>  
		  ,0--<AddressTypeID, smallint,>)  
	   from Onboarding..Onboarding_Suppliers s join Onboarding.dbo.Onboarding_Survey_Result r  
	   on s.SupplierID=r.SupplierID  
	   where LEN(AcceptTerms)>0  
	   and s.SupplierID=@SupplierID  
	   and s.RecordStatus=0  
	     
	--select * from [DataTrue_Main].[dbo].[ContactInfo]  
	  
	   INSERT INTO [DataTrue_Main].[dbo].[ContactInfo]  
		  ([OwnerEntityID]  
		  --,[Title]  
		  ,[FirstName]  
		  --,[LastName]  
		  --,[MiddleName]  
		  ,[DeskPhone]  
		  --,[MobilePhone]  
		  --,[Fax]  
		  ,[Email]  
		  --,[Comments]  
		  ,[DateTimeCreated]  
		  ,[LastUpdateUserID]  
		  ,[DateTimeLastUpdate]  
		  ,[ContactTypeID]  
		  )  
	   select  
		  @NewSupplierID  
		  --,<Title, nvarchar(50),>  
		  ,PrimaryContactName--,<FirstName, nvarchar(50),>  
		  --,<LastName, nvarchar(50),>  
		  --,<MiddleName, nvarchar(50),>  
		  ,PrimaryContactPhone--<DeskPhone, nvarchar(50),>  
		  --,<MobilePhone, nvarchar(50),>  
		  --,<Fax, nvarchar(50),>  
		  ,PrimaryContactEmail--,<Email, nvarchar(500),>  
		  --,<Comments, nvarchar(500),>  
		  ,getdate()--<DateTimeCreated, datetime,>  
		  ,0--<LastUpdateUserID, nvarchar(50),>  
		  ,GETDATE()--<DateTimeLastUpdate, datetime,>  
		  ,0--<ContactTypeID, smallint,>  
		  --select *  
	   from Onboarding..Onboarding_Suppliers s join Onboarding.dbo.Onboarding_Survey_Result r  
	   on s.SupplierID=r.SupplierID  
	   where LEN(AcceptTerms)>0  
	   and s.SupplierID=@SupplierID  
	   and s.RecordStatus=0  
	     
	   INSERT INTO [DataTrue_Main].[dbo].[ContactInfo]  
		  ([OwnerEntityID]  
		  --,[Title]  
		  ,[FirstName]  
		  --,[LastName]  
		  --,[MiddleName]  
		  ,[DeskPhone]  
		  --,[MobilePhone]  
		  --,[Fax]  
		  ,[Email]  
		  --,[Comments]  
		  ,[DateTimeCreated]  
		  ,[LastUpdateUserID]  
		  ,[DateTimeLastUpdate]  
		  ,[ContactTypeID]  
		  )  
	   select  
		  @NewSupplierID  
		  --,<Title, nvarchar(50),>  
		  ,TechContactName--,<FirstName, nvarchar(50),>  
		  --,<LastName, nvarchar(50),>  
		  --,<MiddleName, nvarchar(50),>  
		  ,TechContactPhone--<DeskPhone, nvarchar(50),>  
		  --,<MobilePhone, nvarchar(50),>  
		  --,<Fax, nvarchar(50),>  
		  ,TechContactEmailID--,<Email, nvarchar(500),>  
		  --,<Comments, nvarchar(500),>  
		  ,getdate()--<DateTimeCreated, datetime,>  
		  ,0--<LastUpdateUserID, nvarchar(50),>  
		  ,GETDATE()--<DateTimeLastUpdate, datetime,>  
		  ,3--<ContactTypeID, smallint,>  
		  --select *  
	   from Onboarding..Onboarding_Suppliers s join Onboarding.dbo.Onboarding_Survey_Result r  
	   on s.SupplierID=r.SupplierID  
	   where LEN(AcceptTerms)>0  
	   and s.SupplierID=@SupplierID  
	   and s.RecordStatus=0  
	     
	     
	  exec prGetOnboardingInventoryRules @NewSupplierID,@SupplierID  
	  exec prGetOnbaordingSupplierUsers @SupplierID,@NewSupplierID  
	    
	  --update Onboarding..Onboarding_Survey_Result   
	  --set RecordStatus=1  
	  --where LEN(AcceptTerms)>0  
	  --and RecordStatus=0  
	  --and SupplierID=@SupplierID  
	    
	    
	  update Onboarding..Onboarding_Suppliers  
	  set RecordStatus=1 where SupplierID=@SupplierID  
	  and RecordStatus=0  
	    
	  End  
	    
	  fetch next from @rec into  @SupplierID  
	 end  
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
