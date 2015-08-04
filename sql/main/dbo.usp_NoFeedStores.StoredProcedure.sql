USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_NoFeedStores]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[usp_NoFeedStores] 
	@Banner varchar(50),
	@ChainId varchar(50),
	@SupplierId varchar(50),
	@FeedType varchar(20),
	@FromDate varchar(20),
	@ToDate varchar(20)
AS
BEGIN

	Declare @Query varchar(5000)
	
	set @Query = '	Select distinct SP.SupplierName as [Supplier Name], C.ChainName as [Chain Name], t.Banner, s.StoreIdentifier as [Store Number], 
						convert(date, max(t.OnSaleDate), 101)  as [Last Missing Date], convert(date, (t.LastSaleDate), 101)  as [Last Transmission Date], 
						COUNT(distinct t.OnSaleDate) as [Total Days Missing] 
					from DataTrue_CustomResultSets.dbo.tmpNoStoreFeed t 
						inner join Chains C on C.ChainId=t.ChainId
						inner join Suppliers SP on SP.SupplierId=t.SupplierId
						inner join Stores S on S.StoreID=t.StoreId and S.ChainID=t.ChainId and S.Custom1=t.Banner
						inner join SupplierBanners SB on SB.SupplierId = SP.SupplierId and SB.Status=''Active'' and SB.Banner=t.Banner  
						inner join DataTrue_CustomResultSets.dbo.tmpNoStoreFeed t1 on t1.ChainId=t.ChainId and t1.Banner=t.Banner and t1.StoreId=t.StoreId
					where 1=1 
					'

	if(@ChainId<>'-1') 
		set @Query   = @Query  +  ' and C.ChainID=' + @ChainId 

	if(@SupplierId<>'-1') 
		set @Query   = @Query  +  ' and SP.SupplierId=' + @SupplierId 
		
	if(@Banner<>'All') 
		set @Query  = @Query + ' and t.banner = ''' + @Banner + ''''
	
	if(@FeedType<>'') 
		set @Query  = @Query  +  ' and t.TransactionType=''' + @FeedType  + ''''
	
	if (convert(date, @FromDate ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and t.OnSaleDate >= ''' + @FromDate + '''';

	if(convert(date, @ToDate ) > convert(date,'1900-01-01'))
		set @Query = @Query + ' and t.OnSaleDate <= ''' + @ToDate + '''';

	set @Query = @Query + ' group by SP.SupplierName, C.ChainName,  t.Banner, s.StoreIdentifier, t.ChainId, t.Banner, t.StoreId,t.LastSaleDate '
	
	set @Query = @Query + ' order by 1, 2, 3, 4, 5, 6 desc'
	
	exec  (@Query )

	
END


--exec usp_NoFeedStores 'All',40393,'-1','POS', '06/29/2012', '07/03/2012'
GO
