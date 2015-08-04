USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GeneratePromoLiftReport]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GeneratePromoLiftReport]
 @ChainId varchar(20),
 @Banner varchar(50),
 @UPC varchar(20),
 @StartDate varchar(50),
 @EndDate varchar(50),
 @ProductCategoryId varchar(200)
 
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

	Select W.ChainId, W.Banner, W.ProductID, W.UPC, W.AdWeekEnd as [AdWeek], W.WeeklyPromoUnitSale,
						case when isnull(sum(W.WeeklyPromoUnitSale),0)> 0 then
								sum(W.WeeklyPromoUnitSale*W.AvgUnitCostNet$)/sum(W.WeeklyPromoUnitSale)
							else
								0
						end as AvgUnitCostNet$ ,
						case when isnull(COUNT(W1.AdWeekEnd),0)> 0 then
								sum(W1.WeeklyNonPromoUnitSale)/COUNT(W1.AdWeekEnd)
							else   
								0
						end as [Base (Non Promo Weeks) Weekly Unit Sold],
						case when isnull(sum(W1.WeeklyNonPromoUnitSale),0)> 0 then
								sum(W1.WeeklyNonPromoUnitSale*W1.AvgUnitCost$)/sum(W1.WeeklyNonPromoUnitSale)
							else
								0
						end as [Avg Unit Cost (Base)]
					into #tmpWeeklyPromoLiftData
					from WeeklyPromoLiftData W
					inner join ChainAdWeek C on C.ChainId=W.ChainId and C.Banner=W.Banner
					left join WeeklyPromoLiftData W1 on W.ChainId = W.ChainId and W1.Banner=W.Banner and W1.ProductID=W.ProductID
							and W1.AdWeekEnd<W.AdWeekEnd and W1.PromoFlag='False' and W1.AdWeekEnd> dateadd(WK,-C.NoOfWeekstoCalculateBase, W.AdWeekEnd)
					where W.PromoFlag='True' and W.WeeklyPromoUnitSale>0 
	group by W.ChainId, W.Banner, W.ProductID, W.UPC,  W.AdWeekEnd, W.WeeklyPromoUnitSale, W.AvgUnitCostNet$
	
    set @sqlQuery = 'select Banner, P.ProductCategoryName as [Product Category], UPC, convert(varchar(10), [AdWeek], 101) as [Ad Week], 
						WeeklyPromoUnitSale as [Weekly Promo Unit Sale], 
						cast(AvgUnitCostNet$ as numeric(10,2)) as [Avg Unit Cost Net ($)],
						[Base (Non Promo Weeks) Weekly Unit Sold], 
						cast([Avg Unit Cost (Base)] as numeric(10,2)) as [Avg Unit Cost Base ($)],
						cast(
						case when isnull([Avg Unit Cost (Base)],0)>0 then
								(([Avg Unit Cost (Base)]-AvgUnitCostNet$)/[Avg Unit Cost (Base)]*100)
							else
								0
						end as numeric(10,2)) as [% Reduction In Price],
						Case when [Base (Non Promo Weeks) Weekly Unit Sold]>0 then
								cast((WeeklyPromoUnitSale- [Base (Non Promo Weeks) Weekly Unit Sold]) AS varchar)
							else
								''NA''
						end as [Lift (Units)],
						Case when [Base (Non Promo Weeks) Weekly Unit Sold]>0 then
								cast(((WeeklyPromoUnitSale- [Base (Non Promo Weeks) Weekly Unit Sold])*100/[Base (Non Promo Weeks) Weekly Unit Sold]) AS varchar)
							else
								''NA''
						end as [Lift% (Units)]
					from #tmpWeeklyPromoLiftData T  
					inner join ProductCategoryAssignments PC on PC.ProductID = T.ProductID and PC.StoreBanner=T.Banner
					inner join ProductCategories P on P.ProductCategoryId=PC.ProductCategoryId
					where 1=1 '

	if(@ProductCategoryId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and P.ProductCategoryName = ''' + @ProductCategoryId + ''''
							
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery +  ' and T.ChainId = ' + @ChainId
	
	if(@Banner='') 
		set @sqlQuery = @sqlQuery + ' and T.Banner is Null'

	else if(@Banner<>'-1') 
		set @sqlQuery = @sqlQuery + ' and T.Banner=''' + @Banner + ''''
	
	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and T.UPC like ''%' + @UPC + '%'''
	
	if (convert(date, @StartDate  ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and T.AdWeek >= ''' + @StartDate + ''''  ;

	if (convert(date, @EndDate  ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and T.AdWeek <= ''' + @EndDate  + '''';
						
	set @sqlQuery = @sqlQuery + '  order by 1, 2, 3, 4 desc'
					
	exec(@sqlQuery)
   
End
GO
