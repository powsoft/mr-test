USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Brands]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_Brands]
as
/*
select * from [DataTrue_EDI].[dbo].[Load_Brands] where loadstatus = 0
update [DataTrue_EDI].[dbo].[Load_Brands] set loadstatus = 0 where loadstatus = -2 and BrandName <> 'Ann Arbor News'
select BrandName from [DataTrue_EDI].[dbo].[Load_Brands] group by brandname having count(brandname) > 1
*/
declare @MyID int
set @MyID = 7600

declare @rec cursor
declare @chainidentifier varchar(50)
declare @manufactureridentifier varchar(50)
declare @brandname varchar(50)
declare @brandidentifier varchar(50)
declare @branddescription varchar(500)
declare @recordid int
declare @loadstatus int
declare @manufacturerid int

set @rec = CURSOR local fast_forward FOR
SELECT [ChainIdentifier]
      ,[BrandName]
      ,[BrandIdentifier]
      ,[BrandDescription]
      ,[ManufacturerIdentifier]
      ,[RecordID]
  FROM [DataTrue_EDI].[dbo].[Load_Brands]
  where LoadStatus = 0

open @rec

fetch next from @rec into 
@chainidentifier
,@brandname
,@brandidentifier
,@branddescription
,@manufactureridentifier
,@recordid

while @@FETCH_STATUS = 0
	begin
	
	begin try
	
	begin transaction
	
		set @loadstatus = 1
		
		select @manufacturerid = ManufacturerID from Manufacturers
		where ManufacturerIdentifier = @manufactureridentifier
		
		if @@ROWCOUNT < 1
			begin
				set @loadstatus = -2			
			end
	
		if @loadstatus = 1
			begin
				select BrandID from Brands
				where BrandName = @brandname
				or brandidentifier = @brandidentifier
				
				if @@ROWCOUNT > 0
					begin
						set @loadstatus = -1
					end
				else
					begin
					
						INSERT INTO [dbo].[Brands]
								   ([BrandName]
								   ,[BrandIdentifier]
								   ,[BrandDescription]
								   ,[LastUpdateUserID]
								   ,[DateTimeLastUpdate]
								   ,[ManufacturerID])
							 VALUES
								   (@brandname
								   ,@brandidentifier
								   ,@branddescription
								   ,@MyID
								   ,GETDATE()
								   ,@manufacturerid)
					

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

		update [DataTrue_EDI].[dbo].[Load_Brands] 
		set LoadStatus = @loadstatus 
		where RecordID = @recordid
	
		fetch next from @rec into 
		@chainidentifier
		,@brandname
		,@brandidentifier
		,@branddescription
		,@manufactureridentifier
		,@recordid
	end
	
close @rec
deallocate @rec

	
return
GO
