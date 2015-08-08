USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMaintenanceRequest_Special_MR_Treatment_Stagging_20130909]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
exec [prMaintenanceRequest_Special_MR_Treatment_Paul_C2S_Adopted]
*/

CREATE procedure [dbo].[prMaintenanceRequest_Special_MR_Treatment_Stagging_20130909]
as 

/*
Remember to comment out and maintenancerequestid = 203929
Skip_879_889_Conversion_ProcessCompleted  is null
select *
into import.dbo.MR_Testing
--select *
from maintenancerequests
where chainid in (44285, 59973)
and requeststatus in (0, 1, 2)
*/

DECLARE @start DATETIME2
DECLARE @end DATETIME2

SET @start = GETDATE()
set nocount on

SELECT  
	  MaintenanceRequestID
	--, StartDateTime
	--, EndDatetime
	--, cost 
	--, productid
	--, Banner
	--, SupplierID
	--, ChainID 
INTO	
	#type2_temp
FROM 
import.dbo.MR_Testing as MR
	--MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 8
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)

		OR  ( --whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 
		)
WHERE 
	MR.RequestTypeID = 2 
and MR.PDIParticipant = 1 
and ISNULL(MR.MarkDeleted, 0) <> 1 
and MR.Approved=1 
and MR.Skip_879_889_Conversion_ProcessCompleted  IS NULL 
and MR.productid IS NOT NULL
and mr.MaintenanceRequestID = 203949






/*
SELECT
	  MR.RequestTypeID	
	, MR.MaintenanceRequestID
	, MR.StartDateTime
	, MR.EndDatetime
	, MR.Cost 
	, MR.productid
	, MR.Banner
	, MR.SupplierID
	, MR.ChainID 
	
	, P.ProductPriceID 
	, PromoAllowance = P.UnitPrice
	, P.ActiveStartDate 
	, P.ActiveLastDate  
FROM 
	MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 8
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR  ( --whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 
		)
WHERE 
	MR.RequestTypeID = 2 
and MR.PDIParticipant = 1 
and ISNULL(MR.MarkDeleted, 0) <> 1 
and MR.approved=1 
and MR.Skip_879_889_Conversion_ProcessCompleted  IS NULL 
and MR.productid IS NOT NULL
*/

DECLARE @LastRequest BIGINT
SELECT @LastRequest = MAX(MaintenanceRequestID) FROM MaintenanceRequests

--generate internal MRs
INSERT INTO import.dbo.MR_Testing
	--MaintenanceRequests 
(
	 PDIParticipant
	 
	,[SubmitDateTime]
	,[RequestTypeID]
	,[ChainID]
	,[SupplierID]
	,[Banner]
	
	,[AllStores]
	,[UPC]
	,[BrandIdentifier]
	,[ItemDescription]
	,[CurrentSetupCost]
	
	,[Cost]
	,[SuggestedRetail]
	,[PromoTypeID]
	,[PromoAllowance]
	,[StartDateTime]
	
	,[EndDateTime]
	,[SupplierLoginID]
	,[ChainLoginID]
	,[Approved]
	,[ApprovalDateTime]
	
	,[DenialReason]
	,[EmailGeneratedToSupplier]
	,[EmailGeneratedToSupplierDateTime]
	,[RequestStatus]
	,[CostZoneID]
	
	,[productid]
	,[brandid]
	,[upc12]
	,[datatrue_edi_costs_recordid]
	,[datatrue_edi_promotions_recordid]
	
	,[dtstorecontexttypeid]
	,[TradingPartnerPromotionIdentifier]
	,[MarkDeleted]
	,[DeleteLoginId]
	,[DeleteReason]
	
	,[DeleteDateTime]
	,[datetimecreated]
	,[SkipPopulating879_889Records]
	,[Skip_879_889_Conversion_ProcessCompleted]
)
SELECT  
	1
	
	,MR.[SubmitDateTime]
	,2
	,MR.[ChainID]
	,MR.[SupplierID]
	,MR.[Banner]

	,MR.[AllStores]
	,MR.[UPC]
	,MR.[BrandIdentifier]
	,MR.[ItemDescription]
	,MR.[CurrentSetupCost]
	
	,MR.[Cost] - CASE WHEN P.[UnitPrice] IS NOT NULL THEN ABS(P.[UnitPrice]) ELSE 0 END
	,MR.[SuggestedRetail]
	, 0
	, 0
	,MR.[StartDateTime]
	
	,MR.[EndDatetime]
	,MR.[SupplierLoginID]
	,MR.[ChainLoginID]
	,MR.[Approved]
	,MR.[ApprovalDateTime]
	
	,MR.[DenialReason]
	,MR.[EmailGeneratedToSupplier]
	,MR.[EmailGeneratedToSupplierDateTime]
	,MR.[RequestStatus]
	,MR.[CostZoneID]
	
	,MR.[productid]
	,MR.[brandid]
	,MR.[upc12]
	,MR.[datatrue_edi_costs_recordid]
	,MR.[datatrue_edi_promotions_recordid]
	
	,MR.[dtstorecontexttypeid]
	,MR.[TradingPartnerPromotionIdentifier]
	,MR.[MarkDeleted]
	,MR.[DeleteLoginId]
	,MR.[DeleteReason]
	
	,MR.[DeleteDateTime]
	,GETDATE()
	,0
	,MR.[MaintenanceRequestID]
