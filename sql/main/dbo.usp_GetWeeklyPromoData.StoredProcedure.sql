USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetWeeklyPromoData]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetWeeklyPromoData]
 @ChainId varchar(20),
 @Banner varchar(50),
 @UPC varchar(20),
 @StartDate varchar(50),
 @EndDate varchar(50),
 @ProductCategoryId varchar(200),
 @PromoWeek varchar(10)
 
as
Begin
--exec [usp_GeneratePromoLiftReport] 40393, 'Albertsons - ACME', '014100070337'
--Drop the temp tables at the begining
begin try
        Drop Table #tmpWeeklyPromoLiftData
end try
begin catch
end catch
  
	Declare @sqlQuery varchar(4000)
	
    set @sqlQuery = 'Select distinct PromoLiftId, Banner, P.ProductCategoryName as [Product Category], UPC, 
						convert(varchar(10), [AdWeekStart], 101) as [Ad Week Begin], 
						convert(varchar(10), [AdWeekEnd], 101) as [Ad Week End],
						W.WeeklyUnitSale as [Weekly Unit Sale], cast(W.AvgUnitCost$ as numeric(10,2)) as [Avg Unit Cost ($)],
						W.WeeklyNonPromoUnitSale as [Weekly NonPromo Unit Sale], 
						W.WeeklyPromoUnitSale as [Weekly Promo Unit Sale], cast(W.AvgUnitCostNet$ as numeric(10,2)) as [Avg Unit Cost Net ($)],
						case when W.PromoFlag=''True'' then ''Yes'' 
							 else ''No'' 
						End as [Promo Week]
										
					from WeeklyPromoLiftData W 
					inner join ProductCategoryAssignments PC on PC.ProductID = W.ProductID and PC.StoreBanner=w.Banner
					inner join ProductCategories P on P.ProductCategoryId=PC.ProductCategoryId
					where 1=1 '

	if(@ProductCategoryId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and P.ProductCategoryName = ''' + @ProductCategoryId + ''''
		
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and W.ChainId = ' + @ChainId
	
	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and W.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and W.Banner=''' + @Banner + ''''
	
	if (@PromoWeek<>'All')
		set @sqlQuery = @sqlQuery + ' and W.PromoFlag=''' + @PromoWeek + ''''
		
	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and W.UPC like ''%' + @UPC + '%'''
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and W.AdWeekStart >= ''' + @StartDate + ''''  ;

	if (convert(date, @EndDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and W.AdWeekStart <= ''' + @EndDate  + '''';
		
	set @sqlQuery = @sqlQuery + '  order by 2, 3, 4, 5 desc'
					
	exec(@sqlQuery)
   
End
GO
