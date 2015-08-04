USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeExceptionSuppliersList_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_iControlFeeExceptionSuppliersList] '40393'
CREATE PROCEDURE [dbo].[usp_iControlFeeExceptionSuppliersList_PRESYNC_20150524]	
@ChainId varchar(20)
AS
BEGIN

	--Select distinct ChainId, SupplierID into #tmpNonNewsPaper from StoreTransactions ST With(NOLOCK) where isnull(ST.RecordType,0)<>2
	
	SELECT DISTINCT SB.SupplierId,S.SupplierName 
	FROM 
		SupplierBanners SB  With(NOLOCK)
		INNER JOIN Suppliers S With(NOLOCK) ON SB.SupplierId=S.SupplierID 
		--INNER JOIN #tmpNonNewsPaper ST ON ST.SupplierId=SB.SupplierId and ST.ChainId=SB.ChainId
	Where 
		1=1 
		AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
	ORDER BY S.SupplierName
	
END
GO
