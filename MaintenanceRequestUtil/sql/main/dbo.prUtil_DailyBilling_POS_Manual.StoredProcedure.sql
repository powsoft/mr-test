USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_DailyBilling_POS_Manual]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_DailyBilling_POS_Manual]
as

exec dbo.prSendEmailNotification_PassEmailAddresses 'Daily Billing Job Started'
,'Retailer and supplier invoicing has started for today''s POS files'
,'DataTrue System', 0, 'charlie.clark@icontroldsd.com;tatiana.alperovitch@icontroldsd.com;gilad.keren@icontroldsd.com'
GO
