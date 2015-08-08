USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetEmails_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_GetEmails_PRESYNC_20150415]
(
@ID INT,
@AccessType VARCHAR(20)
)
AS
BEGIN
	IF(@AccessType = 'Supplier')	
		BEGIN
			Select P.FirstName + ' ' + P.LastName AS Name,P.PersonID,Login AS Email from SupplierAccess S
			INNER JOIN Persons P ON P.PersonID=S.PersonId
			INNER JOIN Logins L ON L.OwnerEntityId=P.PersonID
			Where SupplierId=@ID AND P.PersonID > 0
		END
	ELSE IF(@AccessType='Chain')
		BEGIN
			Select P.FirstName + ' ' + P.LastName AS Name,P.PersonID,Login AS Email from RetailerAccess R
			INNER JOIN Persons P ON P.PersonID=R.PersonId
			INNER JOIN Logins L ON L.OwnerEntityId=P.PersonID
			Where ChainId=@ID AND P.PersonID > 0
		END
END
GO
