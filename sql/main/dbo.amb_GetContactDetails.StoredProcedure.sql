USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetContactDetails]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[amb_GetContactDetails] 
	-- Add the parameters for the stored procedure here
@EntityID nvarchar(50),
@SupplierID nvarchar(20)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ContactType int
	
	SELECT @ContactType= CT.ContactTypeId 
	FROM dbo.ContactInfo CI
	INNER JOIN dbo.ContactTypes CT on CT.ContactTypeId=CI.ContactTypeId
	WHERE CI.OwnerEntityId=@SupplierID

    IF(@ContactType=0)
		BEGIN
			Select S.SupplierIdentifier as [WholesalerID],S.SupplierName as [WholesalerName],A.Address1 as [Address],
			A.City,A.State,A.PostalCode as [ZipCode],CI.DeskPhone as [Tel],CI.Fax,CI.FirstName as [Contact],CI.Email,A.Address2,
			'0' as [SellOutAlert],'' as [CorporateParent],'' as [CircManagementSys],'' as [POSWaitTimeForDCR],
			CI.FirstName as [AccountingContact],CI.Email as [AccountingEmail],CI.DeskPhone as [AccountingTel],CI.Fax as [AccountingFax]

			FROM dbo.Suppliers S
			INNER JOIN dbo.Addresses A ON A.OwnerEntityId=S.SupplierID
			INNER JOIN dbo.ContactInfo CI ON CI.OwnerEntityId=S.SupplierId
			WHERE S.SupplierId=@SupplierID
		END
    ELSE
		BEGIN
			SELECT [WholesalerID],[WholesalerName],[Address],[City],[State],[ZipCode],[Tel],[Fax]
				  ,[Contact],[Email],[Address2],[SellOutAlert],[CorporateParent],[CircManagementSys]
				  ,[POSWaitTimeForDCR],[AccountingContact],[AccountingEmail],[AccountingTel],[AccountingFax]
			FROM [IC-HQSQL2].icontrol.dbo.WholesalersList 
			WHERE WholesalerID = @EntityID
		  END
END
GO
