USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Custom_Calendar]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[usp_Custom_Calendar] 
	@PersonID int,
	@chainID varchar(50),
	@InternalName varchar(50)
AS --Select * from custom_dates
BEGIN
--exec usp_Custom_Calendar 40384,40393,-1
Declare @Query varchar(5000)

Set @Query=' select Custom_date_id,internal_name as [Calender Name] ,Description  ,start_date as [Start date] , end_date as [End Date] from custom_dates where 1=1 '
if(@InternalName<>'-1')
	set @Query=@Query+ ' and Custom_date_id=''' +@InternalName+''''
IF (@chainID<>'-1')
	set @Query=@Query+ ' and OwnerEntityID=''' +@chainID+''''

PRINT @Query
exec (@Query )
END
GO
