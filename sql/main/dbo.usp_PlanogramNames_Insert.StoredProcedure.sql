USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PlanogramNames_Insert]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_PlanogramNames_Insert]  
     @PlanogramID int  Output , 
     @PlanogramName nvarchar(50),
     @ChainId varchar(10),
     @PlanogramTypeID int,
     @UserIDCreated varchar(10),
     @UserIdModified varchar(50),
     @Active bit 
       
     as 
     
if (@PlanogramID = 0) 
begin 
      Insert into [PlanogramNames] (
        [PlanogramName],
        [RetailerID]  , 
        [PlanogramTypeID]  , 
        [UserID_Created],
        [DateTimeCreated],
        [Active] ) 
      Values(
        @PlanogramName,
        @ChainId,
        @PlanogramTypeID,
        @UserIDCreated,
        GetDate() , 
        @Active 
         ) 

end 

if (@PlanogramID > 0)
Begin 

     Update [PlanogramNames] Set 
     [PlanogramName] =  @PlanogramName , 
     [RetailerID] =  @ChainId , 
     [PlanogramTypeID] =  @PlanogramTypeID ,
     [UserId_Modified]=@UserIdModified,
     [DateTimeLastUpdate]=GetDate(),
     [Active]=@Active
      Where [PlanogramID] = @PlanogramID

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
