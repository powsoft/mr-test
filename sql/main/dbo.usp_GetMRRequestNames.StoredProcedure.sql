USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetMRRequestNames]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetMRRequestNames]
	@MaintenanceRequestIds varchar(MaX)
as
--exec usp_GetMRRequestNames '(1,2,3)'
Begin
	begin try
        Drop TABLE [@tmpRequestNames]
	end try
	begin catch
	end catch
	
	DECLARE @RequestTypes VARCHAR(MAX)
	Declare @strSQL varchar(MAX)
	
	set @strSQL = 'Select distinct Mt.RequestTypeDescription as RequestTypeName 
					into [@tmpRequestNames]
					from MaintenanceRequests mreq
					INNER JOIN MaintananceRequestsTypes Mt ON mreq.RequestTypeID=Mt.RequestType
					where mreq.MaintenanceRequestId in ' + @MaintenanceRequestIds + '
					order by 1 '
					
	exec (@strSQL)	
						
	
	SELECT @RequestTypes = COALESCE(@RequestTypes+'/' ,'') + RequestTypeName
	FROM [@tmpRequestNames]

	SELECT @RequestTypes
	
	begin try
        Drop TABLE [@tmpRequestNames]
	end try
	begin catch
	end catch

End


--Select * from MaintenanceRequests where SupplierID=42255 and ApprovalDateTime>=getdate()-1
--update MaintenanceRequests SET Approved=NULL, ApprovalDateTime =NULL where SupplierID=42255 and ApprovalDateTime>=getdate()-1
GO
