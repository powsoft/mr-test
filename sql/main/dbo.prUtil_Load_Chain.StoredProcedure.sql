USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Load_Chain]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Load_Chain]
@chainidentifier nvarchar(50),
@chainname nvarchar(100),
@comments nvarchar(500),
@startdate datetime,
@enddate datetime,
@userid int,
@BaseUnitsCalculationPerNoOfweeks money,
@CostFromRetailPercent tinyint,
@BillingRuleID tinyint,
@IncludeDollarDiffDetails tinyint,
@forpdi bit,
@address nvarchar(100) = '',
@address2 nvarchar(100) = '',
@city nvarchar(100) = '',
@state nvarchar(100) = '',
@zip nvarchar(10) = '',
@defaultbanner varchar(100) = '',
@ftpdirectory varchar(255) = '',
@dunsnumber varchar(50) = ''
/*
prUtil_Load_Chain 'WorldMart','This tested the chain load','1/1/2011','12/31/2025',2,17,75,1,1
*/

as

declare @entitytypeid int
declare @chainid int
declare @MyID int
set @MyID = 7611

begin try

	begin transaction
	
	select @entitytypeid = EntityTypeID
	from DataTrue_Main.dbo.EntityTypes
	where EntityTypeName = 'Chain'

	INSERT INTO [dbo].[SystemEntities]
			   ([EntityTypeID]
			   ,[LastUpdateUserID])
		 VALUES
			   (@entitytypeid
			   ,@userid)

	set @chainid = SCOPE_IDENTITY()

	INSERT INTO [dbo].[Chains]
			   ([ChainID]
			   ,[ChainIdentifier]
			   ,[ChainName]
			   ,[ActiveStartDate]
			   ,[ActiveEndDate]
			   ,[Comments]
			   ,[LastUpdateUserID]
			   ,[PDITradingPartner]
			   ,[DefaultBanner])
		 VALUES
			   (@chainid
			   ,@chainidentifier
			   ,@chainname
			   ,@startdate
			   ,@enddate
			   ,@comments
			   ,@userid
			   ,@forpdi
			   ,@defaultbanner)
			   
	If @forpdi = 1
		Begin	   
			INSERT INTO [DataTrue_EDI].[dbo].[Chains]
			   ([ChainID]
			   ,[ChainIdentifier]
			   ,[ChainName]
			   ,[ActiveStartDate]
			   ,[ActiveEndDate]
			   ,[Comments]
			   ,[LastUpdateUserID]
			   ,[PDITradingPartner]
			   ,[DateTimeCreated]
			   ,[DateTimeLastUpdate]
			   ,[DefaultBanner])
			VALUES
			   (@chainid
			   ,@chainidentifier
			   ,@chainname
			   ,@startdate
			   ,@enddate
			   ,@comments
			   ,@userid
			   ,@forpdi
			   ,GETDATE()
			   ,GETDATE()
			   ,@defaultbanner)
			   
		    DECLARE @allPDIParams BIT = 1
			IF @ftpdirectory = ''
				BEGIN
					SET @allPDIParams = 0
				END
			IF @allPDIParams = 1
				BEGIN 
					EXEC DataTrue_EDI.dbo.usp_AddBusinessRules_PDIRetailer @chainidentifier, @ftpdirectory
				END		
			   
		End
	IF @forpdi = 0
			BEGIN
				EXEC DataTrue_EDI.dbo.[usp_AddBusinessRules_EDIServiceRetailer] @chainidentifier, @chainidentifier
			END		
				
	  INSERT INTO [dbo].[Addresses]
		   ([OwnerEntityID]
		   ,[AddressDescription]
		   ,[Address1]
		   ,[Address2]
		   ,[City]
		   ,[State]
		   ,[PostalCode]
		   ,[LastUpdateUserID]
		   ,[DunsNumber])
	 VALUES
		   (@chainid
		   ,'Main'
		   ,ISNULL(@address, '')
		   ,ISNULL(@address2, '')
		   ,ISNULL(@city, '')
		   ,ISNULL(@state, '')
		   ,ISNULL(@zip, '')
		   ,@MyID
		   ,@dunsnumber)

