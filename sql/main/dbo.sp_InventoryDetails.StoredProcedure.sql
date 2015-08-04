USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_InventoryDetails]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_InventoryDetails]
	-- Add the parameters for the stored procedure here
	@supplierID varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   select t1.StoreId,t2.StoreIdentifier,sum(t1.TotalCost) as invamount,t1.SaleDate,t1.InventorySettlementId,t1.invoiceDetailId,t1.InvoiceDetailTypeID,t1.ChainID,t1.supplierId
from InvoiceDetails t1,Stores t2
 where t1.InventorySettlementId is null and t1.supplierId=@supplierID
 and t1.StoreId=t2.storeId group by t1.StoreId,t2.StoreIdentifier,t1.SaleDate ,t1.InventorySettlementId,t1.invoiceDetailId,t1.InvoiceDetailTypeID,t1.ChainID,t1.supplierId
 order by t1.storeid,t1.SaleDate desc
END
GO
