USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateProductsPricesPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[amb_UpdateProductsPricesPUB]
	 @CostToStore money,
	 @CostToStore4Wholesaler money,
	 @CostToWholesaler money,
	 @SuggRetail money,
	 @BiPad varchar(20),
	 @WholesalerID varchar(20),
	 @ChainID varchar(20),
	 @dbType varchar(20)
AS
BEGIN
	if(@dbType='0')
		begin
			UPDATE [IC-HQSQL\ICONTROL].iControl.dbo.ProductsPrices 
			SET 
			CostToStore =  @CostToStore  , 
			CostToStore4Wholesaler =  @CostToStore4Wholesaler,
			CostToWholesaler =  @CostToWholesaler , 
			SuggRetail =  @SuggRetail 
			WHERE BiPad= @BiPad 
			AND WholesalerID= @WholesalerID AND ChainID = @ChainID
		end

	else
		begin	
			UPDATE dbo.ProductPrices 
			SET UnitPrice=@CostToStore,
			UnitRetail=@SuggRetail	
			FROM dbo.ProductPrices PP
			INNER JOIN dbo.Products P ON P.ProductID=PP.ProductID
			INNER JOIN dbo.ProductIdentifiers PI ON PI.ProductID=PP.ProductID AND PI.ProductIdentifierTypeID=8
			INNER JOIN dbo.Suppliers S ON S.SupplierID=PP.SupplierID
			INNER JOIN dbo.Chains C ON C.ChainID=PP.ChainID
			WHERE PI.Bipad=@BiPad AND S.SupplierIdentifier=@WholesalerID AND C.ChainIdentifier=@ChainID
		end
	END
GO
