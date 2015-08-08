USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeExceptionChainsList_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_iControlFeeExceptionChainsList]
CREATE PROCEDURE [dbo].[usp_iControlFeeExceptionChainsList_PRESYNC_20150524]	
AS
BEGIN

	--Select distinct ChainId, SupplierID into #tmpNonNewsPaper from StoreTransactions ST With(NOLOCK) where isnull(ST.RecordType,0)<>2
	
	SELECT DISTINCT SB.ChainID,C.ChainName 
	FROM 
		SupplierBanners SB With(NOLOCK)
		INNER JOIN Chains C With(NOLOCK) ON SB.ChainID=C.ChainID 
		--INNER JOIN #tmpNonNewsPaper ST ON ST.SupplierId=SB.SupplierId and ST.ChainId=SB.ChainId
	ORDER BY C.ChainName
	
END
GO
