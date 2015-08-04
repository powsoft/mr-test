USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SavePOPrintDetails]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_SavePOPrintInformation '06/18/2012', 40557, 40365, 15
Create  Procedure [dbo].[usp_SavePOPrintDetails]
     @PuchaseOrderNo varchar(50),
     @ProductId varchar(50),
     @Qty int,
     @RetailPrice money,
     @Allowance money,
     @Cost money
     
as
begin

    INSERT INTO [DataTrue_Main].[dbo].[PO_PrintDetails]
           ([PuchaseOrderNo]
           ,[ProductId]
           ,[Qty]
           ,[RetailPrice]
           ,[Allowance]
           ,[Cost])
     VALUES
           (@PuchaseOrderNo
           ,@ProductId
           ,@Qty
           ,@RetailPrice
           ,@Allowance
           ,@Cost
           )
end
GO
