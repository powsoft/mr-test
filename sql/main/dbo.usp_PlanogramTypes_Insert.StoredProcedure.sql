USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PlanogramTypes_Insert]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_PlanogramTypes_Insert]  
     @PlanogramTypeID int  Output , 
     @PlanogramTypeName nvarchar(50),
     @UserIDCreated varchar(10),
     @UserIdModified varchar(50),
     @Active bit 
       
     as 
     
if (@PlanogramTypeID = 0) 
begin 
      Insert into [PlanogramTypes] (
        [PlanogramTypeName],
        [UserID_Created],
        [DateTimeCreated],
        [Active] ) 
      Values(
        @PlanogramTypeName,
        @UserIDCreated,
        GetDate() , 
        @Active 
         ) 

end 

if (@PlanogramTypeID > 0)
Begin 

     Update [PlanogramTypes] Set 
     [PlanogramTypeName] =  @PlanogramTypeName ,
     [UserId_Modified]=@UserIdModified,
     [DateTimeModified]=GetDate(),
     [Active]=@Active
      Where [PlanogramTypeID] = @PlanogramTypeID

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
