USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_DataScrubbing_Products_Update]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_DataScrubbing_Products_Update]
@productid int,
@productname nvarchar(50),
@productdescription nvarchar(50)

as



update p set ProductName = @productname, [Description] = @productdescription
from Products p
where ProductID = @productid


return
GO
