USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReportRequest_New]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_ReportRequest_New]
  @AutoReportRequestID int,  
     @PersonID int , 
     @ReportID int , 
     @DateRequested datetime , 
     @LastXDays int , 
     @ChainID int , 
     @Banner nvarchar(50) , 
     @SupplierID int , 
     @StoreID int , 
     @ProductUPC int , 
     @GetEveryXDays int ,
     @Days varchar(15),
     @SubscriptionStartDate datetime, 
     @By12pmEST bit , 
     @By5pmEST bit , 
     @FileType nchar(10)    as 

if (@AutoReportRequestID = 0) 

begin 


      Insert into [AutomatedReportsRequests] (
        [PersonID]  , 
        [ReportID]  , 
        [DateRequested]  , 
        [LastXDays]  , 
        [ChainID]  , 
        [Banner]  , 
        [SupplierID]  , 
        [StoreID]  , 
        [ProductUPC]  , 
        [GetEveryXDays]  ,
        [Days] ,
        [SubscriptionStartDate] ,
        [By12pmEST]  , 
        [By5pmEST]  , 
        [FileType]      ) 
      Values( 
        @PersonID  , 
        @ReportID  , 
        @DateRequested  , 
        @LastXDays  , 
        @ChainID  , 
        @Banner  , 
        @SupplierID  , 
        @StoreID  , 
        @ProductUPC  , 
        @GetEveryXDays  , 
        @Days ,
        @SubscriptionStartDate ,
        @By12pmEST  , 
        @By5pmEST  , 
        @FileType      ) 

end 

if (@AutoReportRequestID > 0)
Begin 

     Update [AutomatedReportsRequests] Set 
     [LastXDays] =  @LastXDays , 
     [ChainID] =  @ChainID , 
     [Banner] =  @Banner , 
     [SupplierID] =  @SupplierID , 
     [StoreID] =  @StoreID , 
     [ProductUPC] =  @ProductUPC , 
     [GetEveryXDays] =  @GetEveryXDays , 
     [Days] = @Days ,
     [SubscriptionStartDate] = @SubscriptionStartDate ,
     [By12pmEST] =  @By12pmEST , 
     [By5pmEST] =  @By5pmEST , 
     [FileType] =  @FileType  
     
 where  [AutoReportRequestID] = @AutoReportRequestID 
  

End 
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
