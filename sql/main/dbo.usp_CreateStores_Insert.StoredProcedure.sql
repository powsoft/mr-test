USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateStores_Insert]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_CreateStores_Insert]  
	 @ID int ,
     @StoreNumber int , 
     @SBTNumber int , 
     @Address varchar(50) , 
     @City varchar(50) , 
     @ZipCode varchar(50) , 
     @State varchar(50) , 
     @ChainId varchar(50) , 
     @Banner varchar(50) , 
     @OpeningDate datetime , 
     @StoreMgr varchar(50) , 
     @District varchar(50) , 
     @Area varchar(50) , 
     @UserID varchar(50) , 
     @DateEntered datetime as 

if (@ID = 0) 

begin 


      Insert into [CreateStores] (
        [StoreNumber]  , 
        [SBTNumber]  , 
        [Address]  , 
        [City]  , 
        [ZipCode]  , 
        [State]  , 
        [Banner]  , 
        [ChainId] ,
        [OpeningDate]  , 
        [StoreMgr]  , 
        [District]  , 
        [Area]  , 
        [UserID]  , 
        [DateEntered]   ) 
      Values( 
        @StoreNumber  , 
        @SBTNumber  , 
        @Address  , 
        @City  , 
        @ZipCode  , 
        @State  , 
        @Banner  ,
        @ChainId, 
        @OpeningDate  , 
        @StoreMgr  , 
        @District  , 
        @Area  , 
        @UserID  , 
        @DateEntered   ) 

end 

if (@ID > 0)
Begin 

     Update [CreateStores] Set 
     [StoreNumber] =  @StoreNumber , 
     [SBTNumber] =  @SBTNumber , 
     [Address] =  @Address , 
     [City] =  @City , 
     [ZipCode] =  @ZipCode , 
     [State] =  @State , 
     [Banner] =  @Banner , 
     [ChainId] = @ChainId,
     [OpeningDate] =  @OpeningDate , 
     [StoreMgr] =  @StoreMgr , 
     [District] =  @District , 
     [Area] =  @Area , 
     [UserID] =  @UserID , 
     [DateEntered] =  @DateEntered 
where ID = @ID 

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
