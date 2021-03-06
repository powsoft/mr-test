USE [DataTrue_EDI]
GO
/****** Object:  UserDefinedFunction [dbo].[fnCalcProductHashSig]    Script Date: 06/25/2015 16:58:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[fnCalcProductHashSig]
(
	@SupplierIdentifier VARCHAR(100),
	--@UPC VARCHAR(100),
	--@ItemNumber VARCHAR(100),
	@ProductIdentifier VARCHAR(200),
	@ProductDesc VARCHAR(500),
	@UOM VARCHAR(50),
	@PackSize VARCHAR(50)
)
RETURNS VARBINARY(128)
AS
BEGIN
	DECLARE @Input VARCHAR(1000)
	DECLARE @HashSig VARBINARY(128)
	SELECT @Input = LTRIM(RTRIM(ISNULL(@SupplierIdentifier, ''))) + '/' +
					--LTRIM(RTRIM(ISNULL(@UPC, ''))) + '/' +
					--LTRIM(RTRIM(ISNULL(@ItemNumber, ''))) + '/' +
					LTRIM(RTRIM(ISNULL(@ProductIdentifier, ''))) + '/' +
					LTRIM(RTRIM(ISNULL(@ProductDesc, ''))) + '/' +
					LTRIM(RTRIM(ISNULL(@UOM, ''))) + '/' +
					LTRIM(RTRIM(ISNULL(@PackSize, '')))
	SELECT @HashSig = HASHBYTES('MD5', @Input)	
	RETURN @HashSig
END
GO
