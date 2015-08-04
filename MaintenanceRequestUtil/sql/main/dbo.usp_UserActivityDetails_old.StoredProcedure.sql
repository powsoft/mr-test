USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UserActivityDetails_old]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UserActivityDetails_old]
	@UserID varchar(10),
	@ReportType varchar(10),
	@PageID varchar(10),
	@OrgID varchar(10),
	@FromDate varchar(10),
	@ToDate varchar(10)
as
-- exec [usp_UserActivityDetails_new] '-1','2','-1', '-1','12/16/2014','01/09/2015'
Begin

Declare @sqlQuery varchar(4000)
 
	if(@ReportType = '1')                   
		 begin
			 set @sqlQuery = 'SELECT U.LogID, U.UserID,(P.FirstName + '' '' + P.LastName) as UserName, 
							  S.OrgName as [Organization Name],
							  CONVERT(varchar(10), TimeStamp,101) as Date,
							  CONVERT(VARCHAR(8),U.TimeStamp, 108) as [Login Time],
							  (SELECT top 1 CONVERT(VARCHAR(8),TimeStamp, 108) from UserLog where LogID> U.LogID AND UserId=U.UserID  and (PageName=''Logout'' OR PageName=''Sessionout'') ORDER by U.LogID DESC) as [Logout Time],
							  CONVERT(VARCHAR(8),((SELECT top 1 TimeStamp from UserLog where LogID> U.LogID AND UserId=U.UserID ORDER by U.LogID Desc)-U.TimeStamp), 108) as [Total Time]
							  FROM UserLog U
							  inner JOIN Persons P ON P.PersonID=U.UserID
							  inner join AttributeValues A on A.OwnerEntityId = U.UserId
							  inner Join (Select distinct SupplierID as OrgID, SupplierName as OrgName from Suppliers 
												Union 
												Select distinct ChainID as OrgID, ChainName from Chains
												Union 
												Select distinct ManufacturerId, ManufacturerName from Manufacturers
										  ) S on cast(S.OrgID as varchar) =  A.AttributeValue
							  WHERE 1=1 and U.PageName like ''Login%'' '
			if(@UserID<>'-1')
				set @sqlQuery = @sqlQuery + ' and U.UserID = ' + @UserID
			
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND S.OrgID = ' + @OrgID
			
			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(TimeStamp AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(TimeStamp AS DATE) <= ''' + @ToDate  + ''''
					
			set @sqlQuery = @sqlQuery + ' order BY U.LogID'
					
		end
	else
		begin
			set @sqlQuery = 'SELECT U.LogID,U.UserID,(P.FirstName + '' '' + P.LastName) as UserName,
								S.OrgName as [Organization Name],
								isnull(W.MenuName, U.PageName) as PageName,convert(varchar(10),TimeStamp,101) as Date,
								CONVERT(VARCHAR(8),U.TimeStamp, 108) as [Start Time],
								(SELECT top 1 CONVERT(VARCHAR(8),TimeStamp, 108) from UserLog where LogID> U.LogID AND UserId=U.UserID ORDER by U.LogID Desc) as [End Time],
								CONVERT(VARCHAR(8),((SELECT top 1 TimeStamp from UserLog where LogID> U.LogID AND UserId=U.UserID ORDER by U.LogID Desc)-U.TimeStamp), 108) as [Total Time]
								FROM UserLog U
								inner JOIN Persons P ON P.PersonID=U.UserID
								inner join AttributeValues A on A.OwnerEntityId = U.UserId
								inner Join (Select distinct SupplierID as OrgID, SupplierName as OrgName from Suppliers 
												Union 
												Select distinct ChainID as OrgID, ChainName from Chains
												Union 
												Select distinct ManufacturerId, ManufacturerName from Manufacturers
										  ) S on cast(S.OrgID as varchar) =  A.AttributeValue
								left JOIN webmenus_new W ON W.MenuId=U.PageID 
								WHERE 1=1 '
								
			if(@UserID<>'-1')
				set @sqlQuery = @sqlQuery + ' and U.UserID = ' + @UserID

			if(@PageID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND U.PageID = ' + @PageID
			
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND S.OrgID = ' + @OrgID
			
			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(TimeStamp AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(TimeStamp AS DATE) <= ''' + @ToDate  + ''''
														
			set @sqlQuery = @sqlQuery + ' order BY U.LogID '
			
		end 
print(@sqlQuery);
exec(@sqlQuery);

End
GO
