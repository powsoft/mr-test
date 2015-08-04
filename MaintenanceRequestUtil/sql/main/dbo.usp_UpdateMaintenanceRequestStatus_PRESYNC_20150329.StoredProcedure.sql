USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateMaintenanceRequestStatus_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_UpdateMaintenanceRequestStatus 1,'mike.flebotte@icontroldsd.com','35375','41575',''
CREATE Procedure [dbo].[usp_UpdateMaintenanceRequestStatus_PRESYNC_20150329]
     @ApproveStatus int,
     @SupplierEmailId VarChar(100),
     @MaintenanceRequestID varchar(10),
     @LoginId varchar(10),
     @DenialReason varchar(500)
as
begin
		Declare @MRId as varchar(10)
		Declare @ApprovalDateTime date = getdate()
		
		if(@ApproveStatus<>0)
			set @DenialReason=''
		
		if(@ApproveStatus=11)
		BEGIN
			set @ApproveStatus=NULL
			set @ApprovalDateTime=NULL
		end
		
		Select @MRId= M1.MaintenanceRequestID  
		from MaintenanceRequests M1	
		inner join MaintenanceRequests M2 on M1.SupplierID=M2.SupplierID and M1.ChainID=M2.ChainID 
		and M1.AllStores=M2.AllStores and M1.UPC=M2.UPC
		where M1.RequestTypeID=1 and M1.RequestStatus<>999 and isnull(M1.Approved,0)=0 and M1.Cost=0
		and M2.RequestTypeID=2 and M2.RequestStatus<>999 and isnull(M2.Approved,0)=0
		and M2.MaintenanceRequestID=@MaintenanceRequestID
		
		update MaintenanceRequests set 
		Approved=@ApproveStatus, ApprovalDateTime=@ApprovalDateTime,
		ChainLoginID=@LoginId, DenialReason= @DenialReason, 
		EmailGeneratedToSupplier=@SupplierEmailId, 
		EmailGeneratedToSupplierDateTime=GETDATE()
		where isnull(Approved,0)=0 and MaintenanceRequestID in (@MaintenanceRequestID, @MRId)
			
end
GO
