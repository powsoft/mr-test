USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetMemberships]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetMemberships]
	@ClusterName varchar(20),
	@OwnerEntityID  varchar(30)
AS
--exec usp_GetMemberships '','40393'
BEGIN
 DECLARE @strSQLQuery VARCHAR(4000)
 
 Set @strSQLQuery='Select distinct  
						C.ClusterID
						,C.ClusterName
						,C.ClusterDescription
					FROM Clusters C 
					WHERE   1=1  and C.OwnerEntityID='''+@OwnerEntityID+''''
			if(@ClusterName<>'')
				set @strSQLQuery = @strSQLQuery +  ' and C.ClusterName Like ''%' + @ClusterName +'%'''	
				
			exec(@strSQLQuery)
			
 
END
GO
