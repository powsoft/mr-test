USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SavePODeliveryDates]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SavePODeliveryDates]
     @StoreSetupId varchar(20),
     @DeliveryDayOrDate VarChar(50),
     @DeliveryTime varchar(10),
     @DaysToNextDelivery int
as
begin
	INSERT INTO [PO_DeliveryDates](StoreSetupID,DeliveryDayOrDate,DeliveryTime, DaysToNextDelivery)
	VALUES		(@StoreSetupId, @DeliveryDayOrDate, @DeliveryTime, @DaysToNextDelivery)
	
	
end
GO
