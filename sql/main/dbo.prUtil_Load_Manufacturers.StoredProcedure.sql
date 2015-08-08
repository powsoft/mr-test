USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Manufacturers]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_Manufacturers]
as
/*
select * from DataTrue_EDI..Load_Manufacturers where loadstatus = 0

select * 
--delete
from Stores where StoreName = 'worldmart' 

select *
--delete
FROM  ContactInfo
WHERE (ContactID > 7326)
*/
declare @rec cursor
declare @manufacturername varchar(50)
declare @manufactureridentifier varchar(50)
declare @manufacturerid int
declare @address varchar(100)
declare @address2 varchar(100)
declare @city varchar(50)
declare @state varchar(50)
declare @zip varchar(50)
declare @contact varchar(50)
declare @telephone varchar(50)
declare @firstname varchar(50)
declare @lastname varchar(50)
declare @mobilephone varchar(50)
declare @fax varchar(50)
declare @email varchar(100)
declare @startdate datetime
declare @enddate datetime
declare @recordid int
declare @loadstatus smallint
declare @entitytypeid int
declare @errormessage varchar(4000)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)

declare @MyID int
set @MyID = 24030

select @entitytypeid = EntityTypeID 
--select *
from EntityTypes 
where EntityTypeName = 'Manufacturer'
				

--select * from DataTrue_EDI..Load_Manufacturers
set @rec = cursor local fast_forward for
	select distinct manufacturername, manufactureridentifier, contact, tel, 
	[Address], Address2, City, State, Zip,
	[mobiletel], [fax], [email],
	isnull(ActiveStartDate, '1/1/2011'), 
	isnull(ActiveEndDate, '1/1/2500'), RecordID
	from DataTrue_EDI.dbo.Load_Manufacturers
	where LoadStatus = 0 
	and manufactureridentifier is not null
	
open @rec 

fetch next from @rec into @manufacturername, @manufactureridentifier, @contact, @telephone,
	@address,@address2, @city,@state,@zip, @mobilephone, @fax, @email,
	@startdate, @enddate, @recordid

while @@fetch_status = 0
	begin
	
		begin try
	
		begin transaction
	
		set @loadstatus = 1
		
		
		--if @loadstatus = 1
			--begin
				select manufacturerid 
				from Manufacturers
				where ManufacturerName = @manufacturername
				or @manufactureridentifier = manufactureridentifier
				
				if @@ROWCOUNT > 0
					begin
						set @loadstatus = -1
						
						set @errormessage = 'Manufacturer Name ' + @manufactureridentifier + ' already in use found in prUtil_Load_Stores. Record not loaded and set to status of -1.'
						set @errorlocation = 'prUtil_Load_Manufacturers'
						set @errorsenderstring = 'prUtil_Load_Manufacturers'
						
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

						set @manufacturerid = Scope_Identity()
						
						INSERT INTO [dbo].[Manufacturers]
								   ([ManufacturerID]
								   ,[ManufacturerName]
								   ,[ManufacturerIdentifier]
								   ,[ActiveStartDate]
								   ,[ActiveLastDate]
								   ,[LastUpdateUserID])
							 VALUES
								   (@manufacturerid
								   ,@manufacturername
								   ,@manufactureridentifier
								   ,@startdate
								   ,@enddate
								   ,@MyID)

						  If @contact is not null 
								or @telephone is not null
								or @mobilephone is not null
								or @fax is not null
								or @email is not null

							begin
								
								  set @firstname = ''
								  set @lastname = ''
								
								  if @contact is not null
									begin
										set @firstname = left(ltrim(rtrim(isnull(@contact,''))), charindex(' ', ltrim(rtrim(isnull(@contact,'')))))
										set @lastname = right(ltrim(rtrim(@contact)), len(ltrim(rtrim(isnull(@contact,'')))) - charindex(' ', ltrim(rtrim(isnull(@contact,'')))))
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
								   (@manufacturerid
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
								   (@manufacturerid
								   ,'Main Corporate'
								   ,ISNULL(@address, '')
								   ,ISNULL(@address2, '')
								   ,ISNULL(@city, '')
								   ,ISNULL(@state, '')
								   ,ISNULL(@zip, '')
								   ,@MyID)
						
					end
				--end --if @loadstatus = 1
				
			commit transaction

end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -3
		

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
--print @loadstatus
--print @recordid
		update DataTrue_EDI.dbo.Load_Manufacturers 
		set LoadStatus = @loadstatus 
		where RecordID = @recordid

		fetch next from @rec into @manufacturername, @manufactureridentifier, @contact, @telephone,
			@address,@address2, @city,@state,@zip, @mobilephone, @fax, @email,
			@startdate, @enddate, @recordid
	end
	
close @rec
deallocate @rec

return
GO
