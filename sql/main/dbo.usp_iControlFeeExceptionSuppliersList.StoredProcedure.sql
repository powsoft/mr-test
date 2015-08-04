USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeExceptionSuppliersList]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- DeFCriptiON:	<DeFCriptiON,,>
-- =============================================

-- exec [usp_iControlFeeExceptionSuppliersList] '40393'
CREATE PROCEDURE [dbo].[usp_iControlFeeExceptionSuppliersList]	
@ChainId varchar(20)
AS
BEGIN

	Select distinct ChainId, SupplierID into #tmpNonNewsPaper from StoreTransactions ST where isnull(ST.RecordType,0)<>2
	
	SELECT DISTINCT SB.SupplierId,S.SupplierName 
	FROM 
		SupplierBanners SB 
		INNER JOIN Suppliers S ON SB.SupplierId=S.SupplierID 
		INNER JOIN #tmpNonNewsPaper ST ON ST.SupplierId=SB.SupplierId and ST.ChainId=SB.ChainId
	Where 
		1=1 
		AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
	ORDER BY S.SupplierName
	
END
GO
