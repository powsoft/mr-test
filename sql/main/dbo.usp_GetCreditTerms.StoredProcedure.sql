USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetCreditTerms]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_GetCreditTerms] 40562
CREATE procedure [dbo].[usp_GetCreditTerms]
@SupplierId varchar(20)
as
 
Begin
	Declare @sqlQuery varchar(4000)
    set @sqlQuery = 'SELECT  BillingControlID, BillingControlFrequency, 
			Case    WHEN BillingControlDay=1 THEN ''Sunday''
					WHEN BillingControlDay=2 THEN ''Monday''
					WHEN BillingControlDay=3 THEN ''Tuesday''
					WHEN BillingControlDay=4 THEN ''Wednesday''
					WHEN BillingControlDay=5 THEN ''Thursday''
					WHEN BillingControlDay=6 THEN ''Friday''
					WHEN BillingControlDay=7 THEN ''Saturday''
			End as BillingControlDay, 
						BillingControlClosingDelay, BillingControlNumberOfPastDaysToRebill, 
						LastBillingPeriodEndDateTime, NextBillingPeriodEndDateTime,
						NextBillingPeriodRunDateTime, IsActive, PaymentDueInDays
					FROM  BillingControl where 1=1 '
           
        if(@SupplierId <>'-1' )   
            set @sqlQuery = @sqlQuery + ' and EntityIDToInvoice = ' + @SupplierId
        
        execute(@sqlQuery);
 
End
GO
