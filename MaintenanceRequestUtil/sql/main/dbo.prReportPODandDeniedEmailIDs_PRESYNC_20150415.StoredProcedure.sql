USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prReportPODandDeniedEmailIDs_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[prReportPODandDeniedEmailIDs_PRESYNC_20150415]
@PODTYPES INT
 
AS 
    BEGIN
			
			IF @PODTYPES = 1
			SELECT DISTINCT SupplierIdentifier
			              , SupplierID
						  , SupplierName
						  , FirstName
						  , LastName
						  --, lower(CI.Email) AS Email
						  , Email AS Email
						  ---,'gilad.keren@icucsolutions.com' AS Email
			FROM
			[00000000SENDEMAILNew] where SupplierIdentifier not in ('BG',
'SHRL',
'WR328',
'WR651',
'WR715',
'WR718',
'FRN'   ----end 


) ---and SupplierID=24202

IF @PODTYPES = 2
	SELECT DISTINCT SupplierIdentifier
			              , SupplierID
						  , SupplierName
						  , FirstName
						  , LastName
						  --, lower(CI.Email) AS Email
						   ,Email AS Email
						  ---,'gilad.keren@icucsolutions.com' AS Email
						 ---- into [0_00000DenidEmials]
			FROM [0_00000DenidEmials] ----where SUpplierIDentifier='HNA'
			
			
			
			
			
					--SELECT DISTINCT SupplierIdentifier
			--              , Sup.SupplierID
			--			  , SupplierName
			--			  , CI.FirstName
			--			  , CI.LastName
			--			  --, lower(CI.Email) AS Email
			--			   ,CI.Email AS Email
			--			  ---,'gilad.keren@icucsolutions.com' AS Email
			--			 ---- into [0_00000DenidEmials]
			--FROM
			--	DataTrue_Main..InventoryReport_Newspaper_Shrink_Facts F
			--	INNER JOIN DataTrue_Main..Chains C
			--		ON C.ChainID = F.ChainID and c.ChainIdentifier<>'CVS'
			--	INNER JOIN DataTrue_Main..Suppliers Sup
			--		ON Sup.SupplierID = F.Supplierid
			--	INNER JOIN DataTrue_Main..Stores S
			--		ON S.StoreID = F.StoreID
			--	INNER JOIN DataTrue_Main..ContactInfo CI
			--		ON CI.OwnerEntityID = Sup.SupplierID

			--WHERE
			--((Status =3 and (DeniedDCRSendStatus=0 or DeniedDCRSendStatus = null))
			----or (Status =2 and (PODRequestSendStatus=0 or PODRequestSendStatus = null))) added
			--and (PODReceived =0 or PODReceived is null)) ---added
			--	--Status = 2  or Status=3
			--	--AND (PODReceived = 0
			--	--OR PODReceived IS NULL)
			--	--AND (PODRequestSendStatus = 0
			--	--OR PODRequestSendStatus IS NULL)
			--	--AND PODRequestSendDateTime IS NULL
			--	--AND (DeniedDCRSendStatus = 0 OR DeniedDCRSendStatus IS NULL ) 
			--	--AND  DeniedDCRSendDateTime IS NULL 
				

			----GROUP BY
			----	dbo.getweekend(SaleDateTime, F.Chainid, F.Supplierid)
			----  , C.ChainIdentifier
			----  , S.LegacySystemStoreIdentifier
			----  , Sup.SupplierID
			----  , Sup.SupplierIdentifier
			----  , SupplierName
			----  , CI.FirstName
			----  , CI.LastName
			----  , CI.Email


			--ORDER BY
			--	1
			
			-------------------------------------------------------------------
			--SELECT DISTINCT SupplierIdentifier
			--              , SupplierID
			--			  , SupplierName
			--			  , FirstName
			--			  , LastName
			--			  --, lower(CI.Email) AS Email
			--			   ,Email AS Email
			--			  ---,'gilad.keren@icucsolutions.com' AS Email
			--			 ---- into [0_00000DenidEmials]
			--FROM [0_00000DenidEmials] --where SUpplierIDentifier='WR723'
	END
--update [00000000SENDEMAILNew]  set Email=REPLACE(Email,';',',')
--UPDATE [00000000SENDEMAILNew] SET Email = LEFT(Email, len(Email) -1)WHERE RIGHT(Email,1) = ','
GO
