USE [DataTrue_Main]
GO

/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_SupplierLoginID_Populate]    Script Date: 08/15/2015 16:17:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[prMaintenanceRequest_SupplierLoginID_Populate]
as

declare @rec cursor
declare @supplierid int
declare @banner nvarchar(50)
declare @supplierloginid int


set @rec = CURSOR local fast_forward FOR
	select distinct supplierid, banner
	--select  *
	--update r set SupplierLoginID = -2
	from MaintenanceRequestS r
	where SupplierLoginID = -1
	
open @rec

fetch next from @rec into @supplierid, @banner

If @@FETCH_STATUS = 0
	begin
		exec dbo.prSendEmailNotification_PassEmailAddresses 'prMaintenanceRequest_SupplierLoginID_Populate'
		,'prMaintenanceRequest_SupplierLoginID_Populate found negative one values'
		,'DataTrue System', 0, 'charlie.clark@icontroldsd.com'
	
	end

while @@FETCH_STATUS = 0
	begin

		set @supplierloginid = null
		if @supplierid in (40557)
			begin
				set @supplierloginid = 
				case 
					when @banner = 'Farm Fresh Markets' then 41551 
					else 41550 
				end			
			end
		else
			begin
				set @supplierloginid = 
				case 
					when @supplierid = 40559 then 41612 
					when @supplierid = 40558 then 41598
					when @supplierid = 40560 then 41637 
					when @supplierid = 40561 then 41544
					when @supplierid = 40562 then 41537
					when @supplierid = 40563 then 41568 
					when @supplierid = 40567 then 41579
					when @supplierid = 40570 then 41589
					when @supplierid = 40578 then 41695
					when @supplierid = 41342 then 41479
					when @supplierid = 41464 then 41549
					--when @supplierid = 41465 then 41560
					when @supplierid = 41746 then 42112
					
					else -1
				 end			
			end	
			
		if @supplierloginid is not null
			begin
			
				--select 1
			--/*
				update MaintenanceRequestS
				set SupplierLoginID = @supplierloginid
				where SupplierLoginID = -1
				and SupplierID = @supplierid
				and Banner = @banner
			--*/	
			end
		fetch next from @rec into @supplierid, @banner	
	end

close @rec
deallocate @rec




return

GO

