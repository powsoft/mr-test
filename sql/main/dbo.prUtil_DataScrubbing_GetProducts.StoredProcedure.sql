USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_DataScrubbing_GetProducts]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_DataScrubbing_GetProducts]
as



select ProductId, ProductName, [Description]
from Products
--where ProductID = 0
--where DATEDIFF(day, datetimecreated, getdate()) < 2
order by ProductID Desc


return
GO
