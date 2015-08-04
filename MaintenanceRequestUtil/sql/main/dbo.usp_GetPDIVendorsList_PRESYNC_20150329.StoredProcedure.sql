USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPDIVendorsList_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetPDIVendorsList_PRESYNC_20150329]
@ChainID varchar(20),
@SupplierID varchar(20),
@PDIExcluded bit
As
Begin

--The PDI Vendor which are included in the icontrol fee report
if(@PDIExcluded = 0)
			BEGIN
				Select DISTINCT
						SB.ChainID as RetailerID
					 ,C.ChainName	as RetailerName
					 ,SB.SupplierID as SupplierID
					 ,S.SupplierName as SupplierName
					 --,P.ChainID
					 --,P.SupplierID
					 ,P.IsExcluded
				From 
					SupplierBanners SB
					INNER JOIN Chains C ON SB.ChainID=C.ChainID
					INNER JOIN Suppliers S ON SB.SupplierID=S.SupplierID
					LEFT JOIN PDIVendors P ON P.ChainID=SB.ChainID and P.SupplierID=SB.SupplierID
				Where
					C.PDITradingPartner=1 
					and S.PDITradingPartner=1
					AND (P.ChainID IS NULL AND P.SupplierID IS NULL or P.IsExcluded=0)
					AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainId End
					AND SB.SupplierID like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID End
					
					UNION ALL
					
					Select DISTINCT
					  SB.ChainID as RetailerID
					 ,C.ChainName	as RetailerName
					 ,0 as SupplierID
					 ,'' as SupplierName
					 --,P.ChainID
					 --,P.SupplierID
					 ,P.IsExcluded
				From 
					SupplierBanners SB
					INNER JOIN Chains C ON SB.ChainID=C.ChainID
					LEFT JOIN PDIVendors P ON P.ChainID=SB.ChainID and isnull(P.SupplierID,0)=0
				Where
					C.PDITradingPartner=1 
					AND (P.ChainID IS NULL AND P.SupplierID IS NULL or P.IsExcluded=0)
					AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainId End
				Order BY
					2,4
			END	
	Else
		--The PDI Vendor which are excluded from icontrol fee report
			BEGIN
				Select DISTINCT
					  SB.ChainID as RetailerID
					 ,C.ChainName	as RetailerName
					 ,SB.SupplierID as SupplierID
					 ,S.SupplierName as SupplierName
					 --,P.ChainID
					 --,P.SupplierID
					 ,P.IsExcluded
				From 
					SupplierBanners SB
					INNER JOIN Chains C ON SB.ChainID=C.ChainID
					INNER JOIN Suppliers S ON SB.SupplierID=S.SupplierID
					LEFT JOIN PDIVendors P ON P.ChainID=SB.ChainID and P.SupplierID=SB.SupplierID
				Where
					C.PDITradingPartner=1 
					and S.PDITradingPartner=1
					AND (P.IsExcluded=1)
					AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainId End
					AND SB.SupplierID like CASE WHEN @SupplierID='-1' THEN '%' ELSE @SupplierID End
					
					UNION ALL
					
					Select DISTINCT
					  SB.ChainID as RetailerID
					 ,C.ChainName	as RetailerName
					 ,0 as SupplierID
					 ,''	as SupplierName
					 --,P.ChainID
					 --,P.SupplierID
					 ,P.IsExcluded
				From 
					SupplierBanners SB
					INNER JOIN Chains C ON SB.ChainID=C.ChainID
					LEFT JOIN PDIVendors P ON P.ChainID=SB.ChainID and Isnull(P.SupplierID,0)=0
				Where
					C.PDITradingPartner=1 
					AND (P.IsExcluded=1)
					AND SB.ChainID like CASE WHEN @ChainID='-1' THEN '%' ELSE @ChainId End
				Order BY
					2,4
					
			END
	
End
GO
