USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeDetailsSBT]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_iControlFeeDetailsSBT]
-- Add the parameters for the stored procedure here
@ChainID varchar(10),
@SupplierID varchar(10)	
AS
-- exec usp_iControlFeeDetailsSBT '-1','-1'
BEGIN
		SELECT DISTINCT 
					 SF.ChainID as RetailerId
					,C.ChainName as RetailerName
					,SF.SupplierId
					,CASE WHEN SF.SupplierID IS NULL THEN NULL ELSE S.SupplierName END as SupplierName
					,SF.Fees
					,SF.FeeMode
					,SF.CalculateOn
					,convert(varchar(10),SF.ActiveStartDate,101) as ActiveStartDate
					,convert(varchar(10),SF.ActiveEndDate,101) as ActiveEndDate
					,SF.IsNewspaper
					FROM 
						SBTServiceFees SF
						INNER JOIN Chains C ON SF.ChainID=C.ChainID
						INNER JOIN Suppliers S ON SF.SupplierId=S.SupplierID OR SF.SupplierID IS NULL
					WHERE 
						SF.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
						AND Isnull(SF.SupplierId,0) like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID END
					ORDER BY
						C.ChainName,CASE WHEN SF.SupplierID IS NULL THEN NULL ELSE S.SupplierName END
END
GO
