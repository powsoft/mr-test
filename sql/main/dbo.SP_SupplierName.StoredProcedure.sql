USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[SP_SupplierName]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_SupplierName]
as
begin
select suppliername
from Suppliers
end
GO