FROM 
	import.dbo.MR_Testing as MR
	--MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 8
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)

		OR  ( --whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 
		)
		
WHERE 
	(MR.RequestTypeID = 2 ) --COST CHANGE ONLY
AND (MR.PDIParticipant = 1 ) --PDI ONLY
AND (ISNULL(MR.MarkDeleted, 0) <> 1 )
AND (MR.Approved = 1 )
AND (MR.Skip_879_889_Conversion_ProcessCompleted  IS NULL ) 
AND (MR.ProductID IS NOT NULL )
and mr.MaintenanceRequestID = 203949

ORDER BY MaintenanceRequestID, P.SupplierID, P.ProductID, P.ChainID, P.[UnitPrice]

-- Find MAX inserted MRID per original Inbound MRID
SELECT
	 OriginalMRID = Skip_879_889_Conversion_ProcessCompleted
	,NewMRID = MAX([MaintenanceRequestID])  
INTO
	#type2_temp_newIDs
FROM
	import.dbo.MR_Testing
	--MaintenanceRequests
WHERE
	[MaintenanceRequestID] > @LastRequest
GROUP BY
	Skip_879_889_Conversion_ProcessCompleted
	
--------------------------------------------------------------------------------	
-- UPDATE Inbound MRs to set relationships between Inbound and Internal MRs
--------------------------------------------------------------------------------	
UPDATE mr
SET 
	 mr.Skip_879_889_Conversion_ProcessCompleted = new.NewMRID 
	,mr.SkipPopulating879_889Records = -1 
FROM
	#type2_temp AS old
	-------------------
	INNER JOIN
	-------------------
	#type2_temp_newIDs	AS new ON
		(old.MaintenanceRequestID = new.OriginalMRID)
	-------------------
	INNER JOIN
	-------------------	
	import.dbo.MR_Testing as MR ON
	--MaintenanceRequests AS mr ON
		(mr.MaintenanceRequestID = old.MaintenanceRequestID)

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--
-- PROMOS (MR Type = 3)
--
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

DECLARE @mailtxt VARCHAR(8000)
SET @mailtxt = ''
 
SELECT
	@mailtxt = @mailtxt + 'Multiple Cost exist in product prices table, Please correct .. <br>MRID : ' + CAST(MaintenanceRequestID AS VARCHAR) + '<br>ProductID: ' + CAST( MR.ProductID AS VARCHAR)  + '<br>SupplierID : ' + CAST( MR.SupplierID AS VARCHAR)+ '<br>ChainID : ' + CAST( MR.ChainID AS VARCHAR) + '<br>Rows: ' + CAST(COUNT(*) AS VARCHAR) + '<br>'
FROM 
	import.dbo.MR_Testing as MR
	--MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 3
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)

		OR  (	--whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 
		)
		
WHERE 
	MR.RequestTypeID = 3 
and MR.PDIParticipant = 1 
and MR.Approved = 1	
and ISNULL(MR.MarkDeleted, 0) <> 1 
and MR.Skip_879_889_Conversion_ProcessCompleted IS NULL 
and MR.Productid IS NOT NULL
and mr.MaintenanceRequestID = 203949	
GROUP BY
	  MR.Productid
	, MR.SupplierID
	, MR.ChainID 
	, MR.MaintenanceRequestID 
HAVING 
	COUNT(*) > 1	
	
IF 	LEN(@mailtxt) > 0
BEGIN
	SELECT 	@mailtxt
	PRINT 'Send Email : MRID#' + @mailtxt
	EXEC msdb.dbo.sp_send_dbmail
		@recipients='paul.tsyhura@icontroldsd.com'  ,
		@subject = 'PDI sp item maintenance alert.',
		@body = @mailtxt ,
		@body_format = 'HTML';
END				
	
SET @mailtxt = ''

