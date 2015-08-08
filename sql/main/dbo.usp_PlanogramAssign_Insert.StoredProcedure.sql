USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PlanogramAssign_Insert]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_PlanogramAssign_Insert]  
     @PLASSIGN_ID int output,
     @PlanogramID int , 
     @StoreID varchar(10),
     @UserIDCreated varchar(10),
     @UserIdModified varchar(50),
     @Active bit 
       
     as 
     
if (@PLASSIGN_ID = 0) 
begin 
      Insert into [PlanogramAssignments] (
        [PlanogramID],
        [StoreID]  , 
        [UserID_Created],
        [DateTimeCreated],
        [Active] ) 
      Values(
        @PlanogramID,
        @StoreID,
        @UserIDCreated,
        GetDate() , 
        @Active 
         ) 

end 

if (@PLASSIGN_ID > 0)
Begin 

     Update [PlanogramAssignments] Set 
     [PlanogramID] =  @PlanogramID , 
     [StoreID] =  @StoreID , 
     [UserId_Modified]=@UserIdModified,
     [DateTimeModified]=GetDate(),
     [Active]=@Active
      Where [PLASSIGN_ID] = @PLASSIGN_ID

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
