USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_SUP_Invoices_Web_JobSteps]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prBilling_SUP_Invoices_Web_JobSteps]
as

exec dbo.prGetInboundInventory_WEB

--exec 




return
GO
