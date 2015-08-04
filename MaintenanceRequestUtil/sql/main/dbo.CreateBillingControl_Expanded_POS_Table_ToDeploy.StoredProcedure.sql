USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[CreateBillingControl_Expanded_POS_Table_ToDeploy]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2/2/2015
-- Description:	Creates Billing Control Expanded POS table used for invoicing system
-- =============================================
CREATE PROCEDURE [dbo].[CreateBillingControl_Expanded_POS_Table_ToDeploy]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select BillingControlID
	, SupplierID
	, EntityIDToInvoice
	, B.ChainID
	, dateadd(day, 1, Convert(date, LastBillingPeriodEndDateTime)) as StartDate
	, CONVERT(date, NextBillingPeriodEndDateTime) as EndDate
	, S.EntityTypeID
	, BusinessTypeID 
	, C.ChainIdentifier
	, B.BillingControlFrequency
	Into #TempExplodedBCTable --Drop Table #TempExplodedBCTable  
	from BillingControl B  
	Inner Join SystemEntities S  
	On B.EntityIDToInvoice = S.EntityId  
	Inner Join Chains C on 
	B.ChainID = C.ChainID
	where cast(NextBillingPeriodRunDateTime as date) = CAST(Getdate() as date)  
	and BusinessTypeID in (1, 4) 
	and BillingControlID Not in (Select BillingControlID from BillingControl where ChainID in (40393, 60620) and BusinessTypeID = 4) 
	and IsActive = 1      

If OBJECT_ID('[datatrue_main].[dbo].[BillingControl_Expanded_POS]') Is Not Null Drop Table [datatrue_main].[dbo].[BillingControl_Expanded_POS]	  

	Select T.*, S.StoreID, S.Custom3 as Banner
	Into BillingControl_Expanded_POS 
	from Stores S  Inner Join #TempExplodedBCTable T  
	On S.ChainID = T.EntityIDToInvoice  
	Where T.EntityTypeID = 2   

	Insert Into BillingControl_Expanded_POS (ChainID
	, StartDate
	, EndDate
	, EntityIDToInvoice
	, StoreID
	, SupplierID
	, BillingControlID
	, EntityTypeID
	, BusinessTypeID
	, ChainIdentifier
	, BillingControlFrequency)  
	Select T.ChainID
	, T.StartDate
	, T.EndDate
	, T.EntityIDToInvoice
	, M.MemberEntityID
	, T.SupplierID
	, T.BillingControlID
	, EntityTypeID
	, BusinessTypeID 
	, ChainIdentifier 
	, T.BillingControlFrequency
	From Memberships M  
	Inner Join #TempExplodedBCTable T  
	On M.OrganizationEntityID = T.EntityIDToInvoice  
	Where EntityTypeID = 6  
	and M.MembershipTypeID = 12    

	Insert Into BillingControl_Expanded_POS (ChainID
	, StartDate
	, EndDate
	, EntityIDToInvoice
	, StoreID
	, SupplierID
	, BillingControlID
	, EntityTypeID
	, BusinessTypeID
	, ChainIdentifier
	, BillingControlFrequency)  
	Select Distinct T.ChainID
	, T.StartDate
	, T.EndDate
	, T.EntityIDToInvoice
	, M.StoreID
	, T.SupplierID
	, T.BillingControlID
	, EntityTypeID
	, BusinessTypeID
	, T.ChainIdentifier
	, T.BillingControlFrequency  
	From StoreSetup M  
	Inner Join #TempExplodedBCTable T  
	On M.SupplierID = T.EntityIDToInvoice  
	and M.ChainID = T.ChainID  
	Where EntityTypeID = 5  
	--and M.MembershipTypeID = 12  
	and EndDate between ActiveStartDate and ActiveLastDate 

	--Select P.*
	Update P Set P.Banner = S.Custom3
	From BillingControl_Expanded_POS P
	Inner Join Stores S on S.StoreID = P.StoreID
	Where P.Banner is null

	--Select *  
	--from BillingControl_Expanded_POS

	
	CREATE NONCLUSTERED INDEX IX_BillingControl_Expanded_POS_BillingControlID ON dbo.BillingControl_Expanded_POS
	(
	BillingControlID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	
	CREATE NONCLUSTERED INDEX IX_BillingControl_Expanded_POS_EntitIdToInvoice ON dbo.BillingControl_Expanded_POS
		(
		EntityIDToInvoice
		) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	
End
GO
