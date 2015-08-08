USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PlanogramReplenishment_Insert]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_PlanogramReplenishment_Insert]  
     @PlanReplenishID int output,
     @PlanogramID int , 
     @ProductID varchar(10),
     @MinCapacity varchar(20),
     @MaxCapacity varchar(20),
     @UserIDCreated varchar(10),
     @UserIdModified varchar(50),
     @Active bit 
       
     as 
     
if (@PlanReplenishID = 0) 
begin 
      Insert into [PlanogramReplenishment] (
        [PlanogramID],
        [ProductID]  , 
        [MinCapacity] ,
        [MaxCapacity],
        [UserID_Created],
        [DateTimeCreated],
        [Active] ) 
      Values(
        @PlanogramID,
        @ProductID,
        @MinCapacity,
        @MaxCapacity,
        @UserIDCreated,
        GetDate() , 
        @Active 
         ) 

end 

if (@PlanReplenishID > 0)
Begin 

     Update [PlanogramReplenishment] Set 
     [PlanogramID] =  @PlanogramID , 
     [ProductID] =  @ProductID , 
     [MinCapacity] = @MinCapacity,
     [MaxCapacity] = @MaxCapacity,
     [UserId_Modified]=@UserIdModified,
     [DateTimeModified]=GetDate(),
     [Active]=@Active
      Where [PlanReplenishID] = @PlanReplenishID

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