--******************************************************
INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[CostFromRetailPercent]
           ,[BillingRuleID]
           ,[IncludeDollarDiffDetails]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LastUpdateUserID])
select @chainid
,0
,0
,@BaseUnitsCalculationPerNoOfweeks
,@CostFromRetailPercent
,@BillingRuleID
,@IncludeDollarDiffDetails
,@startdate
,@enddate
,@userid



INSERT INTO [DataTrue_Main].[dbo].[ChainProductFactors]
           ([ChainID]
           ,[ProductID]
           ,[BrandID]
           ,[BaseUnitsCalculationPerNoOfweeks]
           ,[CostFromRetailPercent]
           ,[BillingRuleID]
           ,[IncludeDollarDiffDetails]
           ,[ActiveStartDate]
           ,[ActiveEndDate]
           ,[LastUpdateUserID])
select @chainid
,Productid
,0
,@BaseUnitsCalculationPerNoOfweeks
,@CostFromRetailPercent
,@BillingRuleID
,@IncludeDollarDiffDetails
,@startdate
,@enddate
,@userid
from Products
where ProductID not in
(
select productid
from ChainProductFactors
where ChainID = @chainid
)

--INSERT BASE POS BILLING (TYPE 1) BILLINGCONTROL RECORD
DECLARE  @BillingControlPOSNewID TABLE (BillingControlID INT)
INSERT INTO [DataTrue_Main].[dbo].[BillingControl]
(
[BillingControlFrequency]
,[BillingControlDay]
,[BillingControlClosingDelay]
,[BillingControlNumberOfPastDaysToRebill]
,[ChainID]
,[SupplierID]
,[EntityIDToInvoice]
,[ProductSubGroupType]
,[ProductSubGroupID]
,[InvoiceSeparation]
,[LastBillingPeriodEndDateTime]
,[NextBillingPeriodEndDateTime]
,[NextBillingPeriodRunDateTime]
,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[IsActive]
,[SeparateCredits]
,[PaymentDueInDays]
,[AutoReleasePaymentWhenDue]
,[InvoiceNumberSource]
,[PDIParticipant]
,[ISACH]
,[EDIRecordStatusToApply]
,[EDIRecrodStatusSupplierToApply]
,[AggregationTypeID]
,[POSAdjStartDate]
,[POSAdjPriceRecordCreateDate]
,[RequirePurchaseOrderInfo]
,[ShrinkRan]
,[ADJRan]
,[POSRan]
,[SendEFT]
,[SendEFTReplaceSupplierNameWithVendorID]
,[ItemCostAsNET]
,[BusinessTypeID]
)
VALUES
(
'DAILY'--[BillingControlFrequency]
,1--[BillingControlDay]
,1--[BillingControlClosingDelay]
,30--[BillingControlNumberOfPastDaysToRebill]
,@chainid--[ChainID]
,0--[SupplierID]
,@chainid--[EntityIDToInvoice]
,NULL--[ProductSubGroupType]
,NULL--[ProductSubGroupID]
,4--[InvoiceSeparation]
,GETDATE()--[LastBillingPeriodEndDateTime]
,GETDATE()--[NextBillingPeriodEndDateTime]
,GETDATE()--[NextBillingPeriodRunDateTime]
,GETDATE()--[DateTimeCreated]
,0--[LastUpdateUserID]
,GETDATE()--[DateTimeLastUpdate]
,0--[IsActive]
,0--[SeparateCredits]
,1--[PaymentDueInDays]
,0--[AutoReleasePaymentWhenDue]
,0--[InvoiceNumberSource]
,@forpdi--[PDIParticipant]
,0--[ISACH]
,0--[EDIRecordStatusToApply]
,0--[EDIRecrodStatusSupplierToApply]
,0--[AggregationTypeID]
,'1/1/1900'--[POSAdjStartDate]
,'1/1/2900'--[POSAdjPriceRecordCreateDate]
,0--[RequirePurchaseOrderInfo]
,0--[ShrinkRan]
,0--[ADJRan]
,0--[POSRan]
,1--[SendEFT]
,1--[SendEFTReplaceSupplierNameWithVendorID]
,1--[ItemCostAsNET]
,1--[BusinessTypeID]
)

