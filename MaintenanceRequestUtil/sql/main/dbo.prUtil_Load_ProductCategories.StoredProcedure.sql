USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_ProductCategories]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_ProductCategories]
as

declare @MyID int
set @MyID = 7601
/*
select * from productcategories

*/

declare @rec cursor
declare @chainidentifier varchar(50)
declare @chainid int
declare @owneridentifier nvarchar(50)
declare @ownerentitytypeid smallint
declare @ownerentityid int
declare @categoryidentifier varchar(50)
declare @categoryparentidentifier varchar(50)
declare @categorydescription varchar(500)
declare @productcategoryparentid int
declare @parentcategoryneeded tinyint
declare @loadstatus smallint
declare @recordid int

set @rec = CURSOR local fast_forward FOR
SELECT [ChainIdentifier]
	  ,[OwnerIdentifier]
	  ,[OwnerEntityTypeID]
      ,[categoryIdentifier]
      ,isnull([categoryparentidentifier], '')
      ,isnull([categorydescription], '')
      ,RecordID
  FROM [DataTrue_EDI].[dbo].[Load_ProductCategories]
  where LoadStatus = 0
  order by [order]

open @rec

fetch next from @rec into 
@chainidentifier
,@owneridentifier
,@ownerentitytypeid
,@categoryidentifier
,@categoryparentidentifier
,@categorydescription
,@recordid

while @@FETCH_STATUS = 0
	begin
	
		begin try
		
		begin transaction
		
		set @loadstatus = 1
		
		
		select @chainid = chainid from ChainS
		where LTRIM(rtrim(ChainIdentifier)) = LTRIM(rtrim(@chainidentifier))
		
		if @@ROWCOUNT < 1
			begin
			
				set @chainid = 0
			
			end
		
		if @ownerentitytypeid = 5
			begin
				select @ownerentityid =  supplierid from Suppliers where ltrim(rtrim(SupplierIdentifier)) = @owneridentifier
			end
		else
			begin
				set @ownerentityid = 0
			end
		
		select ProductCategoryID from .ProductCategories
		where ProductCategoryName = @categoryidentifier
		
		if @@ROWCOUNT > 0
			begin
				set @loadstatus = -1
			end
		else
			begin
				set @parentcategoryneeded = 0
				if LEN(@categoryparentidentifier) < 1
					begin
						set @productcategoryparentid = 0
						set @parentcategoryneeded = 0
					end
				else
					begin
						set @parentcategoryneeded = 1
						select @productcategoryparentid =  ProductCategoryID
						from .ProductCategories 
						where ProductCategoryName = @categoryparentidentifier
						if @@ROWCOUNT > 0 
							set @parentcategoryneeded = 0
						else
							set @loadstatus = -2
					end
				if @parentcategoryneeded = 0
					begin
						INSERT INTO .ProductCategories
								   ([ProductCategoryName]
								   ,[ProductCategoryDescription]
								   ,[ProductCategoryParentID]
								   ,[LastUpdateUserID]
								   ,[DateTimeLastUpdate])
							 VALUES
								   (@categoryidentifier
								   ,@categorydescription
								   ,@productcategoryparentid
								   ,@MyID
								   ,GETDATE())
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

		update [DataTrue_EDI].[dbo].[Load_ProductCategories] 
		set LoadStatus = @loadstatus 
		where RecordID = @recordid
		
			fetch next from @rec into 
			@chainidentifier
			,@owneridentifier
			,@ownerentitytypeid
			,@categoryidentifier
			,@categoryparentidentifier
			,@categorydescription
			,@recordid
	end
	
close @rec
deallocate @rec

exec .prProductCategories_HierarchyID_Update

/*
select top 100 * from suppliers order by supplierid desc

*/
GO
