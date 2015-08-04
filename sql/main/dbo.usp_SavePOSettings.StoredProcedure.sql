USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SavePOSettings]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SavePOSettings]
     @StoreSetupId varchar(20),
     @ReplenishmentFrequency int,
     @ReplenishmentType varchar(50),
     @PlanogramCapacityMax int ,
     @PlanogramCapacityMin int ,
     @DateRange int,
     @FillRate float,
     @LeadTime int
    
as
begin
    Declare @strSQL varchar(4000)
	
	DECLARE @RecordExist varchar(20)=''
   
    -- Set Start Date = 18 weeks old and EndDate = 1 week old
    SELECT @RecordExist = StoreSetupID from PO_Criteria where StoreSetupID=@StoreSetupId
           
         
    if(@RecordExist='')
        Begin
            INSERT INTO [DataTrue_Main].[dbo].[PO_Criteria]
			   ([StoreSetupID]
			   ,[ReplenishmentFrequency]
			   ,[ReplenishmentType]
			   ,[PlanogramCapacityMax]
			   ,[PlanogramCapacityMin]
			   ,[DateRange]
			   ,[FillRate]
			   ,[LeadTime])
		    VALUES
			   (@StoreSetupId
			   ,@ReplenishmentFrequency
			   ,@ReplenishmentType
			   ,@PlanogramCapacityMax
			   ,@PlanogramCapacityMin
			   ,@DateRange
			   ,@FillRate
			   ,@LeadTime)
	        End
    else
    Begin
		UPDATE [DataTrue_Main].[dbo].[PO_Criteria]
		   SET [StoreSetupID] = @StoreSetupId
			  ,[ReplenishmentFrequency] = @ReplenishmentFrequency
			  ,[ReplenishmentType] = @ReplenishmentType
			  ,[PlanogramCapacityMax] = @PlanogramCapacityMax
			  ,[PlanogramCapacityMin] = @PlanogramCapacityMin
			  ,[DateRange] = @DateRange
			  ,[FillRate] = @FillRate
			  ,[LeadTime] = @LeadTime
		 WHERE StoreSetupID=@StoreSetupId
    End    
end
GO
