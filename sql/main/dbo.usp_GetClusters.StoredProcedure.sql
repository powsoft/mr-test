USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetClusters]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetClusters]
	
	@ClusterName varchar(20),
	@ClusterDescription varchar(20),	
	@OwnerEntityID  varchar(30)
	

	
AS
--exec usp_GetClusters '','','40393'
BEGIN
 DECLARE @strSQLQuery VARCHAR(4000)
 
		Set @strSQLQuery='Select C.ClusterID,C.ClusterName,C.ClusterDescription,Comments FROM Clusters C
											inner JOIN SystemEntities E ON E.EntityId=C.ClusterID
											WHERE E.EntityTypeID=6 and C.ChainID='''+@OwnerEntityID+''''
			


				if(@ClusterName<>'')
				set @strSQLQuery = @strSQLQuery +  ' and C.ClusterName Like ''%' + @ClusterName +'%'''	
				
				if(@ClusterDescription<>'')
				set @strSQLQuery = @strSQLQuery +  ' and C.ClusterDescription Like ''%' + @ClusterDescription +'%'''			
									
				

				




			exec(@strSQLQuery)
			print @strSQLQuery
 
END
GO