SELECT
	@mailtxt = @mailtxt + 'Cost does not exist in product prices table.. Please correct  <br>MRID : ' + CAST(MaintenanceRequestID AS VARCHAR) + '<br>ProductID: ' + CAST( MR.ProductID AS VARCHAR)  + '<br>SupplierID : ' + CAST( MR.SupplierID AS VARCHAR)+ '<br>ChainID : ' + CAST( MR.ChainID AS VARCHAR) + '<br>'
FROM 
	import.dbo.MR_Testing as MR
	--MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 3
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)

		OR  (	--whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 

		)
WHERE 
	MR.RequestTypeID = 3 
and MR.PDIParticipant = 1 
and MR.Approved = 1	
and ISNULL(MR.MarkDeleted, 0) <> 1 
and MR.Skip_879_889_Conversion_ProcessCompleted IS NULL 
and MR.Productid IS NOT NULL	
and P.ProductPriceID IS NULL

	
IF 	LEN(@mailtxt) > 0
BEGIN
	SELECT 	@mailtxt
	PRINT 'Send Email : MRID#' + @mailtxt
	EXEC msdb.dbo.sp_send_dbmail
		@recipients='paul.tsyhura@icontroldsd.com'  ,
		@subject = 'PDI sp item maintenance alert.',
		@body = @mailtxt ,
		@body_format = 'HTML';
END		

SELECT
	MR.MaintenanceRequestID
INTO
	#dups_mrs_temp	
FROM 
	import.dbo.MR_Testing as MR
	--MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 3
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)

		OR  (	--whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 
		)
WHERE 
	MR.RequestTypeID = 3 
and MR.PDIParticipant = 1 
and MR.Approved = 1	
and ISNULL(MR.MarkDeleted, 0) <> 1 
and MR.Skip_879_889_Conversion_ProcessCompleted IS NULL 
and MR.Productid IS NOT NULL	
GROUP BY
	  MR.Productid
	, MR.SupplierID
	, MR.ChainID 
	, MR.MaintenanceRequestID 
HAVING 
	COUNT(*) > 1	
	
--add index to the temp
CREATE INDEX #dups_mrs_temp_idx ON #dups_mrs_temp (MaintenanceRequestID)

SELECT  
	MR.MaintenanceRequestID
INTO	
	#type3_temp 
FROM
	import.dbo.MR_Testing as MR
	--MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 3
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)

		OR  (	--whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 
		)
	-----------------
	LEFT OUTER JOIN
	-----------------
	#dups_mrs_temp AS d ON
		MR.MaintenanceRequestID = d.MaintenanceRequestID
		
WHERE 
	MR.RequestTypeID = 3 
and MR.PDIParticipant = 1 
and MR.Approved = 1	
and ISNULL(MR.MarkDeleted, 0) <> 1 
and MR.Skip_879_889_Conversion_ProcessCompleted IS NULL 
and MR.Productid IS NOT NULL
and P.ProductPriceID IS NOT NULL
and d.MaintenanceRequestID IS NULL
	

SELECT @LastRequest = MAX(MaintenanceRequestID) FROM MaintenanceRequests

--generate internal MRs
INSERT INTO import.dbo.MR_Testing
	--MaintenanceRequests 
