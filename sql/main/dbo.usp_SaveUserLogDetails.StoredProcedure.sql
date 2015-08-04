USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveUserLogDetails]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_SaveUserLogDetails]

@UserID varchar(100),
@PageID varchar(10),
@PageName varchar(100),
@SystemIP varchar(100)

-- exec usp_SaveUserLogDetails 'gilad.keren@icontroldsd.com','0','Login'
as 
 begin
 declare @UID varchar(10)
 declare @ReturnID varchar(10)
 
 SELECT @UID = OwnerEntityID from  Logins where Login = @UserID or cast(OwnerEntityID as VARCHAR(200))= @UserID

 select @ReturnID = LogId from userlog U where UserID = @UID and PageID = @PageID AND PageName=@PageName and LogID = (SELECT max(LogID) from UserLog where UserID=U.UserID)
 
 if(@ReturnID is null)
    begin
		INSERT INTO [UserLog]
				   (
				   [TimeStamp]
				   ,[UserID]
				   ,[PageID]
				   ,[PageName]
				   ,[IPAddress]
				   )
			 VALUES
				   (
				    getdate()
				   ,@UID
				   ,@PageID
				   ,@PageName 
				   ,@SystemIP
 				   )
 	end			   
end
GO
