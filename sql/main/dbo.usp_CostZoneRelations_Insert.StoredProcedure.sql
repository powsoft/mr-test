USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CostZoneRelations_Insert]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_CostZoneRelations_Insert]  
     @CostZoneRelationId int  Output , 
     @StoreId int, 
     @SupplierId int, 
     @CostZoneId int  as 
     
if (@CostZoneRelationId = 0) 
begin 
      Insert into [CostZoneRelations] (
        [StoreId]  , 
        [SupplierId],[CostZoneID] ) 
      Values( 
        @StoreId  , 
        @SupplierId  , 
        @CostZoneId   ) 

end 

if (@CostZoneRelationId > 0)
Begin 

     Update [CostZoneRelations] Set 
     [StoreId] =  @StoreId , 
     [CostZoneID] =  @CostZoneId , 
     [SupplierId] =  @SupplierId 
      Where [CostZoneRelationID] = @CostZoneRelationId

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
