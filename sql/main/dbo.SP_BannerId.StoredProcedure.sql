USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[SP_BannerId]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BannerId]
as
begin
select custom1
from Stores
end
GO
