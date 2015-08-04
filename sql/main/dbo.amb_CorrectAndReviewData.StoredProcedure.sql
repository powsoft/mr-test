USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_CorrectAndReviewData]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[amb_CorrectAndReviewData]
	@uname varchar(10),
	@WholesalerID varchar(10),
	@ChainID varchar(10),
	@StoreID varchar(50),
	@Bipad varchar(20)
	
AS 
--exec  amb_CorrectAndReviewData 'DQ','WR6491','-1','','-2'
BEGIN
	Declare @sqlQuery varchar(4000)

	set @sqlQuery=' SELECT distinct ss.storesetupid,ss.SupplierID as wholesalerid, ss.StoreID,
					ss.ChainID,ss.ProductID, pi.Bipad ,pi.identifiervalue as UPC,p.ProductName AS Title,
					p.Comments, ss.MonLimitQty, ss.TueLimitQty, ss.WedLimitQty, ss.ThuLimitQty, 
					ss.FriLimitQty, ss.SatLimitQty, ss.SunLimitQty ,pp.UnitPrice, pp.UnitRetail ,
					a.address1,a.city,a.state,convert(varchar(10),pp.activestartdate, 101) as activestartdate ,
					convert(varchar(10),pp.activelastdate, 101) as activelastdate,s.StoreIdentifier,
					c.ChainIdentifier,sup.SupplierIdentifier
					
					from  dbo.storesetup ss
					INNER JOIN dbo.Products p ON ss.ProductID = p.ProductID 
					inner join dbo.ProductIdentifiers pi on p.ProductID=pi.ProductID 
						and pi.productidentifiertypeid=8
					inner join dbo.productprices pp on pp.productid=p.ProductID 
						and pp.SupplierId=ss.SupplierID 
						and pp.ChainId=ss.ChainId 
						and pp.StoreId=ss.StoreId
					inner join dbo.Addresses a on a.ownerentityid=ss.storeid 
					inner join dbo.Suppliers sup on ss.SupplierID =sup.SupplierID
					inner join dbo.Chains c on c.ChainID=ss.ChainID
					inner join dbo.stores s on s.StoreID=ss.StoreID
					
					where 1=1 and pp.productpricetypeid=3 '
	
	if(@WholesalerID<>'-1')
		set @sqlQuery=@sqlQuery+ ' And sup.SupplierIdentifier= ''' + @WholesalerID + ''''
	if(@ChainID<>'-1')
		set @sqlQuery= @sqlQuery+ ' AND C.ChainIdentifier = '''+@ChainID+''''
	if(@StoreID<>'')
		set @sqlQuery= @sqlQuery+ ' AND s.LegacySystemStoreIdentifier Like ''%' + @StoreID+'%'' '
	if(@Bipad<>'-1' and @Bipad<>'-2')
		set @sqlQuery= @sqlQuery+ ' AND pi.productid = ''' + @Bipad+''' '

	set @sqlQuery=@sqlQuery+'  order by ss.storesetupid'
	
	exec(@sqlQuery);
	
END
GO
