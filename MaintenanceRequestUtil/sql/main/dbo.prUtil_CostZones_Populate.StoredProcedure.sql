USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_CostZones_Populate]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_CostZones_Populate]
as


select top 1000 * from SuppliersSetupData

select distinct datatruesupplierid, pricezone 
from SuppliersSetupData
order by datatruesupplierid, pricezone 

select distinct supplierid, pricezone 
from SuppliersSetupDataMore
order by supplierid, pricezone 

select distinct supplierid, pricezone 
from SuppliersSetupDataMoreNestle
order by supplierid, pricezone 

return
GO
