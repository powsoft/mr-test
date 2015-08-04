USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Suppliers092314]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_Suppliers092314]
as
/*
select count(*) from Suppliers
select * from DataTrue_EDI..Load_Suppliers where loadstatus not in (0,1,-3)
update DataTrue_EDI..Load_Suppliers set loadstatus = 0, SupplierName = SupplierName + '-' + SupplierIdentifier where loadstatus = -1
select top 10 * from Suppliers order by SupplierID desc
select supplieridentifier, count(supplieridentifier) from suppliers group by supplieridentifier order by count(supplieridentifier) desc
select * from ContactInfo where OwnerEntityID > 24000
select * from Addresses where OwnerEntityID > 24000 
*/

declare @rec cursor
declare @chainidentifier nvarchar(50)
declare @supplieridentifier nvarchar(50)
declare @suppliername nvarchar(255)
declare @supplierdescription nvarchar(500)
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
declare @loadstatus int
declare @recordid int
declare @supplierid int
declare @entitytypeid int
declare @MyID int
declare @errormessage varchar(4000)
declare @errorlocation varchar(255)
declare @errorsenderstring nvarchar(255)

set @MyID = 7606
select @entitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Supplier'

set @rec = CURSOR local fast_forward FOR
SELECT [ChainIdentifier]
      ,[supplierIdentifier]
      ,[suppliername]
      ,[supplierDescription]
      ,[contact]
      ,[tel]
      ,[Address]
      ,[Address2]
      ,[City]
      ,[State]
      ,[Zip]
      ,[mobiletel]
      ,[fax]
      ,[email]
      ,[ActiveStartDate]
      ,[ActiveLastDate]
      ,[RecordID]
  FROM [DataTrue_EDI].[dbo].[Load_Suppliers]
  where LoadStatus = 0

open @rec

fetch next from @rec into 
@chainidentifier
,@supplieridentifier
,@suppliername
,@supplierdescription
,@contact
,@telephone
,@address
,@address2
,@city
,@state
,@zip
,@mobilephone
,@fax
,@email
,@startdate
,@enddate
,@recordid

while @@FETCH_STATUS = 0
	begin
	
	begin try
	
		begin transaction
	
		set @loadstatus = 1
	
		select SupplierID from Suppliers
		where --SupplierName = @suppliername or 
		SupplierIdentifier = @supplieridentifier
		
		if @@ROWCOUNT > 0
			begin
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
		           

				set @supplierid = Scope_Identity()
					
				INSERT INTO [dbo].[Suppliers]
						   ([SupplierID]
						   ,[SupplierName]
						   ,[SupplierIdentifier]
						   ,[SupplierDescription]
						   ,[ActiveStartDate]
						   ,[ActiveLastDate]
						   ,[LastUpdateUserID])
					 VALUES
						   (@supplierid
						   ,@suppliername
						   ,@supplieridentifier
						   ,@supplierdescription
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
								   (@supplierid
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
								   (@supplierid
								   ,'Main'
								   ,ISNULL(@address, '')
								   ,ISNULL(@address2, '')
								   ,ISNULL(@city, '')
								   ,ISNULL(@state, '')
								   ,ISNULL(@zip, '')
								   ,@MyID)
											   
						   
			end
			
	COMMIT TRANSACTION

end try
	
begin catch
		rollback transaction
		
		set @loadstatus = -3
		
		--declare @errormessage varchar(4500)
		--declare @errorlocation varchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification
		@errorlocation,
		@errormessage,
		@errorlocation,
		@MyID
end catch

		update [DataTrue_EDI].[dbo].[Load_Suppliers] 
		set LoadStatus = @loadstatus 
		where RecordID = @recordid
		
		fetch next from @rec into 
		@chainidentifier
		,@supplieridentifier
		,@suppliername
		,@supplierdescription
		,@contact
		,@telephone
		,@address
		,@address2
		,@city
		,@state
		,@zip
		,@mobilephone
		,@fax
		,@email
		,@startdate
		,@enddate
		,@recordid
	end
	
close @rec
deallocate @rec


	
return
GO
