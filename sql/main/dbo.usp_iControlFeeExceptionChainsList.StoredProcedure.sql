USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeExceptionChainsList]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- DeFCriptiON:	<DeFCriptiON,,>
-- =============================================

-- exec [usp_iControlFeeExceptionChainsList]
CREATE PROCEDURE [dbo].[usp_iControlFeeExceptionChainsList]	
AS
BEGIN

	Select distinct ChainId, SupplierID into #tmpNonNewsPaper from StoreTransactions ST where isnull(ST.RecordType,0)<>2
	
	SELECT DISTINCT SB.ChainID,C.ChainName 
	FROM 
		SupplierBanners SB 
		INNER JOIN Chains C ON SB.ChainID=C.ChainID 
		INNER JOIN #tmpNonNewsPaper ST ON ST.SupplierId=SB.SupplierId and ST.ChainId=SB.ChainId
	ORDER BY C.ChainName
	
END
GO
