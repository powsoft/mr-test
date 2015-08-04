USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeExceptionReport_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_iControlFeeExceptionReport] '2','40393','-1'
 CREATE PROCEDURE [dbo].[usp_iControlFeeExceptionReport_PRESYNC_20150524]
	-- Add the parameters for the stored procedure here
	@ReportName varchar(5),
	@ChainID varchar(10),
	@SupplierID varchar(10)
	
AS
BEGIN

	--Select distinct ChainId, SupplierID into #tmpNonNewsPaper from StoreTransactions ST where isnull(ST.RecordType,0)<>2
	IF(@ReportName='1')	--Regulated Fees not Defined
			BEGIN
				SELECT DISTINCT 
					 1 as ReportName
					,SB.ChainID as RetailerId
					,C.ChainName as RetailerName
					,SB.SupplierID
					,S.SupplierName
					--,SF.ChainId
					--,SF.SupplierId
					FROM 
						SupplierBanners SB WITH(NOLOCK) 
						INNER JOIN Chains C WITH(NOLOCK)  ON SB.ChainID=C.ChainID
						INNER JOIN Suppliers S WITH(NOLOCK) ON SB.SupplierId=S.SupplierID
						LEFT JOIN ServiceFees SF ON SB.ChainID=SF.ChainId AND SB.SupplierId=SF.SupplierId
						
					WHERE 
						ServiceFeeTypeID in (2,3) 
						AND S.IsRegulated=1
						AND SF.ChainId IS NULL And SF.SupplierId IS null 
						AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
						AND SB.SupplierId like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID END
						
					
				UNION ALL	

				SELECT DISTINCT 
					1 as ReportName	
					,SB.ChainID as RetailerId
					,C.ChainName as RetailerName
					,NULL as SupplierID
					,NULL as SupplierName
					--,SF.ChainId
					--,SF.SupplierId
					FROM 
						SupplierBanners SB WITH(NOLOCK) 
						INNER JOIN Chains C WITH(NOLOCK) ON SB.ChainID=C.ChainID
						LEFT JOIN ServiceFees SF ON SB.ChainID=SF.ChainId AND SF.SupplierId=0
					WHERE 
						ServiceFeeTypeID in (2,3) 
						AND SF.ChainId IS NULL AND SF.SupplierId IS null
						AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
						AND SB.SupplierId like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID END
						
			END
			
	ELSE IF (@ReportName='2') --SBT Fees not Defined
			BEGIN
				SELECT DISTINCT 
					2 as ReportName
					,SB.ChainID as RetailerId
					,C.ChainName as RetailerName
					,SB.SupplierID
					,S.SupplierName
					--,SF.ChainId
					--,SF.SupplierId
					FROM 
						SupplierBanners SB WITH(NOLOCK) 
						INNER JOIN Chains C WITH(NOLOCK) ON SB.ChainID=C.ChainID
						INNER JOIN Suppliers S WITH(NOLOCK) ON SB.SupplierId=S.SupplierID
						--INNER JOIN #tmpNonNewsPaper ST ON ST.ChainID=SB.ChainID AND ST.SupplierID=SB.SupplierId
						LEFT JOIN SBTServiceFees SF WITH(NOLOCK) ON SB.ChainID=SF.ChainId AND SB.SupplierId=SF.SupplierId
					WHERE 
						SF.ChainId IS NULL And SF.SupplierId IS null 
						AND SB.SupplierId<>0 AND S.IsRegulated=0
						AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
						AND SB.SupplierId like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID END
					
				UNION ALL	

				SELECT DISTINCT 
					2 as ReportName
					,SB.ChainID as RetailerId
					,C.ChainName as RetailerName
					,NULL as SupplierID
					,NULL as SupplierName
					--,SF.ChainId
					--,SF.SupplierId
					FROM 
						SupplierBanners SB WITH(NOLOCK)
						INNER JOIN Chains C WITH(NOLOCK) ON SB.ChainID=C.ChainID
						--INNER JOIN #tmpNonNewsPaper ST ON ST.ChainID=SB.ChainID AND ST.SupplierID=SB.SupplierId
						LEFT JOIN SBTServiceFees SF WITH(NOLOCK) ON SB.ChainID=SF.ChainId AND SF.SupplierId Is null
					WHERE 
						SF.ChainId IS NULL AND SF.SupplierId IS null	
						AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
						AND SB.SupplierId like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID END 
					ORDER BY
						3,5
							
			END
		
	
END
GO