--INSERT BASE POS BILLING (TYPE 4) BILLINGCONTROL RECORD
DECLARE  @BillingControlPOSSBTNewID TABLE (BillingControlID INT)
INSERT INTO [DataTrue_Main].[dbo].[BillingControl]
(
[BillingControlFrequency]
,[BillingControlDay]
,[BillingControlClosingDelay]
,[BillingControlNumberOfPastDaysToRebill]
,[ChainID]
,[SupplierID]
,[EntityIDToInvoice]
,[ProductSubGroupType]
,[ProductSubGroupID]
,[InvoiceSeparation]
,[LastBillingPeriodEndDateTime]
,[NextBillingPeriodEndDateTime]
,[NextBillingPeriodRunDateTime]
,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[IsActive]
,[SeparateCredits]
,[PaymentDueInDays]
,[AutoReleasePaymentWhenDue]
,[InvoiceNumberSource]
,[PDIParticipant]
,[ISACH]
,[EDIRecordStatusToApply]
,[EDIRecrodStatusSupplierToApply]
,[AggregationTypeID]
,[POSAdjStartDate]
,[POSAdjPriceRecordCreateDate]
,[RequirePurchaseOrderInfo]
,[ShrinkRan]
,[ADJRan]
,[POSRan]
,[SendEFT]
,[SendEFTReplaceSupplierNameWithVendorID]
,[ItemCostAsNET]
,[BusinessTypeID]
)
VALUES
(
'DAILY'--[BillingControlFrequency]
,1--[BillingControlDay]
,1--[BillingControlClosingDelay]
,30--[BillingControlNumberOfPastDaysToRebill]
,@chainid--[ChainID]
,0--[SupplierID]
,@chainid--[EntityIDToInvoice]
,NULL--[ProductSubGroupType]
,NULL--[ProductSubGroupID]
,4--[InvoiceSeparation]
,GETDATE()--[LastBillingPeriodEndDateTime]
,GETDATE()--[NextBillingPeriodEndDateTime]
,GETDATE()--[NextBillingPeriodRunDateTime]
,GETDATE()--[DateTimeCreated]
,0--[LastUpdateUserID]
,GETDATE()--[DateTimeLastUpdate]
,0--[IsActive]
,0--[SeparateCredits]
,1--[PaymentDueInDays]
,0--[AutoReleasePaymentWhenDue]
,0--[InvoiceNumberSource]
,@forpdi--[PDIParticipant]
,0--[ISACH]
,0--[EDIRecordStatusToApply]
,0--[EDIRecrodStatusSupplierToApply]
,0--[AggregationTypeID]
,'1/1/1900'--[POSAdjStartDate]
,'1/1/2900'--[POSAdjPriceRecordCreateDate]
,0--[RequirePurchaseOrderInfo]
,0--[ShrinkRan]
,0--[ADJRan]
,0--[POSRan]
,1--[SendEFT]
,1--[SendEFTReplaceSupplierNameWithVendorID]
,1--[ItemCostAsNET]
,4--[BusinessTypeID]
)

