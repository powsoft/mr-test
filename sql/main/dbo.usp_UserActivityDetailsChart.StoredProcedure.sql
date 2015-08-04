USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UserActivityDetailsChart]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_UserActivityDetailsChart]
	@UserID varchar(10),
	@ReportType varchar(10),
	@PageID varchar(10),
	@OrgID varchar(10),
	@TimeRange varchar(20),
	@FromDate varchar(10),
	@ToDate varchar(10)
as
-- exec [usp_UserActivityDetailsChart] '-1','1','-1','40393','44','11/08/2014','01/15/2015'
Begin

Declare @sqlQuery varchar(4000)
IF OBJECT_ID('#tmpLogData') IS NOT NULL 
   begin 
	  Drop Table #tmpLogData
   end
   
		set @sqlQuery = 'SELECT convert(VARCHAR(10),U.TimeStamp,101) as LogDate, DATENAME(dw,U.TimeStamp) as DayName,OrgID, U.UserID, U.PageID, U.PageName
							into #tmpLogData
							from UserLog U
							inner JOIN Persons P ON P.PersonID=U.UserID
							inner join AttributeValues A on A.OwnerEntityId = U.UserId
							inner Join (Select distinct SupplierID as OrgID, SupplierName as OrgName from Suppliers 
											Union 
											Select distinct ChainID as OrgID, ChainName from Chains
											Union 
											Select distinct ManufacturerId, ManufacturerName from Manufacturers
										) S on cast(S.OrgID as varchar) =  A.AttributeValue
						    Where 1=1 order BY LogDate '
						    
 --ReportType = 1 for Login basis search 
 -- 11 = daily , 22 = Weekly , 33 = monthly , 44 = yearly
 
if(@ReportType = '1')                   
  begin					
	if(@TimeRange='11')
		BEGIN
			set @sqlQuery = @sqlQuery + ' Select LogDate as TimeValue, DayName, count(distinct UserId) as UserCount from #tmpLogData where 1=1 '		
				
			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''
					   		   
			if(@UserID<>'-1')
				set @sqlQuery = @sqlQuery + ' and UserID = ' + @UserID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by LogDate, dayname order by 1'	
		END	
	
    else if(@TimeRange='22')
		BEGIN
			set @sqlQuery = @sqlQuery + ' Select datepart(week,LogDate),convert(varchar(20),DATEADD(dd, 7-(DATEPART(dw, LogDate)), LogDate),101) as TimeValue, 
												 count(distinct UserId) as UserCount from #tmpLogData where 1=1 '		

			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''

			if(@UserID<>'-1')
				set @sqlQuery = @sqlQuery + ' and UserID = ' + @UserID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by datepart(week,LogDate),DATEADD(dd, 7-(DATEPART(dw, LogDate)), LogDate) order by 1'
		END	
	
	else if(@TimeRange='33')
		BEGIN
			set @sqlQuery = @sqlQuery + ' SELECT datepart(month,LogDate) as MonthID,DateName(month,DateAdd(month,datepart(month,LogDate),0) - 1) as TimeValue,
												 count(distinct UserId) as UserCount 
												 from #tmpLogData where 1=1 '		

			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''

			if(@UserID<>'-1')
				set @sqlQuery = @sqlQuery + ' and UserID = ' + @UserID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by datepart(month,LogDate) order by 1'
		END
	
	else if(@TimeRange='44')
		BEGIN
			set @sqlQuery = @sqlQuery + ' SELECT datepart(year,LogDate) as TimeValue,count(distinct UserId) as UserCount from #tmpLogData where 1=1 '		

			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''

			if(@UserID<>'-1')
				set @sqlQuery = @sqlQuery + ' and UserID = ' + @UserID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by datepart(year,LogDate) order by 1'
		END				
end
 --Reporttype = 2 for Page Level search
 -- 11 = daily , 22 = Weekly , 33 = monthly , 44 = yearly
else
	begin
	  if(@TimeRange='11')
		BEGIN
			set @sqlQuery = @sqlQuery + ' Select LogDate as TimeValue, DayName, count(distinct UserId) as UserCount,PageName from #tmpLogData where 1=1 '		
				
			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''
					   		   
			if(@PageID<>'-1')
				set @sqlQuery = @sqlQuery + ' and PageID = ' + @PageID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by LogDate,dayname,PageName order by 1'	
		END	
	 else if(@TimeRange='22')
		BEGIN
			set @sqlQuery = @sqlQuery + ' Select datepart(week,LogDate),convert(varchar(20),DATEADD(dd, 7-(DATEPART(dw, LogDate)), LogDate),101) as TimeValue,PageName, 
												 count(distinct UserId) as UserCount from #tmpLogData where 1=1 '		

			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''

			if(@PageID<>'-1')
				set @sqlQuery = @sqlQuery + ' and PageID = ' + @PageID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by datepart(week,LogDate),DATEADD(dd, 7-(DATEPART(dw, LogDate)), LogDate),PageName order by 1'
		END	
	 else if(@TimeRange='33')
		BEGIN
			set @sqlQuery = @sqlQuery + ' SELECT datepart(month,LogDate) as MonthID,DateName(month,DateAdd(month,datepart(month,LogDate),0) - 1) as TimeValue,PageName,
												 count(distinct UserId) as UserCount 
												 from #tmpLogData where 1=1 '		

			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''

			if(@PageID<>'-1')
				set @sqlQuery = @sqlQuery + ' and PageID = ' + @PageID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by datepart(month,LogDate),PageName order by 1'
		END	
	 else if(@TimeRange='44')
		BEGIN
			set @sqlQuery = @sqlQuery + ' SELECT datepart(year,LogDate) as TimeValue,PageName,count(distinct UserId) as UserCount from #tmpLogData where 1=1 '		

			if (convert(date, @FromDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) >= ''' + @FromDate  + ''''
					   
			if (convert(date, @ToDate) > convert(date,'1900-01-01'))    
				set @sqlQuery = @sqlQuery + ' and cast(LogDate AS DATE) <= ''' + @ToDate  + ''''

			if(@PageID<>'-1')
				set @sqlQuery = @sqlQuery + ' and PageID = ' + @PageID
						
			if(@OrgID<>'-1')
				set @sqlQuery = @sqlQuery + ' AND OrgID = ' + @OrgID
							
			set @sqlQuery = @sqlQuery +	' group by datepart(year,LogDate),PageName order by 1'
		END						
	end 

 exec(@sqlQuery)	
 print(@sqlQuery)
END
GO
