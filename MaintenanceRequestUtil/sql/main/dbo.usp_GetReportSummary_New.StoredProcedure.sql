USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetReportSummary_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_GetReportSummary_New] '-1','-1','','','','17'
CREATE procedure [dbo].[usp_GetReportSummary_New]
 @ChainId varchar(10),
 @SupplierId varchar(10),
 @ReportName varchar(20),
 @LoginName varchar(50),
 @Name varchar(50),
 @AccessLevel varchar(50)
 
as

Begin
 Declare @sqlQuery varchar(4000)
 --Organization ID,Person ID,First Name,Last Name,Login,Organization,Banner Access,Access Rights,Report Name,Banner,Time of Day,Subscription Days
		Select S.SupplierId as [Organization ID], 
				P.PersonID AS [Person ID], 
				P.FirstName AS [First Name], 
				P.LastName AS [Last Name],
				L.Login, 
				SupplierName as [Organization],
				(Select top 1  AttributeValue from AttributeValues with(NOLOCK) where OwnerEntityID=P.PersonID and AttributeID=20) as [Banner Access],
				(Select AttributeValue from AttributeValues with(NOLOCK) where OwnerEntityID=P.PersonID and AttributeID=22) as [Access Rights],
				A.ReportName AS [Report Name],  
				R.Banner, 
				case when R.By12pmEST=1 then '12 PM' else '5 PM' end as [Time of Day],
				case when R.Days  like '%2%' then 'Mon,' else '' end +
				case when R.Days  like '%3%' then 'Tue,' else '' end +
				case when R.Days  like '%4%' then 'Wed,' else '' end +
				case when R.Days  like '%5%' then 'Thu,' else '' end +
				case when R.Days  like '%6%' then 'Fri,' else '' end +
				case when R.Days  like '%7%' then 'Sat,' else '' end +
				case when R.Days  like '%1%' then 'Sun,' else '' end as [Subscription Days] 

		into #tmpReportData
		
		from AutomatedReportsRequests R with(NOLOCK)
			inner join  AutomatedReportsList A with(NOLOCK) on A.ReportID=R.ReportID
			inner join Logins L with(NOLOCK) on L.OwnerEntityId=R.PersonID
			inner join Persons P with(NOLOCK) on P.PersonID=L.OwnerEntityId
			inner join AttributeValues AV with(NOLOCK) on AV.OwnerEntityID=R.PersonID
			inner join Suppliers S with(NOLOCK) on S.SupplierID=AV.AttributeValue
		
		where AV.AttributeID=@AccessLevel

		union 

		Select C.ChainId as [Organization ID], 
				P.PersonID AS [Person ID], 
				P.FirstName AS [First Name], 
				P.LastName AS [Last Name],
				L.Login, 
				ChainName as [Organization],
				(Select top 1 AttributeValue from AttributeValues with(NOLOCK) where OwnerEntityID=P.PersonID and AttributeID=20) as [Banner Access],
				(Select AttributeValue from AttributeValues with(NOLOCK) where OwnerEntityID=P.PersonID and AttributeID=22) as [Access Rights],
				A.ReportName AS [Report Name],
				R.Banner, 
				case when R.By12pmEST=1 then '12 PM' else '5 PM' end as [Time of Day],
				case when R.Days  like '%2%' then 'Mon,' else '' end +
				case when R.Days  like '%3%' then 'Tue,' else '' end +
				case when R.Days  like '%4%' then 'Wed,' else '' end +
				case when R.Days  like '%5%' then 'Thu,' else '' end +
				case when R.Days  like '%6%' then 'Fri,' else '' end +
				case when R.Days  like '%7%' then 'Sat,' else '' end +
				case when R.Days  like '%1%' then 'Sun,' else '' end
				as [Subscription Days] 
		
		from AutomatedReportsRequests R with(NOLOCK)
			inner join  AutomatedReportsList A with(NOLOCK) on A.ReportID=R.ReportID
			inner join Logins L with(NOLOCK) on L.OwnerEntityId=R.PersonID
			inner join Persons P with(NOLOCK) on P.PersonID=L.OwnerEntityId
			inner join AttributeValues AV with(NOLOCK) on AV.OwnerEntityID=R.PersonID
			inner join Chains C with(NOLOCK) on C.ChainId=AV.AttributeValue
		
		where AV.AttributeID=@AccessLevel
		order by 1,3

		set @sqlQuery = 'Select * from #tmpReportData t where 1=1'

		if(@ChainId<>'-1') 
			set @sqlQuery = @sqlQuery +  ' and t.[Organization ID]=' + @ChainId

		if(@SupplierId<>'-1') 
			set @sqlQuery = @sqlQuery +  ' and t.[Organization ID]=' + @SupplierId

		if(@ReportName<>'') 
			set @sqlQuery = @sqlQuery +  ' and t.[Report Name] =''' + @ReportName + ''''

		if(@LoginName<>'') 
			set @sqlQuery = @sqlQuery + ' and t.Login like ''%' + @LoginName + '%''';

		if(@Name<>'') 
			set @sqlQuery = @sqlQuery + ' and (t.[First Name] + '' '' + t.[Last Name]) like ''%' + @Name + '%''';
	
		set @sqlQuery = @sqlQuery + '; IF OBJECT_ID(''#tmpReportData'') IS NOT NULL  
									BEGIN
										DROP TABLE #tmpReportData
									END;'
		exec (@sqlQuery); 

End
GO
