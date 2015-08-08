USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveStoreDeliveryDates]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_SaveStoreDeliveryDates]
     @StoreId varchar(20),
     @ReplenishmentFrequency varchar(10),
     @ReplenishmentType varchar(10),
     @DeliveryDayOrDate VarChar(50),
     @DeliveryTime varchar(10),
     @DaysToNextDelivery int
as
begin
	INSERT INTO [PlanogramStoreDeliveryDates] (StoreID, ReplenishmentFrequency, ReplenishmentType, DeliveryDayOrDate, DeliveryTime, DaysToNextDelivery)
	VALUES		(@StoreId, @ReplenishmentFrequency, @ReplenishmentType, @DeliveryDayOrDate, @DeliveryTime, @DaysToNextDelivery)
	
	
end
GO
