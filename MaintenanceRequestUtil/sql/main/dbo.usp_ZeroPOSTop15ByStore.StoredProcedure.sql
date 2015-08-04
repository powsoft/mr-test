USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ZeroPOSTop15ByStore]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [usp_ZeroPOSTop15ByStore]  '40393','40567'
CREATE PROC [dbo].[usp_ZeroPOSTop15ByStore]
@ChainID Varchar(20),
@SupplierID Varchar(20),
@ReportName NVARCHAR(100),
@ReportTitle NVARCHAR(250)
AS
BEGIN
	DECLARE @Month AS VARCHAR(20)
	IF(Day(GETDATE()) <= 17)
		SELECT @Month = DATENAME(MONTH, DateAdd(month, -2, Convert(date, GETDATE()))) + ', ' + DATENAME(YEAR,DateAdd(month, -2, Convert(date, GETDATE()))) 
	ELSE
		SELECT @Month = DATENAME(MONTH, DateAdd(month, -1, Convert(date, GETDATE()))) + ', ' + DATENAME(YEAR,DateAdd(month, -1, Convert(date, GETDATE()))) 
	
	IF EXISTS(Select ChainID FROM [dbo].[ReportColorAnalysis] WHERE ChainID=@ChainID AND SupplierID=@SupplierID AND [Month]=@Month AND ReportName = @ReportName AND ReportTitle = @ReportTitle)
		BEGIN
			SELECT TOP 15 [BannerIdSec]
						  ,[Banner Store] AS [BannerStore]
						  ,[Store ID] AS [StoreID]
						  ,CAST([Delivery] AS INT) AS [Delivery]
						  ,CAST([Pickup] AS INT) AS [Pickup]
						  ,CAST([Net] AS INT) AS [Net]
						  ,[Month]
						  ,[Color]

					FROM [dbo].[ReportColorAnalysis]
					WHERE [ChainID]= @ChainID
					AND [SupplierID]=@SupplierID
					AND [ReportName]=@ReportName
					AND [ReportTitle]=@ReportTitle
					AND [Month]=@Month
					ORDER BY Net DESC
		END
	ELSE
		BEGIN
			SELECT TOP 15 IR.BannerIdSec,
						  IR.BannerIdSec + '-' + cast(Stores.StoreIdentifier as varchar(20)) as BannerStore  , 
						  Stores.StoreIdentifier AS StoreID  ,
						  SUM(ISNULL(supp_del_cy,0)) as Delivery,
						  SUM(ISNULL(supp_cred_cy,0)) as Pickup,   
						  CAST(SUM(ISNULL(supp_del_cy,0))+SUM(ISNULL(supp_cred_cy,0)) AS INT) as Net,
						  @Month AS [Month],
						  '' AS [Color]
						   
			FROM ir_report_summary_noinv_6weeks IR
				INNER JOIN Stores on stores.StoreID  = ir.StoreID and stores.ChainID = ir.ChainID
				INNER JOIN ProductIdentifiers pi on pi.IdentifierValue = ir.UPC 
				INNER JOIN Products pp on pp.ProductID = pi.ProductID  and ProductIdentifierTypeID=2
			WHERE IR.ChainID=@ChainID and IR.SupplierID=@SupplierID 
			GROUP BY IR.BannerIdSec, Stores.StoreIdentifier,IR.StoreId       
			HAVING   SUM(supp_del_cy)+SUM(supp_cred_cy) <> 0 
			ORDER BY Net DESC
		END
END
GO
