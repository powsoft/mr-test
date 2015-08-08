USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPersonDetail_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_GetPersonDetail_PRESYNC_20150329]
@ID INT

AS 

BEGIN
	SELECT P.FirstName,P.MiddleName , P.LastName ,Login AS Email,P.PersonID
	FROM Persons P 
		INNER JOIN Logins L ON L.OwnerEntityId=P.PersonID
	WHERE P.PersonID = @ID
END
GO