--INSERT BASE SUPPLIER BILLING (TYPE 2) BILLINGCONTROL RECORD
DECLARE  @BillingControlNewID TABLE (BillingControlID INT)
INSERT INTO [DataTrue_Main].[dbo].[BillingControl]
(
[BillingControlFrequency]
,[BillingControlDay]
,[BillingControlClosingDelay]
,[BillingControlNumberOfPastDaysToRebill]
,[ChainID]
,[SupplierID]
,[EntityIDToInvoice]
,[ProductSubGroupType]
,[ProductSubGroupID]
,[InvoiceSeparation]
,[LastBillingPeriodEndDateTime]
,[NextBillingPeriodEndDateTime]
,[NextBillingPeriodRunDateTime]
,[DateTimeCreated]
,[LastUpdateUserID]
,[DateTimeLastUpdate]
,[IsActive]
,[SeparateCredits]
,[PaymentDueInDays]
,[AutoReleasePaymentWhenDue]
,[InvoiceNumberSource]
,[PDIParticipant]
,[ISACH]
,[EDIRecordStatusToApply]
,[EDIRecrodStatusSupplierToApply]
,[AggregationTypeID]
,[POSAdjStartDate]
,[POSAdjPriceRecordCreateDate]
,[RequirePurchaseOrderInfo]
,[ShrinkRan]
,[ADJRan]
,[POSRan]
,[SendEFT]
,[SendEFTReplaceSupplierNameWithVendorID]
,[ItemCostAsNET]
,[BusinessTypeID]
)
OUTPUT inserted.BillingControlID INTO @BillingControlNewID
VALUES
(
'DAILY'--[BillingControlFrequency]
,1--[BillingControlDay]
,1--[BillingControlClosingDelay]
,30--[BillingControlNumberOfPastDaysToRebill]
,@chainid--[ChainID]
,0--[SupplierID]
,@chainid--[EntityIDToInvoice]
,NULL--[ProductSubGroupType]
,NULL--[ProductSubGroupID]
,4--[InvoiceSeparation]
,GETDATE()--[LastBillingPeriodEndDateTime]
,GETDATE()--[NextBillingPeriodEndDateTime]
,GETDATE()--[NextBillingPeriodRunDateTime]
,GETDATE()--[DateTimeCreated]
,63600--[LastUpdateUserID]
,GETDATE()--[DateTimeLastUpdate]
,1--[IsActive]
,0--[SeparateCredits]
,1--[PaymentDueInDays]
,0--[AutoReleasePaymentWhenDue]
,0--[InvoiceNumberSource]
,@forpdi--[PDIParticipant]
,0--[ISACH]
,0--[EDIRecordStatusToApply]
,0--[EDIRecrodStatusSupplierToApply]
,0--[AggregationTypeID]
,'1/1/1900'--[POSAdjStartDate]
,'1/1/2900'--[POSAdjPriceRecordCreateDate]
,0--[RequirePurchaseOrderInfo]
,0--[ShrinkRan]
,0--[ADJRan]
,0--[POSRan]
,1--[SendEFT]
,1--[SendEFTReplaceSupplierNameWithVendorID]
,1--[ItemCostAsNET]
,2--[BusinessTypeID]
)

--INSERT BILLING CONTROL SUP	
INSERT INTO [DataTrue_Main].[dbo].[BillingControl_SUP]
(
BillingControlID,
MaintainEDICreditSeparation,
ParkFutureEffectiveDates,
ParkFutureEffectiveDatesRegulated,
ParkFutureDueDates,
ParkFutureDueDatesRegulated,
AllowBillingZeroDollarLineItems,
AllowBillingZeroDollarLineItemsRegulated,
AllowBillingZeroDollarInvoices,
AllowBillingZeroDollarInvoicesRegulated,
RoundSummedInvoice
)
SELECT
BillingControlID,
CASE WHEN @forpdi = 1 THEN 1 ELSE 0 END, --MaintainEDICreditSeparation
CASE WHEN @forpdi = 1 THEN 0 ELSE 1 END, --ParkFutureEffectiveDates
1, --ParkFutureEffectiveDatesRegulated
CASE WHEN @forpdi = 1 THEN 0 ELSE 1 END, --ParkFutureDueDates
0, --ParkFutureDueDatesRegulated
CASE WHEN @forpdi = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarLineItems
CASE WHEN @forpdi = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarLineItemsRegulated
CASE WHEN @forpdi = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarInvoices
CASE WHEN @forpdi = 1 THEN 1 ELSE 0 END, --AllowBillingZeroDollarInvoicesRegulated
CASE WHEN @forpdi = 1 THEN 1 ELSE 0 END --RoundSummedInvoice
FROM @BillingControlNewID


		commit transaction
	
end try
	
begin catch
		rollback transaction
		declare @errormessage varchar(4500)
		declare @errorlocation varchar(255)

		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		
		exec dbo.prSendEmailNotification
		@errorlocation,
		@errormessage,
		@errorlocation,
		@MyID
end catch
	
return
GO
