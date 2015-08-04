USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_iControlFeeDetails]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- DeFCriptiON:	<DeFCriptiON,,>
-- =============================================

-- exec [usp_iControlFeeDetails] '2','-1','-1'
CREATE PROCEDURE [dbo].[usp_iControlFeeDetails]
	-- Add the parameters for the stored procedure here
	@FeesType varchar(5),
	@ChainID varchar(10),
	@SupplierID varchar(10)
	
AS
BEGIN
	IF(@FeesType='1')	--Regulated Fees Details
			BEGIN
				SELECT DISTINCT 
						SF.ServiceFeeID
					, SF.ChainID as RetailerId
					,C.ChainName as RetailerName
					,CASE WHEN SF.SupplierID=0 THEN NULL ELSE SF.SupplierID END as SupplierID
					,CASE WHEN SF.SupplierID=0 THEN NULL ELSE S.SupplierName END as SupplierName
					,SF.ServiceFeeFactorValue
					,SF.ActiveStartDate
					,SF.ActiveLastDate
					,SF.ServiceFeeTypeID
					--,SF.ChainId
					--,SF.SupplierId
					FROM 
						ServiceFees SF
						INNER JOIN Chains C ON SF.ChainID=C.ChainID
						INNER JOIN Suppliers S ON SF.SupplierId=S.SupplierID OR SF.SupplierID=0
					WHERE 
						SF.ServiceFeeTypeID in (2,3) 
						AND SF.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainID END
						AND SF.SupplierId like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID END
					ORDER BY
						C.ChainName,CASE WHEN SF.SupplierID=0 THEN NULL ELSE S.SupplierName END
			END
			
	ELSE IF (@FeesType='2') --SBT Fees Details
			BEGIN
				SELECT DISTINCT 
					 SF.ChainID as RetailerId
					,C.ChainName as RetailerName
					,SF.SupplierId
					,CASE WHEN SF.SupplierID IS NULL THEN NULL ELSE S.SupplierName END as SupplierName
					,SF.Fees
					,SF.FeeMode
					,SF.CalculateOn
					,SF.ActiveStartDate
					,SF.ActiveEndDate
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
		
	
END
GO
