USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PlanogramAuthList_Insert]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_PlanogramAuthList_Insert]  
     @PAL_ID int output,
     @PlanogramID int , 
     @ProductID varchar(10),
     @UserIDCreated varchar(10),
     @UserIdModified varchar(50),
     @Active bit 
       
     as 
     
if (@PAL_ID = 0) 
begin 
      Insert into [PlanogramAuthorizedList] (
        [PlanogramID],
        [ProductID]  , 
        [UserID_Created],
        [DateTimeCreated],
        [Active] ) 
      Values(
        @PlanogramID,
        @ProductID,
        @UserIDCreated,
        GetDate() , 
        @Active 
         ) 

end 

if (@PAL_ID > 0)
Begin 

     Update [PlanogramAuthorizedList] Set 
     [PlanogramID] =  @PlanogramID , 
     [ProductID] =  @ProductID , 
     [UserId_Modified]=@UserIdModified,
     [DateTimeModified]=GetDate(),
     [Active]=@Active
      Where [PAL_ID] = @PAL_ID

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
