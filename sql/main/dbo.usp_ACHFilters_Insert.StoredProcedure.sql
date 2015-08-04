USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ACHFilters_Insert]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_ACHFilters_Insert]  
     @ACHFilterID int  Output , 
     @SupplierId int,
     @ChainId int,
     @ACHFilterTypeID int,
     @State varchar(20),
     @ACHFilterValue nvarchar(50) 
       
     as 
     
if (@ACHFilterID = 0) 
begin 
      Insert into [ACHFilters] (
        [ChainId]  , 
        [SupplierID]  , 
        [State],
        [ACHFilterTypeId],
        [ACHFilterValue] ) 
      Values(
        @ChainId,
        @SupplierId,
        @State,
        @ACHFilterTypeID  , 
        @ACHFilterValue 
         ) 

end 

if (@ACHFilterID > 0)
Begin 

     Update [ACHFilters] Set 
     [ChainId] =  @ChainId , 
     [SupplierID] =  @SupplierId , 
     [State] =  @State ,
     [ACHFilterTypeId]=@ACHFilterTypeID,
     [ACHFilterValue]=@ACHFilterValue
      Where [ACHFilterID] = @ACHFilterID

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
