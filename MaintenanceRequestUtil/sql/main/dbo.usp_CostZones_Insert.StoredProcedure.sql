USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CostZones_Insert]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec usp_CostZones_Insert 'test','testing data',40557
CREATE Procedure [dbo].[usp_CostZones_Insert]  
     @CostZoneId int  Output , 
     @CostZoneName nvarchar(50) , 
     @CostZoneDescription nchar(255) , 
     @SupplierId int  as 
     
if (@CostZoneId = 0) 
begin 
      Insert into [CostZones] (
        [CostZoneName]  , 
        [CostZoneDescription]  , 
        [SupplierId]   ) 
      Values( 
        @CostZoneName  , 
        @CostZoneDescription  , 
        @SupplierId ) 

end 

if (@CostZoneId > 0)
Begin 

     Update [CostZones] Set 
     [CostZoneName] =  @CostZoneName , 
     [CostZoneDescription] =  @CostZoneDescription , 
     [SupplierId] =  @SupplierId 
      Where [CostZoneId] = @CostZoneId

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