(
	 PDIParticipant
	 
	,[SubmitDateTime]
	,[RequestTypeID]
	,[ChainID]
	,[SupplierID]
	,[Banner]
	
	,[AllStores]
	,[UPC]
	,[BrandIdentifier]
	,[ItemDescription]
	,[CurrentSetupCost]
	
	,[Cost]
	,[SuggestedRetail]
	,[PromoTypeID]
	,[PromoAllowance]
	,[StartDateTime]
	
	,[EndDateTime]
	,[SupplierLoginID]
	,[ChainLoginID]
	,[Approved]
	,[ApprovalDateTime]
	
	,[DenialReason]
	,[EmailGeneratedToSupplier]
	,[EmailGeneratedToSupplierDateTime]
	,[RequestStatus]
	,[CostZoneID]
	
	,[productid]
	,[brandid]
	,[upc12]
	,[datatrue_edi_costs_recordid]
	,[datatrue_edi_promotions_recordid]
	
	,[dtstorecontexttypeid]
	,[TradingPartnerPromotionIdentifier]
	,[MarkDeleted]
	,[DeleteLoginId]
	,[DeleteReason]
	
	,[DeleteDateTime]
	,[datetimecreated]
	,[SkipPopulating879_889Records]
	,[Skip_879_889_Conversion_ProcessCompleted]
)
SELECT  
	1
	
	,MR.[SubmitDateTime]
	,2
	,MR.[ChainID]
	,MR.[SupplierID]
	,MR.[Banner]

	,MR.[AllStores]
	,MR.[UPC]
	,MR.[BrandIdentifier]
	,MR.[ItemDescription]
	,MR.[CurrentSetupCost]
	
	,Cost = P.[UnitPrice] - MR.[PromoAllowance] -- because UnitPrice is coming from PriceType = 3 it actually means the Cost and in MR we actually have PROMO/Discount
	,MR.[SuggestedRetail]
	,0 AS PromoTypeID
	,0 AS PromoAllowance
	,MR.[StartDateTime]
	
	,MR.[EndDatetime]
	,MR.[SupplierLoginID]
	,MR.[ChainLoginID]
	,MR.[Approved]
	,MR.[ApprovalDateTime]
	
	,MR.[DenialReason]
	,MR.[EmailGeneratedToSupplier]
	,MR.[EmailGeneratedToSupplierDateTime]
	,MR.[RequestStatus]
	,MR.[CostZoneID]
	
	,MR.[productid]
	,MR.[brandid]
	,MR.[upc12]
	,MR.[datatrue_edi_costs_recordid]
	,MR.[datatrue_edi_promotions_recordid]
	
	,MR.[dtstorecontexttypeid]
	,MR.[TradingPartnerPromotionIdentifier]
	,MR.[MarkDeleted]
	,MR.[DeleteLoginId]
	,MR.[DeleteReason]
	
	,MR.[DeleteDateTime]
	,GETDATE()
	,0
	,MR.[MaintenanceRequestID]
FROM 
	import.dbo.MR_Testing as MR
	--MaintenanceRequests AS MR
	-----------------
	LEFT OUTER JOIN
	-----------------
	ProductPrices AS P ON 
		MR.ProductID = P.ProductID
	AND MR.SupplierID = P.SupplierID 
	AND MR.ChainID = P.ChainID 
	
	AND P.ProductPriceTypeID = 3
	AND ( 
			(MR.StartDateTime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)
		OR	(MR.EndDatetime BETWEEN P.ActiveStartDate AND P.ActiveLastDate)

		OR  (	--whole INCLUSION
				(MR.StartDateTime <= P.ActiveStartDate) AND (P.ActiveLastDate <= MR.EndDatetime)
			) 

		)
	-----------------
	LEFT OUTER JOIN
	-----------------
	#dups_mrs_temp AS d ON
		MR.MaintenanceRequestID = d.MaintenanceRequestID
		
WHERE 
	MR.RequestTypeID = 3 
and MR.PDIParticipant = 1 
and MR.Approved = 1	
and ISNULL(MR.MarkDeleted, 0) <> 1 
and MR.Skip_879_889_Conversion_ProcessCompleted IS NULL 
and MR.Productid IS NOT NULL
and P.ProductPriceID IS NOT NULL
and d.MaintenanceRequestID IS NULL

ORDER BY MaintenanceRequestID,P.SupplierID, P.ProductID, P.ChainID, P.[UnitPrice]
--------------------------------------------------------------------------------	
-- Find MAX inserted MRID per original Inbound MRID 
-- ALWAYS GROUP BY to cover cases when we created MANY Internal MRs per one Inbound MR
-- So when we update Inbound MR we put latest generated MRID 
-- as value for Skip_879_889_Conversion_ProcessCompleted
--------------------------------------------------------------------------------	
SELECT
	 OriginalMRID = Skip_879_889_Conversion_ProcessCompleted
	,NewMRID = MAX([MaintenanceRequestID])  
INTO
	#type3_temp_newIDs
FROM
	import.dbo.MR_Testing
	--MaintenanceRequests
WHERE
	[MaintenanceRequestID] > @LastRequest
GROUP BY
	Skip_879_889_Conversion_ProcessCompleted
	
--------------------------------------------------------------------------------	
-- UPDATE Inbound MRs to set relationships between Inbound and Internal MRs
--------------------------------------------------------------------------------	
UPDATE mr
SET 
	 mr.Skip_879_889_Conversion_ProcessCompleted = new.NewMRID 
	,mr.SkipPopulating879_889Records = -1 
FROM
	#type3_temp AS old
	-------------------
	INNER JOIN
	-------------------
	#type3_temp_newIDs	AS new ON
		(old.MaintenanceRequestID = new.OriginalMRID)
	-------------------
	INNER JOIN
	-------------------	
	import.dbo.MR_Testing as MR ON
	--MaintenanceRequests AS mr ON
		(mr.MaintenanceRequestID = old.MaintenanceRequestID)
	
SET @end = GETDATE()	
PRINT DATEDIFF(ns,@start,@end)
GO
