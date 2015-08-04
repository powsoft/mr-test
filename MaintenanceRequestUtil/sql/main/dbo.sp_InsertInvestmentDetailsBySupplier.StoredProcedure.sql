USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_InsertInvestmentDetailsBySupplier]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_InsertInvestmentDetailsBySupplier]
	-- Add the parameters for the stored procedure here
	(@storeNumber varchar(50),@StoreID int,@physicalInventoryDate datetime,
	@invoiceAmount money,@settle varchar(50),@supplierRequestingPerson int,@settlementRequestingDate datetime,
	@aggregatedAmount money,@SupplierID int,@RetailerID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [InventorySettlementRequests]
           ([storeNumber]
           ,[storeId]
           ,[physicalInventoryDate]
           ,[invoiceAmount]
           ,[settle]
           ,RequestingPersonID
           ,RequestDate
           ,UnsettledShrink
           ,supplierId
           ,retailerId
           )
           
     VALUES
          (@storeNumber ,@StoreID ,@physicalInventoryDate ,
	@invoiceAmount ,@settle ,@supplierRequestingPerson ,@settlementRequestingDate,@aggregatedAmount
	,@SupplierID ,@RetailerID
	 );
	SELECT SCOPE_IDENTITY();
END
GO
