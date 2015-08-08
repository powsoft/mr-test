USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveContactInfo_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SaveContactInfo_PRESYNC_20150329]

 @C_Id int,
 @SupplierId varchar(50),
 @Title varchar(50),
 @FirstName varchar(50),
 @LastName varchar(50),
 @MidName varchar(50),
 @DeskPhone varchar(50),
 @MobileNo varchar(50),
 @Fax varchar(50),
 @Email varchar(4000),
 @Comments varchar(50),
 @UserID varchar(50), 
 @Default varchar(50),
 @RecvdACH varchar(10),
 @RecvdMonthlyFee varchar(10)
        
as
begin
	if(@Default=2)
	    UPDATE ContactInfo SET ContactTypeID=0 WHERE OwnerEntityID=@SupplierId  
	 
    if(@C_Id=0)
		INSERT INTO [ContactInfo]
           ([OwnerEntityID]
           ,[Title]
           ,[FirstName]
           ,[LastName]
           ,[MiddleName]
           ,[DeskPhone]
           ,[MobilePhone]
           ,[Fax]
           ,[Email]
           ,[Comments]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[ContactTypeID]
           ,[ReceiveACHNotifications]
           ,[ReceiveMonthlyFeeInvoice])
     VALUES
           (
            @SupplierId,
            @Title,
            @FirstName,
            @LastName,
            @MidName,
            @DeskPhone,
            @MobileNo,
            @Fax,
            replace(@Email,',',';'),
            @Comments,
            getdate(),
            @UserID,
            getdate(),
            @Default,
            @RecvdACH,
            @RecvdMonthlyFee
           )
    else
		UPDATE [ContactInfo]
		   SET [OwnerEntityID]=@SupplierId
			   ,[Title]=@Title
			   ,[FirstName]=@FirstName
			   ,[LastName]=@LastName
			   ,[MiddleName]=@MidName
			   ,[DeskPhone]=@DeskPhone
			   ,[MobilePhone]=@MobileNo
			   ,[Fax]=@Fax
			   ,[Email]=replace(@Email,',',';')
			   ,[Comments]=@Comments
			   ,[LastUpdateUserID]=@UserID
			   ,[DateTimeLastUpdate]=getdate()
			   ,[ContactTypeID]=@Default
			   ,[ReceiveACHNotifications]=@RecvdACH
			   ,[ReceiveMonthlyFeeInvoice]=@RecvdMonthlyFee
		 WHERE [ContactID] = @C_Id
end
GO
