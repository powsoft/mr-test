USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Stores_FromCreateStores]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_Stores_FromCreateStores]
as

declare @rec cursor
declare @chainidentifier varchar(50)
declare @storeidentifier varchar(50)
declare @storeid int
declare @storename varchar(50)
declare @address varchar(100)
declare @address2 varchar(100)
declare @city varchar(50)
declare @state varchar(50)
declare @zip varchar(50)
declare @manager varchar(50)
declare @telephone varchar(50)
declare @firstname varchar(50)
declare @lastname varchar(50)
declare @mobilephone varchar(50)
declare @fax varchar(50)
declare @email varchar(100)
declare @clusteridentifier varchar(50)
declare @clusteridentifier2 varchar(50)
declare @clusteridentifier3 varchar(50)
declare @clusteridentifier4 varchar(50)
declare @startdate datetime
declare @enddate datetime='12/31/2099'
declare @recordid int
declare @loadstatus smallint
declare @clusterid int
declare @chainid int
declare @entitytypeid int
declare @errormessage varchar(4500)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)
declare @sbtno nvarchar(50)
declare @banner nvarchar(50)
declare @createstorerecordid int

declare @MyID int
set @MyID = 0

select @entitytypeid = EntityTypeID 
from EntityTypes 
where EntityTypeName = 'Store'
/*				
update DataTrue_EDI.dbo.Load_Stores
set LoadStatus = -2
where LoadStatus = 0
and ISNUMERIC(storeidentifier) < 1

if @@ROWCOUNT > 0
	begin
		set @errormessage = 'Invalid Store Identifiers Found in prUtil_Load_Stores'
		set @errorlocation = 'prUtil_Load_Stores'
		set @errorsenderstring = 'prUtil_Load_Stores'
		
		exec dbo.prLogExceptionAndNotifySupport
		2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
	
	end
*/
--select top 100 * from Load_Stores

	Set @storename='';
	Set @clusteridentifier='';
	Set @clusteridentifier2='';
	Set @clusteridentifier3='';
	Set @clusteridentifier4='';


set @rec = cursor local fast_forward for
	select StoreNumber, address, 
	city, state, ZipCode, StoreMgr, Banner, 
	SBTNumber,OpeningDate, ID, ChainID
	--select *
	from DataTrue_Main.dbo.CreateStores
	where 1=1
	and RecordStatus = 0 
	and StoreNumber is not null
	
	
open @rec 

fetch next from @rec into @storeidentifier,
	@address,@city,@state,@zip,@manager,@banner,@sbtno,@startdate,@createstorerecordid,@ChainID

