USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetEditDetailsSBT]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetEditDetailsSBT]
-- Add the parameters for the stored procedure here
@ChainID varchar(10),
@SupplierID varchar(10),
@StartDate varchar(10),
@EndDate varchar(10)

AS
-- exec usp_GetEditDetailsSBT '60620','','01/01/2012','12/31/2099'
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
						SF.ChainID = @ChainID
						AND Isnull(SF.SupplierId,0)=isnull(@SupplierID,0) 
						and convert(varchar(10),SF.ActiveStartDate,101) = @StartDate
						and convert(varchar(10),SF.ActiveEndDate,101) = @EndDate
END
GO
