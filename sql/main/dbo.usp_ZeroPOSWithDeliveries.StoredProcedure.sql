USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ZeroPOSWithDeliveries]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC usp_ZeroPOSWithDeliveries 40393
CREATE PROC [dbo].[usp_ZeroPOSWithDeliveries]
@ChainId VARCHAR(20),
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
			SELECT   [Supplier Name] AS [SupplierName]
					,[UPC]
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
				
			 ORDER BY [SupplierName] ASC
		END
	ELSE
		BEGIN
			SELECT Suppliers.SupplierName ,
					IR.UPC AS [UPC] ,
					SUM(supp_del_cy) as Delivery,
					SUM(supp_cred_cy) as Pickup,   
					SUM(supp_del_cy)+SUM(supp_cred_cy) as Net,
					@Month AS [Month],
					'' AS [Color]
			FROM ir_report_summary_noinv_6weeks IR WITH(NOLOCK)
				INNER JOIN Stores WITH(NOLOCK) ON Stores.StoreID  = IR.StoreID AND Stores.ChainID = IR.ChainID
				INNER JOIN Suppliers WITH(NOLOCK) ON Suppliers.SupplierID  = IR.SupplierID
				INNER JOIN ProductIdentifiers PI WITH(NOLOCK) ON PI.IdentifierValue = IR.UPC 
				INNER JOIN Products pp WITH(NOLOCK) ON pp.ProductID = PI.ProductID  AND ProductIdentifierTypeID=2
			WHERE IR.ChainID = @ChainId 
			GROUP BY  IR.UPC, Suppliers.SupplierName
			HAVING  SUM(supp_del_cy) + SUM(supp_cred_cy) <> 0 
			
		END
END
GO
