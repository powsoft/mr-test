USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUser_Reporting_Role_Manage_MultiChain]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUser_Reporting_Role_Manage_MultiChain]
@rolename nvarchar(255) --ReportAdmin ReportChain ReportStore ReportSupplier ReportManufacturer
,@loginname nvarchar(50) --email address preferred
,@loginpassword nvarchar(50)
,@fullname nvarchar(50)
,@organizationentityid nvarchar(100)
,@packagetype int
,@actioncode nvarchar(50) --ADD UPDATE CHANGE DELETE
,@actionresult nvarchar(1000) output
/*

prUser_Reporting_Role_Manage_MultiChain 'ReportSupplier', 'karen_weinstein__limone@pepperidgefarm.com', 
'2CA890C9 402CF2BA 27B7FF32 DEECB647 FE661248','karen weinstein','40562',3000,'ADD', '' 

select * from attributevalues where ownerentityid = 41565
doc_access 4 not 6
users_in_groups all 2
*/
as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @loadstatus smallint
declare @MyID int
declare @userid int
declare @roletemplateuserid int
declare @custom1 nvarchar(50)
declare @custom2 nvarchar(50)
declare @custom3 nvarchar(50)

set @MyID = 24141

set @actionresult = ''
select @userid = id from [ir_system33].[dbo].[Users] where login_name = @loginname
select @roletemplateuserid = id from [ir_system33].[dbo].[Users] where login_name = @rolename

set @custom1 =
	case
		when @rolename = 'ReportAdmin' then 'Admin'
		when @rolename = 'ReportChain' then 'Chain'
		when @rolename = 'ReportStore' then 'Store'
		when @rolename = 'ReportSupplier' then 'Supplier'
		when @rolename = 'ReportManufacturer' then 'Manufacturer'
	else '' end

set @custom2 =
	case
		when @rolename = 'ReportAdmin' then '1'
		when @rolename = 'ReportChain' then 'ChainID'
		when @rolename = 'ReportStore' then 'StoreID'
		when @rolename = 'ReportSupplier' then 'SupplierID'
		when @rolename = 'ReportManufacturer' then 'ManufacturerID'
	else '' end

set @custom3 =
	case
		when @rolename = 'ReportAdmin' then '1'
	else @organizationentityid end
	
