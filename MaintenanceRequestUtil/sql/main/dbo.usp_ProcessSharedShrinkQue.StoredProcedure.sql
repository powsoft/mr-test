USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ProcessSharedShrinkQue]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  Procedure [dbo].[usp_ProcessSharedShrinkQue]
as 
begin 
	Declare @ProcessRunning as varchar(100)
	select @ProcessRunning = id from [SharedShrinkUpdate] with (nolock) where StartedAt is not null and CompletedAt is null

	if (@ProcessRunning is null)
		begin
			Declare @ProcessId as int, @SupplierID as varchar(10), @ChainID as varchar(10)
			
			select top 1 @ProcessId=id, @SupplierID=SupplierID, @ChainID=ChainID from [SharedShrinkUpdate] with (nolock) where StartedAt is null order by id
			
			if(@ProcessId is not null)
			Begin
				update [SharedShrinkUpdate] set StartedAt = GETDATE() where id=@ProcessId
				
				Exec usp_SharedShrinkCalculations  @SupplierId, @ChainId
				
				print 'Shared Shrink values updated successfully for Chain ' + @ChainID + ' and Supplier ' + @SupplierID + '.'
				update [SharedShrinkUpdate] set CompletedAt = GETDATE() where id=@ProcessId
			End
			Else
				print 'No process to run.'
		End
	Else
		print 'Another process already running.'
End
GO
