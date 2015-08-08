USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateMaintenanceRequestStores_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UpdateMaintenanceRequestStores_PRESYNC_20150415]
as
Begin
	
	--Delete MS 
	--from MaintenanceRequestStores MS
	--inner join (
	--Select M.MaintenanceRequestID, M.SupplierID, M.CostZoneID , MS.StoreID
	--from MaintenanceRequests M
	--inner join MaintenanceRequestStores MS on MS.MaintenanceRequestID=M.MaintenanceRequestID 
	--where M.FromWebInterface=1 and M.CostZoneID<>'-1' and MS.StoreID not in (Select StoreID from CostZoneRelations C where C.CostZoneID=M.CostZoneID and C.SupplierID=M.SupplierID )
	--) M1 on M1.MaintenanceRequestID=MS.MaintenanceRequestID and MS.StoreID=M1.StoreID 

	Delete from tmpMaintenanceRequestStores 
	where MaintenanceRequestID in (Select distinct MaintenanceRequestID from MaintenanceRequests 
	where datetimecreated>=convert(varchar(10),GETDATE(),101))

	Insert into tmpMaintenanceRequestStores

	SELECT  distinct   mr.MaintenanceRequestID, mrs.StoreId , s.StoreIdentifier  
	FROM       MaintenanceRequests mr with (nolock)
	INNER JOIN  dbo.MaintenanceRequestStores mrs with (nolock) ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID 
	INNER JOIN stores s with (nolock) ON s.StoreID = mrs.StoreID and s.ActiveStatus='Active'
    where mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	
	UNION 
	
	SELECT     mr.MaintenanceRequestID, s.StoreID, s.StoreIdentifier 
	FROM         MaintenanceRequests mr  with (nolock) 
		INNER JOIN CostZoneRelations cz  with (nolock) ON cz.CostZoneID = mr.CostZoneID AND mr.CostZoneID IS NOT NULL 
		INNER JOIN stores s  with (nolock) ON s.StoreID = cz.StoreID and s.ActiveStatus='Active' 
		LEFT OUTER JOIN  dbo.MaintenanceRequestStores mrs  with (nolock) ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID
	WHERE     mrs.MaintenanceRequestID IS NULL
				AND mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	UNION 
	
	SELECT     mr.MaintenanceRequestID, s.StoreID, s.StoreIdentifier 
	FROM         MaintenanceRequests mr  with (nolock) 
		INNER JOIN stores s  with (nolock) ON s.Custom1 = mr.Banner and s.ActiveStatus='Active' 
		Inner join SupplierBanners SB  with(NOLOCK) on  SB.Status='Active' and SB.Banner=s.Custom1 and SB.ChainId=s.ChainId and SB.SupplierId = mr.SupplierID
		Inner Join StoreSetup SS  WITH (NOLOCK)   on SS.StoreId=S.StoreId and SS.SupplierId=SB.SupplierId and SS.ChainId=SB.ChainId
		LEFT OUTER JOIN  dbo.MaintenanceRequestStores mrs  with (nolock) ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID
	WHERE     mr.CostZoneID IS NULL AND mr.Banner IS NOT NULL 
			AND mrs.MaintenanceRequestID IS NULL
			AND mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	UNION 
	
	SELECT     mr.MaintenanceRequestID, s.StoreID, s.StoreIdentifier 
	FROM         MaintenanceRequests mr  with (nolock) 
		INNER JOIN  stores s  with (nolock) ON s.ChainID = mr.ChainID and s.ActiveStatus='Active'  
		LEFT OUTER JOIN	  dbo.MaintenanceRequestStores mrs  with (nolock) ON mrs.MaintenanceRequestID = mr.MaintenanceRequestID
	WHERE     mr.CostZoneID IS NULL AND mr.Banner IS NULL 
			AND mrs.MaintenanceRequestID IS NULL
			AND mr.datetimecreated>=convert(varchar(10),GETDATE(),101)
	
End
GO