while @@fetch_status = 0
	begin
	
		begin try
		
		begin transaction
	
		set @loadstatus = 1
		Set @storename=@banner +'-'+@storeidentifier;
		--select @chainid = ChainID from Chains where ChainIdentifier = @chainidentifier
		/*select @chainid = ChainID from Chains where ChainIdentifier = left(@chainidentifier, 2)
		
		if @@ROWCOUNT < 1
			begin
				set @loadstatus = -2
				
				set @errormessage = 'Invalid Chain Identifier ' + @chainidentifier + ' Found in prUtil_Load_Stores_FromCreateStores. Record not loaded.'
				set @errorlocation = 'prUtil_Load_Stores_FromCreateStores'
				set @errorsenderstring = 'prUtil_Load_Stores_FromCreateStores'
				
				exec dbo.prLogExceptionAndNotifySupport
				2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
				,@errorlocation
				,@errormessage
				,@errorsenderstring
				,@MyID
					
				
			end
		*/
			
		if LEN(@clusteridentifier) > 0 And @loadstatus = 1
			begin
				select @clusterid = ClusterID
				from dbo.Clusters
				where ClusterName = @clusteridentifier
				and ChainID = @chainid
				
				if @@ROWCOUNT < 1
					begin
						set @loadstatus = -2
						
						set @errormessage = 'Invalid Cluster Identifier ' + @clusteridentifier + ' Found in prUtil_Load_Stores_FromCreateStores. Record not loaded.'
						set @errorlocation = 'prUtil_Load_Stores_FromCreateStores'
						set @errorsenderstring = 'prUtil_Load_Stores_FromCreateStores'
						
						exec dbo.prLogExceptionAndNotifySupport
						2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
						,@errorlocation
						,@errormessage
						,@errorsenderstring
						,@MyID
					end				
				
			end
		
		if @loadstatus = 1
			begin
				select storeid 
				from Stores 
				where ChainID = @chainid 
				--and cast(StoreIdentifier as int) = cast(@storeidentifier as int)
				and CAST(custom2 as int) = CAST(@sbtno as int)
				
				if @@ROWCOUNT > 0
					begin
						set @loadstatus = -1
						
						set @errormessage = 'Store Identifier ' + @storeidentifier + ' already in use found in prUtil_Load_Stores_FromCreateStores. Record not loaded.'
						set @errorlocation = 'prUtil_Load_Stores_FromCreateStores'
						set @errorsenderstring = 'prUtil_Load_Stores_FromCreateStores'
						
						exec dbo.prLogExceptionAndNotifySupport
						2 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
						,@errorlocation
						,@errormessage
						,@errorsenderstring
						,@MyID
					end						
				
				
				
				if @loadstatus < 0
					begin
						if @loadstatus > -1
							set @loadstatus = -1
					end
				else
					begin
			
						INSERT INTO [dbo].[SystemEntities]
						   ([EntityTypeID]
						   ,[LastUpdateUserID])
						VALUES
						   (@entitytypeid
						   ,@MyID)

						set @storeid = SCOPE_IDENTITY()
						
						INSERT INTO [dbo].[Stores]
						   ([StoreID]
						   ,[ChainID]
						   ,[StoreName]
						   ,[StoreIdentifier]
						   ,[ActiveFromDate]
						   ,[ActiveLastDate]
						   ,[LastUpdateUserID]
						   ,[Custom1]
						   ,[Custom2]
						   ,[Custom3]
						   ,[ActiveStatus])
						VALUES
						   (@storeid
						   ,@chainid
						   ,@storename
						   ,@storeidentifier
						   ,@startdate
						   ,@enddate
						   ,@MyID
						   ,@banner
						   ,cast(cast(@sbtno as int) as nvarchar(50))
						   ,@chainidentifier
						   ,'Active')
				           
				           
						  If @manager is not null 
								or @telephone is not null
								or @mobilephone is not null
								or @fax is not null
								or @email is not null
							begin
								  set @firstname = ''
								  set @lastname = ''
								
								  if @manager is not null
									begin
										set @firstname = left(ltrim(rtrim(isnull(@manager,''))), charindex(' ', ltrim(rtrim(isnull(@manager,'')))))
										set @lastname = right(ltrim(rtrim(@manager)), len(ltrim(rtrim(isnull(@manager,'')))) - charindex(' ', ltrim(rtrim(isnull(@manager,'')))))
									end
								
								INSERT INTO [dbo].[ContactInfo]
								   ([OwnerEntityID]
								   ,[Title]
								   ,[FirstName]
								   ,[LastName]
								   ,[DeskPhone]
								   ,[MobilePhone]
								   ,[Fax]
								   ,[Email]
								   ,[LastUpdateUserID])
								VALUES
								   (@storeid
								   ,'Contact'
								   ,@firstname
								   ,@lastname
								   ,isnull(@telephone, '')
								   ,isnull(@mobilephone, '')
								   ,isnull(@fax, '')
								   ,isnull(@email, '')
								   ,@MyID)
							end
							
						INSERT INTO [dbo].[Addresses]
								   ([OwnerEntityID]
								   ,[AddressDescription]
								   ,[Address1]
								   ,[Address2]
								   ,[City]
								   ,[State]
								   ,[PostalCode]
								   ,[LastUpdateUserID])
							 VALUES
								   (@Storeid
								   ,'Store Location'
								   ,ISNULL(@address, '')
								   ,ISNULL(@address2, '')
								   ,ISNULL(@city, '')
								   ,ISNULL(@state, '')
								   ,ISNULL(@zip, '')
								   ,@MyID)							
							
							
							
							
							if LEN(@clusteridentifier) > 0
								begin
									select @clusterid = ClusterID
									from dbo.Clusters
									where ClusterName = @clusteridentifier
									
									INSERT INTO [dbo].[Memberships]
									   ([MembershipTypeID]
									   ,[OrganizationEntityID]
									   ,[MemberEntityID]
									   ,[ChainID]
									   ,[LastUpdateUserID])
								 VALUES
									   (1
									   ,@clusterid
									   ,@storeid
									   ,@chainid
									   ,@MyID)
									   
								end
					end
				end --if @loadstatus = 1


			update CreateStores set recordstatus = 1 where ID = @createstorerecordid
				
			commit transaction

end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -3
		

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification
		@errorlocation,
		@errormessage,
		@errorlocation,
		@MyID
end catch
print @loadstatus
print @recordid
		--update DataTrue_EDI.dbo.Load_Stores 
		--set LoadStatus = @loadstatus 
		--where RecordID = @recordid
		
fetch next from @rec into @storeidentifier,
	@address,@city,@state,@zip,@manager,@banner,@sbtno,@startdate,@createstorerecordid,@ChainID
	end
	
close @rec
deallocate @rec


		exec prMemberships_HierarchyID_Update


return
GO
