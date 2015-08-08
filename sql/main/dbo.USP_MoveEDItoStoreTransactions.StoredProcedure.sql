USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[USP_MoveEDItoStoreTransactions]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Joshua Kiracofe
-- Create date: 2/13/2014
-- Description:	Run various step to move EDI data to StoreTransactions Table Daily
-- =============================================
CREATE PROCEDURE [dbo].[USP_MoveEDItoStoreTransactions]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
exec [dbo].[prGetInboundPOSTransactions_Newspapers]

select workingstatus as stat, *
from StoreTransactions_Working With (NoLock)
where ChainIdentifier in (select EntityIdentifier 
							from ProcessStepEntities 
							where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')
and CAST(DateTimeCreated as Date) = CAST(GetDate() as date)
order by workingstatus

exec dbo.prValidateStoresInStoreTransactions_Working_Newspapers

select workingstatus as stat, *
from StoreTransactions_Working With (NoLock)
where ChainIdentifier in (select EntityIdentifier 
							from ProcessStepEntities 
							where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')
and CAST(DateTimeCreated as Date) = CAST(GetDate() as date)
							
							
exec [dbo].[prValidateProductsInStoreTransactions_Working_Newspapers]

select workingstatus as stat, *
from StoreTransactions_Working With (NoLock)
where ChainIdentifier in (select EntityIdentifier 
							from ProcessStepEntities 
							where ProcessStepName = 'prGetInboundPOSTransactions_Newspapers')
and CAST(DateTimeCreated as Date) = CAST(GetDate() as date)
							
exec [dbo].[prValidateSuppliersInStoreTransactions_Working_Newpapers]

select workingstatus as stat, *
from StoreTransactions_Working With (NoLock)
where ChainId in (select EntityIDToInclude 
							from ProcessStepEntities 
							where ProcessStepName = 'prVallidateSuppliersInStoreTransactions_Working_Newspapers')
and CAST(DateTimeCreated as Date) = CAST(GetDate() as date)
						
exec [dbo].[prValidateSourceInStoreTransactions_Working_Newspapers]

select workingstatus as stat, *
from StoreTransactions_Working With (NoLock)
where ChainId in (select EntityIDToInclude 
							from ProcessStepEntities 
							where ProcessStepName = 'prValidateSourceInStoreTransactions_Working_Newspaper')
and CAST(DateTimeCreated as Date) = CAST(GetDate() as date)
							
exec [dbo].[prValidateTransactionTypeInStoreTransactions_Working_Newspapers]
							
select *
from StoreTransactions With (NoLock)
where ChainId in (select EntityIDToInclude 
							from ProcessStepEntities 
							where ProcessStepName = 'prValidateSourceInStoreTransactions_Working_Newspaper')
and CAST(DateTimeCreated as Date) = CAST(GetDate() as date)



END
GO
