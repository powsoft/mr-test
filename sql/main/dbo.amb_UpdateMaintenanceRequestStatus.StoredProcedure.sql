USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateMaintenanceRequestStatus]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[amb_UpdateMaintenanceRequestStatus]
     @ApproveStatus int,
     @SupplierEmailId VarChar(100),
     @MaintenanceRequestID varchar(10),
     @LoginId varchar(10),
     @DenialReason varchar(500)
as
begin
		Declare @MRId as varchar(10)
		
		if(@ApproveStatus=1)
			set @DenialReason=''
			
		Select @MRId= M1.MaintenanceRequestID  
		from MaintenanceRequests M1	
		inner join MaintenanceRequests M2 on M1.SupplierID=M2.SupplierID and M1.ChainID=M2.ChainID 
		and M1.AllStores=M2.AllStores and M1.UPC=M2.UPC
		where M1.RequestTypeID=1 and M1.RequestStatus<>999 and M1.Approved is null and M1.Cost=0
		and M2.RequestTypeID=2 and M2.RequestStatus<>999 and M2.Approved is null 
		and M2.MaintenanceRequestID=@MaintenanceRequestID

		update MaintenanceRequests set 
		Approved=@ApproveStatus, ApprovalDateTime=GETDATE(),
		ChainLoginID=@LoginId, DenialReason= @DenialReason, 
		EmailGeneratedToSupplier=@SupplierEmailId, 
		EmailGeneratedToSupplierDateTime=GETDATE()
		where Approved is Null and MaintenanceRequestID in (@MaintenanceRequestID, @MRId)
		

end
GO
