USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[SP_RetailerName]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_RetailerName]
as
begin
select ChainName
from Chains
end
GO
