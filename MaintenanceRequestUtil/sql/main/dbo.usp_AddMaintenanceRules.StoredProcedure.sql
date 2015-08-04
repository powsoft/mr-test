USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddMaintenanceRules]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_AddMaintenanceRules]
 @MRID int,
 @ChainID varchar(50),
 @SupplierID varchar(50),
 @ClusterID varchar(50),
 @CategoryID varchar(50),
 @RequestTypeID varchar(50),
 @LeadTime varchar(50)
        
as
begin
		
	if(@MRID=0)		
		INSERT INTO [MaintenanceRules]
           ([ChainID]
           ,[SupplierID]
           ,[ClusterID]
           ,[CategoryID]
           ,[RequestTypeID]
           ,[RequiredLeadTime])
		VALUES
           (@ChainID
           ,@SupplierID
           ,@ClusterID
           ,@CategoryID
           ,@RequestTypeID
           ,@LeadTime)
           
	else 
		begin
			UPDATE [MaintenanceRules]
			   SET [ChainID] = @ChainID
			      ,[SupplierID] = @SupplierID
				  ,[ClusterID] = @ClusterID
				  ,[CategoryID] = @CategoryID
				  ,[RequestTypeID] = @RequestTypeID
				  ,[RequiredLeadTime] = @LeadTime
			 WHERE [MRId] = @MRID
		end	 
end
GO
