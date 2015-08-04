USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateContactDetails]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[amb_UpdateContactDetails]
	-- Add the parameters for the stored procedure here
	@EntityID nvarchar(50),
	@SupplierID nvarchar(50),
	@WholesalerName nvarchar(100),
	@Address nvarchar(50),
	@City nvarchar(50),
	@State nvarchar(50),
	@ZipCode nvarchar(50),
	@Contact nvarchar(50),
	@Email nvarchar(255),
	@Fax nvarchar(50),
	@AccountingContact  nvarchar(50),
	@AccountingTel  nvarchar(50),
	@AccountingEmail  nvarchar(255),
	@AccountingFax nvarchar(50),
	@CorporateParent  nvarchar(200),
	@POSWaitTimeForDCR int,
	@Address2 nvarchar(50),
	@Alerts tinyint,
	@CircManagementSys nvarchar(50),
	@Tel nvarchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	
	/* Update to the new database DataTrue_Main */
    UPDATE DataTrue_Main.dbo.Suppliers
		   SET [SupplierName] = @WholesalerName
		       ,[DateTimeLastUpdate]=getdate()
		       ,[LastUpdateUserID]=@SupplierID
		       WHERE SupplierID = @SupplierID 
		   
	UPDATE DataTrue_Main.dbo.Addresses
			SET [Address1]=@Address
				,[City]=@City
				,[State]=@State
				,[PostalCode]=@ZipCode
				,[DateTimeLastUpdate]=getdate()
		        ,[LastUpdateUserID]=@SupplierID
			    WHERE OwnerEntityID=@SupplierID
        
   UPDATE DataTrue_Main.dbo.ContactInfo  
          SET [DeskPhone]=@Tel
             ,[Fax]= @Fax
             ,[FirstName]=@Contact 
             ,[Email]=@Email
             ,[DateTimeLastUpdate]=getdate()
		     ,[LastUpdateUserID]=@SupplierID
             WHERE OwnerEntityID=@SupplierID 
             

   /* Update to the old database(iControl) */	
   UPDATE [IC-HQSQL2].iControl.dbo.[WholesalersList]
		   SET [WholesalerName] = @WholesalerName
			  ,[Address] = @Address
			  ,[City] =@City
			  ,[State] = @State
			  ,[ZipCode] = @ZipCode 
			  ,[Fax] = @Fax
			  ,[Contact] = @Contact
			  ,[Email] = @Email
			  ,[CorporateParent] = @CorporateParent
			  ,[POSWaitTimeForDCR] = @POSWaitTimeForDCR
			  ,[AccountingContact] = @AccountingContact
			  ,[AccountingEmail] = @AccountingEmail
			  ,[AccountingTel] = @AccountingTel
			  ,[AccountingFax] = @AccountingFax
			  ,[Address2]=@Address2
			  ,[SellOutAlert]=@Alerts
			  ,[CircManagementSys]=@CircManagementSys   
			  WHERE WholesalerID = @EntityID 
END
GO
