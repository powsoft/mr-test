USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateMaintenanceRequestStores]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UpdateMaintenanceRequestStores]
as
Begin
	
	Delete from DataTrue_CustomResultSets.dbo.tmpMaintenanceRequestStores 
	where MaintenanceRequestID in (Select distinct MaintenanceRequestID from MaintenanceRequests 
	where datetimecreated>=convert(varchar(10),GETDATE(),101))

	Insert into DataTrue_CustomResultSets.dbo.tmpMaintenanceRequestStores
	SELECT     mr.MaintenanceRequestID, mrs.StoreId , s.StoreIdentifier  
	FROM       MaintenanceRequests mr 
		
		LEFT OUTER JOIN  dbo.MaintenanceRequestStores mrs ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID 
			  AND mrs.MaintenanceRequestID IS NOT NULL
		INNER JOIN stores s ON s.StoreID = mrs.StoreID and s.ActiveStatus='Active'
			  where mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	
	UNION 
	
	SELECT     mr.MaintenanceRequestID, s.StoreID, s.StoreIdentifier 
	FROM         MaintenanceRequests mr 
		INNER JOIN CostZoneRelations cz ON cz.CostZoneID = mr.CostZoneID AND mr.CostZoneID IS NOT NULL 
		INNER JOIN stores s ON s.StoreID = cz.StoreID and s.ActiveStatus='Active' 
		LEFT OUTER JOIN  dbo.MaintenanceRequestStores mrs ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID
	WHERE     mrs.MaintenanceRequestID IS NULL
				AND mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	UNION 
	
	SELECT     mr.MaintenanceRequestID, s.StoreID, s.StoreIdentifier 
	FROM         MaintenanceRequests mr 
		INNER JOIN stores s ON s.Custom1 = mr.Banner and s.ActiveStatus='Active' 
		LEFT OUTER JOIN  dbo.MaintenanceRequestStores mrs ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID
	WHERE     mr.CostZoneID IS NULL AND mr.Banner IS NOT NULL 
			AND mrs.MaintenanceRequestID IS NULL
			AND mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	UNION 
	
	SELECT     mr.MaintenanceRequestID, s.StoreID, s.StoreIdentifier 
	FROM         MaintenanceRequests mr 
		INNER JOIN  stores s ON s.ChainID = mr.ChainID and s.ActiveStatus='Active'  
		LEFT OUTER JOIN	  dbo.MaintenanceRequestStores mrs ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID
	WHERE     mr.CostZoneID IS NULL AND mr.Banner IS NULL 
			AND mrs.MaintenanceRequestID IS NULL
			AND mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	
	UNION 
		
	select distinct M.MaintenanceRequestID, ST.StoreID, ST.StoreIdentifier  
	from MaintenanceRequests M with (nolock)
		inner join MaintenanceRequestStores S with (nolock) on S.MaintenanceRequestID=M.MaintenanceRequestID
		INNER JOIN stores ST ON ST.StoreId= S.StoreId  and ST.ChainId=M.ChainId
		Inner join Chains C on C.ChainId=M.ChainId
		Left Join DataTrue_CustomResultSets.dbo.tmpMaintenanceRequestStores  T on T.MaintenanceRequestID = M.MaintenanceRequestID and T.StoreId=S.StoreId
	where T.StoreId is null and M.DateTimeCReated>getdate()-120 
	
End
GO
