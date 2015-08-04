USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeDetailsRegulated]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_iControlFeeDetailsRegulated]
-- Add the parameters for the stored procedure here
@ChainID varchar(10),
@SupplierID varchar(10),
@FeeID varchar(10)
-- exec usp_iControlFeeDetailsRegulated '-1','-1','4641'	
AS
BEGIN
		SELECT DISTINCT 
			  SF.ServiceFeeID
			, SF.ChainID as RetailerId
			, C.ChainName as RetailerName
			, CASE WHEN SF.SupplierID=0 THEN NULL ELSE SF.SupplierID END as SupplierID
			, CASE WHEN SF.SupplierID=0 THEN NULL ELSE S.SupplierName END as SupplierName
			, SF.ServiceFeeFactorValue
			, convert(varchar(10),SF.ActiveStartDate,101) as ActiveStartDate
			, convert(varchar(10),SF.ActiveLastDate,101) as ActiveLastDate
			, SF.ServiceFeeTypeID
	
			FROM 
				ServiceFees SF
				INNER JOIN Chains C ON SF.ChainID=C.ChainID
				INNER JOIN Suppliers S ON SF.SupplierId=S.SupplierID OR SF.SupplierID=0
			WHERE 
				SF.ServiceFeeTypeID in (2,3) 
				AND SF.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
				AND SF.SupplierId like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID END
				and SF.ServiceFeeID like CASE WHEN @FeeID='0' THEN '%' ELSE @FeeID END
			ORDER BY
				C.ChainName,CASE WHEN SF.SupplierID=0 THEN NULL ELSE S.SupplierName END
END
GO
