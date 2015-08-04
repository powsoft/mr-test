USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUpdateSupplierBanners_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prUpdateSupplierBanners_PRESYNC_20150415]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	Insert into SupplierBanners
	select distinct c.ChainID, 0 AS SupplierID, c.ChainName AS Banner, 'Active' AS Status
	from Chains c
	left outer join SupplierBanners s
	on c.ChainID = s.ChainID
	and 0 = s.SupplierId
	where s.ChainID is null 
	and ISNULL(c.DefaultBanner, '') = ''
	

    -- Insert statements for procedure here
	Insert into SupplierBanners
	select distinct SS.ChainID, SS.SupplierID, S.Custom1 as Banner, 'Active' as Status 
	from Stores S 
	inner join StoreSetup SS on SS.StoreID=S.StoreID and SS.ChainID=S.ChainID
	left join SupplierBanners SB on SB.SupplierId=SS.SupplierID and SS.ChainID=SB.ChainID and S.Custom1=SB.Banner
	where isnull(S.Custom1,'')<>'' and SB.Banner is null
	
	Insert into SupplierBanners
	select distinct S.ChainId, 0, Custom1, 'Active'
	from Stores S
	inner join chains c
	on s.ChainID = c.ChainID
	left join SupplierBanners SB on SB.SupplierId=0 and S.ChainID=SB.ChainID and S.Custom1=SB.Banner
	where isnull(S.Custom1,'') <>'' and SB.Banner is null and isnull(S.Custom1,'') <> c.ChainName
	--and s.Custom1 <> c.ChainName
	--and S.ChainID=74628

	-- Remove SupplierId=0 records for non newspaper chains
	Delete from SupplierBanners  
	where ChainId not in (select distinct ChainId from StoreTransactions with (nolock) where RecordType=2 and SupplierId=0)
	and SupplierID=0
	
	--Remove from SupplierBanners BannerNames that are missing in Stores Table
	Delete SB from SupplierBanners SB
	where SB.Banner not in (Select distinct Custom1 from Stores S with (nolock) where S.ChainID=SB.ChainID)

END
GO
