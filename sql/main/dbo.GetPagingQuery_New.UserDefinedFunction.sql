USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[GetPagingQuery_New]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec GetPagingQuery_New  'SELECT DISTINCT SL.StoreName  as StoreInfo, P.AbbrvName AS Title,B.WholesalerID, B.Frozen,PP.CostToStore, PP.SuggRetail,B.Mon,B.Tue, B.Wed,B.Thur, B.Fri,B.Sat,B.Sun,P.Bipad,SL.StoreID FROM  [IC-HQSQL2].iControl.dbo.BaseOrder B INNER JOIN  [IC-HQSQL2].iControl.dbo.Products P ON B.Bipad = P.Bipad INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON B.StoreID = SL.StoreID AND B.ChainID = SL.ChainID INNER JOIN  [IC-HQSQL2].iControl.dbo.ProductsPrices  PP ON B.WholesalerID = PP.WholesalerID AND B.ChainID = PP.ChainID AND P.Bipad = PP.Bipad WHERE P.PublisherID=''NYT'' AND B.Stopped=0 AND SL.Active=1 AND P.Active=1 ','StoreName ASC',1,50,1
CREATE FUNCTION [dbo].[GetPagingQuery_New]
(
	-- Add the parameters for the function here
	@SQlQuery varchar(8000),
	@OrderBy varchar(8000),
	@StartIndex int,
	@PageSize int,
	@ViewMode int
)
RETURNS varchar(max)
AS
BEGIN

declare @FromFindIndex int
declare @CountStatement varchar(max)
declare @BeforeFromStatement varchar(max)
declare @OrderByFindIndex int
declare @startRecord int 
set @FromFindIndex =  CHARINDEX(' FROM  ', upper( @sqlQuery),1)
set @startRecord = @StartIndex * @PageSize 
set @countStatement = 'Select count(*) ' + substring(@sqlQuery, @fromFindIndex, (len(@sqlQuery)+1 - @fromfindindex))
set @OrderByFindIndex =  CHARINDEX(' order by ', @countStatement,1)
if @OrderByFindIndex >0
set @CountStatement = substring(@countStatement, 1, @OrderByFindIndex)


if CHARINDEX('DISTINCT', @SQlQuery)  > 0 
begin
	set @sqlQuery  =REPLACE(@sqlQuery,'SELECT DISTINCT', 'SELECT DISTINCT TOP (100) PERCENT ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS num,') 
end
else
begin
	set @sqlQuery  ='SELECT TOP (100) PERCENT ROW_NUMBER() OVER (ORDER BY ' + @OrderBy + ') AS num,' + right(@sqlQuery,len(@sqlQuery) -7) 
end
 set @sqlQuery = 'Select * from (' + @sqlQuery +  ') as a where num  between ' + CAST( (@startRecord-@PageSize) + 1  as varchar(20)) + ' and ' + CAST( (@startRecord-@PageSize ) + @PageSize  as varchar(20))

 if @ViewMode = 1 
 set  @SQlQuery =  @countStatement
 
 return @sqlquery
 

END
GO