begin try

	begin transaction
	
		if @actioncode = 'UPDATE' and @userid is not null
			begin
				update [ir_system33].[dbo].[Users]
				set login_password = @loginpassword
				,full_name=case when @fullname = '' then [full_name] else @fullname end
				,custom1 = @custom1
				,custom2 = @custom2
				,custom3 = @custom3
				,custom4 = cast(@packagetype as nvarchar)
				where id = @userid
			end
		else if @actioncode = 'DELETE' and @userid is not null
			begin
				delete [ir_system33].[dbo].[user_in_groups] where [USER_ID] = @userid
				delete [ir_system33].[dbo].[user_access] where [USER_ID] = @userid
				delete [ir_system33].[dbo].[Users] where id = @userid
			end
		else if (@actioncode = 'ADD' and @userid is null) or (@actioncode = 'UPDATE' and @userid is null)
			begin
				INSERT INTO [ir_system33].[dbo].[Users]
				   ([login_name]
				   ,[login_password]
				   ,[full_name]
				   ,[sales_initials]
				   ,[access_level]
				   ,[sales_group]
				   ,[ip_mask]
				   ,[ip_nsb]
				   ,[mapping_id]
				   ,[login_count]
				   ,[all_mappings]
				   ,[last_password_update]
				   ,[isGroup]
				   ,[doc_access]
				   ,[count_favourites_date]
				   ,[custom1]
				   ,[custom2]
				   ,[custom3]
				   ,[custom4]
				   ,[custom5]
				   ,[custom6]
				   ,[custom7]
				   ,[custom8]
				   ,[custom9]
				   ,[custom10])
				select @loginname
					,@loginpassword
					,case when @fullname = '' then [full_name] else @fullname end
					,[sales_initials]
					,[access_level]
					,[sales_group]
					,[ip_mask]
					,[ip_nsb]
					,[mapping_id]
					,[login_count]
					,[all_mappings]
					,[last_password_update]
					,[isGroup]
					,[doc_access]
					,[count_favourites_date]
					,@custom1
					,@custom2
					,@custom3
					,cast(@packagetype as nvarchar)
					,[custom5]
					,[custom6]
					,[custom7]
					,[custom8]
					,[custom9]
					,[custom10]
				from [ir_system33].[dbo].[Users]  
				where login_name = @rolename  
				      
			set @userid = Scope_Identity()
				      
			INSERT INTO [ir_system33].[dbo].[User_Access]
					   ([user_id]
					   ,[mapping_id]
					   ,[mapping_selected]
					   ,[user_key]
					   ,[secondary_user_key]
					   ,[group_key]
					   ,[access_level])
				 select @userid
					   ,[mapping_id]
					   ,[mapping_selected]
					   ,case when @rolename = 'ReportAdmin' then '' else @organizationentityid end
					   ,[secondary_user_key]
					   ,[group_key]
					   ,[access_level]
					   from [ir_system33].[dbo].[User_Access]
					   where [user_id] = @roletemplateuserid


			INSERT INTO [ir_system33].[dbo].[user_in_groups]
					   ([user_id]
					   ,[group_id])
				 select @userid
					    ,[group_id]
						from [ir_system33].[dbo].[user_in_groups]
						where [user_id] = @roletemplateuserid		      
			end
		else if @actioncode = 'CHANGE' and @userid is not null
			begin
			
				delete [ir_system33].[dbo].[user_in_groups] where [USER_ID] = @userid
				delete [ir_system33].[dbo].[user_access] where [USER_ID] = @userid
				
				UPDATE [ir_system33].[dbo].[Users]
				   SET [sales_initials] = u2.[sales_initials]
					  ,[access_level] = u2.[access_level]
					  ,[sales_group] = u2.[sales_group]
					  ,[ip_mask] = u2.[ip_mask]
					  ,[ip_nsb] = u2.[ip_nsb]
					  ,[mapping_id] = u2.[mapping_id]
					  ,[login_count] = u2.[login_count]
					  ,[all_mappings] = u2.[all_mappings]
					  ,[last_password_update] = u2.[last_password_update]
					  ,[isGroup] = u2.[isGroup]
					  ,[doc_access] = u2.[doc_access]
					  ,[count_favourites_date] = u2.[count_favourites_date]
					  ,[custom1] = @custom1
					  ,[custom2] = @custom2
					  ,[custom3] = @custom3
					  ,[custom4] = cast(@packagetype as nvarchar)
					  from [ir_system33].[dbo].[Users] u2
				 WHERE u2.login_name = @rolename


				INSERT INTO [ir_system33].[dbo].[User_Access]
					   ([user_id]
					   ,[mapping_id]
					   ,[mapping_selected]
					   ,[user_key]
					   ,[secondary_user_key]
					   ,[group_key]
					   ,[access_level])
				 select @userid
					   ,[mapping_id]
					   ,[mapping_selected]
					   ,case when @rolename = 'ReportAdmin' then '' else @organizationentityid end
					   ,[secondary_user_key]
					   ,[group_key]
					   ,[access_level]
					   from [ir_system33].[dbo].[User_Access]
					   where [user_id] = @roletemplateuserid


				INSERT INTO [ir_system33].[dbo].[user_in_groups]
					   ([user_id]
					   ,[group_id])
				 select @userid
					    ,[group_id]
						from [ir_system33].[dbo].[user_in_groups]
						where [user_id] = @roletemplateuserid		      
				end
			 
	commit transaction
           
 end try
 
 begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		set @actionresult = @errorlocation + ': ' + @errormessage

		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
 
 end catch
 
 return
GO
