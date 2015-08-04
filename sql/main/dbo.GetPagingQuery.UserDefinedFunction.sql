USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[GetPagingQuery]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetPagingQuery]
(
	-- Add the parameters for the function here
	@SQlQuery varchar(max),
	@OrderBy varchar(max),
	@StartIndex int,
	@PageSize int,
	@ViewMode int
)
RETURNS varchar(max)
AS
BEGIN

declare @FromFindIndex int
declare @CountStatement varchar(max)
declare @BeforeFromStatement varchar(500)
declare @OrderByFindIndex int
declare @startRecord int 
set @FromFindIndex =  CHARINDEX(' From ', @sqlQuery,1)

set @startRecord = @StartIndex * @PageSize 

set @countStatement = 'Select count(*) ' +   substring(@sqlQuery, @fromFindIndex, (len(@sqlQuery)+1 - @fromfindindex) )
set @OrderByFindIndex =  CHARINDEX(' order by ', @countStatement,1)

set @CountStatement = substring(@countStatement, 1, @OrderByFindIndex) 
if CHARINDEX('DISTINCT', @SQlQuery)  > 0 
begin
set @sqlQuery  =REPLACE(@sqlQuery,'SELECT DISTINCT', 'SELECT DISTINCT TOP (100) PERCENT ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS num,') 
end
else
begin
set @sqlQuery  =REPLACE(@sqlQuery,'SELECT ', 'SELECT TOP (100) PERCENT ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS num,') 
end
 set @sqlQuery = 'Select * from (' + @sqlQuery +  ') as a where num  between ' + CAST( (@startRecord-@PageSize) + 1  as varchar) + ' and ' + CAST( (@startRecord-@PageSize ) + @PageSize  as varchar)
 
 --print(cast( @OrderByFindIndex as varchar))
 --set @BeforeFromStatement = SUBSTRING(@sqlQuery, 1 , @fromFindIndex)
 
 --print @FromFindIndex
 if @ViewMode = 1 
 set  @SQlQuery =  @countStatement
 
 return @sqlquery
 

END
GO
