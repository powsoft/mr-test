USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetMaintenanceRequest]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetMaintenanceRequest]
	 @RequestId varchar(8000)
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery= 'SELECT mreq.MaintenanceRequestID, 

				CASE WHEN RequestTypeID = 1     THEN ''New Item''
						WHEN RequestTypeID = 2  THEN ''Cost Change''
												ELSE ''Promo'' 
				END AS RequestType, 
				sup.SupplierName,
				
				CASE WHEN AllStores = 1 THEN ''All'' 
					 ELSE ''Multiple'' 
				END AS AllStores, 
				mreq.Banner AS BannerName, 
			   
				mreq.UPC, mreq.ItemDescription, 
				convert(varchar(10), mreq.SubmitDateTime, 101) as SubmitDateTime, 
				convert(varchar(10), mreq.StartDateTime, 101) as StartDateTime, 
				convert(varchar(10), mreq.EndDateTime, 101) as EndDateTime, 
				mreq.SupplierLoginId, mreq.ChainLoginID, DeleteReason
				                      
				FROM  dbo.MaintenanceRequests AS mreq 
				INNER JOIN dbo.Suppliers AS sup ON mreq.SupplierId = sup.SupplierId 
				INNER JOIN dbo.Chains AS ch ON mreq.ChainId = ch.ChainId 
				where 1=1'

if(@RequestId<>'-1') 
	set @sqlQuery = @sqlQuery + ' and MaintenanceRequestID in (' + @RequestId + ')'

exec (@sqlQuery); 

End
GO
